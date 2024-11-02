// ignore_for_file: unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/data_bloc_part/part_bloc.dart';
import 'package:workout/models/PartFocusRoutine.dart';
import 'package:workout/ui/part_ui/part_card.dart';
import 'package:logging/logging.dart';

import '../../models/exercises.dart';
import '../exercises_ui/exercise_card.dart';
import '../exercises_ui/exercise_details.dart';

class PartDetailBottomSheet extends StatefulWidget {
  final int partId;
  final String userId;

  const PartDetailBottomSheet({
    super.key,
    required this.partId,
    required this.userId
  });

  @override
  _PartDetailBottomSheetState createState() => _PartDetailBottomSheetState();
}


class _PartDetailBottomSheetState extends State<PartDetailBottomSheet> {

  late PartsBloc _partsBloc;
  final _logger = Logger('PartDetailBottomSheet');




  @override
  void initState() {
    super.initState();
    _partsBloc = context.read<PartsBloc>();
    _logger.info("PartDetailBottomSheet initialized with partId: ${widget.partId}");

    if (widget.partId > 0) {
      _partsBloc.add(FetchPartExercises(partId: widget.partId));
    } else {
      _logger.warning("Invalid partId: ${widget.partId}");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçersiz part ID. Lütfen tekrar deneyin.')),
        );
        Navigator.of(context).pop();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final state = _partsBloc.state;
        if (state is PartExercisesLoaded) {
          _partsBloc.add(UpdatePart(state.part));
          _partsBloc.add(FetchParts());
        }
        Navigator.of(context).pop();
      },

      child: BlocListener<PartsBloc, PartsState>(
        listener: (context, state) {
          if (state is PartsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
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
              child: BlocBuilder<PartsBloc, PartsState>(
                builder: (context, state) {
                  _logger.info('PartDetailBottomSheet state: $state');

                  if (state is PartsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is PartExercisesLoaded) {
                    return _buildLoadedContent(state, controller);
                  }

                  if (state is PartsError) {
                    return Center(child: Text('Hata: ${state.message}'));
                  }

                  return Center(
                    child: Text('Beklenmeyen durum: ${state.runtimeType}'),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadedContent(PartExercisesLoaded state, ScrollController controller) {
    return Container(
      color: const Color(0xFF1E1E1E), // Koyu arka plan
      child: ListView(
        controller: controller,
        padding: EdgeInsets.zero,
        children: [
          // Üst Bilgi Bölümü
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.part.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem(
                      Icons.fitness_center,
                      'Egzersiz Sayısı',
                      _getTotalExerciseCount(state.exerciseListByBodyPart).toString(),
                    ),
                    _buildStatItem(
                      Icons.category,
                      'Bölge ID',
                      state.part.id.toString(),
                    ),
                    _buildStatItem(
                      Icons.trending_up,
                      'İlerleme',
                      '${state.part.userProgress ?? 0}%',
                      color: _getProgressColor(state.part.userProgress ?? 0),
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
                value: (state.part.userProgress ?? 0) / 100,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(state.part.userProgress ?? 0),
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
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_getTotalExerciseCount(state.exerciseListByBodyPart)} egzersiz',
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
          ..._buildExerciseList(state.exerciseListByBodyPart),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildExerciseList(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    return exerciseListByBodyPart.entries.map((entry) {
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
            children: entry.value.map((exerciseMap) {
              final exerciseData = Exercises.fromMap(exerciseMap);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExerciseCard(
                  exercise: exerciseData,
                  userId: widget.userId,
                  onCompletionChanged: (isCompleted) {
                    // Firebase'e kaydetme işlemi burada yapılabilir
                    _updateExerciseCompletion(exerciseData.id, isCompleted);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      );
    }).toList();
  }

  void _updateExerciseCompletion(int exerciseId, bool isCompleted) {
    FirebaseFirestore.instance
        .collection('exerciseProgress')
        .doc('${widget.userId}_$exerciseId')
        .set({
      'userId': widget.userId,
      'exerciseId': exerciseId,
      'isCompleted': isCompleted,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
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
  Widget _buildStatItem(IconData icon, String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.white70, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
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
          size: 14,
          color: Colors.white70,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(int progress) {
    if (progress >= 80) return Colors.green;
    if (progress >= 60) return Colors.lightGreen;
    if (progress >= 40) return Colors.orange;
    if (progress >= 20) return Colors.deepOrange;
    return Colors.white70.withRed(15);
  }

  int _getTotalExerciseCount(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    return exerciseListByBodyPart.values
        .fold(0, (sum, exercises) => sum + exercises.length);
  }





  Widget _buildExerciseListTile(Map<String, dynamic> exercise) {
    return ListTile(
      title: Text(exercise['name']),
      subtitle: Text(
        'Set: ${exercise['defaultSets']}, '
            'Tekrar: ${exercise['defaultReps']}, '
            'Ağırlık: ${exercise['defaultWeight']}',
      ),
      trailing: Text(exercise['workoutType']),
    );
  }
}