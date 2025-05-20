import 'package:flutter/material.dart';
import '../../models/sql_models/routines.dart';
import '../../sw_app_theme/app_theme.dart';

class MiniRoutineCard extends StatelessWidget {
  final Routines routine;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  const MiniRoutineCard({super.key, required this.routine, this.onTap, this.onFavorite});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.fitness_center, color: AppTheme.primaryRed, size: 22),
                IconButton(
                  icon: Icon(
                    routine.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: AppTheme.primaryRed,
                    size: 20,
                  ),
                  onPressed: onFavorite,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              routine.name,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
              maxLines: 1,
            ),
            SizedBox(height: 4),
            Text(
              routine.description,
              style: AppTheme.bodySmall.copyWith(color: Colors.white70, overflow: TextOverflow.ellipsis),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
} 