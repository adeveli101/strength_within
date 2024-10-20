import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/data_bloc/routines_bloc.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/models/BodyPart.dart';
import 'package:workout/models/WorkoutType.dart';
import 'package:workout/models/PartFocusRoutine.dart';
import 'package:workout/ui/part_ui/part_card.dart';
import 'package:workout/ui/part_ui/part_description.dart';
import 'package:workout/ui/routine_ui/routine_card.dart';
import 'package:workout/ui/routine_ui/routine_detail.dart';
import '../data_bloc/RoutineRepository.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late RoutinesBloc _routinesBloc;

  @override
  void initState() {
    super.initState();
    _routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    _loadAllData();
  }

  void _loadAllData() {
    _routinesBloc.add(FetchRoutines());
    _routinesBloc.add(FetchBodyParts());
    _routinesBloc.add(FetchWorkoutTypes());
    _routinesBloc.add(FetchParts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ana Sayfa'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadAllData();
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoutines(),
              _buildBodyParts(),
              _buildWorkoutTypes(),
              _buildPartFocusRoutines(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutines() {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      buildWhen: (previous, current) => current is RoutinesLoaded,
      builder: (context, state) {
        if (state is RoutinesLoaded) {
          List<Widget> routineSections = [];

          // Favori Rutinler
          final favoriteRoutines = state.routines.where((r) => r.isFavorite).toList();
          if (favoriteRoutines.isNotEmpty) {
            routineSections.add(_buildRoutineList('Favori Rutinleriniz', favoriteRoutines, state.repository));
          }

          // Son Kullanılan Rutinler
          final recentlyUsedRoutines = state.routines.where((r) => r.lastUsedDate != null).toList()
            ..sort((a, b) => b.lastUsedDate!.compareTo(a.lastUsedDate!));
          if (recentlyUsedRoutines.isNotEmpty) {
            routineSections.add(_buildRoutineList('Son Kullanılan Rutinler', recentlyUsedRoutines, state.repository));
          }

          // Tüm Rutinler
          routineSections.add(_buildRoutineList('Tüm Rutinler', state.routines, state.repository));

          return Column(children: routineSections);
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildBodyParts() {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      buildWhen: (previous, current) => current is RoutinesLoaded && current.bodyParts.isNotEmpty,
      builder: (context, state) {
        if (state is RoutinesLoaded) {
          return _buildBodyPartsList(state.bodyParts);
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildWorkoutTypes() {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      buildWhen: (previous, current) => current is RoutinesLoaded && current.workoutTypes.isNotEmpty,
      builder: (context, state) {
        if (state is RoutinesLoaded) {
          return _buildWorkoutTypesList(state.workoutTypes);
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildPartFocusRoutines() {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      buildWhen: (previous, current) => current is RoutinesLoaded && current.parts.isNotEmpty,
      builder: (context, state) {
        if (state is RoutinesLoaded) {
          return _buildPartFocusRoutinesList(state.parts, state.repository);
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildRoutineList(String title, List<Routines> routines, RoutineRepository repository) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return SizedBox(
                width: 300,
                child: RoutineCard(
                  routine: routine,
                  repository: repository,
                  userId: widget.userId,

                ),
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _buildBodyPartsList(List<BodyParts> bodyParts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Vücut Bölümleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: bodyParts.map((bodyPart) => Chip(label: Text(bodyPart.name))).toList(),
        ),
      ],
    );
  }

  Widget _buildWorkoutTypesList(List<WorkoutTypes> workoutTypes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Antrenman Türleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 5,
          children: workoutTypes.map((workoutType) => Chip(label: Text(workoutType.name))).toList(),
        ),
      ],
    );
  }



  Widget _buildPartFocusRoutinesList(List<Parts> parts, RoutineRepository repository) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Part Odaklı Rutinler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: parts.length,
            itemBuilder: (context, index) {
              final part = parts[index];
              return SizedBox(
                width: 300,
                child: PartFocusRoutineCard(
                  part: part,
                  repository: repository,
                  userId: widget.userId,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PartDescription(
                          part: part,
                          repository: repository,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

}