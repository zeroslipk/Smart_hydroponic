class EmergencyMessage {
  final String? id;
  final String senderId;
  final String senderName;
  final String? recipientId; // null for broadcast
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  EmergencyMessage({
    this.id,
    required this.senderId,
    required this.senderName,
    this.recipientId,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  factory EmergencyMessage.fromMap(Map<String, dynamic> map) {
    return EmergencyMessage(
      id: map['id'] as String?,
      senderId: map['sender_id'] as String,
      senderName: map['sender_name'] as String,
      recipientId: map['recipient_id'] as String?,
      message: map['message'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.custom,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isRead: (map['is_read'] as int) == 1,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'recipient_id': recipientId,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_read': isRead ? 1 : 0,
      'metadata': metadata,
    };
  }
}

enum MessageType {
  help,
  safe,
  location,
  resource,
  medical,
  shelter,
  food,
  water,
  evacuation,
  custom,
}

extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.help:
        return 'Need Help';
      case MessageType.safe:
        return 'I\'m Safe';
      case MessageType.location:
        return 'Share Location';
      case MessageType.resource:
        return 'Resource Available';
      case MessageType.medical:
        return 'Medical Emergency';
      case MessageType.shelter:
        return 'Need Shelter';
      case MessageType.food:
        return 'Need Food';
      case MessageType.water:
        return 'Need Water';
      case MessageType.evacuation:
        return 'Evacuation Alert';
      case MessageType.custom:
        return 'Custom Message';
    }
  }

  String get defaultMessage {
    switch (this) {
      case MessageType.help:
        return 'I need immediate assistance!';
      case MessageType.safe:
        return 'I am safe and accounted for.';
      case MessageType.location:
        return 'My current location: [LOCATION]';
      case MessageType.resource:
        return 'I have resources available to share.';
      case MessageType.medical:
        return 'Medical emergency - need immediate help!';
      case MessageType.shelter:
        return 'I need shelter urgently.';
      case MessageType.food:
        return 'I need food supplies.';
      case MessageType.water:
        return 'I need clean water.';
      case MessageType.evacuation:
        return 'Evacuation required - please leave immediately!';
      case MessageType.custom:
        return '';
    }
  }
}

