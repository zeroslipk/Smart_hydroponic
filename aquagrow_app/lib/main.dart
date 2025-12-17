import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/sensor_provider.dart';
import 'providers/alert_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
  
  runApp(const AquaGrowApp());
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
      ],
      child: MaterialApp(
        title: 'AquaGrow - Smart Hydroponic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF006064),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00BCD4),
            primary: const Color(0xFF006064),
            secondary: const Color(0xFF7CB342),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
