import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../resource/firebase_provider.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Future<List<Map<String, dynamic>>> _userRoutinesFuture;

  @override
  void initState() {
    super.initState();
    _userRoutinesFuture = _fetchUserRoutines();
  }

  Future<List<Map<String, dynamic>>> _fetchUserRoutines() async {
    final userId = FirebaseProvider().getCurrentUserId();
    if (userId == null) {
      throw Exception("User not authenticated");
    }
    return await FirebaseProvider().getUserRoutines();
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
                  'İstatistikler',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                _buildStatCards(),
                SizedBox(height: 24),
                Text(
                  'Haftalık İlerleme',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _buildWeeklyProgressCard(),
                SizedBox(height: 24),
                Text(
                  'Son 7 Gün',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _buildWorkoutChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _userRoutinesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
        }
        final userRoutines = snapshot.data ?? [];
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTotalWorkoutsCard(userRoutines)),
                SizedBox(width: 16),
                Expanded(child: _buildLastWorkoutCard(userRoutines)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMostUsedRoutineCard(userRoutines)),
                SizedBox(width: 16),
                Expanded(child: _buildTotalRoutinesCard(userRoutines)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalWorkoutsCard(List<Map<String, dynamic>> userRoutines) {
    final totalWorkouts = userRoutines.fold(0, (sum, routine) => sum + (routine['progress'] as int? ?? 0));
    return _buildStatCard('Toplam Antrenman', totalWorkouts.toString(), Icons.fitness_center);
  }

  Widget _buildLastWorkoutCard(List<Map<String, dynamic>> userRoutines) {
    final lastWorkout = userRoutines
        .where((routine) => routine['lastUsedDate'] != null)
        .reduce((a, b) => a['lastUsedDate'].toDate().isAfter(b['lastUsedDate'].toDate()) ? a : b);
    final lastWorkoutDate = lastWorkout['lastUsedDate'].toDate();
    final formattedDate = DateFormat('dd/MM/yyyy').format(lastWorkoutDate);
    return _buildStatCard('Son Antrenman', formattedDate, Icons.access_time);
  }

  Widget _buildMostUsedRoutineCard(List<Map<String, dynamic>> userRoutines) {
    final mostUsedRoutine = userRoutines.reduce((a, b) => (a['progress'] ?? 0) > (b['progress'] ?? 0) ? a : b);
    return _buildStatCard('En Çok Kullanılan Rutin', mostUsedRoutine['name'] ?? 'Bilinmiyor', Icons.star);
  }

  Widget _buildTotalRoutinesCard(List<Map<String, dynamic>> userRoutines) {
    return _buildStatCard('Toplam Rutin', userRoutines.length.toString(), Icons.list);
  }

  Widget _buildWeeklyProgressCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _userRoutinesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard('Haftalık İlerleme', 'Yükleniyor...', Icons.trending_up);
        }
        if (snapshot.hasError) {
          return _buildStatCard('Haftalık İlerleme', 'Hata', Icons.error);
        }
        final userRoutines = snapshot.data ?? [];
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weeklyWorkouts = userRoutines
            .where((routine) => routine['lastUsedDate'] != null &&
            routine['lastUsedDate'].toDate().isAfter(weekStart))
            .length;
        return _buildStatCard('Haftalık İlerleme', '$weeklyWorkouts antrenman', Icons.trending_up);
      },
    );
  }

  Widget _buildWorkoutChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _userRoutinesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final userRoutines = snapshot.data ?? [];
        final workoutCounts = {};
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(Duration(days: 6));
        for (var i = 0; i < 7; i++) {
          final date = sevenDaysAgo.add(Duration(days: i));
          workoutCounts[date] = 0;
        }
        for (var routine in userRoutines) {
          if (routine['lastUsedDate'] != null) {
            final date = routine['lastUsedDate'].toDate();
            if (date.isAfter(sevenDaysAgo.subtract(Duration(days: 1))) && date.isBefore(now.add(Duration(days: 1)))) {
              final key = DateTime(date.year, date.month, date.day);
              workoutCounts[key] = (workoutCounts[key] ?? 0) + 1;
            }
          }
        }
        return Container(
          height: 200,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = sevenDaysAgo.add(Duration(days: value.toInt()));
                      return Text(
                        DateFormat('E').format(date),
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: workoutCounts.values.isEmpty ? 1 : workoutCounts.values.reduce((a, b) => a > b ? a : b).toDouble(),
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
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: Color(0x29E91E63)),
                ),
              ],
            ),
          ),
        );
      },
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
}
