import 'package:flutter/material.dart';
import 'package:workout/z.app_theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/main_logo.png',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 20),
            // Uygulama Adı
            Text(
              'Workout App',
              style: AppTheme.headingLarge.copyWith(color: AppTheme.primaryRed),
            ),
            SizedBox(height: 20),
            // Yükleme Göstergesi
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
            ),
          ],
        ),
      ),
    );
  }
}
