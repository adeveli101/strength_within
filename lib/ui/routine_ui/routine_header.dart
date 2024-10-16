import 'package:flutter/material.dart';
import '../../models/routines.dart';
import '../../utils/routine_helpers.dart';
import '../../resource/routines_bloc.dart';

class RoutineHeaderDelegate extends SliverPersistentHeaderDelegate {
  RoutineHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.routinesBloc,
  });

  final double minHeight;
  final double maxHeight;
  final RoutinesBloc routinesBloc;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = shrinkOffset / maxExtent;
    final fontSize = _lerp(28, 22, progress);

    return StreamBuilder<Routine?>(
      stream: routinesBloc.currentRoutine,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: Color(0xFF121212));
        }

        final routine = snapshot.data!;

        return Container(
          color: Color(0xFF121212),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 1 - progress,
                child: Hero(
                  tag: 'routine_image_${routine.id}',
                  child: Image.asset(
                    'assets/images/${mainTargetedBodyPartToStringConverter(routine.mainTargetedBodyPart).toLowerCase()}.jpg',
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.5),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: _lerp(16, 8, progress),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      routine.name,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Opacity(
                      opacity: 1 - progress,
                      child: Text(
                        '${routine.partIds.length} exercises',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                top: _lerp(16, 8, progress),
                child: Opacity(
                  opacity: 1 - progress,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFE91E63),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      mainTargetedBodyPartToStringConverter(routine.mainTargetedBodyPart),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _lerp(double min, double max, double t) {
    return (1 - t) * min + t * max;
  }

  @override
  bool shouldRebuild(RoutineHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        routinesBloc != oldDelegate.routinesBloc;
  }
}
