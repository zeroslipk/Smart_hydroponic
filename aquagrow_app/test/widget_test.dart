import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:aquagrow_app/firebase_options.dart';
import 'package:flutter/services.dart'; 
import 'package:aquagrow_app/main.dart'; 
import 'package:provider/provider.dart';
import 'package:aquagrow_app/providers/sensor_provider.dart';
import 'package:aquagrow_app/providers/alert_provider.dart';
import 'package:aquagrow_app/screens/dashboard_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

typedef Callback = void Function(MethodCall call);

// Mock for FirebasePlatform
class MockFirebasePlatform extends FirebasePlatform {
  @override
  FirebasePlatform get delegate => this;

  @override
  Map<String, dynamic> get pluginConstants => {};

  @override
  bool get isAutoInitEnabled => true;

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return FirebaseAppPlatform(
      name ?? '[DEFAULT]',
      options ?? const FirebaseOptions(
        apiKey: '123',
        appId: '123',
        messagingSenderId: '123',
        projectId: '123',
      ),
    );
  }

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) {
    return FirebaseAppPlatform(
      name,
      const FirebaseOptions(
        apiKey: '123',
        appId: '123',
        messagingSenderId: '123',
        projectId: '123',
      ),
    );
  }

  @override
  List<FirebaseAppPlatform> get apps => [];
}


void main() {
  // Inject the mock platform
  FirebasePlatform.instance = MockFirebasePlatform();
  // Initialize FFI for sqflite in tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('Dashboard loads and shows title', (WidgetTester tester) async {
    // Initialize standard binding (Platform instance handles the logic now)
    await Firebase.initializeApp();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SensorProvider()),
          ChangeNotifierProvider(create: (_) => AlertProvider()),
        ],
        child: MaterialApp(home: const DashboardScreen()),
      ),
    );

    // Verify finding the title
    expect(find.text('HydroPulse'), findsOneWidget);
    expect(find.text('HydroPulse System'), findsOneWidget);

    // Verify Quick Control buttons exist
    expect(find.text('Pump'), findsOneWidget);
    expect(find.text('Lights'), findsOneWidget);
    expect(find.text('Fan'), findsOneWidget);
  });
}
