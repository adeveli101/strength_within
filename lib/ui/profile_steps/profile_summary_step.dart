import 'package:flutter/material.dart';
import '../../sw_app_theme/app_theme.dart';
import '../userpprofilescreen.dart';
import 'profile_step_widgets.dart';

class ProfileSummaryStep extends StatelessWidget {
  final UserProfileFormModel model;
  final VoidCallback onSubmit;
  const ProfileSummaryStep({required this.model, required this.onSubmit, super.key});
  bool get isValid {
    return model.weight >= 30 && model.weight <= 250 &&
      model.height >= 120 && model.height <= 220 &&
      (model.gender == 0 || model.gender == 1) &&
      model.age >= 15 && model.age <= 90 &&
      model.selectedDays.length >= 2 && model.selectedDays.length <= 6;
  }
  @override
  Widget build(BuildContext context) {
    String? error;
    if (!isValid) {
      error = 'Lütfen tüm bilgileri doğru doldurun.';
    }
    return MetricPage(
      title: 'Profil Özeti',
      description: 'Bilgilerinizi kontrol edin ve profilinizi oluşturun.',
      isLastPage: true,
      input: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SummaryItem(icon: Icons.monitor_weight, label: 'Kilo', value: '${model.weight.round()} kg'),
          SummaryItem(icon: Icons.height, label: 'Boy', value: '${model.height.round()} cm'),
          SummaryItem(icon: model.gender == 0 ? Icons.male : Icons.female, label: 'Cinsiyet', value: model.gender == 0 ? 'Erkek' : 'Kadın'),
          SummaryItem(icon: Icons.calendar_today, label: 'Yaş', value: '${model.age}'),
          SummaryItem(icon: Icons.fitness_center, label: 'Antrenman', value: '${model.selectedDays.length} gün'),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(error, style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      onNext: isValid ? onSubmit : null,
    );
  }
} 