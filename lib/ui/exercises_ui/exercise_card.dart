// ignore_for_file: use_super_parameters

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/sql_models/exercises.dart';
import '../../sw_app_theme/app_theme.dart';
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
    return _buildCardContainer(
      child: _buildCardContent(),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: AppTheme.paddingSmall / 2,
        horizontal: AppTheme.paddingSmall,
      ),
      child: Card(
        elevation: AppTheme.elevations['card'],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: child,
      ),
    );
  }

  Widget _buildCardContent() {
    return InkWell(
      onTap: () => _navigateToDetails(),
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Container(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          gradient: AppTheme.createGradient(
            colors: [
              isCompleted
                  ? AppTheme.successGreen.withOpacity(AppTheme.primaryOpacity)
                  : AppTheme.primaryRed.withOpacity(AppTheme.primaryOpacity),
              isCompleted
                  ? AppTheme.successGreen.withOpacity(AppTheme.cardOpacity)
                  : AppTheme.secondaryRed.withOpacity(AppTheme.cardOpacity),
            ],
          ),
        ),
        child: _buildExerciseInfo(),
      ),
    );
  }

  void _navigateToDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetails(
          exerciseId: widget.exercise.id,
          userId: widget.userId,
        ),
      ),
    );
  }

  Widget _buildExerciseInfo() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.exercise.name,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppTheme.paddingSmall / 2),
              _buildExerciseMetrics(),
            ],
          ),
        ),
        _buildCompletionCheckbox(),
      ],
    );
  }

  Widget _buildExerciseMetrics() {
    return Row(
      children: [
        if (widget.exercise.defaultSets > 0) ...[
          _buildCompactInfo(Icons.repeat, '${widget.exercise.defaultSets} set'),
          SizedBox(width: AppTheme.paddingSmall),
        ],
        if (widget.exercise.defaultReps > 0) ...[
          _buildCompactInfo(Icons.fitness_center, '${widget.exercise.defaultReps} tekrar'),
          SizedBox(width: AppTheme.paddingSmall),
        ],
        if (widget.exercise.defaultWeight > 0)
          _buildCompactInfo(Icons.monitor_weight_outlined, '${widget.exercise.defaultWeight} kg'),
      ],
    );
  }

  Widget _buildCompletionCheckbox() {
    return Checkbox(
      value: isCompleted,
      onChanged: (bool? value) {
        if (value != null) {
          setState(() {
            isCompleted = value;
          });
          _updateCompletionStatus(value);
        }
      },
      checkColor: AppTheme.textPrimary,
      fillColor: WidgetStateProperty.resolveWith(
            (states) => Colors.transparent,
      ),
    );
  }

  Widget _buildCompactInfo(IconData icon, String text) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingSmall,
        vertical: AppTheme.paddingSmall / 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white.withOpacity(AppTheme.secondaryOpacity),
          ),
          SizedBox(width: AppTheme.paddingSmall / 2),
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}


