import 'package:flutter/material.dart';
import 'package:workout/utils/routine_helpers.dart';
import 'package:workout/ui/part_edit_page.dart';

import '../../models/exercise.dart';
import '../../models/part.dart';
import '../../models/routine.dart';

typedef StringCallback = void Function(String val);

class PartEditCard extends StatefulWidget {
  final VoidCallback onDelete;
  final StringCallback? onTextEdited;
  final Part part;
  final Routine curRoutine;

  const PartEditCard({
    super.key,
    required this.onDelete,
    this.onTextEdited,
    required this.part,
    required this.curRoutine,
  });

  @override
  State<PartEditCard> createState() => PartEditCardState();
}

class PartEditPageHelper {
  static TargetedBodyPart radioValueToTargetedBodyPartConverter(int radioValue) {
    switch (radioValue) {
      case 0: return TargetedBodyPart.abs;
      case 1: return TargetedBodyPart.arm;
      case 2: return TargetedBodyPart.back;
      case 3: return TargetedBodyPart.chest;
      case 4: return TargetedBodyPart.leg;
      case 5: return TargetedBodyPart.shoulder;
      case 6: return TargetedBodyPart.bicep;
      case 7: return TargetedBodyPart.tricep;
      case 8: return TargetedBodyPart.fullBody;
      default: throw Exception('Invalid radio value for TargetedBodyPart');
    }
  }

// Diğer yardımcı metodlar...
}

class PartEditCardState extends State<PartEditCard> {
  late Part part;

  @override
  void initState() {
    super.initState();
    part = widget.part;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Card(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
        elevation: 12,
        color: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildExerciseListView(),
              _buildActionButtons(),
            ],
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
        style: const TextStyle(color: Colors.white70),
      ),
      subtitle: Text(
        targetedBodyPartToStringConverter(part.targetedBodyPart),
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildExerciseListView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _buildExerciseHeader(),
          ...part.exercises.map(_buildExerciseRow).expand((widget) => [widget, const Divider(color: Colors.white38)]),
        ],
      ),
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


  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _editPart,
          child: const Text('EDIT', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
        TextButton(
          onPressed: _showDeleteConfirmation,
          child: const Text('DELETE', style: TextStyle(color: Colors.red, fontSize: 16)),
        ),
      ],
    );
  }

  void _editPart() {
    Navigator.push<Part?>(
      context,
      MaterialPageRoute(
        builder: (context) => PartEditPage(
          addOrEdit: AddOrEdit.edit,
          part: part,
          curRoutine: widget.curRoutine,
        ),
      ),
    ).then((value) {
      if (value != null) {
        setState(() => part = value);
      }
    });
  }

  void _showDeleteConfirmation() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete this part of routine?'),
        content: const Text('You cannot undo this.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              widget.onDelete();
              Navigator.of(context).pop(true);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
