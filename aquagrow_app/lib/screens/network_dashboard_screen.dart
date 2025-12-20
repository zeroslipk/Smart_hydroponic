import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_service.dart';
import '../models/network_device.dart';
import '../models/emergency_message.dart';
import 'chat_screen.dart';
import 'package:flutter/services.dart';

class NetworkDashboardScreen extends StatefulWidget {
  const NetworkDashboardScreen({super.key});

  @override
  State<NetworkDashboardScreen> createState() => _NetworkDashboardScreenState();
}

class _NetworkDashboardScreenState extends State<NetworkDashboardScreen> {
  final NetworkService _networkService = NetworkService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNetwork();
  }

  Future<void> _initializeNetwork() async {
    // Get device name from user or use default
    final deviceName = await _getDeviceName();
    if (deviceName != null) {
      final initialized = await _networkService.initialize(deviceName: deviceName);
      if (initialized && mounted) {
        setState(() {
          _isInitialized = true;
        });
        // Start both advertising and discovering
        await _networkService.startAdvertising();
        await _networkService.startDiscovering();
      }
    }
  }

  Future<String?> _getDeviceName() async {
    // In a real app, get from user profile or settings
    return 'BEACON-${_networkService.deviceId.substring(0, 8).toUpperCase()}';
  }

  @override
  void dispose() {
    _networkService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BEACON Network'),
        backgroundColor: const Color(0xFF006064),
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<bool>(
            stream: _networkService.connectionStream,
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? false;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<NetworkDevice>>(
              stream: _networkService.deviceStream,
              initialData: _networkService.discoveredDevices,
              builder: (context, snapshot) {
                final devices = snapshot.data ?? [];
                final connectedDevices = devices.where((d) => d.isConnected).toList();
                final discoveredDevices = devices.where((d) => !d.isConnected).toList();

                return Column(
                  children: [
                    // Status Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: _networkService.isConnected
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(
                            _networkService.isConnected
                                ? Icons.wifi
                                : Icons.wifi_off,
                            color: _networkService.isConnected
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _networkService.isAdvertising
                                      ? 'Hosting Network'
                                      : 'Joining Network',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${connectedDevices.length} connected • ${discoveredDevices.length} nearby',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quick Message Button
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () => _showQuickMessageDialog(context),
                            tooltip: 'Send Quick Message',
                          ),
                        ],
                      ),
                    ),

                    // Connected Devices Section
                    if (connectedDevices.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.devices, color: Color(0xFF006064)),
                            const SizedBox(width: 8),
                            Text(
                              'Connected Devices (${connectedDevices.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: connectedDevices.length,
                          itemBuilder: (context, index) {
                            return _buildDeviceCard(connectedDevices[index], true);
                          },
                        ),
                      ),
                    ],

                    // Discovered Devices Section
                    if (discoveredDevices.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Color(0xFF006064)),
                            const SizedBox(width: 8),
                            Text(
                              'Nearby Devices (${discoveredDevices.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: discoveredDevices.length,
                          itemBuilder: (context, index) {
                            return _buildDeviceCard(discoveredDevices[index], false);
                          },
                        ),
                      ),
                    ],

                    // Empty State
                    if (devices.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.devices_other,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No devices found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Make sure other devices are nearby\nand have BEACON running',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickMessageDialog(context),
        backgroundColor: const Color(0xFF006064),
        icon: const Icon(Icons.emergency),
        label: const Text('Quick Message'),
      ),
    );
  }

  Widget _buildDeviceCard(NetworkDevice device, bool isConnected) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isConnected
              ? Colors.green
              : Colors.orange,
          child: Icon(
            isConnected ? Icons.check : Icons.radio_button_unchecked,
            color: Colors.white,
          ),
        ),
        title: Text(
          device.deviceName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${device.deviceId.substring(0, 8)}...'),
            Text(
              'Last seen: ${device.timeSinceLastSeen}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: isConnected
            ? IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        device: device,
                        networkService: _networkService,
                      ),
                    ),
                  );
                },
                tooltip: 'Start Chat',
              )
            : ElevatedButton(
                onPressed: () async {
                  if (device.endpointId != null) {
                    await _networkService.connectToDevice(device.endpointId!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006064),
                ),
                child: const Text('Connect'),
              ),
      ),
    );
  }

  void _showQuickMessageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Quick Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: MessageType.values.map((type) {
            return ListTile(
              leading: Icon(_getMessageIcon(type)),
              title: Text(type.displayName),
              subtitle: Text(type.defaultMessage),
              onTap: () {
                Navigator.pop(context);
                _sendQuickMessage(type);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  IconData _getMessageIcon(MessageType type) {
    switch (type) {
      case MessageType.help:
        return Icons.help_outline;
      case MessageType.safe:
        return Icons.check_circle_outline;
      case MessageType.location:
        return Icons.location_on;
      case MessageType.resource:
        return Icons.inventory_2_outlined;
      case MessageType.medical:
        return Icons.medical_services_outlined;
      case MessageType.shelter:
        return Icons.home_outlined;
      case MessageType.food:
        return Icons.restaurant_outlined;
      case MessageType.water:
        return Icons.water_drop_outlined;
      case MessageType.evacuation:
        return Icons.warning_outlined;
      case MessageType.custom:
        return Icons.message_outlined;
    }
  }

  Future<void> _sendQuickMessage(MessageType type) async {
    final message = EmergencyMessage(
      senderId: _networkService.deviceId,
      senderName: _networkService.deviceName ?? 'Unknown',
      message: type.defaultMessage,
      type: type,
      timestamp: DateTime.now(),
    );

    await _networkService.broadcastMessage(message);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.displayName} message sent'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

