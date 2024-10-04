import 'package:flutter/material.dart';
import 'package:workout/models/routine.dart';
import 'package:intl/intl.dart';

class RoutineDescriptionCard extends StatelessWidget {
  final Routine routine;

  const RoutineDescriptionCard({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Card(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
        elevation: 12,
        color: Colors.grey[700],
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                routine.routineName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'You have done this workout',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              Text(
                routine.completionCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 36, color: Colors.white),
              ),
              const Text(
                'times',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'since',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              Text(
                DateFormat('MM/dd/yyyy').format(routine.createdDate),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}