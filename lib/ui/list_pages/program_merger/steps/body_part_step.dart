import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:strength_within/blocs/data_exercise_bloc/exercise_bloc.dart';
import 'package:strength_within/models/sql_models/BodyPart.dart';
import 'package:strength_within/ui/list_pages/program_merger/program_merger_model.dart';
import '../../../../sw_app_theme/app_theme.dart';

class BodyPartStep extends StatelessWidget {
  final VoidCallback onNext;

  const BodyPartStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vücut Bölgesi Seç', style: AppTheme.headingMedium),
          SizedBox(height: AppTheme.paddingSmall),
          Text('Çalışmak istediğin vücut bölgelerini seç.', style: AppTheme.bodyMedium.copyWith(color: Colors.white70)),
          SizedBox(height: AppTheme.paddingLarge),
          Expanded(
            child: BlocBuilder<ExerciseBloc, ExerciseState>(
              builder: (context, state) {
                if (state is ExerciseLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (state is ExerciseError) {
                  return Center(child: Text('Vücut bölgeleri yüklenemedi: ${state.message}', style: TextStyle(color: Colors.red)));
                }
                if (state is BodyPartsLoaded) {
                  final bodyParts = state.bodyParts;
                  return Consumer<ProgramMergerFormModel>(
                    builder: (context, model, child) {
                      return ListView.builder(
                        itemCount: bodyParts.length,
                        itemBuilder: (context, index) {
                          final part = bodyParts[index];
                          final isSelected = model.selectedBodyParts?.contains(part.id) ?? false;
                          return Card(
                            color: isSelected ? AppTheme.primaryRed.withOpacity(0.2) : AppTheme.cardBackground,
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(part.name, style: AppTheme.bodyLarge),
                              trailing: Icon(
                                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                color: isSelected ? AppTheme.primaryRed : Colors.white54,
                              ),
                              onTap: () => model.toggleBodyPart(part.id),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
                // Eğer state BodyPartsLoaded değilse, event gönder.
                context.read<ExerciseBloc>().add(FetchBodyParts());
                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
          SizedBox(height: AppTheme.paddingLarge),
          Consumer<ProgramMergerFormModel>(
            builder: (context, model, child) {
              return ElevatedButton(
                onPressed: (model.selectedBodyParts != null && model.selectedBodyParts!.isNotEmpty) ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                child: Text('Devam Et', style: AppTheme.bodyLarge),
              );
            },
          ),
        ],
      ),
    );
  }
} 