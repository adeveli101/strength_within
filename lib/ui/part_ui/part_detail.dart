import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/models/PartFocusRoutine.dart';

import '../../data_bloc_part/part_bloc.dart';

class PartDetailPage extends StatefulWidget {
  final int partId;
  final String userId;

  const PartDetailPage({Key? key, required this.partId, required this.userId}) : super(key: key);

  @override
  _PartDetailPageState createState() => _PartDetailPageState();
}

class _PartDetailPageState extends State<PartDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<PartsBloc>().add(FetchPartExercises(partId: widget.partId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PartsBloc, PartsState>(
      builder: (context, state) {
        if (state is PartsLoading) {
          return Scaffold(
            appBar: AppBar(title: Text('Loading...')),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is PartExercisesLoaded) {
          return Scaffold(
            appBar: AppBar(
              title: Text(state.part.name),
              actions: [
                IconButton(
                  icon: Icon(state.part.isFavorite ? Icons.favorite : Icons.favorite_border),
                  onPressed: () {
                    context.read<PartsBloc>().add(TogglePartFavorite(
                      userId: widget.userId,
                      partId: state.part.id.toString(),
                      isFavorite: !state.part.isFavorite,
                    ));
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Body Part: ${state.part.bodyPartId}'),
                    Text('Set Type: ${state.part.setType}'),
                    if (state.part.additionalNotes != null && state.part.additionalNotes.isNotEmpty)
                      Text('Additional Notes: ${state.part.additionalNotes}'),
                    SizedBox(height: 16),
                    Text('Exercises', style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 8),
                    _buildExerciseList(context, state.exerciseListByBodyPart),
                  ],
                ),
              ),
            ),
          );
        } else if (state is PartsError) {
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









  Widget _buildPartDetails(BuildContext context, PartExercisesLoaded state) {
    return Scaffold(
      appBar: AppBar(
        title: Text(state.part.name),
        actions: [
          IconButton(
            icon: Icon(state.part.isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              context.read<PartsBloc>().add(TogglePartFavorite(
                userId: widget.userId,
                partId: state.part.id.toString(),
                isFavorite: !state.part.isFavorite,
              ));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSection(context, state.part),
              SizedBox(height: 16),
              _buildProgressSection(state.part),
              SizedBox(height: 24),
              Text('Exercises', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 8),
              _buildExerciseList(context, state.exerciseListByBodyPart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, Parts part) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Body Part: ${part.bodyPartId}'),
            SizedBox(height: 8),
            Text('Set Type: ${part.setType}'),
            if (part.additionalNotes != null && part.additionalNotes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Notes: ${part.additionalNotes}'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(Parts part) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress: ${part.userProgress}%'),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: part.userProgress! / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildExerciseList(BuildContext context, Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: exerciseListByBodyPart.entries.map((entry) {
        String bodyPartName = entry.key;
        List<Map<String, dynamic>> exercises = entry.value;

        return ExpansionTile(
          title: Text(bodyPartName, style: Theme.of(context).textTheme.titleLarge),
          children: exercises.map((exercise) {
            return ListTile(
              title: Text(exercise['name']),
              subtitle: Text('Sets: ${exercise['defaultSets']}, Reps: ${exercise['defaultReps']}'),
              trailing: Text('Weight: ${exercise['defaultWeight']}'),
              onTap: () {
                // TODO: Navigate to exercise detail page or show exercise details
                print('Tapped on exercise: ${exercise['name']}');
              },
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}