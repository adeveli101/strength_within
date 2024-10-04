import 'package:flutter/material.dart';
import 'package:workout/models/routine.dart';
import 'package:workout/ui/routine_detail_page.dart';
import 'package:workout/bloc/routines_bloc.dart';

class RoutineOverviewCard extends StatelessWidget {
  final Routine routine;
  final bool isRecRoutine;

  const RoutineOverviewCard({
    super.key,
    required this.routine,
    this.isRecRoutine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(6),
        elevation: 4,
        child: InkWell(
          splashColor: Colors.grey,
          borderRadius: BorderRadius.circular(6),
          onTap: () => _navigateToDetailPage(context),
          child: SizedBox(
            height: 72,
            child: Stack(
              children: [
                _buildRoutineInfo(),
                _buildWeekdayIndicators(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineInfo() {
    return Positioned(
      top: 6,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 12),
        child: Text(
          routine.routineName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 26, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildWeekdayIndicators() {
    return Positioned(
      top: 8,
      right: 12,
      child: Row(
        children: List.generate(7, (index) => _weekdayIndicator(index + 1)),
      ),
    );
  }

  Widget _weekdayIndicator(int weekday) {
    final bool isSelected = routine.weekdays.contains(weekday);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        height: 16,
        width: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isSelected ? Colors.deepOrange : Colors.transparent,
        ),
        child: Center(
          child: Text(
            ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1],
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _navigateToDetailPage(BuildContext context) {
    routinesBloc.setCurrentRoutine(routine);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineDetailPage(isRecRoutine: isRecRoutine, routine: routine),
      ),
    );
  }
}