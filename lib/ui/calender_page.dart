import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workout/models/routine.dart';
import 'package:workout/ui/components/routine_card.dart';
import 'package:workout/resource/db_provider.dart';

class CalendarPage extends StatelessWidget {
  final List<Routine> routines;

  const CalendarPage({Key? key, required this.routines}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: SafeArea(
        child: CalendarPageContent(routines: routines),
      ),
    );
  }
}

class CalendarPageContent extends StatefulWidget {
  final List<Routine> routines;

  const CalendarPageContent({Key? key, required this.routines}) : super(key: key);

  @override
  State<CalendarPageContent> createState() => _CalendarPageContentState();
}

class _CalendarPageContentState extends State<CalendarPageContent> {
  late DateTime _selectedDate;
  late Map<String, Routine> _dateToRoutineMap;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadWorkoutDates();
  }

  Future<void> _loadWorkoutDates() async {
    _dateToRoutineMap = await _getWorkoutDates(widget.routines);
    setState(() {});
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

  void _showBottomSheet(Routine routine) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              color: Colors.transparent,
              width: MediaQuery.of(context).size.width,
              child: RoutineCard(routine: routine),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, Routine>> _getWorkoutDates(List<Routine> routines) async {
    final Map<String, Routine> dates = {};
    final dateFormat = DateFormat('yyyy-MM-dd');
    final db = await DBProvider.db.database;

    for (var routine in routines) {
      final routineHistory = await db.query('RoutineHistory',
          where: 'routineId = ?', whereArgs: [routine.id]);

      for (var history in routineHistory) {
        final date = DateTime.fromMillisecondsSinceEpoch(history['completedDate'] as int).toLocal();
        dates[dateFormat.format(date)] = routine;
      }
    }

    return dates;
  }
}
