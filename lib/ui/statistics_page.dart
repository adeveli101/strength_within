import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../firebase_class/RoutineHistory.dart';
import '../firebase_class/firebase_routines.dart';
import '../resource/firebase_provider.dart';
import '../resource/routines_bloc.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
  final RoutinesBloc routinesBloc;

  const StatisticsPage({Key? key, required this.routinesBloc}) : super(key: key);
}

class _StatisticsPageState extends State<StatisticsPage> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final deviceId = await BlocProvider.of<RoutinesBloc>(context).getDeviceId();
    final id = await FirebaseProvider.getUserId(deviceId);
    setState(() {
      userId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Center(child: CircularProgressIndicator());
    }

    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        if (state is RoutinesLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (state is RoutinesLoaded) {
          return _buildStatisticsContent(context, state.routines.cast<FirebaseRoutine>());
        } else if (state is RoutinesError) {
          return Center(child: Text('Hata: ${state.message}'));
        }
        return Center(child: Text('İstatistikler yüklenemedi.'));
      },
    );
  }

  Widget _buildStatisticsContent(BuildContext context, List<FirebaseRoutine> routines) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          flexibleSpace: FlexibleSpaceBar(
            title: Text('İstatistikler'),
            background: Image.asset('assets/statistics_background.jpg', fit: BoxFit.cover),
          ),
          pinned: true,
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            _buildWeeklyProgressChart(routines),
            _buildMostUsedRoutines(routines),
            _buildRecentActivity(context),
          ]),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgressChart(List<FirebaseRoutine> routines) {
    final weeklyData = _getWeeklyProgressData(routines);

    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: weeklyData.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    weeklyData[value.toInt()].day,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                },
                reservedSize: 38,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: weeklyData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  color: Colors.blue,
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }


  List<ProgressData> _getWeeklyProgressData(List<FirebaseRoutine> routines) {
    Map<String, int> progressByDay = {
      'Pzt': 0, 'Sal': 0, 'Çar': 0, 'Per': 0, 'Cum': 0, 'Cmt': 0, 'Paz': 0
    };

    for (var routine in routines) {
      if (routine.lastUsedDate != null) {
        String dayName = _getDayName(routine.lastUsedDate!.weekday);
        progressByDay[dayName] = (progressByDay[dayName] ?? 0) + (routine.userProgress ?? 0);
      }
    }

    return progressByDay.entries.map((e) => ProgressData(e.key, e.value)).toList();
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Pzt';
      case 2: return 'Sal';
      case 3: return 'Çar';
      case 4: return 'Per';
      case 5: return 'Cum';
      case 6: return 'Cmt';
      case 7: return 'Paz';
      default: return '';
    }
  }

  Widget _buildMostUsedRoutines(List<FirebaseRoutine> routines) {
    var sortedRoutines = List<FirebaseRoutine>.from(routines)
      ..sort((a, b) => (b.userProgress ?? 0).compareTo(a.userProgress ?? 0));
    var topRoutines = sortedRoutines.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text('En Çok Kullanılan Rutinler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: topRoutines.length,
          itemBuilder: (context, index) {
            var routine = topRoutines[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text('Rutin ${routine.routineId}'),
              subtitle: Text('İlerleme: ${routine.userProgress ?? 0}%'),
              trailing: Icon(Icons.fitness_center),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return FutureBuilder<List<RoutineHistory>>(
      future: BlocProvider.of<RoutinesBloc>(context).getUserRoutineHistory(userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          var recentActivities = snapshot.data!.take(10).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('Son Aktiviteler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: recentActivities.length,
                itemBuilder: (context, index) {
                  var activity = recentActivities[index];
                  return ListTile(
                    leading: Icon(Icons.history),
                    title: Text('Rutin ${activity.routineId}'),
                    subtitle: Text('Tarih: ${activity.completedDate.toString().split(' ')[0]}'),
                  );
                },
              ),
            ],
          );
        }
        return Center(child: Text('Aktivite bulunamadı.'));
      },
    );
  }
}

class ProgressData {
  final String day;
  final int value;

  ProgressData(this.day, this.value);
}
