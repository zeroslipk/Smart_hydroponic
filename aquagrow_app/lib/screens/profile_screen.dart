import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadEmergencyContacts();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
        _userName = user.displayName ?? 'User';
      });
    }
  }

  Future<void> _loadEmergencyContacts() async {
    setState(() {
      _isLoading = true;
    });

    final contacts = await _databaseService.getAllEmergencyContacts();
    
    setState(() {
      _contacts.clear();
      _contacts.addAll(contacts);
      _isLoading = false;
    });
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRelationship = 'family';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedRelationship,
                  items: const [
                    DropdownMenuItem(value: 'family', child: Text('Family')),
                    DropdownMenuItem(value: 'friend', child: Text('Friend')),
                    DropdownMenuItem(
                      value: 'emergency_services',
                      child: Text('Emergency Services'),
                    ),
                    DropdownMenuItem(value: 'neighbor', child: Text('Neighbor')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRelationship = value!;
                    });
                  },
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
                // Validate
                final nameError = Validators.validateName(nameController.text);
                final phoneError = phoneController.text.isEmpty
                    ? 'Phone number is required'
                    : null;

                if (nameError != null || phoneError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(nameError ?? phoneError!),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final contact = EmergencyContact(
                  name: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  relationship: selectedRelationship,
                  createdAt: DateTime.now(),
                );

                await _databaseService.insertEmergencyContact(contact);

                if (mounted) {
                  Navigator.pop(context);
                  _loadEmergencyContacts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Emergency contact added'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006064),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Emergency Contacts'),
        backgroundColor: const Color(0xFF006064),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: const Color(0xFF006064),
                                child: Text(
                                  _userName?[0].toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userName ?? 'User',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_userEmail != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _userEmail!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _authService.signOut();
                              if (mounted) {
                                Navigator.pushReplacementNamed(context, '/auth');
                              }
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign Out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Emergency Contacts Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddContactDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Contact'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF006064),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (_contacts.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.emergency_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No emergency contacts',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add contacts to notify during emergencies',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._contacts.map((contact) => _buildContactCard(contact)),
                ],
              ),
            ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.isPrimary
              ? const Color(0xFF006064)
              : Colors.grey[300],
          child: Text(
            contact.name[0].toUpperCase(),
            style: TextStyle(
              color: contact.isPrimary ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              contact.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (contact.isPrimary) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF006064),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRIMARY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 14),
                const SizedBox(width: 4),
                Text(contact.phoneNumber),
              ],
            ),
            if (contact.email != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email, size: 14),
                  const SizedBox(width: 4),
                  Text(contact.email!),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Relationship: ${contact.relationship}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.star, size: 18),
                  SizedBox(width: 8),
                  Text('Set as Primary'),
                ],
              ),
              onTap: () async {
                // Remove primary from all contacts
                for (var c in _contacts) {
                  if (c.isPrimary && c.id != contact.id) {
                    await _databaseService.updateEmergencyContact(
                      c.copyWith(isPrimary: false),
                    );
                  }
                }
                // Set this as primary
                await _databaseService.updateEmergencyContact(
                  contact.copyWith(isPrimary: true),
                );
                _loadEmergencyContacts();
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
              onTap: () => _showEditContactDialog(contact),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () async {
                if (contact.id != null) {
                  await _databaseService.deleteEmergencyContact(contact.id!);
                  _loadEmergencyContacts();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditContactDialog(EmergencyContact contact) {
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phoneNumber);
    final emailController = TextEditingController(text: contact.email ?? '');
    String selectedRelationship = contact.relationship;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedRelationship,
                  items: const [
                    DropdownMenuItem(value: 'family', child: Text('Family')),
                    DropdownMenuItem(value: 'friend', child: Text('Friend')),
                    DropdownMenuItem(
                      value: 'emergency_services',
                      child: Text('Emergency Services'),
                    ),
                    DropdownMenuItem(value: 'neighbor', child: Text('Neighbor')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRelationship = value!;
                    });
                  },
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
                final nameError = Validators.validateName(nameController.text);
                if (nameError != null || phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(nameError ?? 'Phone number is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final updated = contact.copyWith(
                  name: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  relationship: selectedRelationship,
                );

                await _databaseService.updateEmergencyContact(updated);

                if (mounted) {
                  Navigator.pop(context);
                  _loadEmergencyContacts();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006064),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}


