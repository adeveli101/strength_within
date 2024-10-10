import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workout/models/routine.dart';
import 'package:workout/ui/components/routine_card.dart';

class CalendarPage extends StatelessWidget {
  final List<Routine> routines;

  const CalendarPage({super.key, required this.routines});

  @override
  Widget build(BuildContext context) {
    return CalendarPageContent(routines: routines);
  }
}

class CalendarPageContent extends StatefulWidget {
  final List<Routine> routines;

  const CalendarPageContent({super.key, required this.routines});

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
    _dateToRoutineMap = _getWorkoutDates(widget.routines);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _changeMonth(-1);
        } else if (details.primaryVelocity! < 0) {
          _changeMonth(1);
        }
      },
      child: Column(
        children: [
          _buildMonthHeader(),
          Expanded(child: _buildCalendarGrid()),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_selectedDate),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
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

    return Material(
      elevation: 1,
      child: InkWell(
        onTap: isWorkout ? () => _showBottomSheet(_dateToRoutineMap[dateStr]!) : null,
        child: Container(
          decoration: BoxDecoration(
            color: isWorkout ? Colors.grey[300] : Colors.transparent,
            border: Border.all(color: Colors.grey[400]!, width: 0.5),
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: isWorkout ? Colors.black : Colors.grey[600],
                fontWeight: isWorkout ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _changeMonth(int months) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + months, 1);
    });
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

  Map<String, Routine> _getWorkoutDates(List<Routine> routines) {
    final Map<String, Routine> dates = {};
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (var routine in routines) {
      for (var timestamp in routine.routineHistory) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
        dates[dateFormat.format(date)] = routine;
      }
    }

    return dates;
  }
}
