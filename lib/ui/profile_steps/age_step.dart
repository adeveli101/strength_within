import 'package:flutter/material.dart';
import '../../sw_app_theme/app_theme.dart';
import '../userpprofilescreen.dart';
import 'profile_step_widgets.dart';

class AgeStep extends StatefulWidget {
  final UserProfileFormModel model;
  final String description;
  final VoidCallback onNext;
  const AgeStep({required this.model, required this.description, required this.onNext, super.key});
  @override
  State<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<AgeStep> {
  String? error;
  @override
  Widget build(BuildContext context) {
    final min = 15;
    final max = 90;
    final value = widget.model.age;
    error = (value < min || value > max) ? 'Yaş $min-$max aralığında olmalı.' : null;
    return MetricPage(
      title: 'Yaşınız',
      description: widget.description,
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: AppTheme.headingLarge),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor: AppTheme.primaryRed,
            inactiveColor: AppTheme.primaryRed.withOpacity(0.3),
            onChanged: (v) => setState(() => widget.model.setAge(v.round())),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(error!, style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      onNext: error == null ? widget.onNext : null,
    );
  }
} 