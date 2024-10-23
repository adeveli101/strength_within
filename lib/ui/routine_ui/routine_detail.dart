import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/data_bloc_routine/routines_bloc.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/ui/routine_ui/routine_card.dart';

class RoutineDetailBottomSheet extends StatefulWidget {
  final int routineId;
  final String userId;

  const RoutineDetailBottomSheet({
    Key? key,
    required this.routineId,
    required this.userId,
  }) : super(key: key);

  @override
  _RoutineDetailBottomSheetState createState() => _RoutineDetailBottomSheetState();
}

class _RoutineDetailBottomSheetState extends State<RoutineDetailBottomSheet> {
  late RoutinesBloc _routinesBloc;

  @override
  void initState() {
    super.initState();

    _routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    _routinesBloc.add(FetchRoutineExercises(routineId: widget.routineId));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }
        final state = _routinesBloc.state;
        if (state is RoutineExercisesLoaded) {
          _routinesBloc.add(FetchRoutines());
          _routinesBloc.add(UpdateRoutine(state.routine));
        }
        Navigator.of(context).pop();
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: BlocBuilder<RoutinesBloc, RoutinesState>(
              builder: (context, state) {
                if (state is RoutinesLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is RoutineExercisesLoaded) {
                  return _buildRoutineDetails(state.routine, state.exerciseListByBodyPart, controller);
                } else if (state is RoutinesError) {
                  return Center(child: Text('Hata: ${state.message}'));
                }
                return Center(child: Text('Veriler yükleniyor...'));
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoutineDetails(Routines routine, Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart, ScrollController controller) {
    return ListView(
      controller: controller,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: RoutineCard(routine: routine, userId: widget.userId),
        ),
        _buildInfoSection(routine),
        _buildProgressSection(routine),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Egzersizler',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...exerciseListByBodyPart.entries.map((entry) {
          return _buildExerciseSection(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildInfoSection(Routines routine) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rutin Bilgileri', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text('Hedef Vücut Bölgesi: ${routine.mainTargetedBodyPartId}'),
            Text('Antrenman Tipi: ${routine.workoutTypeId}'),
            if (routine.lastUsedDate != null)
              Text('Son Kullanım: ${routine.lastUsedDate!.toLocal()}'),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(Routines routine) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('İlerleme', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: routine.userProgress != null ? routine.userProgress! / 100 : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(Colors.blue),
            ),
            SizedBox(height: 4),
            Text('${routine.userProgress ?? 0}% Tamamlandı'),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSection(String bodyPartName, List<Map<String, dynamic>> exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            bodyPartName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...exercises.map((exercise) {
          return ListTile(
            title: Text(exercise['name']),
            subtitle: Text(
              'Set: ${exercise['defaultSets']}, Tekrar: ${exercise['defaultReps']}, Ağırlık: ${exercise['defaultWeight']} kg',
            ),
          );
        }).toList(),
      ],
    );
  }
}