// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'program_merger_form_model.dart';
import 'steps/day_step.dart';
import 'steps/goal_step.dart';
import 'steps/exercise_step.dart';
import 'steps/summary_step.dart';
import '../../../blocs/data_bloc_part/PartRepository.dart';
import '../../../blocs/data_bloc_part/part_bloc.dart';
import '../../../blocs/data_exercise_bloc/exercise_bloc.dart';
import '../../../blocs/data_schedule_bloc/schedule_repository.dart';
import '../../../models/sql_models/PartExercises.dart';
import '../../../models/sql_models/PartTargetedBodyParts.dart';
import '../../../models/sql_models/Parts.dart';
import '../../../models/sql_models/exercises.dart';
import '../../../sw_app_theme/app_theme.dart';
import '../../exercises_ui/exercise_card.dart';

class ProgramMergerPage extends StatefulWidget {
  final String userId;
  const ProgramMergerPage({required this.userId, super.key});

  @override
  State<ProgramMergerPage> createState() => _ProgramMergerPageState();
}

class _ProgramMergerPageState extends State<ProgramMergerPage> {
  int currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProgramMergerFormModel(),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Rutin Oluştur'),
          ),
          body: Column(
            children: [
              _buildStepper(),
              SizedBox(height: 8),
              if (currentStep == 0) _buildWeekDaysBar(context),
              Expanded(
                child: _buildStepContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepper() {
    final steps = ['Hedef', 'Günler', 'Egzersiz', 'Özet'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(steps.length, (i) {
        final isActive = i == currentStep;
        return GestureDetector(
          onTap: () {
            setState(() => currentStep = i);
          },
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: isActive ? Colors.red : Colors.grey,
                child: Text('${i + 1}', style: TextStyle(color: Colors.white)),
              ),
              Text(steps[i], style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        );
      }),
    );
  }

  static const weekDays = [1, 2, 3, 4, 5, 6, 7];
  static const weekDayNames = {
    1: 'Pzt', 2: 'Sal', 3: 'Çrş', 4: 'Per', 5: 'Cum', 6: 'Cmt', 7: 'Paz',
  };

  Widget _buildWeekDaysBar(BuildContext context) {
    final selectedDays = context.watch<ProgramMergerFormModel>().selectedDays;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekDays.map((day) {
          final isSelected = selectedDays.contains(day);
          return AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: isSelected ? 48 : 28,
            height: isSelected ? 48 : 28,
            decoration: BoxDecoration(
              color: isSelected ? Colors.red : Colors.grey[300],
              borderRadius: BorderRadius.circular(isSelected ? 16 : 14),
              boxShadow: isSelected
                  ? [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 2))]
                  : [],
            ),
            child: Center(
              child: Text(
                weekDayNames[day]!,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSelected ? 16 : 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return GoalStep(onNext: () => setState(() => currentStep = 1));
      case 1:
        return DayStep(
          onNext: () => setState(() => currentStep = 2),
          onBack: () => setState(() => currentStep = 0),
        );
      case 2:
        return ExerciseStep(
          onNext: () => setState(() => currentStep = 3),
          onBack: () => setState(() => currentStep = 1),
        );
      case 3:
        return SummaryStep(onBack: () => setState(() => currentStep = 2));
      default:
        return Container();
    }
  }
}