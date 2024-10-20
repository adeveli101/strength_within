import 'package:flutter/material.dart';
import 'package:workout/models/PartFocusRoutine.dart';
import 'package:workout/models/exercises.dart';
import 'package:workout/models/BodyPart.dart';
import 'package:workout/data_bloc/RoutineRepository.dart';
import '../exercises_ui/exercise_card.dart';

class PartDescription extends StatefulWidget {
  final Parts part;
  final RoutineRepository repository;
  final String userId;

  const PartDescription({
    Key? key,
    required this.part,
    required this.repository,
    required this.userId,
  }) : super(key: key);

  @override
  _PartDescriptionState createState() => _PartDescriptionState();
}

class _PartDescriptionState extends State<PartDescription> {
  late Future<Map<BodyParts, List<Exercises>>> _groupedExercisesFuture;
  late Map<int, BodyParts> _bodyPartsMap;

  @override
  void initState() {
    super.initState();
    _loadBodyPartsMap();
    _groupedExercisesFuture = _loadGroupedExercises();
  }

  Future<void> _loadBodyPartsMap() async {
    final bodyParts = await widget.repository.getAllBodyParts();
    _bodyPartsMap = {for (var part in bodyParts) part.id: part};
  }

  Future<Map<BodyParts, List<Exercises>>> _loadGroupedExercises() async {
    final exerciseIds = await widget.repository.getExerciseIdsForPart(widget.part.id);
    final exercises = await Future.wait(
      exerciseIds.map((id) => widget.repository.getExerciseById(id)),
    );
    final validExercises = exercises.whereType<Exercises>().toList();

    Map<BodyParts, List<Exercises>> groupedExercises = {};
    for (var exercise in validExercises) {
      final bodyPart = await widget.repository.getBodyPartById(exercise.mainTargetedBodyPartId);
      if (bodyPart != null) {
        if (!groupedExercises.containsKey(bodyPart)) {
          groupedExercises[bodyPart] = [];
        }
        groupedExercises[bodyPart]!.add(exercise);
      }
    }
    return groupedExercises;
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.part.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (Diğer widget'lar aynı kalıyor)
            FutureBuilder<Map<BodyParts, List<Exercises>>>(
              future: _groupedExercisesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
                }
                final groupedExercises = snapshot.data ?? {};
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: groupedExercises.length,
                  itemBuilder: (context, index) {
                    final bodyPart = groupedExercises.keys.elementAt(index);
                    final exercises = groupedExercises[bodyPart] ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            bodyPart.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        ...exercises.map((exercise) => ExerciseCard(
                          exercise: exercise,
                          repository: widget.repository,
                          bodyPartsMap: _bodyPartsMap,
                          onTap: () {
                            // Egzersiz detay sayfasına yönlendirme
                          },
                        )).toList(),
                        Divider(),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}