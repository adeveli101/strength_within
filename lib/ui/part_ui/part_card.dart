import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data_bloc_part/part_bloc.dart';
import '../../models/PartFocusRoutine.dart';

class PartCard extends StatefulWidget {
  final Parts part;
  final String userId;
  final VoidCallback? onTap;
  final bool isSmall;

  const PartCard({
    Key? key,
    required this.part,
    required this.userId,
    this.onTap,
    this.isSmall = false,
  }) : super(key: key);

  @override
  _PartCardState createState() => _PartCardState();
}

class _PartCardState extends State<PartCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
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
          final screenWidth = MediaQuery.of(context).size.width;
          double cardWidth;
          double cardHeight;
          double fontSize;

          if (screenWidth > 1200) {
            cardWidth = widget.isSmall ? 70.0 : constraints.maxWidth * 0.3;
            cardHeight = widget.isSmall ? 70.0 : 280.0;
            fontSize = 20.0;
          } else if (screenWidth > 800) {
            cardWidth = widget.isSmall ? 60.0 : constraints.maxWidth * 0.45;
            cardHeight = widget.isSmall ? 60.0 : 260.0;
            fontSize = 18.0;
          } else {
            cardWidth = widget.isSmall ? 56.0 : constraints.maxWidth * 0.9;
            cardHeight = widget.isSmall ? 56.0 : 240.0;
            fontSize = 16.0;
          }

          if (_isExpanded && !widget.isSmall) {
            cardHeight *= 1.2;
          }

          return _buildCard(cardWidth, cardHeight, fontSize);
        },
      ),
    );
  }

  Widget _buildCard(double width, double height, double fontSize) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GestureDetector(
          onVerticalDragUpdate: widget.isSmall ? null : (details) {
            if (details.primaryDelta! < -20 && !_isExpanded) {
              setState(() => _isExpanded = true);
            } else if (details.primaryDelta! > 20 && _isExpanded) {
              setState(() => _isExpanded = false);
            }
          },
          child: Transform.scale(
            scale: widget.isSmall ? 1 : (1 + (_animation.value * 0.05)),
            child: Card(
              elevation: widget.isSmall ? 2 : (4 + (_animation.value * 4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.isSmall ? 8 : 15),
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
                onHover: widget.isSmall ? null : (isHovering) {
                  isHovering ? _controller.forward() : _controller.reverse();
                },
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.isSmall ? 8 : 15),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.part.setTypeColor.withOpacity(0.7),
                        widget.part.setTypeColor.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: widget.isSmall
                      ? _buildSmallBody()
                      : _buildResponsiveBody(fontSize),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallBody() {
    return Center(
      child: Text(
        widget.part.name.substring(0, 1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildResponsiveBody(double fontSize) {
    return Column(
      children: [
        _buildHeader(fontSize),
        Expanded(child: _buildBody(fontSize)),
        if (_isExpanded) _buildExpandedContent(fontSize),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader(double fontSize) {
    return Container(
      padding: EdgeInsets.all(12),
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
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
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

  Widget _buildBody(double fontSize) {
    return Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Vücut Bölgesi',
            _getBodyPartName(widget.part.bodyPartId),
            Icons.fitness_center,
            fontSize: fontSize,
          ),
          SizedBox(height: 1),
          _buildInfoRow(
            'Set Tipi',
            widget.part.setTypeString,
            Icons.repeat,
            fontSize: fontSize,
          ),
          SizedBox(height: 1),
          _buildDifficultyIndicator(fontSize),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(double fontSize) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ek Bilgiler',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (widget.part.additionalNotes.isNotEmpty)
            Text(
              widget.part.additionalNotes,
              style: TextStyle(
                color: Colors.white70,
                fontSize: fontSize - 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: _buildProgressIndicator(),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {required double fontSize}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: fontSize),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(color: Colors.white, fontSize: fontSize - 2),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyIndicator(double fontSize) {
    return Row(
      children: [
        Icon(Icons.fitness_center, color: Colors.white, size: fontSize),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zorluk: ${_getDifficultyText(widget.part.difficulty)}',
                style: TextStyle(color: Colors.white, fontSize: fontSize - 2),
              ),
              SizedBox(height: 4),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < widget.part.difficulty ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < widget.part.difficulty
                        ? _getDifficultyColor(widget.part.difficulty)
                        : Colors.white24,
                    size: fontSize - 6,
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
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_open_rounded, color: Colors.white.withOpacity(0.7), size: 16),
              SizedBox(width: 8),
              Text(
                'Başlamak için hazır',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'İlerleme: $progress%',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(Colors.white),
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
