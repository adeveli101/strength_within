// ignore_for_file: unused_field

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:strength_within/ui/part_ui/part_card.dart';
import 'package:strength_within/ui/part_ui/part_detail.dart';
import 'package:strength_within/ui/routine_ui/routine_card.dart';
import 'package:strength_within/ui/routine_ui/routine_detail.dart';
import 'package:strength_within/ui/routine_ui/mini_routine_card.dart';
import 'package:strength_within/ui/part_ui/mini_part_card.dart';
import 'package:logging/logging.dart';
import '../blocs/data_bloc_part/PartRepository.dart';
import '../blocs/data_bloc_part/part_bloc.dart';
import '../blocs/data_bloc_routine/routines_bloc.dart';
import '../blocs/data_bloc_routine/RoutineRepository.dart';
import '../models/sql_models/Parts.dart';
import '../models/sql_models/routines.dart';
import '../models/sql_models/workoutGoals.dart';
import '../models/sql_models/WorkoutType.dart';
import '../sw_app_theme/app_theme.dart';
import '../sw_app_theme/welcome_header.dart';
import 'list_pages/parts_page.dart';
import 'list_pages/routines_page.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({super.key, required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {

  final _logger = Logger('HomePage');

  late RoutinesBloc _routinesBloc;
  late PartsBloc _partsBloc;
  late RoutineRepository _routineRepository;
  List<WorkoutGoals> _goals = [];
  List<WorkoutTypes> _workoutTypes = [];
  bool _loadingGoals = true;
  bool _loadingTypes = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupLogging();
    _routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    _partsBloc = BlocProvider.of<PartsBloc>(context);
    _routineRepository = _routinesBloc.repository;
    _fetchGoalsAndTypes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routinesBloc.add(FetchRoutines());
      _partsBloc.add(FetchParts());
    });
  }

  void _setupLogging() {
    hierarchicalLoggingEnabled = true;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.loggerName}: ${record.level.name}: ${record.message}');
    });
  }

  Future<void> _fetchGoalsAndTypes() async {
    setState(() { _loadingGoals = true; _loadingTypes = true; });
    try {
      _goals = await _routineRepository.getAllWorkoutGoals();
      _workoutTypes = await _routineRepository.sqlProvider.getAllWorkoutTypes();
    } catch (e) {
      _logger.warning('Goals/types fetch error: $e');
    }
    setState(() { _loadingGoals = false; _loadingTypes = false; });
  }

  @override
  void dispose() {
    _routinesBloc.close();
    _partsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            color: AppTheme.primaryRed,
            backgroundColor: AppTheme.darkBackground,
            strokeWidth: 3,
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              _routinesBloc.add(FetchRoutines());
              _partsBloc.add(FetchParts());
              await _fetchGoalsAndTypes();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              children: [
                WelcomeHeader(),
                _ConditionalContinueSection(userId: widget.userId, constraints: constraints),
                _ConditionalQuickPicksSection(userId: widget.userId, constraints: constraints),
                _ConditionalBodyPartSection(userId: widget.userId, constraints: constraints),
                if (!_loadingTypes && _workoutTypes.isNotEmpty)
                  ..._buildWorkoutTypeSections(constraints),
                _ConditionalFeaturedSection(userId: widget.userId, constraints: constraints),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildWorkoutTypeSections(BoxConstraints constraints) {
    return _workoutTypes.map((type) => FutureBuilder<List<Routines>>(
      future: _routineRepository.getAllRoutines().then((routines) => routines.where((r) => r.workoutTypeId == type.id).toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox.shrink();
        final routines = snapshot.data!;
        return _RoutineHorizontalList(
          title: type.name,
          routines: routines,
          userId: widget.userId,
          constraints: constraints,
        );
      },
    )).toList();
  }

  Widget _buildFavoritesSection(BoxConstraints constraints) {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        if (state is RoutinesLoaded) {
          final favorites = state.routines.where((r) => r.isFavorite).toList();
          if (favorites.isEmpty) return SizedBox.shrink();
          return _RoutineHorizontalList(
            title: 'Favori Rutinler',
            routines: favorites,
            userId: widget.userId,
            constraints: constraints,
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildRecentlyUsedSection(BoxConstraints constraints) {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        if (state is RoutinesLoaded) {
          final recent = state.routines.where((r) => r.lastUsedDate != null).toList()
            ..sort((a, b) => (b.lastUsedDate ?? DateTime(0)).compareTo(a.lastUsedDate ?? DateTime(0)));
          if (recent.isEmpty) return SizedBox.shrink();
          return _RoutineHorizontalList(
            title: 'Devam Eden Rutinler',
            routines: recent.take(6).toList(),
            userId: widget.userId,
            constraints: constraints,
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}

class _RoutineHorizontalList extends StatelessWidget {
  final String title;
  final List<Routines> routines;
  final String userId;
  final BoxConstraints constraints;
  const _RoutineHorizontalList({required this.title, required this.routines, required this.userId, required this.constraints});

  @override
  Widget build(BuildContext context) {
    final isWideScreen = constraints.maxWidth > AppTheme.tabletBreakpoint;
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium, vertical: AppTheme.paddingSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: isWideScreen ? AppTheme.headingMedium : AppTheme.headingSmall),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (context) => RoutinesPage(userId: userId),
                        ),
                      );
                    },
                  icon: Text('Hepsini Gör', style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
                  label: Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryRed),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: isWideScreen ? 320 : 290,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingSmall),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: isWideScreen ? 300 : 320,
                  child: Card(
                    margin: EdgeInsets.all(AppTheme.paddingSmall),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    color: AppTheme.cardBackground,
                    child: RoutineCard(
                      key: ValueKey(routines[index].id),
                      routine: routines[index],
                      userId: userId,
                      onTap: () => _showRoutineDetailBottomSheet(context, routines[index].id, userId),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future _showRoutineDetailBottomSheet(BuildContext context, int routineId, String userId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoutineDetailBottomSheet(
        routineId: routineId,
        userId: userId,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onActionTap;
  const _SectionTitle({required this.title, required this.action, this.onActionTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.headingSmall),
          if (onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(action, style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryRed)),
            ),
        ],
      ),
    );
  }
}

class _ConditionalContinueSection extends StatelessWidget {
  final String userId;
  final BoxConstraints constraints;
  const _ConditionalContinueSection({required this.userId, required this.constraints});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        if (state is RoutinesLoaded) {
          final recent = state.routines.where((r) => r.lastUsedDate != null).toList()
            ..sort((a, b) => (b.lastUsedDate ?? DateTime(0)).compareTo(a.lastUsedDate ?? DateTime(0)));
          if (recent.isEmpty) return SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: 'Devam Eden Rutinler',
                action: 'Tümünü Gör',
                onActionTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RoutinesPage(userId: userId)),
                  );
                },
              ),
              _RoutineCardList(routines: recent.take(8).toList(), userId: userId, constraints: constraints),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}

