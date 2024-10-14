import 'package:flutter/material.dart';
import 'package:workout/ui/routine_edit_page.dart';
import '../models/routine.dart';
import '../resource/routines_bloc.dart';
import '../utils/routine_helpers.dart';
import 'components/routine_card.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final scrollController = ScrollController();
  bool showShadow = false;
  List<MainTargetedBodyPart> selectedParts = [];
  List<Routine> filteredRoutines = [];
  bool showRecommended = true;

  @override
  void initState() {
    super.initState();
    routinesBloc.initialize();
    scrollController.addListener(_scrollListener);
    _listenToRoutines();
    _checkShowRecommended();
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (mounted) {
      setState(() {
        showShadow = scrollController.offset > 0;
      });
    }
  }

  void _listenToRoutines() {
    routinesBloc.allRoutines.listen((routines) {
      if (mounted) {
        setState(() {
          filteredRoutines = _filterRoutines(routines);
        });
      }
    });
  }

  void _checkShowRecommended() async {
    bool hasStarted = await routinesBloc.hasStartedAnyRoutine();
    setState(() {
      showRecommended = !hasStarted;
    });
  }

  List<Routine> _filterRoutines(List<Routine> routines) {
    if (selectedParts.isEmpty) {
      return routines;
    }
    return routines.where((routine) =>
        selectedParts.contains(routine.mainTargetedBodyPart)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        elevation: showShadow ? 4 : 0,
        backgroundColor: Colors.transparent,
        title: Text('My Routines', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _buildRoutineList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFE91E63),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _showAddRoutineBottomSheet,
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: MainTargetedBodyPart.values.length,
        itemBuilder: (context, index) {
          final part = MainTargetedBodyPart.values[index];
          final isSelected = selectedParts.contains(part);
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: ChoiceChip(
              label: Text(mainTargetedBodyPartToStringConverter(part)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedParts.add(part);
                  } else {
                    selectedParts.remove(part);
                  }
                  routinesBloc.fetchAllRoutines();
                });
              },
              backgroundColor: Color(0xFF2C2C2C),
              selectedColor: Color(0xFFE91E63),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoutineList() {
    return StreamBuilder<List<Routine>>(
      stream: routinesBloc.allRoutines,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading routines', style: TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No routines available', style: TextStyle(color: Colors.white)));
        }
        List<Routine> routines = _filterRoutines(snapshot.data!);
        return ListView.builder(
          controller: scrollController,
          itemCount: routines.length + (showRecommended ? 1 : 0),
          itemBuilder: (context, index) {
            if (showRecommended && index == 0) {
              return _buildRecommendedSection();
            }
            final routineIndex = showRecommended ? index - 1 : index;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: RoutineCard(
                routine: routines[routineIndex],
                isRecRoutine: false,
                isSmall: false,
                onFavoriteToggle: () => routinesBloc.toggleRoutineFavorite(routines[routineIndex].id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Recommended Routines',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          height: 180,
          child: FutureBuilder<List<Routine>>(
            future: routinesBloc.getRecommendedRoutines(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No recommended routines', style: TextStyle(color: Colors.white70)));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(left: 16, right: index == snapshot.data!.length - 1 ? 16 : 0),
                    child: SizedBox(
                      width: 140,
                      child: RoutineCard(
                        routine: snapshot.data![index],
                        isRecRoutine: true,
                        isSmall: true,
                        onFavoriteToggle: () => routinesBloc.toggleRoutineFavorite(snapshot.data![index].id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddRoutineBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: RoutineEditPage(
          routine: Routine(
            id: DateTime.now().millisecondsSinceEpoch,
            name: '',
            mainTargetedBodyPart: MainTargetedBodyPart.fullBody,
            partIds: [],
            isRecommended: false,
            difficulty: 1,
            estimatedTime: 30,
          ),
        ),
      ),
    );
  }

}
