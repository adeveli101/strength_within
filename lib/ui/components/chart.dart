import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../models/exercise.dart';
import '../../models/RoutineHistory.dart';
import '../../resource/db_provider.dart';

class StackedAreaLineChart extends StatelessWidget {
  final bool animate;
  final Exercise exercise;

  const StackedAreaLineChart(this.exercise, {Key? key, required this.animate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RoutineHistory>?>(
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
            primaryXAxis: NumericAxis(
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
            series: _createData(snapshot.data!),
            enableSideBySideSeriesPlacement: false,
            backgroundColor: Color(0xFF121212),
            legend: Legend(isVisible: false),
            tooltipBehavior: TooltipBehavior(enable: true, color: Color(0xFF2C2C2C)),
          );
        }
      },
    );
  }

  Future<List<RoutineHistory>?> _getExerciseHistory() async {
    return await DBProvider.db.getRoutineHistoryForExercise(exercise.id);
  }

  List<CartesianSeries<LinearWeightCompleted, int>> _createData(List<RoutineHistory> history) {
    List<LinearWeightCompleted> weightCompletedList = [];
    for (int i = 0; i < history.length; i++) {
      Map? additionalData = _getWeightFromHistory(history[i]);
      if (additionalData != null && additionalData.containsKey(exercise.id.toString())) {
        var weightData = additionalData[exercise.id.toString()]['weight'];
        if (weightData != null) {
          double weight = (weightData is int) ? weightData.toDouble() : weightData;
          weightCompletedList.add(LinearWeightCompleted(i, weight.toInt()));
        }
      }
    }

    return <CartesianSeries<LinearWeightCompleted, int>>[
      LineSeries<LinearWeightCompleted, int>(
        dataSource: weightCompletedList,
        xValueMapper: (LinearWeightCompleted weightCompleted, _) => weightCompleted.month,
        yValueMapper: (LinearWeightCompleted weightCompleted, _) => weightCompleted.weight,
        color: Color(0xFFE91E63),
        width: 2,
        markerSettings: MarkerSettings(isVisible: true, color: Color(0xFFE91E63)),
      )
    ];
  }


  Map? _getWeightFromHistory(RoutineHistory history) {
    return history.additionalData;
  }
}

class LinearWeightCompleted {
  final int month;
  final int weight;
  LinearWeightCompleted(this.month, this.weight);
}
