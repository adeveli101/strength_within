// ignore_for_file: unused_element, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/data_bloc_routine/routines_bloc.dart';
import '../../blocs/data_schedule_bloc/schedule_bloc.dart';
import '../../models/sql_models/routines.dart';
import '../../sw_app_theme/app_theme.dart';


enum ExpansionDirection {
  left,
  right,
  down,
  up
}


class RoutineCard extends StatefulWidget {
  final Routines routine;
  final String userId;
  final VoidCallback? onTap;

  const RoutineCard({
    super.key,
    required this.routine,
    required this.userId,
    this.onTap,
  });

  @override
  _RoutineCardState createState() => _RoutineCardState();
}

class _RoutineCardState extends State<RoutineCard> with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late Animation<double> _blurAnimation;
  bool _isExpanded = false;



  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  void _handleAnimationStatus(AnimationStatus status) {
    setState(() => _isExpanded = status == AnimationStatus.completed);
  }

  void _initializeAnimations() {
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 3.0,
    ).animate(_expandAnimation);

    _expandController.addStatusListener((status) {
      setState(() {
        _isExpanded = status == AnimationStatus.completed;
      });
    });
  }


  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<RoutinesBloc, RoutinesState>(
      listener: (context, state) {
        if (state is RoutinesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          onTap: () {
            if (widget.routine.id > 0) {
              HapticFeedback.lightImpact();
              context.read<RoutinesBloc>().add(
                  FetchRoutineExercises(routineId: widget.routine.id)
              );
              widget.onTap?.call();
            }
          },
          child: Container(
            height: 400,
            width: 400,
            margin: EdgeInsets.all(AppTheme.paddingSmall),
            decoration: AppTheme.decoration(
              gradient: AppTheme.getPartGradient(
                difficulty: widget.routine.difficulty,
                secondaryColor: AppTheme.getTargetColor(widget.routine.goalId),
              ),
              borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusMedium),
              shadows: [
                BoxShadow(
                  color: AppTheme.getDifficultyColor(widget.routine.difficulty)
                      .withOpacity(AppTheme.shadowOpacity),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.cardBackground.withOpacity(AppTheme.primaryOpacity),
                        AppTheme.surfaceColor.withOpacity(AppTheme.secondaryOpacity),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildBody(),
                      _buildFooter(),
                    ],
                  ),
                ),
                Positioned(
                  top: AppTheme.paddingSmall,
                  right: AppTheme.paddingSmall,
                  child: BlocBuilder<ScheduleBloc, ScheduleState>(
                    builder: (context, state) {
                      if (state is SchedulesLoaded) {
                        final schedules = state.schedules
                            .where((schedule) =>
                        schedule.itemId == widget.routine.id &&
                            schedule.type == 'routine'
                        ).toList();
                        if (schedules.isEmpty) return const SizedBox.shrink();

                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.paddingSmall,
                              vertical: AppTheme.paddingSmall / 2
                          ),
                          decoration: AppTheme.decoration(
                            color: AppTheme.surfaceColor.withOpacity(AppTheme.cardOpacity),
                            borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
                            shadows: [
                              BoxShadow(
                                color: AppTheme.shadowColor,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: AppTheme.difficultyStarBaseSize,
                                color: AppTheme.textPrimary,
                              ),
                              SizedBox(width: AppTheme.paddingSmall / 2),
                              Text(
                                _formatScheduleDays(schedules.first.selectedDays),
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }





  String _formatScheduleDays(List<int> days) {
    if (days.isEmpty) return '';

    final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    if (days.length > 2) {
      return '${days.length} gün';
    }
    return days.map((day) => dayNames[day - 1]).join(', ');
  }



  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingSmall),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceColor.withOpacity(AppTheme.primaryOpacity),
            AppTheme.cardBackground.withOpacity(AppTheme.secondaryOpacity),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.routine.name,
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildFavoriteButton(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center,
                  color: AppTheme.textSecondary,
                  size: AppTheme.difficultyStarBaseSize
              ),
              SizedBox(width: AppTheme.paddingSmall),
              Expanded(
                child: Text(
                  _getWorkoutTypeByName(widget.routine.workoutTypeId),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.paddingMedium),
          Row(
            children: [
              Icon(Icons.speed,
                  color: AppTheme.textSecondary,
                  size: AppTheme.difficultyStarBaseSize
              ),
              SizedBox(width: AppTheme.paddingSmall),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppTheme.buildDifficultyStars(widget.routine.difficulty),
                  ),
                ),
              ),
            ],
          ),
          if (widget.routine.description.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: AppTheme.paddingSmall),
              child: Text(
                widget.routine.description,
                style: AppTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_outline,
              color: AppTheme.primaryRed,
              size: AppTheme.difficultyStarBaseSize,
            ),
            SizedBox(width: AppTheme.paddingSmall),
            Text(
              'Başlamak için hazır',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }





  Widget _buildFavoriteButton() {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        bool isLoading = state is RoutinesLoading;

        return AnimatedContainer(
          duration: AppTheme.quickAnimation,
          decoration: AppTheme.decoration(
            color: widget.routine.isFavorite
                ? AppTheme.primaryRed.withOpacity(AppTheme.cardOpacity)
                : AppTheme.surfaceColor.withOpacity(AppTheme.cardOpacity),
            borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
            shadows: [
              BoxShadow(
                color: widget.routine.isFavorite
                    ? AppTheme.primaryRed.withOpacity(AppTheme.shadowOpacity)
                    : AppTheme.shadowColor,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: AppTheme.quickAnimation,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                widget.routine.isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey<bool>(widget.routine.isFavorite),
                color: widget.routine.isFavorite
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                size: AppTheme.difficultyStarBaseSize,
              ),
            ),
            onPressed: isLoading ? null : () {
              if (widget.routine.id > 0) {
                HapticFeedback.lightImpact();
                context.read<RoutinesBloc>().add(
                  ToggleRoutineFavorite(
                    userId: widget.userId,
                    routineId: widget.routine.id.toString(),
                    isFavorite: !widget.routine.isFavorite,
                  ),
                );
              }
            },
            splashColor: AppTheme.primaryRed.withOpacity(AppTheme.cardOpacity),
            highlightColor: AppTheme.surfaceColor,
          ),
        );
      },
    );
  }






  String _getWorkoutTypeByName(int workouttypeId) {
    switch (workouttypeId) {
      case 1:
        return 'Strength';
      case 2:
        return 'Hypertrophy';
      case 3:
      return  'Endurance';
      case 4:
        return 'Power';
      case 5:
        return 'Flexibility';
      default:
        return 'Bilinmeyen';
    }
  }
}
