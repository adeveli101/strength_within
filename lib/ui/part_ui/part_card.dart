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
import 'dart:math' as math;

enum ExpansionDirection {
  left,
  right,
  down
}

class PartCard extends StatefulWidget {
  final Parts part;
  final String userId;
  final Function() onTap;
  final Function(bool) onFavoriteChanged;
  final PartRepository repository;

  const PartCard({
    super.key,
    required this.part,
    required this.userId,
    required this.onTap,
    required this.onFavoriteChanged,
    required this.repository,
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.95,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: parts.length,
        padding: EdgeInsets.all(AppTheme.metrics['padding']!['medium']!),
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
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.metrics['padding']!['medium']!,
      ),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.metrics['padding']!['small']!,
          ),
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
      duration: AppTheme.normalAnimation,
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
    setState(() => _isExpanded = status == AnimationStatus.completed);
  }

  Future<void> _loadTargetedParts() async {
    final targets = await context.read<PartRepository>().getPartTargetedBodyParts(widget.part.id);

    if (!mounted) return;

    setState(() {
      _primaryTargets = targets.where((t) => t.targetPercentage > 30).toList();
      _secondaryTargets = targets.where(
              (t) => t.targetPercentage >= 15 && t.targetPercentage <= 30
      ).toList();
    });
  }

  LinearGradient _buildGradient() {
    return AppTheme.getPartGradient(
      difficulty: widget.part.difficulty,
      secondaryColor: _primaryTargets.isNotEmpty
          ? AppTheme.getTargetColor(_primaryTargets.first.bodyPartId)
          : AppTheme.primaryRed,
    );
  }

  Widget _buildFavoriteButton() {
    return IconButton(
      icon: Icon(
        widget.part.isFavorite ? Icons.favorite_outlined : Icons.favorite_border_outlined,
        color: Colors.white,
      ),
      onPressed: () => widget.onFavoriteChanged(!widget.part.isFavorite),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _handleLongPress();
        _expandController.forward();
      },
      onLongPressEnd: (_) => _expandController.reverse(),
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Container(
            decoration: AppTheme.decoration(
              gradient: AppTheme.getPartGradient(
                difficulty: widget.part.difficulty,
                secondaryColor: _primaryTargets.isNotEmpty
                    ? AppTheme.getTargetColor(_primaryTargets.first.bodyPartId)
                    : AppTheme.primaryRed,
              ),
              borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusMedium),
              shadows: [
                BoxShadow(
                  color: AppTheme.getDifficultyColor(widget.part.difficulty)
                      .withOpacity(AppTheme.shadowOpacity),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                _buildMainContent(),
                Positioned(
                  top: AppTheme.paddingSmall,
                  right: AppTheme.paddingSmall,
                  child: _buildFavoriteButton(),
                ),
                if (_isExpanded) _buildExpandedContent(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = _calculateCardWidth(screenWidth);

        return Container(
          width: cardWidth,
          constraints: BoxConstraints(
            minHeight: AppTheme.metrics['difficulty']!['starBaseSize']! * 5,
            maxHeight: constraints.maxHeight,
          ),
          padding: EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.part.name,
                style: AppTheme.headingMedium.copyWith(
                  fontSize: AppTheme.metrics['difficulty']!['starBaseSize']!,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppTheme.paddingSmall),
              _buildDifficultyIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildTargetsCard(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculateCardWidth(double screenWidth) {
    if (screenWidth <= AppTheme.mobileBreakpoint) {
      return screenWidth * 0.65;
    } else if (screenWidth <= AppTheme.tabletBreakpoint) {
      return screenWidth * 0.4;
    }
    return screenWidth * 0.3;
  }

  Widget _buildDifficultyIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AppTheme.buildDifficultyStars(widget.part.difficulty),
      ),
    );
  }



  Widget _buildTargetsCard() {
    if (_primaryTargets.isEmpty && _secondaryTargets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTargetList(_primaryTargets, true),
          if (_secondaryTargets.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Divider(height: 1, color: Colors.white12),
            ),
            _buildTargetList(_secondaryTargets, false),
          ],
        ],
      ),
    );
  }

  Widget _buildTargetList(List<PartTargetedBodyParts> targets, bool isPrimary) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(6),
      itemCount: isPrimary ? targets.length : math.min(targets.length, 2),
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, index) => _buildTargetItem(targets[index], isPrimary),
    );
  }

  Widget _buildTargetItem(PartTargetedBodyParts target, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          buildTargetIcon(target, isPrimary),
          SizedBox(width: 6),
          Expanded(
            child: FutureBuilder<String?>(
              future: context.read<PartRepository>().getBodyPartName(target.bodyPartId),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? '',
                  style: TextStyle(
                    fontSize: isPrimary ? 13 : 12,
                    color: isPrimary ? Colors.white : Colors.white70,
                    fontWeight: isPrimary ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              },
            ),
          ),
          _buildIntensityIndicator(target),
        ],
      ),
    );
  }

  Widget _buildIntensityIndicator(PartTargetedBodyParts target) {
    final allTargets = [..._primaryTargets, ..._secondaryTargets];
    final normalizedValue = _normalizePercentage(target.targetPercentage, allTargets);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
              (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              Icons.square_foot_rounded,
              size: 10,
              color: _getIntensityColor(normalizedValue, index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetName(PartTargetedBodyParts target, bool isPrimary) {
    return FutureBuilder<String?>(
      future: context.read<PartRepository>().getBodyPartName(target.bodyPartId),
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? '',
          style: TextStyle(
            fontSize: isPrimary ? 13 : 12,
            color: isPrimary ? Colors.white : Colors.white70,
            fontWeight: isPrimary ? FontWeight.w500 : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      },
    );
  }

  String _normalizePercentage(int percentage, List<PartTargetedBodyParts> allTargets) {
    final sortedTargets = [...allTargets]..sort((a, b) => b.targetPercentage.compareTo(a.targetPercentage));
    final highestPercentage = sortedTargets.first.targetPercentage;
    final lowestPercentage = sortedTargets.last.targetPercentage;
    final range = highestPercentage - lowestPercentage;
    final step = range / 3;

    if (percentage >= highestPercentage - step) return 'high';
    if (percentage >= highestPercentage - (step * 2)) return 'medium';
    return 'low';
  }

  Color _getIntensityColor(String intensity, int index) {
    final baseColor = Colors.white;
    switch (intensity) {
      case 'high':
        return baseColor;
      case 'medium':
        return index == 0 ? baseColor : baseColor.withOpacity(0.3);
      case 'low':
        return index == 0 ? baseColor : baseColor.withOpacity(0.1);
      default:
        return baseColor.withOpacity(0.1);
    }
  }

  ExpansionDirection _calculateExpansionDirection() {
  final box = context.findRenderObject() as RenderBox;
  final position = box.localToGlobal(Offset.zero);
  final screenSize = MediaQuery.of(context).size;

  // Ekranın alt kısmındaysa yukarı açılsın
  if (position.dy > screenSize.height * 0.7) {
  return ExpansionDirection.down;
  }

  // Ekranın sağ tarafındaysa sola açılsın
  if (position.dx > screenSize.width * 0.7) {
  return ExpansionDirection.left;
  }

  // Varsayılan olarak sağa açılsın
  return ExpansionDirection.right;
  }

  void _showOverlay(BuildContext context) {
    _overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 3.0 * _expandAnimation.value.clamp(0.0, 1.0),
                    sigmaY: 3.0 * _expandAnimation.value.clamp(0.0, 1.0),
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(
                        (AppTheme.shadowOpacity * _expandAnimation.value).clamp(0.0, 1.0)
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTapUp: (_) => _hideOverlay(),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ],
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
    final screenSize = MediaQuery.of(context).size;

    _overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // Arkaplan Blur Efekti
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 5 * _expandAnimation.value,
                    sigmaY: 5 * _expandAnimation.value,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(
                        AppTheme.metrics['opacity']!['shadow']! * _expandAnimation.value
                    ),
                  ),
                ),
              ),

              // Genişleyen Kart
              Positioned(
                left: _cardOffset!.dx,
                top: _cardOffset!.dy,
                width: screenSize.width * 0.85 * _expandAnimation.value,
                height: screenSize.height * 0.7 * _expandAnimation.value,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: AppTheme.decoration(
                      gradient: AppTheme.getPartGradient(
                        difficulty: widget.part.difficulty,
                        secondaryColor: _primaryTargets.isNotEmpty
                            ? AppTheme.getTargetColor(_primaryTargets.first.bodyPartId)
                            : AppTheme.primaryRed,
                      ),
                      borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusMedium),
                    ),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(AppTheme.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildExpandedHeader(),
                          SizedBox(height: AppTheme.paddingMedium),
                          _buildTargetsCard(),
                          if (widget.part.additionalNotes.isNotEmpty) ...[
                            SizedBox(height: AppTheme.paddingSmall),
                            _buildAdditionalInfo(),
                          ],
                          SizedBox(height: AppTheme.paddingSmall),
                          _buildSetTypeDetails(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpandedCardContent(double width, double height) {
    return Positioned(
      left: _cardOffset!.dx,
      top: _cardOffset!.dy,
      width: width * _expandAnimation.value,
      height: height * _expandAnimation.value,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: AppTheme.decoration(
            gradient: AppTheme.getPartGradient(
              difficulty: widget.part.difficulty,
              secondaryColor: _primaryTargets.isNotEmpty
                  ? AppTheme.getTargetColor(_primaryTargets.first.bodyPartId)
                  : AppTheme.primaryRed,
            ),
            borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusMedium),
            shadows: [
              BoxShadow(
                color: AppTheme.getDifficultyColor(widget.part.difficulty)
                    .withOpacity(AppTheme.shadowOpacity),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(AppTheme.paddingMedium),
            child: _buildExpandedCardBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedCardBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandedHeader(),
        SizedBox(height: AppTheme.paddingLarge),
        Container(
          decoration: AppTheme.decoration(
            color: Colors.black26,
            borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
          ),
          padding: EdgeInsets.all(AppTheme.paddingMedium),
          child: _buildTargetsCard(),
        ),
        if (widget.part.additionalNotes.isNotEmpty) ...[
          SizedBox(height: AppTheme.paddingMedium),
          _buildAdditionalInfo(),
        ],
        SizedBox(height: AppTheme.paddingMedium),
        _buildSetTypeDetails(),
      ],
    );
  }

  Widget _buildHeader() {
    return Text(
      widget.part.name,
      style: AppTheme.headingMedium.copyWith(
        fontSize: AppTheme.metrics['difficulty']!['starBaseSize']!,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 2,
      overflow: TextOverflow.fade,
      softWrap: true,
    );
  }

  Widget _buildExpandedHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.part.name,
            style: AppTheme.headingMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildDifficultyIndicator(),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: Text(
        widget.part.additionalNotes,
        style: AppTheme.bodySmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSetTypeDetails() {
    return Text(
      'Set Type: ${widget.part.setTypeString}',
      style: AppTheme.bodySmall,
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
        _buildTargetsCard(),
        SizedBox(height: AppTheme.paddingSmall),
        _buildAdditionalInfo(),
        SizedBox(height: AppTheme.paddingSmall),
        _buildSetTypeDetails(),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return AnimatedContainer(
      duration: AppTheme.normalAnimation,
      child: _buildExpandedCardBody(),
    );
  }

  Widget _buildTargetIndicator(PartTargetedBodyParts target, {bool isPrimary = false}) {
    return FutureBuilder<String>(
      future: context.read<PartRepository>().getBodyPartName(target.bodyPartId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final bodyPartName = snapshot.data!;
        final color = isPrimary ? AppTheme.primaryRed : AppTheme.warningYellow;
        final percentage = target.targetPercentage;

        return Container(
          margin: EdgeInsets.only(bottom: AppTheme.paddingSmall),
          decoration: AppTheme.decoration(
            color: Colors.black12,
            borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
          ),
          child: Stack(
            children: [
              // Progress Bar
              ClipRRect(
                borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: color.withOpacity(AppTheme.metrics['opacity']!['secondary']!),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 64,
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(AppTheme.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side - Name and Icon
                    Row(
                      children: [
                        Icon(
                          isPrimary ? Icons.local_fire_department : Icons.fitness_center,
                          color: Colors.white,
                          size: AppTheme.metrics['difficulty']!['starBaseSize']!,
                        ),
                        SizedBox(width: AppTheme.paddingSmall),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bodyPartName.toUpperCase(),
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              isPrimary ? 'Primary Target' : 'Secondary Target',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Right side - Percentage
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingMedium,
                        vertical: AppTheme.paddingSmall,
                      ),
                      decoration: AppTheme.decoration(
                        color: color.withOpacity(0.2),
                        borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusLarge),
                      ),

                      child: Text(
                        '$percentage%',
                        style: AppTheme.headingSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }}
