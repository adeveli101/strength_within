import 'package:flutter/material.dart';
import '../../sw_app_theme/app_theme.dart';
import '../userpprofilescreen.dart';
import 'profile_step_widgets.dart';

class GenderStep extends StatefulWidget {
  final UserProfileFormModel model;
  final String description;
  final VoidCallback onNext;
  const GenderStep({required this.model, required this.description, required this.onNext, super.key});
  @override
  State<GenderStep> createState() => _GenderStepState();
}

class _GenderStepState extends State<GenderStep> {
  String? error;
  @override
  Widget build(BuildContext context) {
    final value = widget.model.gender;
    error = (value != 0 && value != 1) ? 'Cinsiyet seçimi zorunlu.' : null;
    return MetricPage(
      title: 'Cinsiyetiniz',
      description: widget.description,
      isLastPage: false,
      input: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GenderButton(model: widget.model, value: 0, icon: Icons.male, label: 'Erkek'),
          SizedBox(width: AppTheme.paddingLarge),
          GenderButton(model: widget.model, value: 1, icon: Icons.female, label: 'Kadın'),
        ],
      ),
      onNext: error == null ? widget.onNext : null,
    );
  }
} 