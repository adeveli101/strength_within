import 'package:flutter/material.dart';
import '../../sw_app_theme/app_theme.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  const WelcomeStep({required this.onNext, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: AppTheme.primaryRed),
          SizedBox(height: AppTheme.paddingLarge),
          Text(
            'Hoşgeldiniz!',
            style: AppTheme.headingLarge.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.paddingMedium),
          Text(
            'Kişisel fitness profilinizi oluşturmak için birkaç soruya cevap vereceğiz. Bu bilgiler, size özel en iyi antrenman programını ve önerileri sunmamıza yardımcı olacak. Hazır mısınız?',
            style: AppTheme.bodyLarge.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.paddingLarge * 2),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
            ),
            onPressed: onNext,
            child: Text('Başla', style: AppTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
} 