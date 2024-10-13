import 'package:flutter/material.dart';
import '../../controllers/routines_bloc.dart';
import '../../models/routine.dart';
import '../../models/exercise.dart';
import '../../utils/routine_helpers.dart';
import '../routine_detail_page.dart';
import '../../resource/db_provider.dart';

class RoutineOverviewCard extends StatefulWidget {
  final Routine routine;
  final bool isRecRoutine;

  RoutineOverviewCard({Key? key, required this.routine, this.isRecRoutine = false})
      : super(key: key);

  @override
  _RoutineOverviewCardState createState() => _RoutineOverviewCardState();
}

class _RoutineOverviewCardState extends State<RoutineOverviewCard> {
  List<Exercise> exercises = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final loadedExercises = await _getExercises();
    setState(() {
      exercises = loadedExercises;
    });
  }

  Future<List<Exercise>> _getExercises() async {
    final db = await DBProvider.db.database;
    final exercises = await Future.wait(
      widget.routine.partIds.take(3).map((partId) async {
        final part = await DBProvider.db.getPart(partId);
        if (part != null && part.exerciseIds.isNotEmpty) {
          final exerciseId = part.exerciseIds.first;
          final result = await db.query('Exercises', where: 'Id = ?', whereArgs: [exerciseId]);
          return Exercise.fromMap(result.first);
        }
        return null;
      }),
    );
    return exercises.whereType<Exercise>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          routinesBloc.setCurrentRoutine(widget.routine);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoutineDetailPage(
                isRecRoutine: widget.isRecRoutine,
                routine: widget.routine,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.routine.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                mainTargetedBodyPartToStringConverter(widget.routine.mainTargetedBodyPart),
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              SizedBox(height: 16),
              _buildExerciseList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: exercises.map((exercise) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          exercise.name,
          style: TextStyle(color: Colors.grey[300], fontSize: 14),
        ),
      )).toList(),
    );
  }
}
