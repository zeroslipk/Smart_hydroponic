class NetworkDevice {
  final String deviceId;
  final String deviceName;
  final String? endpointId;
  final DateTime lastSeen;
  final bool isConnected;
  final int? signalStrength; // RSSI value
  final Map<String, dynamic>? metadata;

  NetworkDevice({
    required this.deviceId,
    required this.deviceName,
    this.endpointId,
    required this.lastSeen,
    this.isConnected = false,
    this.signalStrength,
    this.metadata,
  });

  factory NetworkDevice.fromMap(Map<String, dynamic> map) {
    return NetworkDevice(
      deviceId: map['device_id'] as String,
      deviceName: map['device_name'] as String,
      endpointId: map['endpoint_id'] as String?,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['last_seen'] as int),
      isConnected: (map['is_connected'] as int) == 1,
      signalStrength: map['signal_strength'] as int?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'endpoint_id': endpointId,
      'last_seen': lastSeen.millisecondsSinceEpoch,
      'is_connected': isConnected ? 1 : 0,
      'signal_strength': signalStrength,
      'metadata': metadata,
    };
  }

  NetworkDevice copyWith({
    String? deviceId,
    String? deviceName,
    String? endpointId,
    DateTime? lastSeen,
    bool? isConnected,
    int? signalStrength,
    Map<String, dynamic>? metadata,
  }) {
    return NetworkDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      endpointId: endpointId ?? this.endpointId,
      lastSeen: lastSeen ?? this.lastSeen,
      isConnected: isConnected ?? this.isConnected,
      signalStrength: signalStrength ?? this.signalStrength,
      metadata: metadata ?? this.metadata,
    );
  }

  String get timeSinceLastSeen {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

