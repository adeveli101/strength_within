import 'package:flutter/material.dart';
import '../../sw_app_theme/app_theme.dart';
import '../userpprofilescreen.dart';
import 'profile_step_widgets.dart';
import 'package:flutter/services.dart';

class WeightStep extends StatefulWidget {
  final UserProfileFormModel model;
  final String description;
  final VoidCallback onNext;
  const WeightStep({required this.model, required this.description, required this.onNext, super.key});
  @override
  State<WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends State<WeightStep> {
  String? error;
  @override
  Widget build(BuildContext context) {
    final min = 30.0;
    final max = 250.0;
    final value = widget.model.weight;
    error = (value < min || value > max) ? 'Kilo $min-$max kg aralığında olmalı.' : null;
    return MetricPage(
      title: 'Kilonuz',
      description: widget.description,
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${value.round()} kg', style: AppTheme.headingLarge),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: 150.0,
                  divisions: 120,
                  activeColor: AppTheme.primaryRed,
                  inactiveColor: AppTheme.primaryRed.withOpacity(0.3),
                  onChanged: (v) => setState(() => widget.model.setWeight(v.roundToDouble())),
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
                    if (intVal != null && intVal >= 30 && intVal <= 150) {
                      setState(() => widget.model.setWeight(intVal.toDouble()));
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