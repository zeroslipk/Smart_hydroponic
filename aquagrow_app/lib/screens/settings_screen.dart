import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/alert_provider.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool criticalOnly = false;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool darkMode = false;

  double tempMin = 22;
  double tempMax = 28;
  double phMin = 5.8;
  double phMax = 6.8;
  double waterMin = 40;
  double waterMax = 95;
  bool _thresholdsLoaded = false;

  void _loadThresholdsFromProvider() {
    final alertProvider = context.read<AlertProvider>();
    final thresholds = alertProvider.thresholds;
    
    // Load temperature thresholds
    if (thresholds.containsKey('temperature')) {
      final temp = thresholds['temperature']!;
      tempMin = temp.criticalMin;
      tempMax = temp.criticalMax;
    }
    
    // Load pH thresholds
    if (thresholds.containsKey('pH')) {
      final ph = thresholds['pH']!;
      phMin = ph.criticalMin;
      phMax = ph.criticalMax;
    }
    
    // Load water level thresholds
    if (thresholds.containsKey('waterLevel')) {
      final water = thresholds['waterLevel']!;
      waterMin = water.criticalMin;
      waterMax = water.criticalMax;
    }
    
    if (mounted) setState(() {});
  }
  
  void _saveThresholdsToProvider() {
    final alertProvider = context.read<AlertProvider>();
    
    // Update temperature thresholds
    alertProvider.updateThreshold('temperature', SensorThreshold(
      criticalMin: tempMin,
      criticalMax: tempMax,
      warningMin: tempMin + 3, // Warning is 3 units inside critical
      warningMax: tempMax - 3,
    ));
    
    // Update pH thresholds
    alertProvider.updateThreshold('pH', SensorThreshold(
      criticalMin: phMin,
      criticalMax: phMax,
      warningMin: phMin + 0.3, // Warning is 0.3 inside critical
      warningMax: phMax - 0.3,
    ));
    
    // Update water level thresholds
    alertProvider.updateThreshold('waterLevel', SensorThreshold(
      criticalMin: waterMin,
      criticalMax: waterMax,
      warningMin: waterMin + 10, // Warning is 10% inside critical
      warningMax: waterMax - 5,
    ));
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sensor thresholds updated successfully'),
        backgroundColor: Color(0xFF7CB342),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load thresholds once after widget tree is built
    if (!_thresholdsLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadThresholdsFromProvider();
        _thresholdsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF006064), Color(0xFFF5F5F5)],
            stops: [0.0, 0.25],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildUserProfile(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Sensor Thresholds'),
                    _buildThresholdSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Notifications'),
                    _buildNotificationSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('System'),
                    _buildSystemSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('About'),
                    _buildAboutSection(),
                    const SizedBox(height: 24),
                    _buildLogoutSection(),
                    _buildDeleteAccountSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildGlassIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Customize your experience',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    final user = AuthService().currentUser;
    final name = user?.displayName ?? 'User';
    final email = user?.email ?? 'No email';
    final initials = name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFF7CB342)],
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProfileButton(
                  'Edit Profile',
                  Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfileButton('Password', Icons.lock_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton(String label, IconData icon) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF00BCD4), size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThresholdSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildThresholdSlider(
            label: 'Temperature',
            icon: Icons.thermostat_outlined,
            color: const Color(0xFFFF5252),
            minValue: tempMin,
            maxValue: tempMax,
            unit: '°C',
            rangeMin: 15,
            rangeMax: 35,
            onChanged: (min, max) {
              setState(() {
                tempMin = min;
                tempMax = max;
              });
              _saveThresholdsToProvider();
            },
          ),
          const SizedBox(height: 24),
          _buildThresholdSlider(
            label: 'pH Level',
            icon: Icons.science_outlined,
            color: const Color(0xFF9C27B0),
            minValue: phMin,
            maxValue: phMax,
            unit: '',
            rangeMin: 4.0,
            rangeMax: 8.0,
            onChanged: (min, max) {
              setState(() {
                phMin = min;
                phMax = max;
              });
              _saveThresholdsToProvider();
            },
          ),
          const SizedBox(height: 24),
          _buildThresholdSlider(
            label: 'Water Level',
            icon: Icons.water_drop_outlined,
            color: const Color(0xFF00BCD4),
            minValue: waterMin,
            maxValue: waterMax,
            unit: '%',
            rangeMin: 0,
            rangeMax: 100,
            onChanged: (min, max) {
              setState(() {
                waterMin = min;
                waterMax = max;
              });
              _saveThresholdsToProvider();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider({
    required String label,
    required IconData icon,
    required Color color,
    required double minValue,
    required double maxValue,
    required String unit,
    required double rangeMin,
    required double rangeMax,
    required Function(double, double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${minValue.toStringAsFixed(1)} - ${maxValue.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RangeSlider(
          values: RangeValues(minValue, maxValue),
          min: rangeMin,
          max: rangeMax,
          divisions: ((rangeMax - rangeMin) * 10).toInt(),
          activeColor: color,
          inactiveColor: color.withValues(alpha: 0.2),
          labels: RangeLabels(
            '${minValue.toStringAsFixed(1)}$unit',
            '${maxValue.toStringAsFixed(1)}$unit',
          ),
          onChanged: (values) {
            onChanged(values.start, values.end);
          },
        ),
        // Visual zone indicator
        Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                Colors.red.withValues(alpha: 0.2),
                color.withValues(alpha: 0.2),
                Colors.red.withValues(alpha: 0.2),
              ],
              stops: [
                0.0,
                (minValue - rangeMin) / (rangeMax - rangeMin),
                (maxValue - rangeMin) / (rangeMax - rangeMin),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Safe zone highlight
              Positioned(
                left:
                    ((minValue - rangeMin) / (rangeMax - rangeMin)) *
                    MediaQuery.of(context).size.width *
                    0.7,
                width:
                    ((maxValue - minValue) / (rangeMax - rangeMin)) *
                    MediaQuery.of(context).size.width *
                    0.7,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Safe Zone',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Enable Notifications',
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
            },
          ),
          const Divider(height: 1),
          _buildSwitchTile(
            icon: Icons.priority_high,
            title: 'Critical Alerts Only',
            value: criticalOnly,
            onChanged: (value) {
              setState(() {
                criticalOnly = value;
              });
            },
          ),
          const Divider(height: 1),
          _buildSwitchTile(
            icon: Icons.volume_up_outlined,
            title: 'Sound',
            value: soundEnabled,
            onChanged: (value) {
              setState(() {
                soundEnabled = value;
              });
            },
          ),
          const Divider(height: 1),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: 'Vibration',
            value: vibrationEnabled,
            onChanged: (value) {
              setState(() {
                vibrationEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            value: darkMode,
            onChanged: (value) {
              setState(() {
                darkMode = value;
              });
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.language,
            title: 'Language',
            trailing: 'English',
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.straighten,
            title: 'Units',
            trailing: 'Metric',
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.tune,
            title: 'Calibrate All Sensors',
            color: const Color(0xFF00BCD4),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.restore,
            title: 'Factory Reset',
            color: const Color(0xFFFF5252),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.info_outline,
            title: 'App Version',
            trailing: '1.0.0',
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            color: Colors.black87,
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            color: Colors.black87,
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            color: Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF00BCD4), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF00BCD4),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF00BCD4), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await AuthService().signOut();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (route) => false,
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: Color(0xFFFF5252)),
                const SizedBox(width: 12),
                const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF5252),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountSection() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Account'),
                content: const Text(
                  'Are you sure you want to delete your account? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              try {
                await AuthService().deleteAccount();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_forever, color: Colors.grey),
                const SizedBox(width: 12),
                const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
