import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data_bloc_routine/routines_bloc.dart';
import '../../models/routines.dart';



class RoutineCard extends StatefulWidget {
  final Routines routine;
  final String userId;
  final VoidCallback? onTap;

  const RoutineCard({
    Key? key,
    required this.routine,
    required this.userId,
    this.onTap,
  }) : super(key: key);

  @override
  _RoutineCardState createState() => _RoutineCardState();
}

class _RoutineCardState extends State<RoutineCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Ekran genişliğine göre kart boyutunu ayarla
          final cardWidth = constraints.maxWidth * 0.9;
          final cardHeight = cardWidth * 1.5;
          final fontSize = cardWidth * 0.05;

          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: (1 + (_animation.value * 0.05)).toDouble(),

                child: Card(
                  elevation: (4 + (_animation.value * 4)).toDouble(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (widget.routine.id > 0) {
                        context.read<RoutinesBloc>().add(
                          FetchRoutineExercises(routineId: widget.routine.id),
                        );
                        widget.onTap?.call();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Geçersiz rutin ID. Lütfen tekrar deneyin.'),
                          ),
                        );
                      }
                    },
                    onHover: (isHovering) {
                      isHovering ? _controller.forward() : _controller.reverse();
                    },
                    child: Container(
                      width: cardWidth.toDouble(),
                      height: cardHeight.toDouble(),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getDifficultyColor(widget.routine.difficulty),
                            _getDifficultyColor(widget.routine.difficulty).withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildHeader(fontSize.toDouble()),
                          _buildBody(fontSize.toDouble()),
                          _buildFooter(fontSize.toDouble()),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }



  Widget _buildHeader(double fontSize) {
    return Container(
      padding: EdgeInsets.all(fontSize * 0.5),
      decoration: const BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.routine.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildFavoriteButton(fontSize),
        ],
      ),
    );
  }

  Widget _buildBody(double fontSize) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(fontSize),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: fontSize * 0.5),
            _buildInfoRow(
              'Egzersiz Türü',
              _getWorkoutTypeName(widget.routine.workoutTypeId),
              Icons.category_outlined,
              fontSize,
            ),
            SizedBox(height: fontSize * 0.5),
            _buildDifficultyIndicator(fontSize),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(double fontSize) {
    return Container(
      padding: EdgeInsets.all(fontSize),
      decoration: const BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: _buildProgressIndicator(fontSize),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, double fontSize) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: fontSize),
        SizedBox(width: fontSize),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize * 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyIndicator(double fontSize) {
    return Row(
      children: [
        Icon(Icons.fitness_center, color: Colors.white, size: fontSize),
        SizedBox(width: fontSize),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zorluk: ${_getDifficultyText(widget.routine.difficulty)}',
                style: TextStyle(color: Colors.white, fontSize: fontSize * 0.8),
              ),
              SizedBox(height: fontSize * 0.2),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < widget.routine.difficulty
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: index < widget.routine.difficulty
                        ? Colors.red.shade500
                        : Colors.white24,
                    size: fontSize,
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton(double fontSize) {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        return IconButton(
          icon: Icon(
            widget.routine.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: widget.routine.isFavorite ? Colors.red : Colors.white,
            size: fontSize,
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
      },
    );
  }

  Widget _buildProgressIndicator(double fontSize) {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        final progress = widget.routine.userProgress ?? 0;
        if (progress <= 0) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: fontSize * 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_open_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: fontSize,
                ),
                SizedBox(width: fontSize * 0.5),
                Text(
                  'Başlamak için hazır',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: fontSize * 0.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: fontSize,
                ),
                SizedBox(width: fontSize * 0.5),
                Text(
                  'İlerleme: $progress%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize * 0.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: fontSize * 0.2),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ],
        );
      },
    );
  }




  // ignore: unused_element
  String _getBodyPartName(int bodyPartId) {
    switch (bodyPartId) {
      case 1:
        return 'Göğüs';
      case 2:
        return 'Sırt';
      case 3:
        return 'Bacak';
      case 4:
        return 'Omuz';
      case 5:
        return 'Kol';
      case 6:
        return 'Karın';
      default:
        return 'Bilinmeyen';
    }
  }

  String _getWorkoutTypeName(int workoutTypeId) {
    switch (workoutTypeId) {
      case 1:
        return 'Strength';
      case 2:
        return 'Hypertrophy';
      case 3:
        return 'Endurance';
      case 4:
        return 'Power';
      case 5:
        return 'Flexibility';
      default:
        return 'Bilinmeyen';
    }
  }



  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Başlangıç';
      case 2:
        return 'Orta Başlangıç';
      case 3:
        return 'Orta';
      case 4:
        return 'Orta İleri';
      case 5:
        return 'İleri';
      default:
        return 'Belirsiz';
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
