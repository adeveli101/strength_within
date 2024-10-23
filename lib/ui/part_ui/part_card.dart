import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data_bloc_part/part_bloc.dart';
import '../../models/PartFocusRoutine.dart';

class PartCard extends StatefulWidget {
  final Parts part;
  final String userId;
  final VoidCallback? onTap;

  const PartCard({
    Key? key,
    required this.part,
    required this.userId,
    this.onTap,
  }) : super(key: key);

  @override
  _PartCardState createState() => _PartCardState();
}

class _PartCardState extends State<PartCard> with SingleTickerProviderStateMixin {
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
    return BlocListener<PartsBloc, PartsState>(
      listener: (context, state) {
        if (state is PartsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive genişlik hesaplama
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
                      if (widget.part.id > 0) {
                        context.read<PartsBloc>().add(
                          FetchPartExercises(partId: widget.part.id),
                        );
                        widget.onTap?.call();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Geçersiz part ID. Lütfen tekrar deneyin.'),
                          ),
                        );
                      }
                    },
                    onHover: (isHovering) {
                      isHovering ? _controller.forward() : _controller.reverse();
                    },
                    child: Container(
                      width: cardWidth,
                      height: cardWidth * 1.5, // Aspect ratio koruma
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.part.setTypeColor.withOpacity(0.7),
                            widget.part.setTypeColor.withOpacity(0.3),
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
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.part.name,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Vücut Bölgesi',
              _getBodyPartName(widget.part.bodyPartId),
              Icons.fitness_center,
            ),
            const SizedBox(height: 5),
            _buildInfoRow(
              'Set Tipi',
              widget.part.setTypeString,
              Icons.repeat,
            ),
            const SizedBox(height: 5),
            _buildDifficultyIndicator(),
            if (widget.part.additionalNotes.isNotEmpty) ...[
              const SizedBox(height: 5),
              Expanded(
                child: Text(
                  widget.part.additionalNotes,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 3,
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
        const Icon(Icons.speed, color: Colors.white, size: 16),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zorluk: ${_getDifficultyText(widget.part.difficulty)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 7),
              LinearProgressIndicator(
                value: widget.part.difficulty / 3.8,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getDifficultyColor(widget.part.difficulty),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return BlocBuilder<PartsBloc, PartsState>(
      buildWhen: (previous, current) => true,
      builder: (context, state) {
        return IconButton(
          icon: Icon(
            widget.part.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: widget.part.isFavorite ? Colors.red : Colors.white,
            size: 20,
          ),
          onPressed: () {
            if (widget.part.id > 0) {
              context.read<PartsBloc>().add(
                TogglePartFavorite(
                  userId: widget.userId,
                  partId: widget.part.id.toString(),
                  isFavorite: !widget.part.isFavorite,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return BlocBuilder<PartsBloc, PartsState>(
      buildWhen: (previous, current) {
        if (current is PartsLoaded) {
          return current.parts.any((p) => p.id == widget.part.id);
        }
        return false;
      },
      builder: (context, state) {
        final progress = widget.part.userProgress ?? 0;

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
                Icon(
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
      case 1: return 'Göğüs';
      case 2: return 'Sırt';
      case 3: return 'Bacak';
      case 4: return 'Omuz';
      case 5: return 'Kol';
      case 6: return 'Karın';
      default: return 'Bilinmeyen';
    }
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1: return 'Başlangıç';
      case 2: return 'Orta';
      case 3: return 'İleri';
      default: return 'Belirsiz';
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }
}
