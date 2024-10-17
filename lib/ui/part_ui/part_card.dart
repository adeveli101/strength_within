import 'package:flutter/material.dart';
import '../../models/BodyPart.dart';
import '../../models/exercises.dart';
import '../../models/parts.dart';
import '../../resource/routines_bloc.dart';

class PartCard extends StatelessWidget {
  final Parts part;
  final bool isExpanded;
  final Function(bool) onExpandToggle;
  final VoidCallback onDelete;
  final VoidCallback? onPartTap;
  final RoutinesBloc routinesBloc;

  const PartCard({
    Key? key,
    required this.part,
    required this.isExpanded,
    required this.onExpandToggle,
    required this.onDelete,
    required this.routinesBloc,
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
    return FutureBuilder<List<Exercises>>(
      future: routinesBloc.getExercisesByBodyPart(part as MainTargetedBodyPart),
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

  Widget _buildExerciseRow(Exercises ex) {
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
              ex.defaultReps.toString(),
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
