import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/models/BodyPart.dart';
import 'package:workout/models/WorkoutType.dart';
import 'package:workout/ui/part_ui/part_card.dart';
import 'package:workout/ui/part_ui/part_detail.dart';
import 'package:workout/ui/routine_ui/routine_card.dart';

import '../data_bloc_part/part_bloc.dart';
import '../data_bloc_routine/routines_bloc.dart';
import '../models/PartFocusRoutine.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late RoutinesBloc _routinesBloc;
  late PartsBloc _partsBloc;

  @override
  void initState() {
    super.initState();
    _routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    _partsBloc = BlocProvider.of<PartsBloc>(context);
    _loadAllData();
  }

  void _loadAllData() {
    _routinesBloc.add(FetchHomeData(userId: widget.userId));
    _partsBloc.add(FetchParts());
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
              _buildParts(context),
              BlocBuilder<RoutinesBloc, RoutinesState>(
                builder: (context, state) {
                  if (state is RoutinesLoading) {
                    return Center(child: CircularProgressIndicator());
                  } else if (state is RoutinesLoaded) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRoutines(state),
                        _buildBodyParts(state.bodyParts),
                        _buildWorkoutTypes(state.workoutTypes),
                      ],
                    );
                  } else if (state is RoutinesError) {
                    return Center(child: Text('Hata: ${state.message}'));
                  }
                  return Center(child: Text('Bilinmeyen durum'));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutines(RoutinesLoaded state) {
    List<Widget> routineSections = [];

    final favoriteRoutines = state.routines.where((r) => r.isFavorite).toList();
    if (favoriteRoutines.isNotEmpty) {
      routineSections.add(_buildRoutineList('Favori Rutinleriniz', favoriteRoutines));
    }

    final recentlyUsedRoutines = state.routines.where((r) => r.lastUsedDate != null).toList()
      ..sort((a, b) => (b.lastUsedDate ?? DateTime(0)).compareTo(a.lastUsedDate ?? DateTime(0)));
    if (recentlyUsedRoutines.isNotEmpty) {
      routineSections.add(_buildRoutineList('Son Kullanılan Rutinler', recentlyUsedRoutines));
    }

    routineSections.add(_buildRoutineList('Tüm Rutinler', state.routines));

    return Column(children: routineSections);
  }

  Widget _buildRoutineList(String title, List<Routines> routines) {
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
                  userId: widget.userId,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBodyParts(List<BodyParts> bodyParts) {
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

  Widget _buildWorkoutTypes(List<WorkoutTypes> workoutTypes) {
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

  Widget _buildParts(BuildContext context) {
    return BlocBuilder<PartsBloc, PartsState>(
      builder: (context, state) {
        print('Current PartsBloc state: $state'); // Bu satırı ekleyin
        if (state is PartsLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (state is PartsLoaded) {
          print('Loaded parts count: ${state.parts.length}');
          List<Widget> partSections = [];

          final favoriteParts = state.parts.where((p) => p.isFavorite).toList();
          if (favoriteParts.isNotEmpty) {
            partSections.add(_buildPartList('Favori Part\'larınız', favoriteParts));
          }

          final recentlyUsedParts = state.parts.where((p) => p.lastUsedDate != null).toList()
            ..sort((a, b) => (b.lastUsedDate ?? DateTime(0)).compareTo(a.lastUsedDate ?? DateTime(0)));
          if (recentlyUsedParts.isNotEmpty) {
            partSections.add(_buildPartList('Son Kullanılan Part\'lar', recentlyUsedParts.take(5).toList()));
          }

          final allParts = List<Parts>.from(state.parts)..shuffle();
          partSections.add(_buildPartList('Keşfet', allParts.take(5).toList()));

          return Column(children: partSections);
        } else if (state is PartsError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return Center(child: Text('No parts available: $state')); // Bu satırı güncelleyin
      },
    );
  }

  Widget _buildPartList(String title, List<Parts> parts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 230, // Yüksekliği biraz artırdık
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: parts.length,
            itemBuilder: (context, index) {
              final part = parts[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 180, // Genişliği biraz artırdık
                  child: PartCard(
                    part: part,
                    userId: widget.userId,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PartDetailPage(
                            partId: part.id,
                            userId: widget.userId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

}
