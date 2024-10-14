import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../models/exercise.dart';
import '../../resource/firebase_provider.dart';

class StackedAreaLineChart extends StatelessWidget {
  final bool animate;
  final Exercise exercise;
  final String userId;

  const StackedAreaLineChart(this.exercise, {Key? key, required this.animate, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getExerciseHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white70)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available', style: TextStyle(color: Colors.white70)));
        } else {
          return SfCartesianChart(
            primaryXAxis: DateTimeAxis(
              majorGridLines: MajorGridLines(width: 0),
              axisLine: AxisLine(width: 0),
              labelStyle: TextStyle(color: Colors.white70),
            ),
            primaryYAxis: NumericAxis(
              majorGridLines: MajorGridLines(width: 0.5, color: Colors.grey[800]),
              axisLine: AxisLine(width: 0),
              labelStyle: TextStyle(color: Colors.white70),
            ),
            plotAreaBorderWidth: 0,
            series: <CartesianSeries<LinearWeightCompleted, DateTime>>[
              LineSeries<LinearWeightCompleted, DateTime>(
                dataSource: _getWeightCompletedList(snapshot.data!),
                xValueMapper: (LinearWeightCompleted weightCompleted, _) => weightCompleted.date,
                yValueMapper: (LinearWeightCompleted weightCompleted, _) => weightCompleted.weight,
                color: Color(0xFFE91E63),
                width: 2,
                markerSettings: MarkerSettings(isVisible: true, color: Color(0xFFE91E63)),
              )
            ],
            enableSideBySideSeriesPlacement: false,
            backgroundColor: Color(0xFF121212),
            legend: Legend(isVisible: false),
            tooltipBehavior: TooltipBehavior(enable: true, color: Color(0xFF2C2C2C)),
          );
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getExerciseHistory() async {
    return await firebaseProvider.getUserRoutines();
  }

  List<LinearWeightCompleted> _getWeightCompletedList(List<Map<String, dynamic>> history) {
    List<LinearWeightCompleted> weightCompletedList = [];
    for (var routine in history) {
      if (routine['lastUsedDate'] != null && routine['progress'] != null) {
        DateTime date = (routine['lastUsedDate'] as Timestamp).toDate();
        int progress = routine['progress'] as int;
        weightCompletedList.add(LinearWeightCompleted(date, progress));
      }
    }
    weightCompletedList.sort((a, b) => a.date.compareTo(b.date));
    return weightCompletedList;
  }
}

class LinearWeightCompleted {
  final DateTime date;
  final int weight;
  LinearWeightCompleted(this.date, this.weight);
}
