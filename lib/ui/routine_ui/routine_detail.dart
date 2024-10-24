import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/root_controller.dart';
import 'package:workout/data_bloc_routine/routines_bloc.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/ui/routine_ui/routine_card.dart';

import '../../models/exercises.dart';
import '../exercises_ui/exercise_card.dart';
import '../exercises_ui/exercise_details.dart';

class RoutineDetailBottomSheet extends StatefulWidget {
  final int routineId;
  final String userId;

  const RoutineDetailBottomSheet({
    Key? key,
    required this.routineId,
    required this.userId,

  }) : super(key: key);



  @override
  _RoutineDetailBottomSheetState createState() => _RoutineDetailBottomSheetState();
}






class _RoutineDetailBottomSheetState extends State<RoutineDetailBottomSheet> {
  late RoutinesBloc _routinesBloc;

  @override
  void initState() {
    super.initState();
    _routinesBloc = context.read<RoutinesBloc>();
    _routinesBloc.add(FetchRoutineExercises(routineId: widget.routineId));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) return;

        final state = _routinesBloc.state;
        if (state is RoutineExercisesLoaded) {
          _routinesBloc.add(FetchRoutines());
        }

        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: BlocBuilder<RoutinesBloc, RoutinesState>(
              buildWhen: (previous, current) {
                return current is RoutinesLoading ||
                    current is RoutineExercisesLoaded ||
                    current is RoutinesError;
              },
              builder: (context, state) {
                if (state is RoutinesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is RoutineExercisesLoaded) {
                  final routine = state.routine;
                  if (routine.id != widget.routineId) {
                    return const Center(child: Text('Rutin bulunamadı'));
                  }
                  return _buildRoutineDetails(
                    routine,
                    state.exerciseListByBodyPart,
                    controller,
                  );
                }

                if (state is RoutinesError) {
                  return Center(child: Text('Hata: ${state.message}'));
                }

                return const Center(child: Text('Veriler yükleniyor...'));
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoutineDetails(
      Routines routine,
      Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart,
      ScrollController controller,
      ) {
    return Container(
      color: const Color(0xFF1E1E1E), // Koyu arka plan
      
      child: ListView(
        controller: controller,
        padding: EdgeInsets.zero,
        children: [
          // Üst Bilgi Bölümü
          Container(
            padding: const EdgeInsets.all(25.0),

            decoration: BoxDecoration(

              color: const Color(0xFF2C2C2C),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(60),
                topRight: Radius.circular(60),
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  routine.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem(
                      Icons.fitness_center,
                      'Hedef',

                      routine.mainTargetedBodyPartId.toString(),
                      
                    ),
                    _buildStatItem(
                      Icons.category,
                      'Tip',
                      routine.workoutTypeId.toString(),
                    ),
                    _buildStatItem(
                      Icons.trending_up,
                      'İlerleme',
                      '${routine.userProgress ?? 0}%',
                      color: _getProgressColor(routine.userProgress ?? 0),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // İlerleme Çubuğu
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (routine.userProgress ?? 0) / 100,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(routine.userProgress ?? 0),
                ),
              ),
            ),
          ),

          // Egzersiz Başlığı
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Egzersizler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(

                    '${_getTotalExerciseCount(exerciseListByBodyPart)} egzersiz',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Egzersiz Listesi
          ...exerciseListByBodyPart.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: const Color(0xFF2C2C2C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  backgroundColor: Colors.transparent,
                  collapsedBackgroundColor: Colors.transparent,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getBodyPartIcon(entry.key),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    entry.key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.value.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  children: entry.value.asMap().entries.map((exercise) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF383838),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          child: Text(
                            '${exercise.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          exercise.value['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            _buildExerciseInfo(
                              Icons.repeat,
                              '${exercise.value['defaultSets']} set',
                            ),
                            const SizedBox(width: 16),
                            _buildExerciseInfo(
                              Icons.fitness_center,
                              '${exercise.value['defaultReps']} tekrar',
                            ),
                            const SizedBox(width: 16),
                            _buildExerciseInfo(
                              Icons.monitor_weight_outlined,
                              '${exercise.value['defaultWeight']} kg',
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExerciseDetails(
                              exerciseId: exercise.value['id'],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.white70.withRed(15), size: 32),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.white70.withRed(15),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }



  Widget _buildCompactInfoCard(Routines routine) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Detaylar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildCompactInfoRow(Icons.track_changes, 'Hedef', routine.mainTargetedBodyPartId.toString()),
            _buildCompactInfoRow(Icons.category, 'Tip', routine.workoutTypeId.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactProgressCard(Routines routine) {
    final progress = routine.userProgress ?? 0;
    final color = _getProgressColor(progress);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 18, color: color),
                    const SizedBox(width: 8),
                    Text(
                      'İlerleme',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Text(
                  '%$progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildExerciseSection(String bodyPartName, List<Map<String, dynamic>> exercises) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              _getBodyPartIcon(bodyPartName),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(bodyPartName),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${exercises.length}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                title: Text(exercise['name']),
                subtitle: Text(
                  '${exercise['defaultSets']} set × ${exercise['defaultReps']} tekrar',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  '${exercise['defaultWeight']} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseDetails(
                        exerciseId: exercise['id'],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getBodyPartIcon(String bodyPartName) {
    switch (bodyPartName.toLowerCase()) {
      case 'göğüs':
        return Icons.fitness_center;
      case 'sırt':
        return Icons.accessibility_new;
      case 'bacak':
        return Icons.directions_walk;
      case 'omuz':
        return Icons.sports_gymnastics;
      case 'kol':
        return Icons.sports_handball;
      case 'karın':
        return Icons.straighten;
      default:
        return Icons.fitness_center;
    }
  }

  int _getTotalExerciseCount(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    return exerciseListByBodyPart.values
        .fold(0, (sum, exercises) => sum + exercises.length);
  }



  Widget _buildInfoSection(Routines routine) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rutin Bilgileri',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.fitness_center,
                      'Hedef Bölge',
                      routine.mainTargetedBodyPartId.toString(),
                    ),
                    _buildInfoRow(
                      Icons.category,
                      'Antrenman Tipi',
                      routine.workoutTypeId.toString(),
                    ),
                    if (routine.lastUsedDate != null)
                      _buildInfoRow(
                        Icons.access_time,
                        'Son Kullanım',
                        routine.lastUsedDate!.toLocal().toString().split('.')[0],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(Routines routine) {
    final progress = routine.userProgress ?? 0;
    final color = _getProgressColor(progress);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'İlerleme',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '%$progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                softWrap: icon.isBlank,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }




  Color _getProgressColor(int progress) {
    if (progress >= 80) return Colors.green;
    if (progress >= 60) return Colors.lightGreen;
    if (progress >= 40) return Colors.orange;
    if (progress >= 20) return Colors.deepOrange;
    return Colors.white70.withRed(15);
  }


}