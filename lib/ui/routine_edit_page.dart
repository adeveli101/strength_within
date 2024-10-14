import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/part.dart';
import '../models/exercise.dart';
import '../resource/db_provider.dart';
import '../resource/firebase_provider.dart';
import '../resource/routines_bloc.dart';

class RoutineEditPage extends StatefulWidget {
  final Routine? routine;
  final bool isEditing;

  const RoutineEditPage({Key? key, this.routine, this.isEditing = false}) : super(key: key);

  @override
  _RoutineEditPageState createState() => _RoutineEditPageState();
}

class _RoutineEditPageState extends State<RoutineEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  List<Part> _availableParts = [];
  Map<int, List<Exercise>> _exercisesByPart = {};
  Map<int, List<Exercise>> _selectedExercisesByPart = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine?.name ?? '');
    _loadData();
  }

  Future<void> _loadData() async {
    _availableParts = await DBProvider.db.getAllParts();
    for (var part in _availableParts) {
      _exercisesByPart[part.id] = (await DBProvider.db.getExercisesForPart(part)) as List<Exercise>;
    }
    if (widget.isEditing && widget.routine != null) {
      for (var partId in widget.routine!.partIds) {
        var part = _availableParts.firstWhere((p) => p.id == partId);
        _selectedExercisesByPart[partId] = (await DBProvider.db.getExercisesForPart(part)) as List<Exercise>;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Routine' : 'Create Routine'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveRoutine,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Routine Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name for the routine';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            Text('Select Exercises:', style: Theme.of(context).textTheme.titleLarge),
            ..._buildExerciseSelectionWidgets(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExerciseSelectionWidgets() {
    return _availableParts.map((part) {
      return ExpansionTile(
        title: Text(part.name),
        children: (_exercisesByPart[part.id] ?? []).map((exercise) {
          bool isSelected = (_selectedExercisesByPart[part.id] ?? []).contains(exercise);
          return CheckboxListTile(
            title: Text(exercise.name),
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedExercisesByPart.putIfAbsent(part.id, () => []).add(exercise);
                } else {
                  _selectedExercisesByPart[part.id]?.remove(exercise);
                }
              });
            },
          );
        }).toList(),
      );
    }).toList();
  }

  Future<void> _saveRoutine() async {
    if (_formKey.currentState!.validate()) {
      List<int> selectedPartIds = _selectedExercisesByPart.keys.toList();
      MainTargetedBodyPart mainTargetedBodyPart = MainTargetedBodyPart.fullBody;

      if (selectedPartIds.isNotEmpty) {
        Part firstSelectedPart = _availableParts.firstWhere((p) => p.id == selectedPartIds.first);
        mainTargetedBodyPart = _convertToMainTargetedBodyPart(firstSelectedPart.targetedBodyPart);
      }

      Routine newRoutine = Routine(
        id: widget.routine?.id ?? DateTime.now().millisecondsSinceEpoch,
        name: _nameController.text,
        mainTargetedBodyPart: mainTargetedBodyPart,
        partIds: selectedPartIds,
        isRecommended: widget.routine?.isRecommended ?? false,
        difficulty: 1, // Varsayılan zorluk seviyesi
        estimatedTime: 30, // Varsayılan tahmini süre (dakika cinsinden)
      );

      try {
        await FirebaseProvider().saveUserRoutine(newRoutine);
        if (widget.isEditing) {
          await RoutinesBloc().updateRoutine(newRoutine);
        } else {
          await RoutinesBloc().addRoutine(newRoutine);
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving routine: $e')),
        );
      }
    }
  }

  MainTargetedBodyPart _convertToMainTargetedBodyPart(TargetedBodyPart partTargetedBodyPart) {
    switch (partTargetedBodyPart) {
      case TargetedBodyPart.upperBody:
        return MainTargetedBodyPart.upperBody;
      case TargetedBodyPart.lowerBody:
        return MainTargetedBodyPart.lowerBody;
      case TargetedBodyPart.core:
        return MainTargetedBodyPart.core;
      default:
        return MainTargetedBodyPart.fullBody;
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
