import 'package:flutter/material.dart';
import '../../controllers/routines_bloc.dart';
import '../../models/routine.dart';
import '../routine_detail_page.dart';

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final bool isRecRoutine;
  final bool isSmall;

  RoutineCard({
    Key? key,
    required this.routine,
    this.isRecRoutine = false,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        routinesBloc.setCurrentRoutine(routine);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoutineDetailPage(
              isRecRoutine: isRecRoutine,
              routine: routine,
            ),
          ),
        );
      },
      child: Container(
        width: isSmall ? 140 : double.infinity,
        height: isSmall ? 120 : 180,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: isSmall ? 4 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 8 : 12),
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
                        fontSize: isSmall ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      routine.isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: isSmall ? 16 : 20,
                      color: routine.isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      // Implement favorite toggle functionality
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: isSmall ? 4 : 8),
              _buildDifficultyStars(),
              SizedBox(height: isSmall ? 4 : 8),
              Text(
                '${routine.estimatedTime ?? 30} min',
                style: TextStyle(fontSize: isSmall ? 10 : 12, color: Colors.grey),
              ),
              if (!isSmall) Spacer(),
              if (!isSmall) _buildQuickStartButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyStars() {
    return Row(
      children: List.generate(3, (index) {
        return Icon(
          index < (routine.difficulty ?? 1) ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: isSmall ? 15 : 20,
        );
      }),
    );
  }

  Widget _buildQuickStartButton(BuildContext context) {
    return ElevatedButton(
      child: Text('Quick Start', style: TextStyle(fontSize: 12)),
      onPressed: () {
        // t0d0 Implement quick start functionality
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        minimumSize: Size(double.infinity, 30),
        padding: EdgeInsets.zero,
      ),
    );
  }
}