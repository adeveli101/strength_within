import 'package:flutter/material.dart';
import 'package:workout/ui/routine_edit_page.dart';
import '../controllers/routines_bloc.dart';
import '../models/routine.dart';
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

  @override
  void initState() {
    super.initState();
    routinesBloc.fetchAllRoutines();
    scrollController.addListener(_scrollListener);
    _listenToRoutines();
  }

  @override
  void dispose() {
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

  List<Routine> _filterRoutines(List<Routine> routines) {
    if (selectedParts.isEmpty) {
      return routines;
    }
    return routines.where((routine) =>
        selectedParts.contains(routine.mainTargetedBodyPart)).toList();
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi,',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.normal)),
            Text(_getGreeting(),
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Implement settings functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Categories',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              buildFilterOptions(),
              SizedBox(height: 24),
              Text('Önerilen Rutinler',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Container(
                height: 180,
                child: buildRoutineList(isRecommended: true),
              ),
              SizedBox(height: 24),
              buildRoutineList(isRecommended: false),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFE91E63),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _showAddRoutineBottomSheet,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: Color(0xFFE91E63),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget buildFilterOptions() {
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: MainTargetedBodyPart.values.length,
        itemBuilder: (context, index) {
          final part = MainTargetedBodyPart.values[index];
          final isSelected = selectedParts.contains(part);
          final label = part.toString().split('.').last.capitalize();

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) => _togglePartSelection(part),
              backgroundColor: Color(0xFF2C2C2C),
              selectedColor: Color(0xFFE91E63),
              labelStyle: TextStyle(color: Colors.white, fontSize: 12),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          );
        },
      ),
    );
  }

  Widget buildRoutineList({bool isRecommended = false}) {
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

        List<Routine> routines = isRecommended
            ? snapshot.data!.where((r) => r.isRecommended).take(3).toList()
            : _filterRoutines(snapshot.data!);

        return ListView.builder(
          scrollDirection: isRecommended ? Axis.horizontal : Axis.vertical,
          itemCount: routines.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(right: isRecommended ? 16 : 0, bottom: isRecommended ? 0 : 16),
              child: RoutineCard(
                routine: routines[index],
                isRecRoutine: isRecommended,
                isSmall: isRecommended,
              ),
            );
          },
        );
      },
    );
  }

  void _togglePartSelection(MainTargetedBodyPart part) {
    setState(() {
      if (selectedParts.contains(part)) {
        selectedParts.remove(part);
      } else {
        selectedParts.clear();
        selectedParts.add(part);
      }
    });
  }

  void _showAddRoutineBottomSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineEditPage(
          addOrEdit: AddOrEdit.add,
          mainTargetedBodyPart: MainTargetedBodyPart.fullBody,
          routine: Routine(
            id: DateTime.now().millisecondsSinceEpoch,
            name: 'New Routine',
            mainTargetedBodyPart: MainTargetedBodyPart.fullBody,
            partIds: [],
            createdDate: DateTime.now(),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}