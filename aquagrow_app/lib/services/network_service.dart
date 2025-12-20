import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/network_device.dart';
import '../models/emergency_message.dart';
import 'dart:async';
import 'dart:convert';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Nearby _nearby = Nearby();
  final String _serviceId = 'com.beacon.emergency';
  final String _deviceId = const Uuid().v4();
  
  String? _deviceName;
  Strategy _strategy = Strategy.P2P_STAR;
  
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  bool _isConnected = false;
  
  final Map<String, NetworkDevice> _discoveredDevices = {};
  final Map<String, NetworkDevice> _connectedDevices = {};
  
  // Streams
  final _deviceStreamController = StreamController<List<NetworkDevice>>.broadcast();
  final _messageStreamController = StreamController<EmergencyMessage>.broadcast();
  final _connectionStreamController = StreamController<bool>.broadcast();
  
  Stream<List<NetworkDevice>> get deviceStream => _deviceStreamController.stream;
  Stream<EmergencyMessage> get messageStream => _messageStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;
  
  List<NetworkDevice> get discoveredDevices => _discoveredDevices.values.toList();
  List<NetworkDevice> get connectedDevices => _connectedDevices.values.toList();
  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;
  bool get isConnected => _isConnected;
  
  String get deviceId => _deviceId;
  String? get deviceName => _deviceName;

  /// Initialize the network service
  Future<bool> initialize({required String deviceName}) async {
    _deviceName = deviceName;
    
    // Request necessary permissions
    final permissions = await _requestPermissions();
    if (!permissions) {
      debugPrint('NetworkService: Permissions denied');
      return false;
    }
    
    return true;
  }

  /// Request required permissions
  Future<bool> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final location = await Permission.location.request();
      final storage = await Permission.storage.request();
      final bluetooth = await Permission.bluetooth.request();
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();
      
      return location.isGranted && 
             (storage.isGranted || bluetooth.isGranted) &&
             (bluetoothScan.isGranted || bluetoothConnect.isGranted);
    }
    return true;
  }

  /// Start advertising (host mode)
  Future<bool> startAdvertising() async {
    if (_isAdvertising) return true;
    
    try {
      await _nearby.startAdvertising(
        _deviceName ?? 'BEACON Device',
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
      
      _isAdvertising = true;
      _connectionStreamController.add(true);
      debugPrint('NetworkService: Started advertising');
      return true;
    } catch (e) {
      debugPrint('NetworkService: Error starting advertising: $e');
      return false;
    }
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    
    try {
      await _nearby.stopAdvertising();
      _isAdvertising = false;
      _connectionStreamController.add(false);
      debugPrint('NetworkService: Stopped advertising');
    } catch (e) {
      debugPrint('NetworkService: Error stopping advertising: $e');
    }
  }

  /// Start discovering devices
  Future<bool> startDiscovering() async {
    if (_isDiscovering) return true;
    
    try {
      await _nearby.startDiscovery(
        _deviceName ?? 'BEACON Device',
        _strategy,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: _serviceId,
      );
      
      _isDiscovering = true;
      debugPrint('NetworkService: Started discovering');
      return true;
    } catch (e) {
      debugPrint('NetworkService: Error starting discovery: $e');
      return false;
    }
  }

  /// Stop discovering
  Future<void> stopDiscovering() async {
    if (!_isDiscovering) return;
    
    try {
      await _nearby.stopDiscovery();
      _isDiscovering = false;
      debugPrint('NetworkService: Stopped discovering');
    } catch (e) {
      debugPrint('NetworkService: Error stopping discovery: $e');
    }
  }

  /// Connect to a discovered device
  Future<bool> connectToDevice(String endpointId) async {
    try {
      await _nearby.requestConnection(
        _deviceName ?? 'BEACON Device',
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      return true;
    } catch (e) {
      debugPrint('NetworkService: Error connecting to device: $e');
      return false;
    }
  }

  /// Accept connection request
  Future<bool> acceptConnection(String endpointId) async {
    try {
      await _nearby.acceptConnection(
        endpointId,
        onPayLoadRecieved: _onPayloadReceived,
        onPayloadTransferUpdate: _onPayloadTransferUpdate,
      );
      return true;
    } catch (e) {
      debugPrint('NetworkService: Error accepting connection: $e');
      return false;
    }
  }

  /// Reject connection request
  Future<bool> rejectConnection(String endpointId) async {
    try {
      await _nearby.rejectConnection(endpointId);
      return true;
    } catch (e) {
      debugPrint('NetworkService: Error rejecting connection: $e');
      return false;
    }
  }

  /// Send message to connected device
  Future<bool> sendMessage(EmergencyMessage message, String endpointId) async {
    if (!_connectedDevices.containsKey(endpointId)) {
      debugPrint('NetworkService: Device not connected: $endpointId');
      return false;
    }
    
    try {
      final payload = Payload.bytesMessage(
        Uint8List.fromList(utf8.encode(jsonEncode(message.toMap()))),
      );
      
      await _nearby.sendPayload(endpointId, payload);
      debugPrint('NetworkService: Message sent to $endpointId');
      return true;
    } catch (e) {
      debugPrint('NetworkService: Error sending message: $e');
      return false;
    }
  }

  /// Broadcast message to all connected devices
  Future<void> broadcastMessage(EmergencyMessage message) async {
    for (final device in _connectedDevices.values) {
      if (device.endpointId != null) {
        await sendMessage(message, device.endpointId!);
      }
    }
  }

  /// Callbacks
  void _onEndpointFound(String endpointId, String deviceName, String serviceId) {
    debugPrint('NetworkService: Endpoint found: $deviceName ($endpointId)');
    
    final device = NetworkDevice(
      deviceId: endpointId,
      deviceName: deviceName,
      endpointId: endpointId,
      lastSeen: DateTime.now(),
      isConnected: false,
    );
    
    _discoveredDevices[endpointId] = device;
    _deviceStreamController.add(_discoveredDevices.values.toList());
  }

  void _onEndpointLost(String endpointId) {
    debugPrint('NetworkService: Endpoint lost: $endpointId');
    _discoveredDevices.remove(endpointId);
    _connectedDevices.remove(endpointId);
    _deviceStreamController.add(_discoveredDevices.values.toList());
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    debugPrint('NetworkService: Connection initiated: $endpointId');
    // Auto-accept connections in emergency mode
    acceptConnection(endpointId);
  }

  void _onConnectionResult(String endpointId, Status status) {
    debugPrint('NetworkService: Connection result: $endpointId - $status');
    
    if (status == Status.CONNECTED) {
      final device = _discoveredDevices[endpointId];
      if (device != null) {
        final connectedDevice = device.copyWith(
          isConnected: true,
          lastSeen: DateTime.now(),
        );
        _connectedDevices[endpointId] = connectedDevice;
        _isConnected = true;
        _connectionStreamController.add(true);
        _deviceStreamController.add(_discoveredDevices.values.toList());
      }
    }
  }

  void _onDisconnected(String endpointId) {
    debugPrint('NetworkService: Disconnected: $endpointId');
    _connectedDevices.remove(endpointId);
    if (_connectedDevices.isEmpty) {
      _isConnected = false;
      _connectionStreamController.add(false);
    }
    _deviceStreamController.add(_discoveredDevices.values.toList());
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    debugPrint('NetworkService: Payload received from: $endpointId');
    
    if (payload.type == PayloadType.BYTES) {
      try {
        final messageJson = utf8.decode(payload.bytes!);
        final messageMap = jsonDecode(messageJson) as Map<String, dynamic>;
        final message = EmergencyMessage.fromMap(messageMap);
        _messageStreamController.add(message);
      } catch (e) {
        debugPrint('NetworkService: Error parsing message: $e');
      }
    }
  }

  void _onPayloadTransferUpdate(String endpointId, PayloadTransferUpdate update) {
    // Handle transfer updates if needed
    debugPrint('NetworkService: Payload transfer update: ${update.status}');
  }

  /// Disconnect from all devices and cleanup
  Future<void> disconnect() async {
    await stopAdvertising();
    await stopDiscovering();
    _discoveredDevices.clear();
    _connectedDevices.clear();
    _isConnected = false;
    _connectionStreamController.add(false);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _deviceStreamController.close();
    _messageStreamController.close();
    _connectionStreamController.close();
  }
}

