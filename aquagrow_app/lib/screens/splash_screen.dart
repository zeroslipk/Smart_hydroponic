import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _bubbleController;
  late AnimationController _growthController;
  late Animation<double> _growAnimation;
  
  List<Bubble> bubbles = [];

  @override
  void initState() {
    super.initState();
    
    // Wave animation controller
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Bubble animation controller
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Plant growth animation
    _growthController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _growAnimation = CurvedAnimation(
      parent: _growthController,
      curve: Curves.elasticOut,
    );

    // Start animations
    _growthController.forward();
    
    // Generate random bubbles
    _generateBubbles();

    // Navigate to next screen after delay
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    });
  }

  void _generateBubbles() {
    for (int i = 0; i < 20; i++) {
      bubbles.add(Bubble(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 30 + 10,
        speed: math.Random().nextDouble() * 2 + 1,
      ));
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _bubbleController.dispose();
    _growthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF006064),
                      Color(0xFF00838F),
                      Color(0xFF00ACC1),
                      Color(0xFF00BCD4),
                    ],
                    stops: [
                      0.0,
                      0.3 + (_waveController.value * 0.2),
                      0.6 + (_waveController.value * 0.2),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),

          // Animated bubbles
          AnimatedBuilder(
            animation: _bubbleController,
            builder: (context, child) {
              return CustomPaint(
                painter: BubblePainter(
                  bubbles: bubbles,
                  animationValue: _bubbleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo/plant
                ScaleTransition(
                  scale: _growAnimation,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: _buildPlantIcon(),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // App name with liquid effect
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Color(0xFF00BCD4),
                            Colors.white,
                          ],
                          stops: [
                            0.0,
                            _waveController.value,
                            1.0,
                          ],
                        ).createShader(bounds);
                      },
                      child: const Text(
                        'AquaGrow',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Tagline with typewriter effect
                DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Grow Smarter, Flow Better',
                        speed: const Duration(milliseconds: 100),
                      ),
                    ],
                    totalRepeatCount: 1,
                  ),
                ),

                const SizedBox(height: 60),

                // Loading indicator with water ripple
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple effect
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return Container(
                            width: 60 * (1 + _waveController.value * 0.5),
                            height: 60 * (1 + _waveController.value * 0.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white
                                    .withValues(alpha: 1 - _waveController.value),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                      // Inner circle
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Water drops overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: WaterDropPainter(
                    animationValue: _bubbleController.value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Water drop shape
        Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00BCD4).withValues(alpha: 0.8),
                Color(0xFF00838F).withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(40),
              bottom: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // Plant inside droplet
        Icon(
          Icons.eco,
          size: 50,
          color: Color(0xFF7CB342),
        ),
      ],
    );
  }
}

// Bubble data class
class Bubble {
  double x;
  double y;
  final double size;
  final double speed;

  Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

// Bubble painter
class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double animationValue;

  BubblePainter({required this.bubbles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.1);

    for (var bubble in bubbles) {
      // Move bubble up
      bubble.y -= (bubble.speed * 0.01);
      if (bubble.y < -0.1) {
        bubble.y = 1.1;
        bubble.x = math.Random().nextDouble();
      }

      final center = Offset(
        bubble.x * size.width,
        bubble.y * size.height,
      );

      // Draw bubble with gradient
      final gradient = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.05),
        ],
      );

      final rect = Rect.fromCircle(center: center, radius: bubble.size);
      paint.shader = gradient.createShader(rect);

      canvas.drawCircle(center, bubble.size, paint);

      // Add highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(center.dx - bubble.size * 0.3, center.dy - bubble.size * 0.3),
        bubble.size * 0.3,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) => true;
}

// Water drop painter
class WaterDropPainter extends CustomPainter {
  final double animationValue;

  WaterDropPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Draw occasional water drops
    if (animationValue > 0.8) {
      for (int i = 0; i < 3; i++) {
        final x = size.width * (0.2 + i * 0.3);
        final y = size.height * ((animationValue - 0.8) * 5);

        final path = Path();
        path.moveTo(x, y);
        path.quadraticBezierTo(x - 5, y + 15, x, y + 20);
        path.quadraticBezierTo(x + 5, y + 15, x, y);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(WaterDropPainter oldDelegate) => true;
}
