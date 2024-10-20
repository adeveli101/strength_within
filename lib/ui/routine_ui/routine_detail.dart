import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/models/exercises.dart';
import 'package:workout/models/BodyPart.dart';
import 'package:workout/models/WorkoutType.dart';
import 'package:workout/data_bloc/routines_bloc.dart';

class RoutineDetails extends StatefulWidget {
  final Routines routine;
  final String userId;

  const RoutineDetails({
    Key? key,
    required this.routine,
    required this.userId,
  }) : super(key: key);

  @override
  _RoutineDetailsState createState() => _RoutineDetailsState();
}

class _RoutineDetailsState extends State<RoutineDetails> {
  late RoutinesBloc _routinesBloc;
  late Future<Routines?> _routineFuture;

  @override
  void initState() {
    super.initState();
    _routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    _loadData();
  }



  void _loadData() {
    _routineFuture = _routinesBloc.repository.getRoutineWithUserData(widget.userId, widget.routine.id);
    _routinesBloc.add(FetchExercises());
    _routinesBloc.add(FetchBodyParts());
    _routinesBloc.add(FetchWorkoutTypes());
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine.name),
        actions: [
          IconButton(
            icon: Icon(
              widget.routine.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.routine.isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: FutureBuilder<Routines?>(
        future: _routineFuture,
        builder: (context, routineSnapshot) {
          if (routineSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (routineSnapshot.hasError) {
            return Center(child: Text('Error: ${routineSnapshot.error}'));
          } else if (routineSnapshot.hasData) {
            return BlocBuilder<RoutinesBloc, RoutinesState>(
              builder: (context, state) {
                if (state is RoutinesLoaded) {
                  return _buildRoutineDetails(routineSnapshot.data!, state);
                } else if (state is RoutinesError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return Center(child: CircularProgressIndicator());
              },
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  Widget _buildRoutineDetails(Routines routine, RoutinesLoaded state) {
    final bodyPart = state.bodyParts.firstWhere(
          (bp) => bp.id == routine.mainTargetedBodyPartId,
      orElse: () => BodyParts(id: 0, name: 'Unknown', mainTargetedBodyPart: MainTargetedBodyPart.abs),
    );
    final workoutType = state.workoutTypes.firstWhere(
          (wt) => wt.id == routine.workoutTypeId,
      orElse: () => WorkoutTypes(id: 0, name: 'Unknown'),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(routine.name, style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 8),
            Text(routine.description, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 16),
            _buildInfoSection(bodyPart, workoutType),
            SizedBox(height: 16),
            _buildProgressSection(),
            SizedBox(height: 16),
            _buildExerciseList(routine, state.exercises),
          ],
        ),
      ),
    );
  }



  Widget _buildInfoSection(BodyParts bodyPart, WorkoutTypes workoutType) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Routine Information', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text('Target Body Part: ${bodyPart.mainTargetedBodyPartString}'),
            Text('Workout Type: ${workoutType.name}'),
            if (widget.routine.lastUsedDate != null)
              Text('Last Used: ${widget.routine.lastUsedDate!.toLocal()}'),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: widget.routine.userProgress != null ? widget.routine.userProgress! / 100 : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 4),
            Text('${widget.routine.userProgress ?? 0}% Complete'),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList(Routines routine, List<Exercises> allExercises) {
    final routineExercises = allExercises.where((exercise) => routine.exerciseIds.contains(exercise.id)).toList();

    if (routineExercises.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No exercises found for this routine.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exercises', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: routineExercises.length,
              itemBuilder: (context, index) {
                final exercise = routineExercises[index];
                return ListTile(
                  title: Text(exercise.name),
                  subtitle: Text('${exercise.defaultSets} sets x ${exercise.defaultReps} reps'),
                  trailing: Text('${exercise.defaultWeight} kg'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  void _toggleFavorite() {
    _routinesBloc.add(ToggleRoutineFavorite(
      userId: widget.userId,
      routineId: widget.routine.id.toString(),
      isFavorite: !widget.routine.isFavorite,
    ));
  }
}
