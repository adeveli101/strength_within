import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../resource/routines_bloc.dart';
import '../firebase_class/firebase_routines.dart';
import '../models/routines.dart';


class StatisticsPage extends StatelessWidget {
  final RoutinesBloc routinesBloc;

  const StatisticsPage({Key? key, required this.routinesBloc}) : super(key: key);

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
    return StreamBuilder<List<Routine>>(
      stream: routinesBloc.allRoutines,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}', style: TextStyle(color: Colors.white)));
        }
        final userRoutines = snapshot.data ?? [];
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTotalWorkoutsCard(userRoutines.cast<FirebaseRoutine>())),
                SizedBox(width: 16),
                Expanded(child: _buildLastWorkoutCard(userRoutines.cast<FirebaseRoutine>())),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMostUsedRoutineCard(userRoutines.cast<FirebaseRoutine>())),
                SizedBox(width: 16),
                Expanded(child: _buildTotalRoutinesCard(userRoutines.cast<FirebaseRoutine>())),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalWorkoutsCard(List<FirebaseRoutine> userRoutines) {
    final totalWorkouts = userRoutines.fold(0, (sum, routine) => sum + (routine.userProgress ?? 0));
    return _buildStatCard('Toplam Antrenman', totalWorkouts.toString(), Icons.fitness_center);
  }

  Widget _buildLastWorkoutCard(List<FirebaseRoutine> userRoutines) {
    if (userRoutines.isEmpty) {
      return _buildStatCard('Son Antrenman', 'Veri yok', Icons.access_time);
    }
    final routinesWithDate = userRoutines.where((routine) => routine.lastUsedDate != null).toList();
    if (routinesWithDate.isEmpty) {
      return _buildStatCard('Son Antrenman', 'Veri yok', Icons.access_time);
    }
    final lastWorkout = routinesWithDate.reduce((a, b) => a.lastUsedDate!.isAfter(b.lastUsedDate!) ? a : b);
    final formattedDate = DateFormat('dd/MM/yyyy').format(lastWorkout.lastUsedDate!);
    return _buildStatCard('Son Antrenman', formattedDate, Icons.access_time);
  }

  Widget _buildMostUsedRoutineCard(List<FirebaseRoutine> userRoutines) {
    if (userRoutines.isEmpty) {
      return _buildStatCard('En Çok Kullanılan Rutin', 'Veri yok', Icons.star);
    }
    final mostUsedRoutine = userRoutines.reduce((a, b) => (a.userProgress ?? 0) > (b.userProgress ?? 0) ? a : b);
    return _buildStatCard('En Çok Kullanılan Rutin', mostUsedRoutine.routine.name, Icons.star);
  }

  Widget _buildTotalRoutinesCard(List<FirebaseRoutine> userRoutines) {
    return _buildStatCard('Toplam Rutin', userRoutines.length.toString(), Icons.list);
  }

  Widget _buildWeeklyProgressCard() {
    return StreamBuilder<List<Routine>>(
      stream: routinesBloc.allRoutines,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard('Haftalık İlerleme', 'Yükleniyor...', Icons.trending_up);
        }
        if (snapshot.hasError) {
          return _buildStatCard('Haftalık İlerleme', 'Hata', Icons.error);
        }
        final routines = snapshot.data ?? [];

        // FirebaseRoutine listesini oluştur
        final userRoutines = routines.map((routine) =>
            FirebaseRoutine.fromRoutine(routine)
        ).toList();

        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));

        // Haftalık antrenman sayısını hesapla
        final weeklyWorkouts = userRoutines
            .where((firebaseRoutine) =>
        firebaseRoutine.lastUsedDate != null &&
            firebaseRoutine.lastUsedDate!.isAfter(weekStart))
            .length;

        return _buildStatCard('Haftalık İlerleme', '$weeklyWorkouts antrenman', Icons.trending_up);
      },
    );
  }

  Widget _buildWorkoutChart() {
    return StreamBuilder<List<Routine>>(
      stream: routinesBloc.allRoutines,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}', style: TextStyle(color: Colors.white)));
        }
        final userRoutines = snapshot.data ?? [];
        final workoutCounts = _getWorkoutCounts(userRoutines.cast<FirebaseRoutine>());
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
                      final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
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
                  spots: workoutCounts.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
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

  Map<int, int> _getWorkoutCounts(List<FirebaseRoutine> userRoutines) {
    final workoutCounts = Map<int, int>.fromIterable(
      List.generate(7, (index) => index),
      key: (item) => item as int,
      value: (_) => 0,
    );
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 6));
    for (var routine in userRoutines) {
      if (routine.lastUsedDate != null) {
        final date = routine.lastUsedDate!;
        if (date.isAfter(sevenDaysAgo) && date.isBefore(now.add(Duration(days: 1)))) {
          final daysAgo = now.difference(date).inDays;
          workoutCounts[6 - daysAgo] = (workoutCounts[6 - daysAgo] ?? 0) + 1;
        }
      }
    }
    return workoutCounts;
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