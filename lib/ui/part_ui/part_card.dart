import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:weather_icons/weather_icons.dart';
import '../../data_bloc_part/PartRepository.dart';
import '../../data_bloc_part/part_bloc.dart';
import '../../data_schedule_bloc/schedule_bloc.dart';
import '../../models/BodyPart.dart';
import '../../models/PartTargetedBodyParts.dart';
import '../../models/Parts.dart';
import '../../utils/routine_helpers.dart';
import '../../z.app_theme/app_theme.dart';

enum ExpansionDirection {
  left,
  right,
  both
}



class PartCard extends StatefulWidget {
  final Parts part;
  final String userId;
  final Function() onTap;
  final Function(bool) onFavoriteChanged;
  final PartRepository repository;  // Add this line

  const PartCard({
    super.key,
    required this.part,
    required this.userId,
    required this.onTap,
    required this.onFavoriteChanged,
    required this.repository,  // Add this line
  });


  static Widget buildPartCardList({
    required List<Parts> parts,
    required String userId,
    required PartRepository repository,
    required Function(int) onTap,
    required Function(bool, String) onFavoriteChanged,
    ScrollController? scrollController,
    bool isGridView = false,
  }) {
    if (isGridView) {
      return GridView.builder(
        controller: scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.95,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: parts.length,
        itemBuilder: (context, index) {
          return PartCard(
            key: ValueKey(parts[index].id),
            part: parts[index],
            userId: userId,
            repository: repository,
            onTap: () => onTap(parts[index].id),
            onFavoriteChanged: (isFavorite) =>
                onFavoriteChanged(isFavorite, parts[index].id.toString()),
          );
        },
      );
    }


    return ListView.builder(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: parts.length,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: PartCard(
            key: ValueKey(parts[index].id),
            part: parts[index],
            userId: userId,
            repository: repository,
            onTap: () => onTap(parts[index].id),
            onFavoriteChanged: (isFavorite) =>
                onFavoriteChanged(isFavorite, parts[index].id.toString()),
          ),
        );
      },
    );
  }

  @override
  State<PartCard> createState() => _PartCardState();
}

