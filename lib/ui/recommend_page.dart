import 'package:flutter/material.dart';
import '../resource/routines_bloc.dart';
import '../models/routine.dart';
import '../utils/routine_helpers.dart';
import 'components/routine_card.dart';

class RecommendPage extends StatefulWidget {
  @override
  _RecommendPageState createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final scrollController = ScrollController();
  bool showShadow = false;
  List<MainTargetedBodyPart> selectedParts = [];
  List<Routine> filteredRoutines = [];

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
    _loadRecommendedRoutines();
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

  void _loadRecommendedRoutines() async {
    final recommendedRoutines = await routinesBloc.getRecommendedRoutines();
    setState(() {
      filteredRoutines = recommendedRoutines;
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
        title: Text("Önerilen Rutinler"),
        backgroundColor: Colors.transparent,
        elevation: showShadow ? 4 : 0,
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _buildRecommendedRoutinesList(),
          ),
        ],
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
                  filteredRoutines = _filterRoutines(filteredRoutines);
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

  Widget _buildRecommendedRoutinesList() {
    if (filteredRoutines.isEmpty) {
      return Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: filteredRoutines.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: RoutineCard(
            routine: filteredRoutines[index],
            isRecRoutine: true,
            isSmall: false,
            onFavoriteToggle: () {
              routinesBloc.toggleRoutineFavorite(filteredRoutines[index].id);
            },
          ),
        );
      },
    );
  }
}
