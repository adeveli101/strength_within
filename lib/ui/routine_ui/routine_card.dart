// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data_bloc_routine/routines_bloc.dart';
import '../../data_schedule_bloc/schedule_bloc.dart';
import '../../models/routines.dart';

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
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        child: InkWell(
          onTap: () {
            if (widget.routine.id > 0) {
              context.read<RoutinesBloc>().add(
                FetchRoutineExercises(routineId: widget.routine.id),
              );
              widget.onTap?.call();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Stack(  // Column yerine Stack kullanıyoruz
            children: [
              // Ana içerik
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getRoutineColor(),
                      _getRoutineColor().withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildBody(),
                    _buildFooter(),
                  ],
                ),
              ),

              // Schedule göstergesi
              Positioned(
                top: 8,
                right: 8,
                child: BlocBuilder<ScheduleBloc, ScheduleState>(
                  builder: (context, state) {
                    if (state is SchedulesLoaded) {
                      final schedules = state.schedules.where(
                              (schedule) =>
                          schedule.itemId == widget.routine.id &&
                              schedule.type == 'routine'
                      ).toList();

                      if (schedules.isEmpty) return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatScheduleDays(schedules.first.selectedDays),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
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


  Color _getRoutineColor() {
    // Egzersiz türüne göre renk belirleme
    switch (widget.routine.workoutTypeId) {
      case 1:
        return const Color(0xFF1E88E5); // Mavi
      case 2:
        return const Color(0xFF43A047); // Yeşil
      default:
        return const Color(0xFF1E88E5); // Varsayılan mavi
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.routine.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center,
                  color: Colors.white.withOpacity(0.7),
                  size: 16
              ),
              const SizedBox(width: 8),
              Text(
                'Tür: ${_getWorkoutTypeByName(widget.routine.workoutTypeId)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.speed,
                  color: Colors.white.withOpacity(0.7),
                  size: 16
              ),
              const SizedBox(width: 8),
              Text(
                'Zorluk: ',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              ...List.generate(5, (index) {
                return Icon(
                  index < widget.routine.difficulty ? Icons.star : Icons.star_border,
                  color: Colors.white,
                  size: 16,
                );
              }),
            ],
          ),
          if (widget.routine.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.routine.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            color: Colors.white.withOpacity(0.9),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Başlamak için hazır',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return IconButton(
      icon: Icon(
        widget.routine.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: Colors.white,
        size: 20,
      ),
      onPressed: () {
        if (widget.routine.id > 0) {
          context.read<RoutinesBloc>().add(
            ToggleRoutineFavorite(
              userId: widget.userId,
              routineId: widget.routine.id.toString(),
              isFavorite: !widget.routine.isFavorite,
            ),
          );
        }
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
        return 'Bacak';
      case 4:
      return 'Endurance';
      case 5:
        return 'Power';
      case 6:
        return 'Flexibility';
      default:
        return 'Bilinmeyen';
    }
  }
}