class _ConditionalQuickPicksSection extends StatelessWidget {
  final String userId;
  final BoxConstraints constraints;
  const _ConditionalQuickPicksSection({required this.userId, required this.constraints});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        if (state is RoutinesLoaded) {
          final picks = state.routines.take(10).toList();
          if (picks.isEmpty) return SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: 'Senin İçin Öneriler',
                action: 'Tümünü Gör',
                onActionTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RoutinesPage(userId: userId)),
                  );
                },
              ),
              _RoutineCardList(routines: picks, userId: userId, constraints: constraints),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}

class _ConditionalBodyPartSection extends StatelessWidget {
  final String userId;
  final BoxConstraints constraints;
  const _ConditionalBodyPartSection({required this.userId, required this.constraints});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PartsBloc, PartsState>(
      builder: (context, state) {
        if (state is PartsLoaded) {
          final parts = state.parts.take(10).toList();
          if (parts.isEmpty) return SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: 'Bölge Bazlı Programlar',
                action: 'Tümünü Gör',
                onActionTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PartsPage(userId: userId)),
                  );
                },
              ),
              _PartCardList(parts: parts, userId: userId, constraints: constraints),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}

class _ConditionalFeaturedSection extends StatelessWidget {
  final String userId;
  final BoxConstraints constraints;
  const _ConditionalFeaturedSection({required this.userId, required this.constraints});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        if (state is RoutinesLoaded) {
          final featured = state.routines.where((r) => r.userRecommended == true).toList();
          if (featured.isEmpty) return SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: 'Öne Çıkanlar',
                action: 'Tümünü Gör',
                onActionTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RoutinesPage(userId: userId)),
                  );
                },
              ),
              _RoutineCardList(routines: featured, userId: userId, constraints: constraints),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}

class _RoutineCardList extends StatelessWidget {
  final List<Routines> routines;
  final String userId;
  final BoxConstraints constraints;
  const _RoutineCardList({required this.routines, required this.userId, required this.constraints});
  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) return SizedBox.shrink();
    final isWideScreen = constraints.maxWidth > 600;
    if (routines.length == 1) {
      return SizedBox(
        height: 180,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _SmallRoutineCard(routine: routines.first, userId: userId),
          ],
        ),
      );
    }
    return SizedBox(
      height: isWideScreen ? 320 : 290,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingSmall),
        itemCount: routines.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: isWideScreen ? 300 : 320,
            child: Card(
              margin: EdgeInsets.all(AppTheme.paddingSmall),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              color: AppTheme.cardBackground,
              child: RoutineCard(
                key: ValueKey(routines[index].id),
                routine: routines[index],
                userId: userId,
                onTap: () => _showRoutineDetailBottomSheet(context, routines[index].id, userId),
              ),
            ),
          );
        },
      ),
    );
  }

  Future _showRoutineDetailBottomSheet(BuildContext context, int routineId, String userId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoutineDetailBottomSheet(
        routineId: routineId,
        userId: userId,
      ),
    );
  }
}

class _SmallRoutineCard extends StatelessWidget {
  final Routines routine;
  final String userId;
  const _SmallRoutineCard({required this.routine, required this.userId});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
        color: AppTheme.cardBackground,
        child: RoutineCard(
          key: ValueKey(routine.id),
          routine: routine,
          userId: userId,
          onTap: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => RoutineDetailBottomSheet(
                routineId: routine.id,
                userId: userId,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PartCardList extends StatelessWidget {
  final List<Parts> parts;
  final String userId;
  final BoxConstraints constraints;
  const _PartCardList({required this.parts, required this.userId, required this.constraints});
  @override
  Widget build(BuildContext context) {
    final isWideScreen = constraints.maxWidth > 600;
    return SizedBox(
      height: isWideScreen ? 280 : 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: parts.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: isWideScreen ? 220 : 240,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
              child: PartCard(
                part: parts[index],
                userId: userId,
                repository: context.read<PartRepository>(),
                onTap: () => _showPartDetailBottomSheet(context, parts[index].id, userId),
                onFavoriteChanged: (isFavorite) {/* favori değiştir */},
              ),
            ),
          );
        },
      ),
    );
  }

  Future _showPartDetailBottomSheet(BuildContext context, int partId, String userId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PartDetailBottomSheet(
        partId: partId,
        userId: userId,
      ),
    );
  }
}
