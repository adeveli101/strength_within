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
import 'package:logging/logging.dart';
import '../blocs/data_bloc_part/PartRepository.dart';
import '../blocs/data_bloc_part/part_bloc.dart';
import '../blocs/data_bloc_routine/routines_bloc.dart';
import '../models/sql_models/Parts.dart';
import '../models/sql_models/routines.dart';
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
  final List<int> _updatedPartIds = [];

  List<Routines> _randomRoutines = [];
  List<Parts> _randomParts = [];
  bool _isLoading = true;

  // AutomaticKeepAliveClientMixin için gerekli
  @override
  bool get wantKeepAlive => true;


  @override
  void initState() {
    super.initState();
    _setupLogging();
    _routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    _partsBloc = BlocProvider.of<PartsBloc>(context);
    _loadAllData(resetRandomParts: true);

  }


  void _setupLogging() {
    hierarchicalLoggingEnabled = true;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.loggerName}: ${record.level.name}: ${record.message}');
    });
  }



  void _loadAllData({bool resetRandomParts = false}) {
    if (_isLoading) return;
    _isLoading = true;

    _logger.info('Loading all data for user: ${widget.userId}');

    // Load data using BLoC events
    _partsBloc.add(FetchParts());
    _routinesBloc.add(FetchRoutines());

    // Reset random parts if needed
    if (resetRandomParts) {
      setState(() {
        _randomParts = [];
        _randomRoutines = [];
      });
    }
    // Handle updated parts
    else if (_updatedPartIds.isNotEmpty) {
      _reloadUpdatedParts();
      setState(() {
        _randomRoutines = [];
      });
    }

    // Reset loading state after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _isLoading = false;
    });
  }

  void _reloadUpdatedParts() {
    for (final partId in _updatedPartIds) {
      _partsBloc.add(FetchSinglePart(partId: partId));
    }
    _updatedPartIds.clear();
  }

  // ignore: unused_element
  void _updateRandomPartsFavoriteStatus(int partId, bool isFavorite) {
    setState(() {
      _randomParts = _randomParts.map((part) {
        if (part.id == partId) {
          return part.copyWith(isFavorite: isFavorite);
        }
        return part;
      }).toList();
    });
  }

  void _updateRoutineFavoriteStatus(int routineId, bool isFavorite) {
    setState(() {
      _randomRoutines = _randomRoutines.map((routine) {
        if (routine.id == routineId) {
          return routine.copyWith(
            isFavorite: isFavorite,
          );
        }
        return routine;
      }).toList();
    });
  }


  @override
  void dispose() {
    _routinesBloc.close();
    _partsBloc.close();
    super.dispose();
  }
  void _handleError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTheme.bodySmall,
        ),
        backgroundColor: AppTheme.errorRed.withOpacity(AppTheme.primaryOpacity),
        duration: AppTheme.normalAnimation,
      ),
    );

    // Otomatik yenileme
    Future.delayed(AppTheme.quickAnimation, () {
      _loadAllData(resetRandomParts: true);
    });
  }




  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için
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
               _loadAllData();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: WelcomeHeader(),
                ),
                SliverToBoxAdapter(
                  child: _buildParts(constraints),
                ),
                SliverToBoxAdapter(
                  child: _buildRoutines(constraints),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParts(BoxConstraints constraints) {
    return BlocConsumer<PartsBloc, PartsState>(
      listener: (context, state) {
        if (state is PartsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.primaryRed.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PartsLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (state is PartsLoaded) {
          final parts = state.parts;
          final startedParts = parts.where((p) => p.lastUsedDate != null).toList()
            ..sort((a, b) => (b.lastUsedDate ?? DateTime(0)).compareTo(a.lastUsedDate ?? DateTime(0)));

          return AnimatedOpacity(
            duration: AppTheme.quickAnimation,
            opacity: 1.0,
            child: Column(
              children: [
                if (startedParts.isNotEmpty) ...[
                  _buildPartList('Devam Eden Antrenmanlar', startedParts, constraints),
                  SizedBox(height: AppTheme.paddingMedium),
                ],
                _buildPartList('Keşfet', _getRandomParts(parts), constraints, showAllButton: true),
              ],
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.primaryRed),
              SizedBox(height: AppTheme.paddingSmall),
              Text(
                'Veriler yüklenirken bir hata oluştu',
                style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPartList(String title, List<Parts> parts, BoxConstraints constraints, {bool showAllButton = false}) {
    final isWideScreen = constraints.maxWidth > AppTheme.tabletBreakpoint;

    return Container(
      margin: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.paddingMedium,
              vertical: AppTheme.paddingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: isWideScreen ? AppTheme.headingMedium : AppTheme.headingSmall,
                ),
                if (showAllButton)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PartsPage(userId: widget.userId),
                        ),
                      );
                    },
                    icon: Text(
                      'Hepsini Gör',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    label: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.primaryRed,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: isWideScreen ? 280 : 230,
            child: PartCard.buildPartCardList(
              parts: parts,
              userId: widget.userId,
              repository: context.read<PartRepository>(),
              onTap: _showPartDetailBottomSheet,
              onFavoriteChanged: (isFavorite, partId) {
                setState(() {
                  final index = _randomParts.indexWhere((p) => p.id.toString() == partId);
                  if (index != -1) {
                    _randomParts[index] = _randomParts[index].copyWith(isFavorite: isFavorite);
                  }
                });
              },
              scrollController: ScrollController(),
              isGridView: false,
            ),
          ),
        ],
      ),
    );
  }

  List<Parts> _getRandomParts(List<Parts> parts) {
    if (_randomParts.isEmpty && parts.isNotEmpty) {
      final shuffledParts = List<Parts>.from(parts)..shuffle();
      _randomParts = shuffledParts.take(5).toList();
    }
    return _randomParts;
  }

  Future<void> _showPartDetailBottomSheet(int partId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PartDetailBottomSheet(
        partId: partId,
        userId: widget.userId,
      ),
    );
    // Bottom sheet kapandıktan sonra verileri yeniden yükle
    _loadAllData();
  }

  Widget _buildRoutines(BoxConstraints constraints) {
    return BlocConsumer<RoutinesBloc, RoutinesState>(
      listener: (context, state) {
        if (state is RoutinesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.primaryRed.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is RoutinesLoading) {
          return Center(
            child: LoadingAnimationWidget.newtonCradle(
              color: AppTheme.primaryRed,
              size: 50,
            ),
          );
        }

        if (state is RoutinesLoaded) {
          final List routines = state.routines;
          if (routines.isEmpty) {
            return _buildEmptyRoutinesMessage(constraints);
          }

          final List startedRoutines = routines
              .where((r) => r.lastUsedDate != null)
              .toList()
            ..sort((a, b) => (b.lastUsedDate ?? DateTime(0))
                .compareTo(a.lastUsedDate ?? DateTime(0)));

          return AnimatedOpacity(
            duration: AppTheme.quickAnimation,
            opacity: 1.0,
            child: Column(
              children: [
                if (startedRoutines.isNotEmpty) ...[
                  _buildRoutineList('Devam Eden Rutinler', startedRoutines, constraints),
                  SizedBox(height: AppTheme.paddingMedium),
                ],
                _buildRoutineList(
                  'Önerilen Rutinler',
                  _getRandomRoutines(routines),
                  constraints,
                  showAllButton: true,
                ),
              ],
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.primaryRed),
              SizedBox(height: AppTheme.paddingSmall),
              Text(
                'Rutinler yüklenirken bir hata oluştu',
                style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoutineList(String title, List routines, BoxConstraints constraints, {bool showAllButton = false}) {
    final isWideScreen = constraints.maxWidth > AppTheme.tabletBreakpoint;

    return Container(
      margin: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.paddingSmall,
              vertical: AppTheme.paddingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: isWideScreen ? AppTheme.headingMedium : AppTheme.headingSmall,
                ),
                if (showAllButton)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoutinesPage(userId: widget.userId),
                        ),
                      );
                    },
                    icon: Text(
                      'Hepsini Gör',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    label: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.primaryRed,
                    ),
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
                  child: _buildRoutineCard(routines[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRoutineCard(Routines routine) {
    return Card(
      margin: EdgeInsets.all(AppTheme.paddingSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      color: AppTheme.cardBackground,
      child: RoutineCard(
        key: ValueKey(routine.id),
        routine: routine,
        userId: widget.userId,
        onTap: () => _showRoutineDetailBottomSheet(routine.id),
      ),
    );
  }


  Future _showRoutineDetailBottomSheet(int routineId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoutineDetailBottomSheet(
        routineId: routineId,
        userId: widget.userId,
      ),
    );
  }

  Widget _buildEmptyRoutinesMessage(BoxConstraints constraints) {
    final isWideScreen = constraints.maxWidth > AppTheme.tabletBreakpoint;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: isWideScreen ? 100 : 80, color: AppTheme.primaryRed),
          SizedBox(height: AppTheme.paddingMedium),
          Text(
            'Henüz rutin bulunmamaktadır.',
            style: isWideScreen ? AppTheme.headingMedium : AppTheme.headingSmall,
          ),
          SizedBox(height: AppTheme.paddingMedium),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium, vertical: AppTheme.paddingSmall),
            ),
            onPressed: () {
              // Rutin ekleme sayfasına yönlendir
            },
            child: Text('Rutin Ekle'),
          ),
        ],
      ),
    );
  }

  List<Routines> _getRandomRoutines(List<dynamic> routines) {
    if (_randomRoutines.isEmpty) {
      if (routines.isEmpty) return [];

      final randomRoutines = List<Routines>.from(routines);
      randomRoutines.shuffle();
      _randomRoutines = randomRoutines.take(6).toList();
      return _randomRoutines.cast<Routines>();
    }
    return _randomRoutines.cast<Routines>();
  }
}
