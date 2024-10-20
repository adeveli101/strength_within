import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/data_bloc/routines_bloc.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/models/BodyPart.dart';
import 'package:workout/models/WorkoutType.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<RoutinesBloc>(context).add(FetchHomeData(userId: widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ana Sayfa'),
      ),
      body: BlocBuilder<RoutinesBloc, RoutinesState>(
        builder: (context, state) {
          print("Current state: $state"); // Hata ayıklama için eklendi
          if (state is RoutinesLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is RoutinesLoaded) {
            print("Received RoutinesLoaded state with ${state.routines.length} routines");
            if (state.routines.isEmpty) {
              return Center(child: Text('Henüz rutin bulunmamaktadır.'));
            }
            return ListView.builder(
              itemCount: state.routines.length,
              itemBuilder: (context, index) {
                final routine = state.routines[index];
                return ListTile(
                  title: Text(routine.name),
                  subtitle: Text(routine.description ?? ''),
                  trailing: Icon(routine.isFavorite ? Icons.favorite : Icons.favorite_border),
                );
              },
            );
          } else if (state is RoutinesError) {
            return Center(child: Text('Hata: ${state.message}'));
          }
          return Center(child: Text('Bilinmeyen durum: ${state.runtimeType}'));
        },
      ),
    );
  }
}
  Widget _buildFavoriteRoutines(List<Routines> routines) {
    final favoriteRoutines = routines.where((routine) => routine.isFavorite).toList();
    return _buildRoutineList('Favori Rutinleriniz', favoriteRoutines);
  }

  Widget _buildRecentRoutines(List<Routines> routines) {
    final recentRoutines = routines
        .where((routine) => routine.lastUsedDate != null)
        .toList()
      ..sort((a, b) => b.lastUsedDate!.compareTo(a.lastUsedDate!));
    return _buildRoutineList('Son Kullanılan Rutinler', recentRoutines.take(5).toList());
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
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return Card(
                child: Container(
                  width: 120,
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(routine.name, style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(routine.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      Spacer(),
                      Text('İlerleme: ${routine.userProgress ?? 0}%'),

                    ],
                  ),
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
          runSpacing: 8,
          children: workoutTypes.map((workoutType) => Chip(label: Text(workoutType.name))).toList(),
        ),

      ],
    );
  }