class _PartCardState extends State<PartCard> with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late Animation<double> _blurAnimation;
  bool _isExpanded = false;
  List<PartTargetedBodyParts> _primaryTargets = [];
  List<PartTargetedBodyParts> _secondaryTargets = [];
  OverlayEntry? _overlayEntry;
  Offset? _cardOffset;
  Size? _cardSize;


  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTargetedParts();
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

    _expandController.addStatusListener(_handleAnimationStatus);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() => _isExpanded = true);
    } else if (status == AnimationStatus.dismissed) {
      setState(() => _isExpanded = false);
    }
  }

  Future<void> _loadTargetedParts() async {
    final repository = context.read<PartRepository>();
    final targets = await repository.getPartTargetedBodyParts(widget.part.id);

    setState(() {
      _primaryTargets = targets.where((t) => t.targetPercentage > 30).toList();
      _secondaryTargets = targets.where(
              (t) => t.targetPercentage >= 15 && t.targetPercentage <= 30
      ).toList();
    });
  }

  LinearGradient _buildGradient() {
    final difficulty = widget.part.difficulty;
    final primaryColor = _getDifficultyColor(difficulty);
    final secondaryColor = _primaryTargets.isNotEmpty
        ? _getTargetColor(_primaryTargets.first.bodyPartId)
        : AppTheme.primaryRed;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor,
        primaryColor.withOpacity(0.8),
        secondaryColor.withOpacity(0.6),
      ],
    );
  }



  Color _getTargetColor(int bodyPartId) {
    // Default color if no target or primary target not found
    return AppTheme.primaryRed;
  }

  Color _getPrimaryColor(int difficulty) {
    switch (difficulty) {
      case 1: return Colors.blue[900]!;
      case 2: return Colors.purple[900]!;
      case 3: return Colors.orange[900]!;
      case 4: return Colors.red[900]!;
      case 5: return const Color(0xFF590000);
      default: return Colors.grey[900]!;
    }
  }

  Widget _buildFavoriteButton() {
    return IconButton(
      icon: Icon(
        widget.part.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: Colors.white,
      ),
      onPressed: () => widget.onFavoriteChanged(!widget.part.isFavorite),
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _expandController.forward();
      },
      onLongPressEnd: (_) {
        _expandController.reverse();
      },
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getDifficultyColor(widget.part.difficulty),
                  _getDifficultyColor(widget.part.difficulty).withOpacity(0.8),
                  widget.part.setTypeColor.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              boxShadow: [
                BoxShadow(
                  color: _getDifficultyColor(widget.part.difficulty).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main Content
                _buildMainContent(),

                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      widget.part.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                    ),
                    onPressed: () => widget.onFavoriteChanged(!widget.part.isFavorite),
                  ),
                ),

                // Expanded Content
                if (_isExpanded) _buildExpandedContent(),
              ],
            ),
          );
        },
      ),
    );
  }



  Widget _buildMainContent() {
    return Container(
      width: 240,  // Sabit kart genişliği
      height: 320, // Sabit kart yüksekliği
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İsim
          Text(
            widget.part.name,
            style: AppTheme.headingMedium.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Zorluk Göstergesi
          Row(
            children: [
              _buildDifficultyIndicator()

            ],
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 8),

          // Hedef Kas Grupları Listesi
          Expanded(
            child: _buildTargetsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Additional Notes Section
          if (widget.part.additionalNotes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.part.additionalNotes,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodySmall.copyWith(color: Colors.white70),
              ),
            ),

          // All Targeted Body Parts
          _buildAllTargetsSection(),

          // Set Type Details
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Set Type: ${widget.part.setType}',
              style: AppTheme.bodySmall.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            5,
                (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.rotate(
                angle: 0.1,
                child: Icon(
                  index < widget.part.difficulty
                      ? Icons.star_sharp   // Keskin köşeli dikdörtgen
                      : Icons.star_sharp,
                  color: index < widget.part.difficulty
                      ? _getGlowingColor(widget.part.difficulty, index)
                      : Colors.white24,
                  size: 18 + (index * 0.5), // Her ikon biraz daha büyük
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1: return Colors.blue[900]!;
      case 2: return Colors.purple[900]!;
      case 3: return Colors.orange[900]!;
      case 4: return Colors.red[900]!;
      case 5: return const Color(0xFF590000);
      default: return Colors.grey[900]!;
    }
  }

  Color _getGlowingColor(int difficulty, int index) {
    late final Color baseColor;
    switch (difficulty) {
      case 1:
        baseColor = const Color(0xFF00FFFF); // Neon Cyan
      case 2:
        baseColor = const Color(0xFFFF00FF); // Neon Mor
      case 3:
        baseColor = const Color(0xFFFF8000); // Parlak Turuncu
      case 4:
        baseColor = const Color(0xFFFF2D2D); // Yoğun Kırmızı
      case 5:
        baseColor = const Color(0x86FF0000); // Saf Kırmızı
      default:
        baseColor = const Color(0xFFCFD8DC); // Parlak Gri
    }
    return baseColor.withOpacity(0.75 + (index * 0.07));
  }

  Widget _buildAllTargetsSection() {
    return FutureBuilder<List<PartTargetedBodyParts>>(
      future: context.read<PartRepository>().getPartTargetedBodyParts(widget.part.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final targets = snapshot.data!;
        final primaryTargets = targets.where((t) => t.targetPercentage > 30).toList();
        final secondaryTargets = targets
            .where((t) => t.targetPercentage >= 15 && t.targetPercentage <= 30)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...primaryTargets.map((t) => _buildTargetIndicator(t, isPrimary: true)),
            ...secondaryTargets.map((t) => _buildTargetIndicator(t)),
          ],
        );
      },
    );
  }


  List<Widget> _buildAllTargetParts() {
    return _primaryTargets.map((target) =>
        FutureBuilder<String>(
          future: context.read<PartRepository>().getBodyPartName(target.bodyPartId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: target.targetPercentage / 100,
                      strokeWidth: 3,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          target.targetPercentage > 30 ?
                          AppTheme.primaryRed : Colors.white70
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    snapshot.data!,
                    style: AppTheme.bodyMedium.copyWith(
                      color: target.targetPercentage > 30 ?
                      Colors.white : Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          },
        )
    ).toList();
  }

// Position calculation for expansion
  ExpansionDirection _calculateExpansionDirection() {
    final box = context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    if (position.dx < screenWidth * 0.3) return ExpansionDirection.right;
    if (position.dx > screenWidth * 0.7) return ExpansionDirection.left;
    return ExpansionDirection.both;
  }

  void _showOverlay(BuildContext context) {
    _overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _blurAnimation.value,
              sigmaY: _blurAnimation.value,
            ),
            child: Container(
              color: Colors.black.withOpacity(0.5 * _expandAnimation.value),
              child: GestureDetector(
                onTapUp: (_) => _hideOverlay(),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _expandController.reverse();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _expandController.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    _showOverlay(context);
    _expandController.forward();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _hideOverlay();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    final box = context.findRenderObject() as RenderBox;
    _cardOffset = box.localToGlobal(Offset.zero);
    _cardSize = box.size;
    _showExpandedCard();
  }

  void _showExpandedCard() {
    _overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // Blur background
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 5 * _expandAnimation.value,
                    sigmaY: 5 * _expandAnimation.value,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.5 * _expandAnimation.value),
                  ),
                ),
              ),
              // Expanded card
              Positioned(
                left: _cardOffset!.dx,
                top: _cardOffset!.dy,
                width: _cardSize!.width + (100 * _expandAnimation.value),
                height: _cardSize!.height + (150 * _expandAnimation.value),
                child: Transform.scale(
                  scale: 1 + (0.05 * _expandAnimation.value),
                  child: _buildExpandedCardContent(),
                ),
              ),
            ],
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _expandController.forward();
  }

  Widget _buildExpandedCardContent() {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: _buildGradient(),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildTargetedBodyParts(),
              if (widget.part.additionalNotes.isNotEmpty)
                _buildAdditionalNotes(),
              _buildSetTypeInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      widget.part.name,
      style: AppTheme.headingMedium.copyWith(color: Colors.white),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTargetedBodyParts() {
    return FutureBuilder<List<PartTargetedBodyParts>>(
      future: context.read<PartRepository>().getPartTargetedBodyParts(widget.part.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final targets = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: targets
              .where((target) => target.targetPercentage >= 15)
              .map((target) => _buildTargetIndicator(target))
              .toList(),
        );
      },
    );
  }

  Widget _buildAdditionalNotes() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        widget.part.additionalNotes,
        style: AppTheme.bodySmall.copyWith(color: Colors.white70),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSetTypeInfo() {
    return Text(
      'Set Type: ${widget.part.setTypeString}',
      style: AppTheme.bodySmall.copyWith(color: Colors.white70),
    );
  }

  void _hideExpandedCard() {
    _expandController.reverse().whenComplete(() {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  Widget _buildDetailedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTargetsSection(),
        _buildAdditionalInfo(),
        _buildSetTypeDetails(),
      ],
    );
  }

  Widget _buildTargetsSection() {
    return FutureBuilder<List<PartTargetedBodyParts>>(
      future: widget.repository.getPartTargetedBodyParts(widget.part.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final targets = snapshot.data!;
        final primaryTarget = targets.firstWhereOrNull((t) => t.targetPercentage > 30);
        final secondaryTarget = targets
            .where((t) => t.targetPercentage >= 15 && t.targetPercentage <= 30)
            .firstOrNull;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (primaryTarget != null)
                Expanded(child: _buildTargetIndicator(primaryTarget, isPrimary: true)),
              if (primaryTarget != null && secondaryTarget != null)
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
              if (secondaryTarget != null)
                Expanded(child: _buildTargetIndicator(secondaryTarget)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTargetIndicator(PartTargetedBodyParts target, {bool isPrimary = false}) {
    return FutureBuilder<String>(
      future: context.read<PartRepository>().getBodyPartName(target.bodyPartId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final bodyPartName = snapshot.data!;
        final color = isPrimary
            ? const Color(0xFFFF2D2D)  // Parlak kırmızı
            : const Color(0xFFFFAB40); // Parlak turuncu

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bodyPartName.toUpperCase(),
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white70,
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '${target.targetPercentage}%',
                style: AppTheme.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: isPrimary ? 16 : 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdditionalInfo() {
    if (widget.part.additionalNotes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        widget.part.additionalNotes,
        style: AppTheme.bodySmall.copyWith(color: Colors.white70),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSetTypeDetails() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        'Set Type: ${widget.part.setType}',
        style: AppTheme.bodySmall.copyWith(color: Colors.white70),
      ),
    );
  }

}
