import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../models/part.dart';
import '../../resource/db_provider.dart';

typedef PartTapCallback = void Function(Part part);
typedef StringCallback = void Function(String val);

class PartCard extends StatelessWidget {
  final Part part;
  final bool isExpanded;
  final Function(bool) onExpandToggle;
  final VoidCallback onDelete;
  final VoidCallback? onPartTap;

  const PartCard({
    Key? key,
    required this.part,
    required this.isExpanded,
    required this.onExpandToggle,
    required this.onDelete,
    this.onPartTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              part.name,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onTap: onPartTap,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white70,
                  ),
                  onPressed: () => onExpandToggle(!isExpanded),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.white70),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          if (isExpanded) _buildExerciseList(),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return FutureBuilder<List<Exercise>>(
      future: _getExercises(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(color: Color(0xFFE91E63));
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red));
        }
        final exercises = snapshot.data ?? [];
        return Column(
          children: [
            _buildExerciseHeader(),
            ...exercises.map(_buildExerciseRow),
          ],
        );
      },
    );
  }

  Widget _buildExerciseHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 22, child: SizedBox()),
          Expanded(flex: 5, child: Text('sets', style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: SizedBox()),
          Expanded(flex: 5, child: Text('reps', style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildExerciseRow(Exercise ex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 22,
            child: Text(
              ex.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              ex.defaultSets.toString(),
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'x',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              ex.defaultReps ?? '8',
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Exercise>> _getExercises() async {
    final db = await DBProvider.db.database;
    final exercises = await Future.wait(
        part.exerciseIds.map((id) async {
          var result = await db.query('Exercises', where: 'Id = ?', whereArgs: [id]);
          return Exercise.fromMap(result.first);
        })
    );
    return exercises;
  }
}
