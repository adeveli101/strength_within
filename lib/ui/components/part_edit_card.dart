import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../models/part.dart';
import '../../models/routine.dart';
import '../../resource/db_provider.dart';

class PartEditCard extends StatefulWidget {
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final Part part;
  final Routine curRoutine;

  const PartEditCard({
    Key? key,
    required this.onDelete,
    required this.onTap,
    required this.part,
    required this.curRoutine,
  }) : super(key: key);

  @override
  _PartEditCardState createState() => _PartEditCardState();
}

class _PartEditCardState extends State<PartEditCard> {
  bool _isExpanded = false;
  late Future<Map<int, Exercise>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _loadExercises() as Future<Map<int, Exercise>>;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF2C2C2C), // Koyu arka plan rengi
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.part.name,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: widget.onTap,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white70),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
          if (_isExpanded) _buildExerciseListView(),
        ],
      ),
    );
  }

  Widget _buildExerciseListView() {
    return FutureBuilder<Map<int, Exercise>>(
      future: _exercisesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(color: Color(0xFFE91E63));
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red));
        }
        final exercises = snapshot.data?.values.toList() ?? [];
        return Column(
          children: [
            _buildExerciseHeader(),
            ...exercises.map(_buildExerciseRow).expand((widget) => [widget, const Divider(color: Colors.white24)]),
          ],
        );
      },
    );
  }

  Future<Map<String, Exercise>> _loadExercises() async {
    return await DBProvider.db.getExercisesForPart(widget.part);
  }

  Widget _buildExerciseHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16, color: Colors.white70),
                  onPressed: () => _updateExerciseSets(ex, ex.defaultSets! - 1),
                ),
                Text(
                  ex.defaultSets.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16, color: Colors.white70),
                  onPressed: () => _updateExerciseSets(ex, ex.defaultSets! + 1),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'x',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16, color: Colors.white70),
                  onPressed: () => _updateExerciseReps(ex, int.parse(ex.defaultReps!) - 1),
                ),
                Text(
                  ex.defaultReps ?? '8',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16, color: Colors.white70),
                  onPressed: () => _updateExerciseReps(ex, int.parse(ex.defaultReps!) + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateExerciseSets(Exercise exercise, int newSets) async {
    if (newSets > 0) {
      exercise.defaultSets = newSets;
      await DBProvider.db.updateExercise(exercise);
      setState(() {});
    }
  }

  void _updateExerciseReps(Exercise exercise, int newReps) async {
    if (newReps > 0) {
      exercise.defaultReps = newReps.toString();
      await DBProvider.db.updateExercise(exercise);
      setState(() {});
    }
  }
}
