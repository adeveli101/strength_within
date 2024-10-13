import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/RoutineHistory.dart';
import '../../models/routine.dart';
import '../../resource/db_provider.dart';
import '../controllers/routines_bloc.dart';
import '../../resource/shared_prefs_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Future<int> _dailyRankFuture;
  late Future<List<RoutineHistory>> _routineHistoryFuture;

  @override
  void initState() {
    super.initState();
    _dailyRankFuture = sharedPrefsProvider.getDailyRank();
    _routineHistoryFuture = DBProvider.db.getAllRoutineHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi,',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                Text(
                  'Statistics',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                _buildStatCards(),
                SizedBox(height: 24),
                _buildWorkoutChart(),
                SizedBox(height: 24),
                Text(
                  'Routine Statistics',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _buildRoutineStatsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDailyRankCard()),
            SizedBox(width: 16),
            Expanded(child: _buildTotalWorkoutsCard()),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildLastWorkoutCard()),
            SizedBox(width: 16),
            Expanded(child: _buildMostUsedRoutineCard()),
          ],
        ),
        SizedBox(height: 16),
        _buildWeeklyProgressCard(),
      ],
    );
  }

  Widget _buildDailyRankCard() {
    return FutureBuilder<int>(
      future: _dailyRankFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard('Daily Rank', 'Loading...', Icons.emoji_events);
        }
        if (snapshot.hasError) {
          return _buildStatCard('Daily Rank', 'Error', Icons.error);
        }
        final rank = snapshot.data ?? 0;
        return _buildStatCard('Daily Rank', rank.toString(), Icons.emoji_events);
      },
    );
  }

  Widget _buildTotalWorkoutsCard() {
    return FutureBuilder<List<RoutineHistory>>(
      future: _routineHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard('Total Workouts', 'Loading...', Icons.fitness_center);
        }
        if (snapshot.hasError) {
          return _buildStatCard('Total Workouts', 'Error', Icons.error);
        }
        final totalWorkouts = snapshot.data?.length ?? 0;
        return _buildStatCard('Total Workouts', totalWorkouts.toString(), Icons.fitness_center);
      },
    );
  }

  Widget _buildLastWorkoutCard() {
    return FutureBuilder<List<RoutineHistory>>(
      future: _routineHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard('Last Workout', 'Loading...', Icons.access_time);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildStatCard('Last Workout', 'No data', Icons.access_time);
        }
        final lastWorkout = snapshot.data!.last.completedDate;
        final formattedDate = DateFormat('dd/MM/yyyy').format(lastWorkout);
        return _buildStatCard('Last Workout', formattedDate, Icons.access_time);
      },
    );
  }

  Widget _buildMostUsedRoutineCard() {
    return FutureBuilder<List<RoutineHistory>>(
      future: _routineHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard('Most Used Routine', 'Loading...', Icons.star);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildStatCard('Most Used Routine', 'No data', Icons.star);
        }
        final routineCounts = <int, int>{};
        for (var history in snapshot.data!) {
          routineCounts[history.routineId] = (routineCounts[history.routineId] ?? 0) + 1;
        }
        final mostUsedRoutineId = routineCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        return StreamBuilder<List<Routine>>(
          stream: routinesBloc.allRoutines,
          builder: (context, routineSnapshot) {
            if (!routineSnapshot.hasData) return _buildStatCard('Most Used Routine', 'Loading...', Icons.star);
            final mostUsedRoutine = routineSnapshot.data!.firstWhere((r) => r.id == mostUsedRoutineId);
            return _buildStatCard('Most Used Routine', mostUsedRoutine.name, Icons.star);
          },
        );
      },
    );
  }

  Widget _buildWeeklyProgressCard() {
    return FutureBuilder<SharedPreferences>(
      future: sharedPrefsProvider.sharedPreferences,
      builder: (context, prefsSnapshot) {
        if (prefsSnapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard('Weekly Progress', 'Loading...', Icons.trending_up);
        }
        if (prefsSnapshot.hasError || !prefsSnapshot.hasData) {
          return _buildStatCard('Weekly Progress', 'Error', Icons.error);
        }

        final weeklyGoal = prefsSnapshot.data!.getInt(weeklyAmountKey) ?? 3;

        return FutureBuilder<List<RoutineHistory>>(
          future: _routineHistoryFuture,
          builder: (context, historySnapshot) {
            if (historySnapshot.connectionState == ConnectionState.waiting) {
              return _buildStatCard('Weekly Progress', 'Loading...', Icons.trending_up);
            }
            if (historySnapshot.hasError || !historySnapshot.hasData) {
              return _buildStatCard('Weekly Progress', 'Error', Icons.error);
            }

            final now = DateTime.now();
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final workoutsThisWeek = historySnapshot.data!
                .where((history) => history.completedDate.isAfter(startOfWeek))
                .length;

            final progress = (workoutsThisWeek / weeklyGoal * 100).toStringAsFixed(1);
            return _buildStatCard('Weekly Progress', '$progress%', Icons.trending_up);
          },
        );
      },
    );
  }

  Widget _buildWorkoutChart() {
    return FutureBuilder<List<RoutineHistory>>(
      future: _routineHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No data available', style: TextStyle(color: Colors.white));
        }

        final workouts = snapshot.data!;
        final workoutCounts = <DateTime, int>{};
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(Duration(days: 6));

        for (var i = 0; i < 7; i++) {
          final date = sevenDaysAgo.add(Duration(days: i));
          workoutCounts[date] = 0;
        }

        for (var workout in workouts) {
          final date = DateTime(workout.completedDate.year, workout.completedDate.month, workout.completedDate.day);
          if (date.isAfter(sevenDaysAgo.subtract(Duration(days: 1))) && date.isBefore(now.add(Duration(days: 1)))) {
            workoutCounts[date] = (workoutCounts[date] ?? 0) + 1;
          }
        }

        return Container(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = sevenDaysAgo.add(Duration(days: value.toInt()));
                      return Text(
                        DateFormat('E').format(date),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: workoutCounts.values.reduce((a, b) => a > b ? a : b).toDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: workoutCounts.entries.map((e) {
                    final daysFromStart = e.key.difference(sevenDaysAgo).inDays;
                    return FlSpot(daysFromStart.toDouble(), e.value.toDouble());
                  }).toList(),
                  isCurved: true,
                  color: Color(0xFFE91E63),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: Color(0x29E91E63)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoutineStatsList() {
    return StreamBuilder<List<Routine>>(
      stream: routinesBloc.allRoutines,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final routines = snapshot.data!;
        return SizedBox(
          height: 150, // Kartların yüksekliğini ayarlayın
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true, // Sağdan sola doğru sıralama
            itemCount: routines.length,
            itemBuilder: (context, index) => _buildRoutineStatCard(routines[index]),
          ),
        );
      },
    );
  }

  Widget _buildRoutineStatCard(Routine routine) {
    return Container(
      width: 250, // Kartın genişliğini ayarlayın
      margin: EdgeInsets.only(left: 10),
      child: Card(
        color: Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                routine.name,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 10),
              FutureBuilder<List<RoutineHistory>>(
                future: DBProvider.db.getRoutineHistory(routine.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text('Loading...', style: TextStyle(color: Colors.white70));
                  final completions = snapshot.data!.length;
                  return Text('Completions: $completions', style: TextStyle(color: Colors.white70));
                },
              ),
              SizedBox(height: 5),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Color(0xFFE91E63), size: 24),
            SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.white70, fontSize: 14)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  String _formatWeekdays(List<int> weekdays) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays.map((day) => days[day - 1]).join(', ');
  }
}
