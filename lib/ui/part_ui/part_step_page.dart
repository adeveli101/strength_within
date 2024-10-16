import 'package:flutter/material.dart';

import '../../models/exercises.dart';
import '../../models/parts.dart';
import '../../resource/routines_bloc.dart';
import '../../utils/routine_helpers.dart';


class PartStepPage extends StatefulWidget {
  final Part part;
  final RoutinesBloc routinesBloc;

  const PartStepPage({Key? key, required this.part, required this.routinesBloc}) : super(key: key);

  @override
  _PartStepPageState createState() => _PartStepPageState();
}

class _PartStepPageState extends State<PartStepPage> {
  List<Exercise> exercises = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final loadedExercises = await Future.wait(
      widget.part.exerciseIds.map((id) => widget.routinesBloc.getExerciseById(id)),
    );
    setState(() {
      exercises = loadedExercises.whereType<Exercise>().toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: exercises.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.part.name),
          bottom: TabBar(
            isScrollable: true,
            tabs: _getTabs(),
          ),
        ),
        body: TabBarView(
          children: _getTabChildren(),
        ),
      ),
    );
  }

  List<Widget> _getTabs() {
    return exercises.map((exercise) {
      return Tab(text: exercise.name);
    }).toList();
  }

  List<Widget> _getTabChildren() {
    return exercises.map((exercise) {
      return TabChild(exercise: exercise, setType: widget.part.setType);
    }).toList();
  }
}

class TabChild extends StatelessWidget {
  final Exercise exercise;
  final SetType setType;

  const TabChild({Key? key, required this.exercise, required this.setType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Exercise History for: ${exercise.name}'),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Set Type: ${setTypeToStringConverter(setType)}'),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Default Weight: ${exercise.defaultWeight}'),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Default Sets: ${exercise.defaultSets ?? "Not set"}'),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Default Reps: ${exercise.defaultReps ?? "Not set"}'),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Workout Type: ${workoutTypeToStringConverter(exercise.workoutType)}'),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Main Targeted Body Part: ${mainTargetedBodyPartToStringConverter(exercise.mainTargetedBodyPart)}'),
          ),
          // Here you would add your chart or other widgets to display exercise history
        ],
      ),
    );
  }
}
