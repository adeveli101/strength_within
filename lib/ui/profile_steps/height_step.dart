import 'package:flutter/material.dart';
import '../../sw_app_theme/app_theme.dart';
import '../userpprofilescreen.dart';
import 'profile_step_widgets.dart';
import 'package:flutter/services.dart';

class HeightStep extends StatefulWidget {
  final UserProfileFormModel model;
  final String description;
  final VoidCallback onNext;
  const HeightStep({required this.model, required this.description, required this.onNext, super.key});
  @override
  State<HeightStep> createState() => _HeightStepState();
}

class _HeightStepState extends State<HeightStep> {
  String? error;
  @override
  Widget build(BuildContext context) {
    final min = 120.0;
    final max = 220.0;
    final value = widget.model.height;
    error = (value < min || value > max) ? 'Boy $min-$max cm aralığında olmalı.' : null;
    return MetricPage(
      title: 'Boyunuz',
      description: widget.description,
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${value.round()} cm', style: AppTheme.headingLarge),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: 210.0,
                  divisions: 90,
                  activeColor: AppTheme.primaryRed,
                  inactiveColor: AppTheme.primaryRed.withOpacity(0.3),
                  onChanged: (v) => setState(() => widget.model.setHeight(v.roundToDouble())),
                ),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  controller: TextEditingController(text: value.round().toString()),
                  onChanged: (text) {
                    final intVal = int.tryParse(text);
                    if (intVal != null && intVal >= 120 && intVal <= 210) {
                      setState(() => widget.model.setHeight(intVal.toDouble()));
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                ),
              ),
            ],
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