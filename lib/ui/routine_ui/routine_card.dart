import 'package:flutter/material.dart';
import '../../firebase_class/firebase_routines.dart';
import '../../data_bloc/RoutineRepository.dart';
import 'routine_detail.dart';

class RoutineCard extends StatelessWidget {
  final FirebaseRoutines routine;
  final Function(bool) onFavoriteToggle;
  final bool isFavorite;
  final RoutineRepository repository;

  const RoutineCard({
    Key? key,
    required this.routine,
    required this.onFavoriteToggle,
    required this.isFavorite,
    required this.repository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey[900],
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => RoutineDetail(
              routine: routine,
              repository: repository,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
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
                      routine.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      routine.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: routine.isFavorite ? Colors.red : Colors.grey[400],
                    ),
                    onPressed: () => onFavoriteToggle(!routine.isFavorite),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Hedef Bölge: ${routine.mainTargetedBodyPartId.toString().split('.').last}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'İlerleme: ${routine.userProgress}%',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: routine.userProgress! / 100,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
