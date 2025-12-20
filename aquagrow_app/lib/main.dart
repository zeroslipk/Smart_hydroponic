import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/sensor_provider.dart';
import 'providers/alert_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
    
    // Initialize Notification Service
    final notificationService = NotificationService();
    try {
      await notificationService.initialize();
      // Request permissions (but don't block if denied)
      await notificationService.requestPermissions();
    } catch (e) {
      debugPrint("Notification init error: $e");
    }
    
    runApp(const AquaGrowApp());
  }, (error, stack) {
    debugPrint("CRITICAL: Uncaught error: $error");
    debugPrint(stack.toString());
  });
}

class AquaGrowApp extends StatefulWidget {
  const AquaGrowApp({super.key});

  @override
  State<AquaGrowApp> createState() => _AquaGrowAppState();
}

class _AquaGrowAppState extends State<AquaGrowApp> {
  late final SensorProvider _sensorProvider;
  late final AlertProvider _alertProvider;

  @override
  void initState() {
    super.initState();
    _sensorProvider = SensorProvider();
    _alertProvider = AlertProvider();
    
    // Link sensor updates to alert checking
    _sensorProvider.onSensorUpdate = (sensors) {
      debugPrint('Checking ${sensors.length} sensors for alerts...');
      _alertProvider.checkAllSensors(sensors);
    };
  }

  @override
  void dispose() {
    _sensorProvider.dispose();
    _alertProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _sensorProvider),
        ChangeNotifierProvider.value(value: _alertProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'AquaGrow - Smart Hydroponic',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
