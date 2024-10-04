import 'package:flutter/material.dart';
import 'package:workout/utils/routine_helpers.dart';

import '../../models/exercise.dart';
import '../../models/part.dart';

typedef PartTapCallback = void Function(Part part);
typedef StringCallback = void Function(String val);

class PartCard extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback? onPartTap;
  final StringCallback? onTextEdited;
  final Part part;

  const PartCard({
    super.key,
    required this.onDelete,
    required this.onPartTap,
    this.onTextEdited,
    required this.part,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Card(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
        elevation: 12,
        color: Theme.of(context).primaryColor,
        child: InkWell(
          onTap: onPartTap,
          splashColor: Colors.grey,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildExerciseList(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ListTile(
      leading: targetedBodyPartToImageConverter(part.targetedBodyPart),
      title: Text(
        setTypeToStringConverter(part.setType),
        style: const TextStyle(color: Colors.white70, fontSize: 16),
      ),
      subtitle: Text(
        targetedBodyPartToStringConverter(part.targetedBodyPart),
        style: const TextStyle(color: Colors.white54, fontSize: 16),
      ),
    );
  }



  Widget _buildExerciseList() {
    return Column(
      children: [
        _buildExerciseHeader(),
        ...part.exercises.map(_buildExerciseRow).expand((widget) => [widget, const Divider(color: Colors.white38)]),
      ],
    );
  }

  Widget _buildExerciseHeader() {
    return const Row(
      children: [
        Expanded(flex: 22, child: SizedBox()),
        Expanded(flex: 5, child: Text('sets', style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center)),
        Expanded(flex: 1, child: SizedBox()),
        Expanded(flex: 5, child: Text('reps', style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _buildExerciseRow(Exercise ex) {
    return Row(
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
          child: Text(
            ex.sets.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
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
          child: Text(
            ex.reps,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}