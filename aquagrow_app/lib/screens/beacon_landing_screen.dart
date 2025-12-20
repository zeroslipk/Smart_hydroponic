import 'package:flutter/material.dart';
import 'network_dashboard_screen.dart';
import '../services/network_service.dart';
import '../services/auth_service.dart';

class BeaconLandingScreen extends StatefulWidget {
  const BeaconLandingScreen({super.key});

  @override
  State<BeaconLandingScreen> createState() => _BeaconLandingScreenState();
}

class _BeaconLandingScreenState extends State<BeaconLandingScreen> {
  final NetworkService _networkService = NetworkService();
  bool _isInitializing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF006064),
              Color(0xFF00838F),
              Color(0xFF00BCD4),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'BEACON',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Emergency Communication Network',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Description
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Connect with nearby devices when traditional communication fails. Share critical information, coordinate resources, and request help through peer-to-peer connectivity.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),

                // Action Buttons
                if (!_isInitializing) ...[
                  _buildActionButton(
                    icon: Icons.add_circle_outline,
                    title: 'Create Network',
                    subtitle: 'Host a new emergency network',
                    color: Colors.green,
                    onTap: () => _createNetwork(),
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.search,
                    title: 'Join Network',
                    subtitle: 'Connect to existing network',
                    color: Colors.blue,
                    onTap: () => _joinNetwork(),
                  ),
                ] else
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),

                const SizedBox(height: 32),

                // Info Text
                Text(
                  'Requires location and nearby device permissions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createNetwork() async {
    setState(() {
      _isInitializing = true;
    });

    // Get user name for device
    final userName = AuthService().currentUser?.displayName ?? 'User';
    final deviceName = 'BEACON-${userName.substring(0, 6).toUpperCase()}';

    // Initialize network service
    final initialized = await _networkService.initialize(deviceName: deviceName);
    
    if (initialized) {
      // Start advertising (host mode)
      final started = await _networkService.startAdvertising();
      
      if (started && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const NetworkDashboardScreen(),
          ),
        );
      } else {
        setState(() {
          _isInitializing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create network. Please check permissions.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize network service.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinNetwork() async {
    setState(() {
      _isInitializing = true;
    });

    // Get user name for device
    final userName = AuthService().currentUser?.displayName ?? 'User';
    final deviceName = 'BEACON-${userName.substring(0, 6).toUpperCase()}';

    // Initialize network service
    final initialized = await _networkService.initialize(deviceName: deviceName);
    
    if (initialized) {
      // Start discovering (client mode)
      final started = await _networkService.startDiscovering();
      
      if (started && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const NetworkDashboardScreen(),
          ),
        );
      } else {
        setState(() {
          _isInitializing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to join network. Please check permissions.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize network service.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

