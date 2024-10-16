import 'package:flutter/material.dart';
import '../models/BodyPart.dart';
import '../models/WorkoutType.dart';
import '../models/routines.dart';
import '../resource/routines_bloc.dart';
import '../utils/routine_helpers.dart';
import 'routine_ui/routine_card.dart';
import '../firebase_class/firebase_routines.dart';

class HomePage extends StatefulWidget {
  final RoutinesBloc routinesBloc;

  HomePage({required this.routinesBloc});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final scrollController = ScrollController();
  bool showShadow = false;
  MainTargetedBodyPart? selectedBodyPart;
  WorkoutType? selectedWorkoutType;
  List<FirebaseRoutine> filteredRoutines = [];
  bool showRecommended = true;


  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.routinesBloc.initialize();
    scrollController.addListener(_scrollListener);
    _listenToRoutines();
    _checkShowRecommended();

    searchController.addListener(_onSearchChanged);

  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();

    searchController.removeListener(_onSearchChanged);
    searchController.dispose();

    super.dispose();
  }


  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text;
    });
  }



  void _scrollListener() {
    if (mounted) {
      setState(() {
        showShadow = scrollController.offset > 0;
      });
    }
  }

  void _listenToRoutines() {
    widget.routinesBloc.allRoutines.listen((routines) {
      if (mounted) {
        setState(() {
          filteredRoutines = _filterRoutines(routines.cast<FirebaseRoutine>());
        });
      }
    });
  }

  void _checkShowRecommended() async {
    bool hasStarted = await widget.routinesBloc.hasStartedAnyRoutine();
    setState(() {
      showRecommended = !hasStarted;
    });
  }

  List<FirebaseRoutine> _filterRoutines(List<FirebaseRoutine> routines) {
    return routines.where((routine) =>
    (selectedBodyPart == null || routine.routine.mainTargetedBodyPart == selectedBodyPart) &&
        (selectedWorkoutType == null || routine.routine.workoutType == selectedWorkoutType) &&
        (searchQuery.isEmpty || routine.routine.name.toLowerCase().contains(searchQuery.toLowerCase()))
    ).toList();
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
          _buildSearchBar(),
          _buildFilters(),
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



  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search routines...',
          hintStyle: TextStyle(color: Colors.white54),
          prefixIcon: Icon(Icons.search, color: Colors.white54),
          filled: true,
          fillColor: Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }



  Widget _buildFilters() {
    return Container(
      height: 150,
      child: Column(
        children: [
          _buildFilterRow('Body Part', MainTargetedBodyPart.values, selectedBodyPart, (value) {
            setState(() {
              selectedBodyPart = (selectedBodyPart == value) ? null : value;
              widget.routinesBloc.fetchAllRoutines();
            });
          }),
          FutureBuilder<List<WorkoutType>>(
            future: widget.routinesBloc.getAllWorkoutTypes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('No workout types available');
              } else {
                return _buildFilterRow('Workout Type', snapshot.data!, selectedWorkoutType, (value) {
                  setState(() {
                    selectedWorkoutType = (selectedWorkoutType == value) ? null : value;
                    widget.routinesBloc.fetchAllRoutines();
                  });
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow<T>(String title, List<T> values, T? selectedValue, Function(T?) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, top: 8),
          child: Text(title, style: TextStyle(color: Colors.white70)),
        ),
        Container(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: values.length,
            itemBuilder: (context, index) {
              final value = values[index];
              final isSelected = value == selectedValue;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: ChoiceChip(
                  label: Text(value is MainTargetedBodyPart
                      ? mainTargetedBodyPartToStringConverter(value)
                      : (value as WorkoutType).name),
                  selected: isSelected,
                  onSelected: (_) => onSelected(value),
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
        ),
      ],
    );
  }

  Widget _buildRoutineList() {
    return StreamBuilder<List<Routine>>(
      stream: widget.routinesBloc.allRoutines,
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

        List<FirebaseRoutine> routines = _filterRoutines(snapshot.data!.cast<FirebaseRoutine>());
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
                firebaseRoutine: routines[routineIndex],
                routinesBloc: widget.routinesBloc,
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
          child: FutureBuilder<List<FirebaseRoutine>>(
            future: widget.routinesBloc.getRecommendedRoutines(),
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
                        firebaseRoutine: snapshot.data![index],
                        routinesBloc: widget.routinesBloc,
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
    // Implement the add routine functionality
  }
}






  void _showAddRoutineBottomSheet() {
    // Implement the add routine functionality
  }

