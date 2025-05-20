import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../blocs/data_exercise_bloc/exercise_bloc.dart';
import '../program_merger_form_model.dart';
import '../../../../sw_app_theme/app_theme.dart';

class GoalStep extends StatelessWidget {
  final VoidCallback onNext;
  const GoalStep({required this.onNext, super.key});

  @override
  Widget build(BuildContext context) {
    // Hedefler yüklü değilse event gönder
    final bloc = BlocProvider.of<ExerciseBloc>(context);
    if (bloc.state is! WorkoutGoalsLoaded) {
      bloc.add(FetchWorkoutGoals());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 12),
          Icon(Icons.flag_rounded, size: 48, color: AppTheme.accentAmber),
          SizedBox(height: 8),
          Text('Hedefini Belirle!', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 24)),
          SizedBox(height: 8),
          Text('Hedefin doğrultusunda sana en uygun programı oluşturalım! Hedefini seç ve bir adım daha yaklaş!', style: AppTheme.bodyMedium.copyWith(color: Colors.white70), textAlign: TextAlign.center),
          SizedBox(height: 24),
          Expanded(
            child: BlocBuilder<ExerciseBloc, ExerciseState>(
              builder: (context, state) {
                if (state is ExerciseLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (state is WorkoutGoalsLoaded) {
                  final model = Provider.of<ProgramMergerFormModel>(context);
                  return ListView.separated(
                    itemCount: state.goals.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final goal = state.goals[i];
                      final isSelected = model.selectedGoalId == goal.id;
                      return GestureDetector(
                        onTap: () => model.setGoal(goal.id),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: isSelected
                              ? AppTheme.getPartGradient(difficulty: 4, secondaryColor: AppTheme.accentAmber)
                              : AppTheme.cardGradient,
                            borderRadius: BorderRadius.circular(18),
                            border: isSelected ? Border.all(color: AppTheme.accentAmber, width: 2) : null,
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.18), blurRadius: 10, offset: Offset(0, 2))]
                                : [],
                          ),
                          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          child: Row(
                            children: [
                              Icon(Icons.emoji_events, color: isSelected ? Colors.white : AppTheme.accentAmber, size: 32),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(goal.name, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.accentAmber)),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: Colors.white, size: 28),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return Container();
              },
            ),
          ),
          SizedBox(height: 16),
          Consumer<ProgramMergerFormModel>(
            builder: (context, model, _) => AnimatedOpacity(
              opacity: model.selectedGoalId != null ? 1 : 0.5,
              duration: Duration(milliseconds: 200),
              child: ElevatedButton.icon(
                onPressed: model.selectedGoalId != null ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: AppTheme.accentAmber,
                  minimumSize: Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 4,
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) => null),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                icon: Icon(Icons.arrow_forward, color: Colors.white),
                label: Text('Devam Et', style: TextStyle(fontSize: 19)),
              ),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
} 