import 'dart:math';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:strength_within/ui/part_ui/part_detail.dart';
import '../../blocs/data_bloc_part/PartRepository.dart';
import '../../blocs/data_bloc_part/part_bloc.dart';
import '../../models/sql_models/PartTargetedBodyParts.dart';
import '../../models/sql_models/Parts.dart';
import '../../sw_app_theme/app_theme.dart';
import '../../utils/routine_helpers.dart';
import 'dart:math' as math;

enum ExpansionDirection {
  left,
  right,
  down,
  up
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
    void handleCardTap(BuildContext context, Parts part) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PartDetailBottomSheet(
          userId: userId,
          partId: part.id,
        ),
      ).then((_) {
        // Liste state'ini yenile
        onTap(part.id);
      });
    }

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
            onTap: () => handleCardTap(context, parts[index]),
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
            onTap: () => handleCardTap(context, parts[index]),
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

  bool _isHandlingGesture = false;
  bool _isExpanded = false;
  List<PartTargetedBodyParts> _primaryTargets = [];
  List<PartTargetedBodyParts> _secondaryTargets = [];
  OverlayEntry? _overlayEntry;
  Offset? _cardOffset;
  Size? _cardSize;

  late final PartsBloc _partsBloc;
  int exerciseCount = 0;


  @override
  void initState() {
    super.initState();
    _partsBloc = context.read<PartsBloc>();
    _initializeAnimations();
    _loadTargetedParts();
    _loadExerciseCount();  }


  Future<void> _loadExerciseCount() async {
    try {
      final exercises = await _partsBloc.repository.getPartExercisesByPartId(widget.part.id);
      if (mounted) {
        setState(() {
          exerciseCount = exercises.length;
        });
      }
    } catch (e) {
      debugPrint('Egzersiz sayısı yükleme hatası: $e');
      setState(() {
        exerciseCount = 0;
      });
    }
  }

  Widget _buildExerciseCounter() {
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
        children: [
          Icon(Icons.fitness_center, size: 16, color: Colors.white70),
          SizedBox(width: 8),
          Text(
            '$exerciseCount Egzersiz',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  void _handleAnimationStatus(AnimationStatus status) {
    setState(() => _isExpanded = status == AnimationStatus.completed);
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


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        if (!_isHandlingGesture) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => PartDetailBottomSheet(
              userId: widget.userId,
              partId: widget.part.id,
            ),
          );
        }
      },
      onLongPressStart: (_) => _handleLongPress(),
      onLongPressEnd: (_) {
        _hideExpandedCard();
        Future.delayed(AppTheme.normalAnimation, () {
          if (mounted) {
            setState(() => _isHandlingGesture = false);
          }
        });
      },
      child: Stack(
        children: [
          AnimatedBuilder(
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
                child: _buildMainContent(),
              );
            },
          ),
          Positioned(
            top: AppTheme.paddingSmall,
            right: AppTheme.paddingSmall,
            child: _buildFavoriteButton(),
          ),
        ],
      ),
    );
  }

  void _showExpandedCard() {
    if (!mounted) return;

    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _hideExpandedCard,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, _) => BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(
                  color: Colors.black.withOpacity(
                      (_expandAnimation.value * AppTheme.shadowOpacity).clamp(0.0, 1.0)
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, _) => _buildExpandedCardContent(
              MediaQuery.of(context).size.width * 0.85,
              MediaQuery.of(context).size.height * 0.7,
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideExpandedCard() {
    if (!mounted) return;

    _expandController.reverse().whenComplete(() {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() {
        _isExpanded = false;
        _isHandlingGesture = false;
      });
    });
  }

  @override
  void dispose() {
    _expandController.dispose();
    _overlayEntry?.remove();
    _isHandlingGesture = false;
    super.dispose();
  }

  Future<void> _loadTargetedParts() async {
    final targets = await context.read<PartRepository>()
        .getPartTargetedBodyParts(widget.part.id);

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
        widget.part.isFavorite ? Icons.favorite_outlined : Icons
            .favorite_border_outlined,
        color: Colors.white,
      ),
      onPressed: () => widget.onFavoriteChanged(!widget.part.isFavorite),
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

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery
            .of(context)
            .size
            .width;
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
              SizedBox(height: AppTheme.paddingSmall),
              Text(
                'Targets',
                style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.progressBarColor
                ),
              ),
              SizedBox(height: AppTheme.paddingSmall),
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
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: AppTheme.paddingLarge), // Maksimum genişlik sınırı
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: AppTheme.buildDifficultyStars(widget.part.difficulty),
        ),
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
      separatorBuilder: (_, __) => const SizedBox(height: 2),
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
              future: context.read<PartRepository>().getBodyPartName(
                  target.bodyPartId),
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
    final normalizedValue = _normalizePercentage(
        target.targetPercentage, allTargets);

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
              (index) =>
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  Icons.square_rounded,
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

  String _normalizePercentage(int percentage,
      List<PartTargetedBodyParts> allTargets) {
    final sortedTargets = [...allTargets]
      ..sort((a, b) => b.targetPercentage.compareTo(a.targetPercentage));
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



  Widget _buildTargetIndicator(PartTargetedBodyParts target,
      {bool isPrimary = false}) {
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
            borderRadius: AppTheme.getBorderRadius(
                all: AppTheme.borderRadiusSmall),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: AppTheme.getBorderRadius(
                    all: AppTheme.borderRadiusSmall),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: color.withOpacity(
                      AppTheme.metrics['opacity']!['secondary']!),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 64,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(AppTheme.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPrimary ? Icons.local_fire_department : Icons
                              .fitness_center,
                          color: Colors.white,
                          size: AppTheme
                              .metrics['difficulty']!['starBaseSize']!,
                        ),
                        SizedBox(width: AppTheme.paddingSmall),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bodyPartName.toUpperCase(),
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: isPrimary
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingMedium,
                        vertical: AppTheme.paddingSmall,
                      ),
                      decoration: AppTheme.decoration(
                        color: color.withOpacity(0.2),
                        borderRadius: AppTheme.getBorderRadius(
                            all: AppTheme.borderRadiusLarge),
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
  }

  Widget _buildExpandedHeader() {
    return Container(
      decoration: AppTheme.decoration(
        color: Colors.black12,
        borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
      ),
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              widget.part.name,
              style: AppTheme.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: AppTheme.paddingMedium),
          _buildDifficultyIndicator(),
          SizedBox(width: AppTheme.paddingMedium),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      width: double.infinity,
      decoration: AppTheme.decoration(
        color: Colors.black12,
        borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
      ),
      padding: EdgeInsets.all(AppTheme.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Notes',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          SizedBox(height: AppTheme.paddingSmall),
          Text(
            widget.part.additionalNotes,
            style: AppTheme.bodySmall.copyWith(color: Colors.white70),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSetTypeDetails() {
    return Container(
      width: double.infinity,
      decoration: AppTheme.decoration(
        color: Colors.black12,
        borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
      ),
      padding: EdgeInsets.all(AppTheme.paddingSmall),
      child: Row(
        children: [
          Icon(
            Icons.fitness_center,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          SizedBox(width: AppTheme.paddingSmall),
          Text(
            'Set Type: ',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textColorSecondary,
            ),
          ),
          Text(
            widget.part.setTypeString,
            style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSection(List<PartTargetedBodyParts> targets, bool isPrimary) {
    return Container(
      constraints: BoxConstraints(maxHeight: 160), // Maksimum yükseklik sınırı
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTargetHeader(isPrimary ? 'Primary Targets' : 'Secondary Targets'),
          ...targets.take(isPrimary ? 2 : 1).map( // Hedef sayısını sınırla
                (target) => _buildExpandedTargetItem(target, isPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetHeader(String title) {
    return Container(
      height: 32, // Sabit yükseklik
      margin: EdgeInsets.only(
        top: AppTheme.paddingSmall / 2,
        left: AppTheme.paddingSmall / 2,
        right: AppTheme.paddingSmall / 2,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingSmall,
        vertical: AppTheme.paddingSmall / 2,
      ),
      decoration: AppTheme.decoration(
        color: Colors.black26,
        borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
      ),
      child: Text(
        title,
        style: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryGreen,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTargetInfo(PartTargetedBodyParts target, bool isPrimary) {
    return FutureBuilder<String?>(
      future: context.read<PartRepository>().getBodyPartName(target.bodyPartId),
      builder: (context, snapshot) {
        final bodyPartName = snapshot.data ?? '';
        return SizedBox(
          height: 45, // Sabit yükseklik
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bodyPartName.toUpperCase(),
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                isPrimary ? 'Primary' : 'Secondary',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                maxLines: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPercentageIndicator(int percentage, Color color) {
    return Container(
      width: 40, // Sabit genişlik
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingSmall / 2,
        vertical: 2,
      ),
      decoration: AppTheme.decoration(
        color: color.withOpacity(0.2),
        borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
      ),
      alignment: Alignment.center,
      child: Text(
        '$percentage%',
        style: AppTheme.bodySmall.copyWith(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildExpandedTargetsCard() {
    if (_primaryTargets.isEmpty && _secondaryTargets.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: AppTheme.decoration(
        color: Colors.black12,
        borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,  // Allow growth based on content
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_primaryTargets.isNotEmpty) _buildTargetSection(_primaryTargets, true),
          if (_secondaryTargets.isNotEmpty) _buildTargetSection(_secondaryTargets, false),
        ],
      ),
    );
  }

  Widget _buildExpandedTargetItem(PartTargetedBodyParts target, bool isPrimary) {
    final color = isPrimary ? AppTheme.primaryRed : AppTheme.warningYellow;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingSmall ,
        vertical: AppTheme.paddingSmall ,
      ),
      // Consider using Flexible or remove fixed height
      decoration: AppTheme.decoration(
        color: Colors.black26,
        borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        child: Stack(
          children: [
            LinearProgressIndicator(
              value: target.targetPercentage / 100,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color.withOpacity(0.3)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingSmall / 2),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    isPrimary ? Icons.local_fire_department : Icons.fitness_center,
                    color: Colors.white70,
                    size: 14,
                  ),
                  SizedBox(width: AppTheme.paddingSmall / 4),
                  Expanded(
                    flex: 3,
                    child: _buildTargetInfo(target, isPrimary),
                  ),
                  Container(
                    width: 40, // Fixed width for percentage display
                    alignment: Alignment.center,
                    child: Text(
                      '${target.targetPercentage}%',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedCardContent(double width, double height) {
    final direction = _calculateExpansionDirection();
    final offset = _getPositionedOffset(direction);
    final contentSize = _calculateExpandedContentSize();

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: contentSize.width * _expandAnimation.value,
      height: contentSize.height * _expandAnimation.value,
      child: Transform.translate(
        offset: _calculateTransformOffset(direction, contentSize.width, contentSize.height),
        child: Material(
          type: MaterialType.card,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          elevation: 8,
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
            padding: EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildExpandedHeader(),
                SizedBox(height: AppTheme.paddingMedium),
                _buildExpandedTargetsCard(),
                if (widget.part.additionalNotes.isNotEmpty) ...[
                  SizedBox(height: AppTheme.paddingMedium),
                  _buildAdditionalInfo(),
                ],
                SizedBox(height: AppTheme.paddingMedium),
                _buildSetTypeDetails(),
                SizedBox(height: AppTheme.paddingMedium),
                _buildExerciseCounter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Offset _calculateTransformOffset(ExpansionDirection direction, double width, double height) {
    final progress = 1 - _expandAnimation.value;

    switch (direction) {
      case ExpansionDirection.left:
        return Offset(-width * progress, 0);
      case ExpansionDirection.right:
        return Offset(width * progress, 0);
      case ExpansionDirection.up:
        return Offset(0, -height * progress); // Use negative height for upward movement
      case ExpansionDirection.down:
        return Offset(0, height * progress); // Use positive height for downward movement
      default:
        return Offset.zero; // Fallback case
    }
  }

  Offset _getPositionedOffset(ExpansionDirection direction) {
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = _cardSize!.width;
    final cardHeight = _cardSize!.height;
    final expandedWidth = screenSize.width * 0.95;
    final expandedHeight = screenSize.height * 0.90;

    // Kartın ekrandaki görünür pozisyonunu hesapla
    final visibleOffset = _ensureVisiblePosition(
        originalOffset: _cardOffset!,
        expandedSize: Size(expandedWidth, expandedHeight),
        screenSize: screenSize
    );

    switch (direction) {
      case ExpansionDirection.left:
      case ExpansionDirection.right:
        return Offset(
          // Yatayda ekranın ortasına hizala
          (screenSize.width - expandedWidth) / 2,
          // Dikeyde kartın pozisyonunu koru ama ekran sınırları içinde tut
          visibleOffset.dy.clamp(
              0,
              screenSize.height - expandedHeight
          ),
        );
      case ExpansionDirection.up:
      case ExpansionDirection.down:
        return Offset(
          // Yatayda ekranın ortasına hizala
          (screenSize.width - expandedWidth) / 2,
          // Dikeyde kartın pozisyonunu koru ama ekran sınırları içinde tut
          visibleOffset.dy.clamp(
              0,
              screenSize.height - expandedHeight
          ),
        );
      default:
        return Offset.zero;
    }
  }

// Kartın görünür pozisyonunu hesapla
  Offset _ensureVisiblePosition({
    required Offset originalOffset,
    required Size expandedSize,
    required Size screenSize,
  }) {
    double dx = originalOffset.dx;
    double dy = originalOffset.dy;

    // Yatayda ekran dışına taşmayı engelle
    if (dx < 0) {
      dx = 0;
    } else if (dx + expandedSize.width > screenSize.width) {
      dx = screenSize.width - expandedSize.width;
    }

    // Dikeyde ekran dışına taşmayı engelle
    if (dy < 0) {
      dy = 0;
    } else if (dy + expandedSize.height > screenSize.height) {
      dy = screenSize.height - expandedSize.height;
    }

    return Offset(dx, dy);
  }

  Size _calculateExpandedContentSize() {
    final screenSize = MediaQuery.of(context).size;

    // Yükseklik değerleri artırıldı
    const double headerHeight = 80.0;        // Header yüksekliği
    const double targetItemHeight = 64.0;    // Her bir hedef öğe yüksekliği
    const double notesHeight = 160.0;        // Notlar bölümü yüksekliği
    const double setTypeHeight = 72.0;       // Set tipi yüksekliği
    const double exerciseCountHeight = 64.0; // Egzersiz sayacı yüksekliği
    const double spacing = 24.0;             // Boşluklar artırıldı

    // Başlangıç yüksekliği
    double contentHeight = headerHeight + spacing * 2;

    // Hedef kartları için yükseklik
    final targetCount = min(_primaryTargets.length, 4) + min(_secondaryTargets.length, 2);
    contentHeight += (targetCount * targetItemHeight) + (spacing * (targetCount + 1));

    // Additional Notes yüksekliği
    if (widget.part.additionalNotes.isNotEmpty) {
      contentHeight += notesHeight + spacing * 2;
    }

    // Set tipi yüksekliği
    contentHeight += setTypeHeight + spacing;

    // Egzersiz sayacı yüksekliği
    contentHeight += exerciseCountHeight + spacing;

    // Ekstra padding için yükseklik
    contentHeight += spacing * 4;

    // Maksimum boyutlar
    final maxWidth = screenSize.width * 0.95;
    final maxHeight = screenSize.height * 0.95; // Yükseklik sınırı artırıldı

    return Size(
        maxWidth.clamp(0, screenSize.width),
        maxHeight.clamp(0, screenSize.height)
    );
  }

  ExpansionDirection _calculateExpansionDirection() {
    if (!mounted || context.findRenderObject() == null) {
      return ExpansionDirection.right;
    }

    final box = context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;
    final contentSize = _calculateExpandedContentSize();

    // Calculate available space
    final rightSpace = screenSize.width - (position.dx + box.size.width);
    final leftSpace = position.dx;
    final topSpace = position.dy;
    final bottomSpace = screenSize.height - (position.dy + box.size.height);

    // Determine the most appropriate direction
    if (rightSpace >= contentSize.width) {
      return ExpansionDirection.right;
    }
    if (leftSpace >= contentSize.width) {
      return ExpansionDirection.left;
    }
    if (bottomSpace >= contentSize.height) {
      return ExpansionDirection.down;
    }
    if (topSpace >= contentSize.height) {
      return ExpansionDirection.up;
    }

    // Fallback to the best available space
    return leftSpace >= rightSpace ? ExpansionDirection.left : ExpansionDirection.right;
  }

  ExpansionDirection _findOptimalDirection(Offset position, Size screenSize, double expandedWidth, double expandedHeight) {
    final spaces = {
      ExpansionDirection.right: screenSize.width - (position.dx + _cardSize!.width),
      ExpansionDirection.left: position.dx,
      ExpansionDirection.down: screenSize.height - (position.dy + _cardSize!.height),
      ExpansionDirection.up: position.dy,
    };

    // Identify valid directions based on required space
    final validDirections = spaces.entries.where((entry) {
      final requiredSpace = (entry.key == ExpansionDirection.up || entry.key == ExpansionDirection.down) ? expandedHeight : expandedWidth;
      return entry.value >= requiredSpace;
    }).map((entry) => entry.key).toList();

    // Return the optimal direction if there are valid options
    if (validDirections.isNotEmpty) {
      return validDirections.first;
    }

    // If no valid direction, choose the direction with the most space
    return spaces.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  void _handleLongPress() {
    // Eğer zaten bir gesture işlemi devam ediyorsa işlemi engelle
    if (_isHandlingGesture || _isExpanded) return;

    // Gesture işlemini başlat
    setState(() => _isHandlingGesture = true);

    // Kartın pozisyonunu ve boyutunu hesapla
    final box = context.findRenderObject() as RenderBox;
    _cardOffset = box.localToGlobal(Offset.zero);
    _cardSize = box.size;

    // Ekran boyutlarını al
    final screenSize = MediaQuery.of(context).size;

    // Genişletilmiş içerik boyutunu hesapla
    final contentSize = Size(
      screenSize.width * 0.92, // Ekran genişliğinin %92'si
      screenSize.height * 0.85, // Ekran yüksekliğinin %85'i
    );

    // İçerik boyutu geçerliyse genişletme işlemini başlat
    if (_isValidContentSize(contentSize)) {
      _isExpanded = true;
      _showOverlay();
      _expandController.forward().then((_) {
        if (mounted) {
          setState(() => _isHandlingGesture = false);
        }
      });
    } else {
      setState(() => _isHandlingGesture = false);
    }
  }

  bool _isValidContentSize(Size size) {
    return size.width > 0 &&
        size.height > 0 &&
        size.width <= MediaQuery.of(context).size.width &&
        size.height <= MediaQuery.of(context).size.height;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final contentSize = _calculateExpandedContentSize();

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Blur background
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, _) => GestureDetector(
                onTap: _hideOverlay,
                behavior: HitTestBehavior.opaque,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(
                        (AppTheme.shadowOpacity * _expandAnimation.value).clamp(0.0, 1.0)
                    ),
                  ),
                ),
              ),
            ),
            // Expanded card
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, _) => _buildExpandedCardContent(
                contentSize.width,
                contentSize.height,
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _hideOverlay() async {
    if (!mounted) return;

    setState(() => _isHandlingGesture = false);

    try {
      await _expandController.reverse();
    } finally {
      if (mounted) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        setState(() => _isExpanded = false);
      }
    }
  }

}



