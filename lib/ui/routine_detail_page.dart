import 'package:flutter/material.dart';
import 'package:workout/models/routine.dart';
import 'package:workout/ui/components/part_card.dart';
import '../models/part.dart';
import 'components/part_description_card.dart';

class RoutineDetailPage extends StatelessWidget {
  final bool isRecRoutine;
  final Routine routine;

  const RoutineDetailPage({
    super.key,
    required this.routine,
    this.isRecRoutine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(routine.mainTargetedBodyPart.toString()),
        actions: _buildAppBarActions(context),
      ),
      body: ListView(
        children: [
          RoutineDescriptionCard(routine: routine),
          ..._buildPartCards(context),
        ],
      ),
    );
  }


  List<Widget> _buildAppBarActions(BuildContext context) {
    final List<Widget> actions = [];
    if (!isRecRoutine) {
      actions.addAll([
        IconButton(
          icon: const Icon(Icons.calendar_view_day),
          onPressed: () => _showWeekdayModal(context),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _navigateToEditPage(context),
        ),
        IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () => _navigateToStepPage(context),
        ),
      ]);
    } else {
      actions.add(
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _onAddRecPressed(context),
        ),
      );
    }
    return actions;
  }

  List<Widget> _buildPartCards(BuildContext context) {
    return routine.parts.map((part) => PartCard(
      part: part,
      onPartTap: isRecRoutine ? null : () => _navigateToPartHistoryPage(context, part),
      onDelete: () {},
    )).toList();
  }

  void _showWeekdayModal(BuildContext context) {
    // Implement weekday modal logic
  }

  void _navigateToEditPage(BuildContext context) {
    // Implement navigation to edit page
  }

  void _navigateToStepPage(BuildContext context) {
    // Implement navigation to step page
  }

  void _onAddRecPressed(BuildContext context) {
    // Implement add rec logic
  }

  void _navigateToPartHistoryPage(BuildContext context, Part part) {
    // Implement navigation to part history page
  }
}