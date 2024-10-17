import 'package:flutter/material.dart';
import 'package:workout/models/parts.dart';
import 'package:workout/models/exercises.dart';
import '../../resource/routines_bloc.dart';

class PartDescriptionCard extends StatelessWidget {
  final Parts part;
  final RoutinesBloc routinesBloc;

  const PartDescriptionCard({
    Key? key,
    required this.part,
    required this.routinesBloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        color: Color(0xFF2C2C2C),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                part.name,
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Targeted Body Part: ${part.mainTargetedBodyPart.toString().split('.').last}',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Text(
                'Set Type: ${part.setType.toString().split('.').last}',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'Exercises:',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              FutureBuilder<List<Exercises>>(
                future: routinesBloc.getExercisesByBodyPart(part.mainTargetedBodyPart),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(color: Color(0xFFE91E63));
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('No exercises found', style: TextStyle(color: Colors.white70));
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: snapshot.data!.map((exercise) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${exercise.name}',
                              style: TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                          )
                      ).toList(),
                    );
                  }
                },
              ),
              if (part.additionalNotes.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Additional Notes:',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  part.additionalNotes,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
