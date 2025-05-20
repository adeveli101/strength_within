import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strength_within/ui/list_pages/program_merger/program_merger_model.dart';
import '../../../../sw_app_theme/app_theme.dart';

class DayAssignmentStep extends StatelessWidget {
  final VoidCallback onNext;
  const DayAssignmentStep({super.key, required this.onNext});

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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gün Seçimi', style: AppTheme.headingMedium),
              SizedBox(height: AppTheme.paddingSmall),
              Text('Egzersizleri hangi günlerde yapmak istediğini seç.', style: AppTheme.bodyMedium.copyWith(color: Colors.white70)),
              SizedBox(height: AppTheme.paddingLarge),
              Expanded(
                child: ListView(
                  children: [
                    _buildDaySelectionGrid(model),
                    SizedBox(height: AppTheme.paddingLarge),
                    _buildSelectedExercisesList(model),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.paddingLarge),
              ElevatedButton(
                onPressed: model.trainingDays.isNotEmpty ? onNext : null,
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
      ),
    );
  }

  Widget _buildDaySelectionGrid(ProgramMergerFormModel model) {
    final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        final isSelected = model.trainingDays.contains(index + 1);
        return InkWell(
          onTap: () => model.toggleTrainingDay(index + 1),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryRed : AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedExercisesList(ProgramMergerFormModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seçilen Egzersizler', style: AppTheme.headingSmall),
        SizedBox(height: AppTheme.paddingMedium),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: model.selectedExercises.length,
          itemBuilder: (context, index) {
            final exerciseId = model.selectedExercises[index];
            return Card(
              color: AppTheme.cardBackground,
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('Egzersiz $exerciseId', style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.fitness_center, color: AppTheme.primaryRed),
              ),
            );
          },
        ),
      ],
    );
  }
} 