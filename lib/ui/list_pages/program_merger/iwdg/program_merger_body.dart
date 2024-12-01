// program_merger_body.dart

import 'package:flutter/material.dart';
import '../../../../z.app_theme/app_theme.dart';

class ProgramMergerBody extends StatelessWidget {
  final int currentStep;
  final List<Step> steps;
  final VoidCallback onStepContinue;
  final VoidCallback onStepCancel;
  final Widget Function(BuildContext, ControlsDetails) controlsBuilder;

  const ProgramMergerBody({
    super.key,
    required this.currentStep,
    required this.steps,
    required this.onStepContinue,
    required this.onStepCancel,
    required this.controlsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryRed,
        ),
      ),
      child: Stepper(
        type: StepperType.horizontal,
        currentStep: currentStep,
        onStepContinue: onStepContinue,
        onStepCancel: onStepCancel,
        controlsBuilder: controlsBuilder,
        steps: steps,
      ),
    );
  }
}