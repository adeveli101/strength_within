import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data_bloc_part/part_bloc.dart';
import '../../data_schedule_bloc/schedule_bloc.dart';
import '../../models/PartTargetedBodyParts.dart';
import '../../models/Parts.dart';
import '../../utils/routine_helpers.dart';
import '../../z.app_theme/app_theme.dart';

class PartCard extends StatefulWidget {
  final Parts part;
  final String userId;
  final VoidCallback? onTap;
  final Function(bool)? onFavoriteChanged;

  const PartCard({
    super.key,
    required this.part,
    required this.userId,
    this.onTap,
    this.onFavoriteChanged,
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
        child: Stack(
          children: [
            // Mevcut içerik
            Padding(
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

            // Schedule göstergesi
            Positioned(
              top: AppTheme.paddingSmall,
              right: AppTheme.paddingSmall,
              child: _buildScheduleIndicator(
                widget.userId,
                widget.part.id.toString(),
                'part',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleIndicator(String userId, String itemId, String type) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        if (state is SchedulesLoaded) {
          final schedules = state.schedules.where(
                  (schedule) =>
              schedule.itemId.toString() == itemId &&
                  schedule.type == type
          ).toList();

          if (schedules.isEmpty) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingSmall,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
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
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // Gün formatlaması için yardımcı metod
  String _formatScheduleDays(List<int> days) {
    if (days.isEmpty) return '';

    final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    if (days.length > 2) {
      return '${days.length} gün';
    }
    return days.map((day) => dayNames[day - 1]).join(', ');
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
        // Set Tipi bilgisi
        _buildInfoRow(
          Icons.repeat,
          'Set Tipi: ${setTypeToStringConverter(widget.part.setType)}',
        ),
        const SizedBox(height: 8),

        // Zorluk seviyesi bilgisi
        _buildDifficultyRow(),

        // Hedef kas gruplarını gösteren bilgi
        _buildTargetedBodyPartsRow(widget.part.id)
      ],
    );
  }

// Bilgi satırını oluşturan yardımcı metod
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

  Widget _buildTargetedBodyPartsRow(int partId) {
    return FutureBuilder<List<PartTargetedBodyParts>>(
      future: BlocProvider.of<PartsBloc>(context).repository.getPartTargetedBodyParts(partId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Hedef kas grubu bulunamadı.'));
        }

        final targetedParts = snapshot.data!;

        // firstWhere yerine try-catch ile güvenli kontrol
        try {
          final primaryTarget = targetedParts.firstWhere(
                (target) => target.isPrimary == true,
            orElse: () => targetedParts.first, // Eğer primary yoksa ilk elemanı al
          );

          return FutureBuilder<List<String>>(
            future: _getBodyPartName([primaryTarget.bodyPartId]),
            builder: (context, nameSnapshot) {
              if (nameSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (nameSnapshot.hasError) {
                return Center(child: Text('Hata: ${nameSnapshot.error}'));
              } else if (!nameSnapshot.hasData || nameSnapshot.data!.isEmpty) {
                return const Center(child: Text('Hedef kas ismi bulunamadı.'));
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.man_rounded),
                    const SizedBox(width: 8), // İkon ile metin arası boşluk
                    Expanded(
                      child: Text(
                        '${nameSnapshot.data!.first} (${primaryTarget.targetPercentage}%)',
                        style: const TextStyle(
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        } catch (e) {
          return const Center(child: Text('Hedef kas grubu işlenirken hata oluştu.'));
        }
      },
    );
  }

  Future<List<String>> _getBodyPartName(List<int> bodyPartIds) async {
    // BLoC'dan repository'yi kullanarak body part isimlerini al
    final bodyPartNames = await BlocProvider.of<PartsBloc>(context).repository.getBodyPartNamesByIds(bodyPartIds);
    if (bodyPartNames.isEmpty) {
      return List.filled(bodyPartIds.length, 'Bilinmiyor');
    }

    return bodyPartNames;
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
      padding: const EdgeInsets.symmetric(vertical: 5),
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
          const SizedBox(width: 4),
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
          widget.onFavoriteChanged?.call(!part.isFavorite);
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





  // ignore: unused_element
  Color _getProgressColor(int progress) {
    if (progress >= 80) return const Color(0xFF4CAF50);
    if (progress >= 60) return const Color(0xFF8BC34A);
    if (progress >= 40) return const Color(0xFFFFC107);
    if (progress >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFFF5722);
  }



}
