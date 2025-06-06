// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:strength_within/ui/routine_ui/routine_detail.dart';
import 'package:logging/logging.dart';
import '../../blocs/data_bloc_routine/routines_bloc.dart';
import '../../models/sql_models/routines.dart';
import '../routine_ui/routine_card.dart';

class RoutinesPage extends StatefulWidget {
  final String userId;

  const RoutinesPage({super.key, required this.userId});

  @override
  _RoutinesPageState createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage> {
  late RoutinesBloc _routinesBloc;
  final _logger = Logger('RoutinesPage');
  String? _selectedDifficulty;
  List<Map<String, dynamic>> difficultyFilterOptions = [];
  // ignore: prefer_final_fields
  bool _isListView = false;
  int _currentWorkoutTypeIndex = 0;
  final PageController _pageController = PageController();
  late ScrollController _chipScrollController;

  @override
  void initState() {
    super.initState();
    _chipScrollController = ScrollController();
    _setupLogging();
    _routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    _loadAllData();
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _chipScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _setupLogging() {
    hierarchicalLoggingEnabled = true;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.loggerName}: ${record.level.name}: ${record.message}');
    });
  }

  void _loadAllData() {
    _logger.info('Loading all routines for user: \\${widget.userId}');
    _routinesBloc.add(FetchRoutines());
    setState(() {
      _selectedDifficulty = null;
      _currentWorkoutTypeIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  Future<void> _loadFilterOptions() async {
    List<Routines> allParts = await _routinesBloc.repository.getAllRoutines();
    Set<String> uniqueDifficulties = allParts.map((part) => part.difficulty.toString()).toSet();
    setState(() {
      difficultyFilterOptions = buildDifficultyFilter(uniqueDifficulties.toList())
        ..sort((a, b) => int.parse(a['value']).compareTo(int.parse(b['value'])));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Rutinler', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[850],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: BlocBuilder<RoutinesBloc, RoutinesState>(
        builder: (context, state) {
          if (state is RoutinesLoading) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.white,
                size: 50,
              ),
            );
          } else if (state is RoutinesLoaded) {
            return _buildRoutinesContent(state.routines);
          } else if (state is RoutinesError) {
            return _buildErrorWidget(state.message);
          } else {
            return _buildUnknownStateWidget();
          }
        },
      ),
    );
  }

  Widget _buildRoutinesContent(List<Routines> routines) {
    List<Routines> filteredRoutines = _filterRoutines(routines);
    List<Map<String, dynamic>> workoutTypes = _getWorkoutTypes();
    return Column(
      children: [
        _buildDifficultyFilter(),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  key: const PageStorageKey('workoutTypePageView'),
                  controller: _pageController,
                  itemCount: workoutTypes.length,
                  physics: const BouncingScrollPhysics(),
                  pageSnapping: true,
                  onPageChanged: (index) {
                    setState(() {
                      _currentWorkoutTypeIndex = index;
                    });
                    _scrollToChip(index);
                  },
                  itemBuilder: (context, index) {
                    final workoutType = workoutTypes[index];
                    return KeyedSubtree(
                      key: ValueKey(workoutType['id']),
                      child: Column(
                        children: [
                          _buildWorkoutTypeTabs(workoutTypes),
                          Expanded(
                            child: _buildWorkoutTypeSection(workoutType['id'], workoutType['name'], filteredRoutines),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _buildPageIndicator(workoutTypes.length),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutTypeTabs(List<Map<String, dynamic>> workoutTypes) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: _chipScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: workoutTypes.length,
        itemBuilder: (context, index) {
          final workoutType = workoutTypes[index];
          final isSelected = index == _currentWorkoutTypeIndex;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
              );
              _scrollToChip(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 18 : 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepOrangeAccent : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.deepOrangeAccent.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 2))]
                    : [],
              ),
              child: Center(
                child: Text(
                  workoutType['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSelected ? 16 : 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDifficultyFilter() {
    // Difficulty'leri sırala
    List<Map<String, dynamic>> sortedDifficulties = List.from(difficultyFilterOptions)
      ..sort((a, b) => int.parse(a['value']).compareTo(int.parse(b['value'])));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.grey[850],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: const Icon(Icons.all_inbox, color: Colors.white, size: 15),
              selected: _selectedDifficulty == null,
              onSelected: (selected) {
                setState(() {
                  _selectedDifficulty = null;
                  _currentWorkoutTypeIndex = 0;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(0);
                  }
                });
              },
            ),
            ...sortedDifficulties.map((difficulty) => _buildFilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    color: index < int.parse(difficulty['value']) ? Colors.yellow : Colors.grey,
                    size: 12,
                  );
                }),
              ),
              selected: _selectedDifficulty == difficulty['value'],
              onSelected: (selected) {
                setState(() {
                  _selectedDifficulty = selected ? difficulty['value'] : null;
                  _currentWorkoutTypeIndex = 0;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(0);
                  }
                });
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutTypeSection(int workoutTypeId, String workoutTypeName, List<Routines> filteredRoutines) {
    final workoutTypeRoutines = filteredRoutines.where((routine) => routine.workoutTypeId == workoutTypeId).toList();
    if (workoutTypeRoutines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Bu antrenman türü için rutin bulunamadı.', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    workoutTypeName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right_alt, color: Colors.white),
                    onPressed: () {
                      int nextIndex = (_currentWorkoutTypeIndex + 1) % _getWorkoutTypes().length;
                      _pageController.animateToPage(
                        nextIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildCardView(workoutTypeRoutines),
        ),
      ],
    );
  }

  Widget _buildCardView(List<Routines> routines) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      itemCount: routines.length,
      itemBuilder: (context, index) {
        final routine = routines[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.grey[850],
          child: RoutineCard(
            key: ValueKey(routine.id),
            routine: routine,
            userId: widget.userId,
            onTap: () => _showRoutineDetailBottomSheet(routine.id),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({required Widget label, required bool selected, required Function(bool) onSelected}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: label,
        selected: selected,
        onSelected: onSelected,
        backgroundColor: Colors.grey[800],
        selectedColor: Colors.blue.withOpacity(0.2),
        checkmarkColor: Colors.white,
      ),
    );
  }

  List<Map<String, dynamic>> buildDifficultyFilter(List<String> difficulties) {
    return difficulties.map((difficulty) => {'value': difficulty, 'child': 'Difficulty $difficulty'}).toList();
  }

  List<Routines> _filterRoutines(List<Routines> routines) {
    return routines.where((routine) {
      return _selectedDifficulty == null || routine.difficulty.toString() == _selectedDifficulty;
    }).toList();
  }

  Future<void> _showRoutineDetailBottomSheet(int routineId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoutineDetailBottomSheet(routineId: routineId, userId: widget.userId),
    );
    _loadAllData();
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 16),
          Text('Hata: $message', style: TextStyle(fontSize: 18, color: Colors.white), textAlign: TextAlign.center),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _loadAllData, child: Text('Tekrar Dene')),
        ],
      ),
    );
  }

  Widget _buildUnknownStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
          SizedBox(height: 16),
          Text('Bilinmeyen durum', style: TextStyle(fontSize: 18, color: Colors.white)),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _loadAllData, child: Text('Yenile')),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getWorkoutTypes() {
    return [
      {'id': 1, 'name': 'Kuvvet'},
      {'id': 2, 'name': 'Hypertrophy'},
      {'id': 3, 'name': 'Endurance'},
      {'id': 4, 'name': 'Power'},
      {'id': 5, 'name': 'Flexibility'},
    ];
  }

  Widget _buildPageIndicator(int pageCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _currentWorkoutTypeIndex == index ? 16 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentWorkoutTypeIndex == index ? Colors.blue : Colors.grey,
              boxShadow: _currentWorkoutTypeIndex == index
                  ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 6, offset: Offset(0, 2))]
                  : [],
            ),
          );
        }),
      ),
    );
  }

  void _scrollToChip(int index) {
    // Her chip'in genişliği yaklaşık 90px (padding ve margin ile birlikte)
    double chipWidth = 90.0;
    double offset = (index * chipWidth) - (MediaQuery.of(context).size.width / 2) + (chipWidth / 2);
    if (offset < 0) offset = 0;
    _chipScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }
}
