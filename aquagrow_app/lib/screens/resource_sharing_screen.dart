import 'package:flutter/material.dart';
import '../models/resource_item.dart';
import '../services/database_service.dart';
import '../services/network_service.dart';
import 'package:intl/intl.dart';

class ResourceSharingScreen extends StatefulWidget {
  const ResourceSharingScreen({super.key});

  @override
  State<ResourceSharingScreen> createState() => _ResourceSharingScreenState();
}

class _ResourceSharingScreenState extends State<ResourceSharingScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final NetworkService _networkService = NetworkService();
  final List<ResourceItem> _resources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
    });

    // Load resources from database
    // Note: In a real implementation, resources would be synced via P2P network
    final resources = await _databaseService.getAllResources();
    
    setState(() {
      _resources.clear();
      _resources.addAll(resources);
      _isLoading = false;
    });
  }

  void _showAddResourceDialog() {
    ResourceType? selectedType;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final locationController = TextEditingController();
    final contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Share Resource'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ResourceType>(
                  decoration: const InputDecoration(
                    labelText: 'Resource Type',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedType,
                  items: ResourceType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Resource Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Info (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedType == null || nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final resource = ResourceItem(
                  providerId: _networkService.deviceId,
                  providerName: _networkService.deviceName ?? 'Unknown',
                  type: selectedType!,
                  description: descriptionController.text.isEmpty
                      ? nameController.text
                      : descriptionController.text,
                  quantity: int.tryParse(quantityController.text) ?? 1,
                  location: locationController.text.isEmpty
                      ? null
                      : locationController.text,
                  timestamp: DateTime.now(),
                  contactInfo: contactController.text.isEmpty
                      ? null
                      : contactController.text,
                );

                await _databaseService.insertResource(resource);
                
                // Broadcast resource availability via network
                await _broadcastResource(resource);

                if (mounted) {
                  Navigator.pop(context);
                  _loadResources();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Resource shared successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006064),
              ),
              child: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _broadcastResource(ResourceItem resource) async {
    // Create emergency message for resource sharing
    final message = EmergencyMessage(
      senderId: _networkService.deviceId,
      senderName: _networkService.deviceName ?? 'Unknown',
      message: '${resource.type.displayName} available: ${resource.description}',
      type: MessageType.resource,
      timestamp: DateTime.now(),
      metadata: resource.toMap(),
    );

    await _networkService.broadcastMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Sharing'),
        backgroundColor: const Color(0xFF006064),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Share resources with nearby devices in the network',
                          style: TextStyle(color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),

                // Resources List
                Expanded(
                  child: _resources.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No resources shared yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to share a resource',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _resources.length,
                          itemBuilder: (context, index) {
                            return _buildResourceCard(_resources[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddResourceDialog,
        backgroundColor: const Color(0xFF006064),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildResourceCard(ResourceItem resource) {
    final dateFormat = DateFormat('MMM dd, HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getResourceIcon(resource.type),
                  color: const Color(0xFF006064),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.type.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'by ${resource.providerName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!resource.isAvailable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Unavailable',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              resource.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.numbers, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Quantity: ${resource.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (resource.location != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      resource.location!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (resource.contactInfo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    resource.contactInfo!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              dateFormat.format(resource.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            if (resource.providerId == _networkService.deviceId) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      // Mark as unavailable
                      final updated = resource.copyWith(isAvailable: false);
                      await _databaseService.updateResource(updated);
                      _loadResources();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Mark Unavailable'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getResourceIcon(ResourceType type) {
    switch (type) {
      case ResourceType.medical:
        return Icons.medical_services;
      case ResourceType.food:
        return Icons.restaurant;
      case ResourceType.water:
        return Icons.water_drop;
      case ResourceType.shelter:
        return Icons.home;
      case ResourceType.clothing:
        return Icons.checkroom;
      case ResourceType.tools:
        return Icons.build;
      case ResourceType.communication:
        return Icons.phone_android;
      case ResourceType.transportation:
        return Icons.directions_car;
      case ResourceType.other:
        return Icons.inventory_2;
    }
  }
}

