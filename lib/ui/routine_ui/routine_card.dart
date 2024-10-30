// ignore_for_file: unused_element

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
  late Animation<double> _animation;

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
          final cardWidth = constraints.maxWidth > 600 ? 300.0 : 200.0;

          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + (_animation.value * 0.05),
                child: Card(
                  elevation: 4 + (_animation.value * 4),
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
                      width: cardWidth,
                      height: cardWidth * 1.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withOpacity(0.7),
                            Colors.blue.withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildHeader(),
                          _buildBody(),
                          _buildFooter(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(6),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildFavoriteButton(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Bu satırı ekleyin
          children: [

            const SizedBox(height: 5),
            _buildInfoRow(
              'Egzersiz Türü',
              widget.routine.workoutTypeId.toString(),
              Icons.category,
            ),
            const SizedBox(height: 5),
            _buildDifficultyIndicator(),
            if (widget.routine.description.isNotEmpty) ...[
              const SizedBox(height: 5),
              Flexible( // Expanded yerine Flexible kullanın
                child: Text(
                  widget.routine.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2, // Maksimum satır sayısını sınırlayın
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: _buildProgressIndicator(),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyIndicator() {
    return Row(
      children: [
        const Icon(Icons.fitness_center, color: Colors.white, size: 16),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zorluk: ${_getDifficultyText(widget.routine.difficulty)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < widget.routine.difficulty
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: index < widget.routine.difficulty
                        ? _getDifficultyColor(widget.routine.difficulty)
                        : Colors.white24,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }





  Widget _buildFavoriteButton() {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        return IconButton(
          icon: Icon(
            widget.routine.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: widget.routine.isFavorite ? Colors.red : Colors.white,
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
      },
    );
  }

  Widget _buildProgressIndicator() {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        final progress = widget.routine.userProgress ?? 0;

        if (progress <= 0) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_open_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Başlamak için hazır',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
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
                const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'İlerleme: $progress%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        );
      },
    );
  }

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
