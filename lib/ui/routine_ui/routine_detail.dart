import 'package:flutter/material.dart';
import 'package:workout/models/RoutineExercises.dart';

import '../../data_bloc/RoutineRepository.dart';
import '../../firebase_class/firebase_routines.dart';
import '../../models/BodyPart.dart';
import '../../models/PartFocusRoutine.dart';


class RoutineDetail extends StatefulWidget {
  final FirebaseRoutines routine;
  final RoutineRepository repository;

  const RoutineDetail({
    Key? key,
    required this.routine,
    required this.repository,
  }) : super(key: key);

  @override
  _RoutineDetailState createState() => _RoutineDetailState();
}

class _RoutineDetailState extends State<RoutineDetail> {
  late Future<List<RoutineExercises>> _routineExercisesFuture;

  @override
  void initState() {
    super.initState();
    _routineExercisesFuture = widget.repository.getRoutineExercises(widget.routine.id);  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                widget.routine.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hedef Bölge: ${widget.routine.mainTargetedBodyPartId.toString().split('.').last}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'İlerleme: ${widget.routine.userProgress}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: widget.routine.userProgress! / 100,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 24),
              Text(
                'Parçalar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              FutureBuilder<List<RoutineExercises>>(
                future: _routineExercisesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Hata: ${snapshot.error}', style: TextStyle(color: Colors.red));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('Bu rutin için egzersiz bulunamadı.', style: TextStyle(color: Colors.grey[400]));
                  } else {
                    return Column(
                      children: snapshot.data!.map((routineExercise) => _buildExerciseItem(routineExercise)).toList(),
                    );
                  }
                },
              ),

              if (widget.routine.description != null && widget.routine.description.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24),
                    Text(
                      'Açıklama',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.routine.description,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseItem(RoutineExercises routineExercise) {
    // Bu metodu, RoutineExercises nesnesine göre güncelleyin
    return FutureBuilder<RoutineExercises>(
      future: widget.repository.getExercises(routineExercise.exerciseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Hata: ${snapshot.error}');
        } else if (!snapshot.hasData) {
          return Text('Egzersiz bulunamadı');
        } else {
          final exercise = snapshot.data!;
          return Card(
            color: Colors.grey[850],
            child: ListTile(
              title: Text(exercise.name, style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Hedef Bölge: ${MainTargetedBodyPart.values[exercise.mainTargetedBodyPartId].toString().split('.').last}',
                style: TextStyle(color: Colors.grey[400]),
              ),
              trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
              onTap: () {
                // Egzersiz detaylarına gitmek için navigasyon ekleyebilirsiniz
              },
            ),
          );
        }
      },
    );
}
