import 'package:flutter/material.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/data_bloc/RoutineRepository.dart';
import 'package:workout/models/BodyPart.dart';
import 'package:workout/models/WorkoutType.dart';
import 'package:workout/ui/routine_ui/routine_detail.dart';

import '../../models/RoutineExercises.dart';

class RoutineCard extends StatefulWidget {
  final Routines routine;
  final RoutineRepository repository;
  final String userId;
  final VoidCallback? onTap;

  const RoutineCard({
    Key? key,
    required this.routine,
    required this.repository,
    required this.userId,
    this.onTap,
  }) : super(key: key);

  @override
  _RoutineCardState createState() => _RoutineCardState();
}

class _RoutineCardState extends State<RoutineCard> {
  late Future<BodyParts?> _bodyPartFuture;
  late Future<WorkoutTypes?> _workoutTypeFuture;
  late Future<List<RoutineExercises>> _routineExercisesFuture;

  @override
  void initState() {
    super.initState();
    _bodyPartFuture = widget.repository.getBodyPartById(widget.routine.mainTargetedBodyPartId);
    _workoutTypeFuture = widget.repository.getWorkoutTypeById(widget.routine.workoutTypeId);
    _routineExercisesFuture = widget.repository.getRoutineExercisesByRoutineId(widget.routine.id);
  }
  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoutineDetails(
            routine: widget.routine,

            userId: widget.userId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: InkWell(
        onTap: _handleTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.routine.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      widget.routine.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: widget.routine.isFavorite ? Colors.red : null,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
              SizedBox(height: 8),
              FutureBuilder<List<RoutineExercises>>(
                future: _routineExercisesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Egzersizler yükleniyor...');
                  } else if (snapshot.hasError) {
                    return Text('Egzersizler yüklenirken hata oluştu');
                  } else {
                    return Text('Egzersiz Sayısı: ${snapshot.data?.length ?? 0}');
                  }
                },
              ),
              SizedBox(height: 8),
              Text(
                widget.routine.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              FutureBuilder<BodyParts?>(
                future: _bodyPartFuture,
                builder: (context, snapshot) {
                  return Text('Hedef Bölge: ${snapshot.data?.name ?? 'Yükleniyor...'}');
                },
              ),
              SizedBox(height: 4),
              FutureBuilder<WorkoutTypes?>(
                future: _workoutTypeFuture,
                builder: (context, snapshot) {
                  return Text('Antrenman Türü: ${snapshot.data?.name ?? 'Yükleniyor...'}');
                },
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: widget.routine.userProgress != null ? widget.routine.userProgress! / 100 : 0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 4),
              Text('İlerleme: ${widget.routine.userProgress ?? 0}%'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    try {
      await widget.repository.toggleRoutineFavorite(
        widget.userId,
        widget.routine.id.toString(),
        !widget.routine.isFavorite,
      );
      setState(() {
        widget.routine.isFavorite = !widget.routine.isFavorite;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favori durumu güncellenirken bir hata oluştu')),
      );
    }
  }
}

