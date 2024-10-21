import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/models/BodyPart.dart';
import 'package:workout/models/WorkoutType.dart';

import '../../data_bloc_routine/routines_bloc.dart';

class RoutineDetails extends StatefulWidget {
  final int routineId;
  final String userId;

  const RoutineDetails({
    Key? key,
    required this.routineId,
    required this.userId,
  }) : super(key: key);

  @override
  _RoutineDetailsState createState() => _RoutineDetailsState();
}

class _RoutineDetailsState extends State<RoutineDetails> {
  late RoutinesBloc _routinesBloc;

  @override
  void initState() {
    super.initState();
    _routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    _routinesBloc.add(FetchRoutineExercises(routineId: widget.routineId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        if (state is RoutinesLoading) {
          return Scaffold(
            appBar: AppBar(title: Text('Loading...')),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is RoutineExercisesLoaded) {
          return _buildRoutineDetails(state.routine, state.exerciseListByBodyPart);
        } else if (state is RoutinesError) {
          return Scaffold(
            appBar: AppBar(title: Text('Error')),
            body: Center(child: Text('Error: ${state.message}')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text('Unknown State')),
          body: Center(child: Text('Unknown state')),
        );
      },
    );
  }

  Widget _buildRoutineDetails(Routines routine, Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    return Scaffold(
      appBar: AppBar(
        title: Text(routine.name),
        actions: [
          IconButton(
            icon: Icon(
              routine.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: routine.isFavorite ? Colors.red : null,
            ),
            onPressed: () => _toggleFavorite(routine),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(routine.name, style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 8),
              Text(routine.description, style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: 16),
              _buildInfoSection(routine),
              SizedBox(height: 16),
              _buildProgressSection(routine),
              SizedBox(height: 16),
              _buildExerciseList(exerciseListByBodyPart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(Routines routine) {
    return FutureBuilder<BodyParts?>(
      future: _routinesBloc.repository.getBodyPartById(routine.mainTargetedBodyPartId),
      builder: (context, bodyPartSnapshot) {
        return FutureBuilder<WorkoutTypes?>(
          future: _routinesBloc.repository.getWorkoutTypeById(routine.workoutTypeId),
          builder: (context, workoutTypeSnapshot) {
            final bodyPart = bodyPartSnapshot.data;
            final workoutType = workoutTypeSnapshot.data;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Routine Information', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 8),
                    Text('Target Body Part: ${bodyPart?.name ?? 'Unknown'}'),
                    Text('Workout Type: ${workoutType?.name ?? 'Unknown'}'),
                    if (routine.lastUsedDate != null)
                      Text('Last Used: ${routine.lastUsedDate!.toLocal()}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressSection(Routines routine) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: routine.userProgress != null ? routine.userProgress! / 100 : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 4),
            Text('${routine.userProgress ?? 0}% Complete'),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    if (exerciseListByBodyPart.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No exercises found for this routine.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: exerciseListByBodyPart.length,
      itemBuilder: (context, index) {
        final bodyPart = exerciseListByBodyPart.keys.elementAt(index);
        final exercises = exerciseListByBodyPart[bodyPart]!;

        return Card(
          child: ExpansionTile(
            title: Text(bodyPart),
            children: exercises.map((exercise) {
              return ListTile(
                title: Text(exercise['name']),
                subtitle: Text('${exercise['defaultSets']} sets x ${exercise['defaultReps']} reps'),
                trailing: Text('${exercise['defaultWeight']} kg'),
                onTap: () {
                  // Navigate to exercise details page
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _toggleFavorite(Routines routine) {
    _routinesBloc.add(ToggleRoutineFavorite(
      userId: widget.userId,
      routineId: routine.id.toString(),
      isFavorite: !routine.isFavorite,
    ));
  }
}
