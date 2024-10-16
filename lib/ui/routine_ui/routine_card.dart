import 'package:flutter/material.dart';

import '../../firebase_class/firebase_routines.dart';
import '../../resource/routines_bloc.dart';


class RoutineCard extends StatefulWidget {
  final FirebaseRoutine firebaseRoutine;
  final RoutinesBloc routinesBloc;

  const RoutineCard({
    Key? key,
    required this.firebaseRoutine,
    required this.routinesBloc,
  }) : super(key: key);

  @override
  _RoutineCardState createState() => _RoutineCardState();
}

class _RoutineCardState extends State<RoutineCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/routine_detail', arguments: widget.firebaseRoutine);
        },
        child: Column(
          children: [
            ListTile(
              title: Text(widget.firebaseRoutine.routine.name),
              subtitle: Text('${widget.firebaseRoutine.routine.workoutType.name} - ${widget.firebaseRoutine.routine.difficulty}/5'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      widget.firebaseRoutine.userRecommended ?? false
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: Icon(Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (widget.firebaseRoutine.userProgress != null)
              LinearProgressIndicator(
                value: widget.firebaseRoutine.userProgress! / 100,
                minHeight: 2,
              ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hedef Bölge: ${widget.firebaseRoutine.routine.mainTargetedBodyPart.toString().split('.').last}'),
                    Text('Tahmini Süre: ${widget.firebaseRoutine.routine.estimatedTime} dakika'),
                    SizedBox(height: 8),
                    ElevatedButton(
                      child: Text('Başlat'),
                      onPressed: _startRoutine,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
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
    // Rutini başlatma işlemi burada yapılacak
    await widget.routinesBloc.updateUserRoutineLastUsedDate(
      await widget.routinesBloc.getUserId() ?? '',
      widget.firebaseRoutine.id,
    );
    // Rutin başlatma sayfasına yönlendirme yapılabilir
  }




}
