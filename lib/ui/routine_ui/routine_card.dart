import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/ui/routine_ui/routine_detail.dart';

import '../../data_bloc_routine/routines_bloc.dart';

class RoutineCard extends StatelessWidget {
  final Routines routine;
  final String userId;
  final VoidCallback? onTap;

  const RoutineCard({
    Key? key,
    required this.routine,
    required this.userId,
    this.onTap,
  }) : super(key: key);

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoutineDetails(
            routineId: routine.id,
            userId: userId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      routine.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      routine.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: routine.isFavorite ? theme.colorScheme.secondary : null,
                    ),
                    onPressed: () => _toggleFavorite(context),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                routine.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInfoChip(context, Icons.fitness_center, routine.mainTargetedBodyPartId, 'Hedef Bölge')),
                  SizedBox(width: 8),
                  Expanded(child: _buildInfoChip(context, Icons.schedule, routine.workoutTypeId, 'Antrenman Türü')),
                ],
              ),
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: routine.userProgress != null ? routine.userProgress! / 100 : 0,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
              SizedBox(height: 4),
              Text(
                'İlerleme: ${routine.userProgress ?? 0}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, int id, String label) {
    return FutureBuilder<String>(
      future: _getInfoName(context, label, id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChip(context, icon, 'Yükleniyor...');
        } else if (snapshot.hasError) {
          return _buildChip(context, Icons.error, 'Hata', isError: true);
        } else {
          return _buildChip(context, icon, snapshot.data ?? 'Bilinmiyor');
        }
      },
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label, {bool isError = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isError ? Theme.of(context).colorScheme.error.withOpacity(0.1) : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getInfoName(BuildContext context, String type, int id) async {
    final repository = BlocProvider.of<RoutinesBloc>(context).repository;
    if (type == 'Hedef Bölge') {
      final bodyPart = await repository.getBodyPartById(id);
      return bodyPart?.name ?? 'Bilinmiyor';
    } else if (type == 'Antrenman Türü') {
      final workoutType = await repository.getWorkoutTypeById(id);
      return workoutType?.name ?? 'Bilinmiyor';
    }
    return 'Bilinmiyor';
  }

  void _toggleFavorite(BuildContext context) {
    final routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    routinesBloc.add(ToggleRoutineFavorite(
      userId: userId,
      routineId: routine.id.toString(),
      isFavorite: !routine.isFavorite,
    ));
  }
}
