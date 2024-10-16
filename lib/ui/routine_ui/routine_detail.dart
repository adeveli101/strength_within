import 'package:flutter/material.dart';

import '../../firebase_class/firebase_routines.dart';
import '../../models/exercises.dart';
import '../../resource/routines_bloc.dart';


class RoutineDetailPage extends StatefulWidget {
  final FirebaseRoutine firebaseRoutine;
  final RoutinesBloc routinesBloc;

  const RoutineDetailPage({
    Key? key,
    required this.firebaseRoutine,
    required this.routinesBloc,
  }) : super(key: key);

  @override
  _RoutineDetailPageState createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  late Future<List<Exercise>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = widget.routinesBloc.getExercisesForRoutine(widget.firebaseRoutine.routine.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.firebaseRoutine.routine.name),
        actions: [
          IconButton(
            icon: Icon(
              widget.firebaseRoutine.userRecommended ?? false
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoutineInfo(),
            _buildExerciseList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startRoutine,
        label: Text('Rutini Başlat'),
        icon: Icon(Icons.play_arrow),
      ),
    );
  }

  Widget _buildRoutineInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Zorluk: ${widget.firebaseRoutine.routine.difficulty}/5', style: Theme.of(context).textTheme.titleLarge),
          Text('Antrenman Türü: ${widget.firebaseRoutine.routine.workoutType.name}', style: Theme.of(context).textTheme.titleMedium),
          Text('Hedef Bölge: ${widget.firebaseRoutine.routine.mainTargetedBodyPart.toString().split('.').last}', style: Theme.of(context).textTheme.titleMedium),
          Text('Tahmini Süre: ${widget.firebaseRoutine.routine.estimatedTime} dakika', style: Theme.of(context).textTheme.titleMedium),
          if (widget.firebaseRoutine.userProgress != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(
                value: widget.firebaseRoutine.userProgress! / 100,
                minHeight: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return FutureBuilder<List<Exercise>>(
      future: _exercisesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Bu rutinde egzersiz bulunmamaktadır.'));
        } else {
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final exercise = snapshot.data![index];
              return ListTile(
                title: Text(exercise.name),
                subtitle: Text('${exercise.mainTargetedBodyPart} set, ${exercise.defaultReps} tekrar'),
                leading: Icon(Icons.fitness_center),
              );
            },
          );
        }
      },
    );
  }

  void _toggleFavorite() async {
    final updatedRoutine = widget.firebaseRoutine.copyWith(
      userRecommended: !(widget.firebaseRoutine.userRecommended ?? false),
    );
    await widget.routinesBloc.updateUserRoutine(updatedRoutine);
    setState(() {});
  }

  void _startRoutine() async {
    await widget.routinesBloc.updateUserRoutineLastUsedDate(
      await widget.routinesBloc.getUserId() ?? '',
      widget.firebaseRoutine.id,
    );
    // Burada rutini başlatma işlemi yapılabilir, örneğin yeni bir sayfaya yönlendirme
    // Navigator.push(context, MaterialPageRoute(builder: (context) => StartRoutinePage(routine: widget.firebaseRoutine)));
  }
}
