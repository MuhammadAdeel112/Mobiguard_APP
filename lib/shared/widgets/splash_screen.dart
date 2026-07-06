import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [AppTheme.primaryColor, const Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Abstract background elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .scale(duration: 4.seconds, curve: Curves.easeInOut, begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                .slide(duration: 3.seconds, curve: Curves.easeInOut, begin: const Offset(0, 0), end: const Offset(0.2, -0.2)),
            ),
            
            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Shield Logo
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 80,
                      color: Colors.white,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(duration: 2.seconds, curve: Curves.easeInOut, begin: const Offset(1, 1), end: const Offset(1.05, 1.05))
                    .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.3)),
                    
                  const SizedBox(height: 32),
                  
                  // App Title
                  Text(
                    'MobiGuard',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 36,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.5, curve: Curves.easeOutBack),
                  
                  Text(
                    'SALES & TECH',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(begin: 0.5, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 64),
                  
                  // Sleek loading indicator
                  Column(
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ).animate().fade(duration: 400.ms, delay: 600.ms),
                      const SizedBox(height: 16),
                      Text(
                        'Securing connection...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .fade(duration: 1.seconds, begin: 0.5, end: 1.0),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
