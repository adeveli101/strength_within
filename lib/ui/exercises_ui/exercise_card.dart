// ignore_for_file: use_super_parameters

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/exercises.dart';
import 'exercise_details.dart';



class ExerciseCard extends StatefulWidget {
  final Exercises exercise;
  final String userId;
  final Function(bool)? onCompletionChanged;

  const ExerciseCard({
    Key? key,
    required this.exercise,
    required this.userId,
    this.onCompletionChanged,
  }) : super(key: key);

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus();
  }

  Future<void> _loadCompletionStatus() async {
    final status = await FirebaseFirestore.instance
        .collection('exerciseProgress')
        .doc('${widget.userId}_${widget.exercise.id}')
        .get();

    if (mounted && status.exists) {
      setState(() {
        isCompleted = status.data()?['isCompleted'] ?? false;
      });
    }
  }

  Future<void> _updateCompletionStatus(bool completed) async {
    try {
      await FirebaseFirestore.instance
          .collection('exerciseProgress')
          .doc('${widget.userId}_${widget.exercise.id}')
          .set({
        'userId': widget.userId,
        'exerciseId': widget.exercise.id,
        'isCompleted': completed,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      widget.onCompletionChanged?.call(completed);
    } catch (e) {
      print('Error updating completion status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseDetails(
                exerciseId: widget.exercise.id, userId: widget.userId,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isCompleted ? Colors.green.withOpacity(0.7) : Colors.blue.withOpacity(0.7),
                  isCompleted ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                ],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.exercise.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildCompactInfo(Icons.repeat, '${widget.exercise.defaultSets} set'),
                          const SizedBox(width: 8),
                          _buildCompactInfo(Icons.fitness_center, '${widget.exercise.defaultReps} tekrar'),
                          const SizedBox(width: 8),
                          _buildCompactInfo(Icons.monitor_weight_outlined, '${widget.exercise.defaultWeight} kg'),
                        ],
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isCompleted,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        isCompleted = value;
                      });
                      _updateCompletionStatus(value);
                    }
                  },
                  checkColor: Colors.white,
                  fillColor: WidgetStateProperty.resolveWith(
                        (states) => Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.white70,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}


