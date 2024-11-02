import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data_bloc_part/part_bloc.dart';
import '../../models/PartFocusRoutine.dart';
import '../../z.app_theme/app_theme.dart';

class PartCard extends StatefulWidget {
  final Parts part;
  final String userId;
  final VoidCallback? onTap;

  const PartCard({
    super.key,
    required this.part,
    required this.userId,
    this.onTap,
  });

  @override
  State<PartCard> createState() => _PartCardState();
}

class _PartCardState extends State<PartCard> {

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.part.setTypeColor.withOpacity(0.8),
              widget.part.setTypeColor.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: widget.part.setTypeColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Spacer(),
              _buildInfo(),
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.part.name,
            style: AppTheme.headingSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildFavoriteButton(widget.part),
      ],
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          Icons.fitness_center,
          'Vücut Bölgesi: ${_getBodyPartName(widget.part.bodyPartId)}',
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          Icons.repeat,
          'Set Tipi: ${widget.part.setType}',
        ),
        const SizedBox(height: 8),
        _buildDifficultyRow(),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyRow() {
    return Row(
      children: [
        Icon(
          Icons.trending_up,
          color: Colors.white.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          'Zorluk: ',
          style: AppTheme.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        ...List.generate(
          5,
              (index) => Icon(
            Icons.star,
            size: 16,
            color: index < widget.part.difficulty
                ? Colors.white
                : Colors.white.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: AppTheme.paddingSmall),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Başlamak için hazır',
            style: AppTheme.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFavoriteButton(Parts part) {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingSmall),
      decoration: BoxDecoration(
        color: part.isFavorite ? AppTheme.primaryRed.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: InkWell(
        onTap: () {
          context.read<PartsBloc>().add(
            TogglePartFavorite(
              userId: widget.userId,
              partId: part.id.toString(),
              isFavorite: !part.isFavorite,
            ),
          );
          HapticFeedback.lightImpact();
        },
        customBorder: const CircleBorder(),
        child: AnimatedSwitcher(
          duration: AppTheme.quickAnimation,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: Icon(
            part.isFavorite ? Icons.favorite : Icons.favorite_border,
            key: ValueKey<bool>(part.isFavorite),
            color: part.isFavorite ? AppTheme.primaryRed : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }





  Color _getProgressColor(int progress) {
    if (progress >= 80) return const Color(0xFF4CAF50);
    if (progress >= 60) return const Color(0xFF8BC34A);
    if (progress >= 40) return const Color(0xFFFFC107);
    if (progress >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFFF5722);
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


}
