import 'package:flutter/material.dart';
import '../resource/routines_bloc.dart';
import '../models/routines.dart';
import '../models/BodyPart.dart';
import 'routine_ui/routine_card.dart';
import '../firebase_class/firebase_routines.dart';

class RecommendPage extends StatefulWidget {
  final RoutinesBloc routinesBloc;

  RecommendPage({required this.routinesBloc});

  @override
  _RecommendPageState createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final scrollController = ScrollController();
  bool showShadow = false;
  List<MainTargetedBodyPart> selectedBodyParts = [];

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
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
          _buildBodyPartFilter(),
          Expanded(
            child: _buildRecommendedRoutinesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPartFilter() {
    return FutureBuilder<List<BodyPart>>(
      future: widget.routinesBloc.getAllBodyParts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        List<BodyPart> bodyParts = snapshot.data!;
        return Container(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: bodyParts.length,
            itemBuilder: (context, index) {
              final bodyPart = bodyParts[index];
              final isSelected = selectedBodyParts.contains(bodyPart.mainTargetedBodyPartString);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: ChoiceChip(
                  label: Text(bodyPart.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedBodyParts.add(MainTargetedBodyPart.values.firstWhere((e) => e.name == bodyPart.mainTargetedBodyPartString));
                      } else {
                        selectedBodyParts.remove(MainTargetedBodyPart.values.firstWhere((e) => e.name == bodyPart.mainTargetedBodyPartString));
                      }
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
      },
    );
  }

  Widget _buildRecommendedRoutinesList() {
    return StreamBuilder<List<Routine>>(
      stream: widget.routinesBloc.allRecRoutines,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
        }

        List<Routine> routines = snapshot.data!;
        List<Routine> filteredRoutines = selectedBodyParts.isEmpty
            ? routines
            : routines.where((r) => selectedBodyParts.contains(r.mainTargetedBodyPart)).toList();

        return ListView.builder(
          controller: scrollController,
          itemCount: filteredRoutines.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: RoutineCard(
                firebaseRoutine: FirebaseRoutine.fromRoutine(filteredRoutines[index]),
                routinesBloc: widget.routinesBloc,
              ),
            );
          },
        );
      },
    );
  }
}
