import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/alert_model.dart';

/// Service for handling local push notifications
/// Handles initialization, permissions, and showing notifications for alerts
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  // Notification ID counter (stays within 32-bit integer range: 1-999,999)
  int _notificationIdCounter = 1;
  
  // Notification channel ID for Android
  static const String _channelId = 'aquagrow_alerts';
  static const String _channelName = 'AquaGrow Alerts';
  static const String _channelDescription = 'Critical sensor alerts and warnings';

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('NotificationService: Already initialized');
      return;
    }

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      final bool? initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        // Create Android notification channel
        await _createAndroidChannel();
        _isInitialized = true;
        debugPrint('NotificationService: Initialized successfully');
      } else {
        debugPrint('NotificationService: Initialization returned false');
      }
    } catch (e) {
      debugPrint('NotificationService: Error during initialization: $e');
      // Don't throw - allow app to continue without notifications
    }
  }

  /// Create Android notification channel (required for Android 8.0+)
  Future<void> _createAndroidChannel() async {
    try {
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      debugPrint('NotificationService: Android notification channel created');
    } catch (e) {
      debugPrint('NotificationService: Error creating Android channel: $e');
    }
  }

  /// Request notification permissions (required for iOS and Android 13+)
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      debugPrint('NotificationService: Not initialized, initializing first...');
      await initialize();
    }

    try {
      // Request Android permissions (Android 13+)
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        if (granted == true) {
          debugPrint('NotificationService: Android notification permission granted');
          return true;
        } else {
          debugPrint('NotificationService: Android notification permission denied');
          return false;
        }
      }

      // iOS permissions are requested automatically during initialization
      // Check if already granted
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      if (iosImplementation != null) {
        final settings = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        final granted = settings ?? false;
        if (granted) {
          debugPrint('NotificationService: iOS notification permission granted');
        } else {
          debugPrint('NotificationService: iOS notification permission denied');
        }
        return granted;
      }

      // Default to true for platforms that don't require permission
      return true;
    } catch (e) {
      debugPrint('NotificationService: Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if notification permissions are granted
  Future<bool> hasPermission() async {
    try {
      // Android 13+
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        return granted ?? false;
      }

      // iOS - assume granted if we can initialize
      return _isInitialized;
    } catch (e) {
      debugPrint('NotificationService: Error checking permissions: $e');
      return false;
    }
  }

  /// Get next notification ID (stays within 32-bit integer range)
  int _getNextNotificationId() {
    final id = _notificationIdCounter;
    // Wrap around at 999,999 to stay within safe range (1-999,999)
    _notificationIdCounter = (_notificationIdCounter % 999999) + 1;
    return id;
  }

  /// Show notification for an alert
  Future<void> showAlertNotification(AlertModel alert) async {
    if (!_isInitialized) {
      debugPrint('NotificationService: Not initialized, skipping notification');
      return;
    }

    // Only show notifications for critical and warning alerts (not info)
    if (alert.severity == AlertSeverity.info) {
      debugPrint('NotificationService: Skipping info alert notification');
      return;
    }

    // Check permissions
    final hasPermission = await this.hasPermission();
    if (!hasPermission) {
      debugPrint('NotificationService: Permission not granted, skipping notification');
      return;
    }

    try {
      // Get notification ID
      final notificationId = _getNextNotificationId();

      // Determine importance based on severity
      final importance = alert.severity == AlertSeverity.critical
          ? Importance.high
          : Importance.defaultImportance;

      // Build notification details
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: importance,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _notifications.show(
        notificationId,
        alert.title,
        alert.message,
        notificationDetails,
      );

      debugPrint('NotificationService: Notification shown for alert: ${alert.title} (ID: $notificationId)');
    } catch (e) {
      debugPrint('NotificationService: Error showing notification: $e');
      // Don't throw - fail silently to prevent app crash
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('NotificationService: Cancelled notification $id');
    } catch (e) {
      debugPrint('NotificationService: Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('NotificationService: Cancelled all notifications');
    } catch (e) {
      debugPrint('NotificationService: Error cancelling all notifications: $e');
    }
  }

  /// Handle notification tap (future enhancement)
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('NotificationService: Notification tapped: ${response.id}');
    // TODO: Navigate to alerts screen when notification is tapped
    // This would require accessing Navigator or using a callback
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
