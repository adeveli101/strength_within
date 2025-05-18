import 'package:flutter/material.dart';
import '../../blocs/data_bloc_routine/RoutineRepository.dart';
import '../../blocs/data_provider/firebase_provider.dart';
import '../../blocs/data_provider/sql_provider.dart';
import '../../models/sql_models/workoutGoals.dart';
import '../../sw_app_theme/app_theme.dart';
import '../userpprofilescreen.dart';
import 'profile_step_widgets.dart';
import 'package:provider/provider.dart';

class DifficultyStep extends StatefulWidget {
  final UserProfileFormModel model;
  final VoidCallback onNext;
  const DifficultyStep({required this.model, required this.onNext, super.key});
  @override
  State<DifficultyStep> createState() => _DifficultyStepState();
}

class _DifficultyStepState extends State<DifficultyStep> {
  int selectedDifficulty = 3;
  final List<String> difficultyLabels = [
    'Çok Kolay',
    'Kolay',
    'Orta',
    'Zor',
    'Çok Zor',
  ];

  @override
  void initState() {
    super.initState();
    final parsed = int.tryParse(widget.model.difficulty);
    selectedDifficulty = (parsed != null && parsed >= 1 && parsed <= 5) ? parsed : 3;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.model.setDifficulty(selectedDifficulty.toString());
    });
  }

  void _onSelectDifficulty(int level) {
    setState(() => selectedDifficulty = level);
    widget.model.setDifficulty(level.toString());
    final recommended = _getRecommendedFrequency(level);
    widget.model.setRecommendedFrequency(recommended);
    widget.model.setTrainingFrequency(recommended);
  }

  int _getRecommendedFrequency(int difficulty) {
    switch (difficulty) {
      case 1: return 3;
      case 2: return 4;
      case 3: return 5;
      case 4: return 6;
      case 5: return 6;
      default: return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MetricPage(
      title: 'Zorluk',
      description: 'Antrenman zorluk seviyeni seç.',
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final level = index + 1;
              return IconButton(
                iconSize: 36,
                splashRadius: 22,
                onPressed: () => _onSelectDifficulty(level),
                icon: Icon(
                  level <= selectedDifficulty
                      ? Icons.star
                      : Icons.star_border,
                  color: level <= selectedDifficulty
                      ? Colors.amber
                      : Colors.white24,
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '$selectedDifficulty - ${difficultyLabels[selectedDifficulty - 1]}',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
      onNext: widget.onNext,
    );
  }
} 