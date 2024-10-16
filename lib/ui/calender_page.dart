import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/resource/routines_bloc.dart';
import 'package:workout/firebase_class/firebase_routines.dart';

class CalendarPage extends StatelessWidget {
  final RoutinesBloc routinesBloc;

  const CalendarPage({Key? key, required this.routinesBloc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: SafeArea(
        child: CalendarPageContent(routinesBloc: routinesBloc),
      ),
    );
  }
}

class CalendarPageContent extends StatefulWidget {
  final RoutinesBloc routinesBloc;

  const CalendarPageContent({Key? key, required this.routinesBloc}) : super(key: key);

  @override
  State<CalendarPageContent> createState() => _CalendarPageContentState();
}

class _CalendarPageContentState extends State<CalendarPageContent> {
  late DateTime _selectedDate;
  Map<String, FirebaseRoutine> _dateToRoutineMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadWorkoutDates();
  }

  Future<void> _loadWorkoutDates() async {
    final userId = await widget.routinesBloc.getUserId();
    if (userId != null) {
      final allRoutines = await widget.routinesBloc.allRoutines.first;
      _dateToRoutineMap = await _getWorkoutDates(allRoutines.cast<FirebaseRoutine>());
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi,',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              Text(
                'Good Evening',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        _buildMonthHeader(),
        Expanded(child: _buildCalendarGrid()),
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => _changeMonth(-1),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        return _buildDayCell(index);
      },
    );
  }

  Widget _buildDayCell(int index) {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final dayOffset = firstDayOfMonth.weekday - 1;
    final day = index - dayOffset + 1;
    if (day < 1 || day > DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day) {
      return Container();
    }

    final date = DateTime(_selectedDate.year, _selectedDate.month, day);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final isWorkout = _dateToRoutineMap.containsKey(dateStr);

    return Container(
      decoration: BoxDecoration(
        color: isWorkout ? Color(0xFFE91E63) : Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            color: Colors.white,
            fontWeight: isWorkout ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _changeMonth(int months) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + months, 1);
    });
    _loadWorkoutDates();
  }

  Future<Map<String, FirebaseRoutine>> _getWorkoutDates(List<FirebaseRoutine> routines) async {
    final Map<String, FirebaseRoutine> dates = {};
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (var routine in routines) {
      if (routine.lastUsedDate != null) {
        final dateStr = dateFormat.format(routine.lastUsedDate!);
        dates[dateStr] = routine;
      }
    }

    return dates;
  }
}
