import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const AquaGrowApp());
}

class AquaGrowApp extends StatelessWidget {
  const AquaGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}
