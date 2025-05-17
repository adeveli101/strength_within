import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../blocs/data_provider/firebase_provider.dart';
import '../blocs/data_provider/sql_provider.dart';
import 'app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Function(String?) onInitComplete;

  const SplashScreen({
    super.key,
    required this.onInitComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Sürekli animasyon için
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });
    _controller.forward();
  }

  Future<void> _initializeApp() async {
    if (_isInitialized) return;

    try {
      // Firebase işlemleri
      final firebaseProvider = FirebaseProvider();
      String? userId = await firebaseProvider.signInAnonymously();

      // SQL provider başlat
      final sqlProvider = SQLProvider();
      await sqlProvider.initDatabase();

      // Minimum splash süresi
      await Future.delayed(const Duration(seconds: 2));

      if (mounted && !_isInitialized) {
        _isInitialized = true;
        widget.onInitComplete(userId);
      }
    } catch (e) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        widget.onInitComplete(null);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF000000),
              AppTheme.darkBackground,
              const Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Animation
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryRed.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset('assets/logo_circle.png'),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // App Name with Animation
              AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Text(
                      'Strength Within',
                      style: TextStyle(
                        fontSize: 40,
                        fontFamily: 'Geometria',
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Slogan with Animation
              AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Text(
                      'Daily Power, Lasting Impact',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Geometria',
                        color: AppTheme.primaryRed.withOpacity(0.7),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Loading Indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryRed.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}