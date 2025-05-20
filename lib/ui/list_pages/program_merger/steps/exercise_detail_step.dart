import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:strength_within/blocs/data_exercise_bloc/exercise_bloc.dart';
import 'package:strength_within/models/sql_models/exercises.dart';
import 'package:strength_within/ui/list_pages/program_merger/program_merger_model.dart';
import '../../../../sw_app_theme/app_theme.dart';

class ExerciseDetailStep extends StatefulWidget {
  final VoidCallback onNext;
  const ExerciseDetailStep({super.key, required this.onNext});

  @override
  State<ExerciseDetailStep> createState() => _ExerciseDetailStepState();
}

class _ExerciseDetailStepState extends State<ExerciseDetailStep> {
  final Map<int, Map<String, String?>> _errors = {};

  bool _validateDetail(String field, dynamic value) {
    if (value == null) return false;
    if (field == 'sets' || field == 'reps' || field == 'rest') {
      return value is int && value > 0;
    }
    if (field == 'weight') {
      return value is double && value >= 0;
    }
    return true;
  }

  bool _allValid(ProgramMergerFormModel model) {
    for (final exerciseId in model.selectedExercises) {
      final details = model.exerciseDetails[exerciseId] ?? {};
      if (!_validateDetail('sets', details['sets']) ||
          !_validateDetail('reps', details['reps']) ||
          !_validateDetail('weight', details['weight']) ||
          !_validateDetail('rest', details['rest'])) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Consumer<ProgramMergerFormModel>(
        builder: (context, model, child) {
          if (model.selectedExercises.isEmpty) {
            return Center(
              child: Text('Lütfen önce egzersiz seçin.', style: TextStyle(color: Colors.orange)),
            );
          }

          return BlocBuilder<ExerciseBloc, ExerciseState>(
            builder: (context, state) {
              List<Exercises> allExercises = [];
              if (state is ExerciseLoaded) {
                allExercises = state.exercises;
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: model.selectedExercises.length,
                      itemBuilder: (context, index) {
                        final exerciseId = model.selectedExercises[index];
                        final details = model.exerciseDetails[exerciseId] ?? {};
                        final exercise = allExercises.firstWhere(
                          (ex) => ex.id == exerciseId,
                          orElse: () => Exercises(
                            id: exerciseId,
                            name: 'Egzersiz $exerciseId',
                            defaultSets: 3,
                            defaultReps: 12,
                            defaultWeight: 10.0,
                            workoutTypeId: 0,
                            description: '',
                          ),
                        );
                        final errors = _errors[exerciseId] ?? {};

                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          color: AppTheme.cardBackground,
                          child: Padding(
                            padding: EdgeInsets.all(AppTheme.paddingMedium),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(exercise.name, style: AppTheme.headingSmall),
                                SizedBox(height: AppTheme.paddingMedium),
                                _buildDetailField(
                                  context,
                                  exerciseId,
                                  'Set Sayısı',
                                  'sets',
                                  details['sets'] ?? exercise.defaultSets,
                                  (value) => _updateDetail(model, exerciseId, 'sets', value),
                                  errors['sets'],
                                ),
                                _buildDetailField(
                                  context,
                                  exerciseId,
                                  'Tekrar Sayısı',
                                  'reps',
                                  details['reps'] ?? exercise.defaultReps,
                                  (value) => _updateDetail(model, exerciseId, 'reps', value),
                                  errors['reps'],
                                ),
                                _buildDetailField(
                                  context,
                                  exerciseId,
                                  'Ağırlık (kg)',
                                  'weight',
                                  details['weight'] ?? exercise.defaultWeight,
                                  (value) => _updateDetail(model, exerciseId, 'weight', value),
                                  errors['weight'],
                                ),
                                _buildDetailField(
                                  context,
                                  exerciseId,
                                  'Dinlenme (sn)',
                                  'rest',
                                  details['rest'] ?? 60,
                                  (value) => _updateDetail(model, exerciseId, 'rest', value),
                                  errors['rest'],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: AppTheme.paddingLarge),
                  ElevatedButton(
                    onPressed: _allValid(model) ? widget.onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                    ),
                    child: Text('Devam Et', style: AppTheme.bodyLarge),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailField(
    BuildContext context,
    int exerciseId,
    String label,
    String field,
    dynamic value,
    Function(dynamic) onChanged,
    String? errorText,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(label, style: AppTheme.bodyMedium),
              ),
              Expanded(
                child: TextFormField(
                  initialValue: value.toString(),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.darkBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    errorText: errorText,
                  ),
                  onChanged: (val) {
                    dynamic parsedVal;
                    String? error;
                    if (field == 'weight') {
                      parsedVal = double.tryParse(val);
                      if (parsedVal == null || parsedVal < 0) {
                        error = 'Geçerli bir ağırlık girin (0 veya daha büyük)';
                      }
                    } else {
                      parsedVal = int.tryParse(val);
                      if (parsedVal == null || parsedVal <= 0) {
                        error = 'Pozitif bir değer girin';
                      }
                    }
                    setState(() {
                      _errors[exerciseId] = {...?_errors[exerciseId], field: error};
                    });
                    if (error == null) {
                      onChanged(parsedVal);
                    }
                  },
                ),
              ),
            ],
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(errorText, style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  void _updateDetail(ProgramMergerFormModel model, int exerciseId, String field, dynamic value) {
    final details = model.exerciseDetails[exerciseId] ?? {};
    details[field] = value;
    model.setExerciseDetails(exerciseId, details);
  }
} 