import 'package:flutter/material.dart';
import '../models/network_device.dart';
import '../models/emergency_message.dart';
import '../services/network_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final NetworkDevice device;
  final NetworkService networkService;

  const ChatScreen({
    super.key,
    required this.device,
    required this.networkService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<EmergencyMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    widget.networkService.messageStream.listen((message) {
      // Only show messages from this device or broadcast messages
      if (message.senderId == widget.device.deviceId ||
          message.recipientId == null ||
          message.recipientId == widget.networkService.deviceId) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = EmergencyMessage(
      senderId: widget.networkService.deviceId,
      senderName: widget.networkService.deviceName ?? 'Unknown',
      recipientId: widget.device.deviceId,
      message: text,
      type: MessageType.custom,
      timestamp: DateTime.now(),
    );

    if (widget.device.endpointId != null) {
      final sent = await widget.networkService.sendMessage(
        message,
        widget.device.endpointId!,
      );

      if (sent && mounted) {
        setState(() {
          _messages.add(message);
        });
        _messageController.clear();
        _scrollToBottom();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showQuickMessageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
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
      ),
    );
  }

  Future<void> _sendQuickMessage(MessageType type) async {
    final message = EmergencyMessage(
      senderId: widget.networkService.deviceId,
      senderName: widget.networkService.deviceName ?? 'Unknown',
      recipientId: widget.device.deviceId,
      message: type.defaultMessage,
      type: type,
      timestamp: DateTime.now(),
    );

    if (widget.device.endpointId != null) {
      await widget.networkService.sendMessage(message, widget.device.endpointId!);
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    }
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.device.deviceName),
            Text(
              widget.device.isConnected ? 'Connected' : 'Disconnected',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006064),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency),
            onPressed: _showQuickMessageOptions,
            tooltip: 'Quick Messages',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(EmergencyMessage message) {
    final isMe = message.senderId == widget.networkService.deviceId;
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF006064)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isMe ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeFormat.format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead
                              ? Colors.blue[300]
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF006064),
              child: Text(
                widget.networkService.deviceName?[0].toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.emergency),
            onPressed: _showQuickMessageOptions,
            tooltip: 'Quick Messages',
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: const Color(0xFF006064),
            onPressed: _sendMessage,
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }
}

