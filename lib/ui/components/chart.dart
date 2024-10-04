import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:workout/models/routine.dart';
import '../../models/exercise.dart';

class StackedAreaLineChart extends StatelessWidget {
  final bool animate;
  final Exercise exercise;

  const StackedAreaLineChart(this.exercise, {super.key, required this.animate});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: const NumericAxis(),
      series: _createData(),
      enableSideBySideSeriesPlacement: false,
    );
  }

  List<CartesianSeries<LinearWeightCompleted, int>> _createData() {
    List<LinearWeightCompleted> weightCompletedList = <LinearWeightCompleted>[];
    for (int i = 0; i < exercise.exHistory.length; i++) {
      double tempWeight = _getMaxWeight(exercise.exHistory.values.toList()[i]);
      weightCompletedList.add(LinearWeightCompleted(i, tempWeight.toInt()));
    }

    return <CartesianSeries<LinearWeightCompleted, int>>[
      LineSeries<LinearWeightCompleted, int>(
        dataSource: weightCompletedList,
        xValueMapper: (LinearWeightCompleted weightCompleted, _) => weightCompleted.month,
        yValueMapper: (LinearWeightCompleted weightCompleted, _) => weightCompleted.weight,
        color: Colors.deepOrange,
      )
    ];
  }

  double _getMaxWeight(String weightsStr) {
    List<double> weights = weightsStr.split('/').map((str) => double.parse(str)).toList();
    return weights.reduce((max, weight) => weight > max ? weight : max);
  }
}

class LinearWeightCompleted {
  final int month;
  final int weight;

  LinearWeightCompleted(this.month, this.weight);
}

class DonutAutoLabelChart extends StatelessWidget {
  final List<Routine> routines;
  final bool animate;

  const DonutAutoLabelChart(this.routines, {super.key, required this.animate});

  factory DonutAutoLabelChart.withSampleData() {
    return const DonutAutoLabelChart([], animate: false);
  }

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(
      series: _createData(),
      legend: const Legend(isVisible: true),
    );
  }

  List<PieSeries<LinearRecords, String>> _createData() {
    final data = [
      LinearRecords('Abs', 0, _getTotalCount(MainTargetedBodyPart.abs)),
      LinearRecords('Arms', 1, _getTotalCount(MainTargetedBodyPart.arm)),
      LinearRecords('Back', 2, _getTotalCount(MainTargetedBodyPart.back)),
      LinearRecords('Chest', 3, _getTotalCount(MainTargetedBodyPart.chest)),
      LinearRecords('Legs', 4, _getTotalCount(MainTargetedBodyPart.leg)),
      LinearRecords('Shoulders', 5, _getTotalCount(MainTargetedBodyPart.shoulder)),
      LinearRecords('Full Body', 6, _getTotalCount(MainTargetedBodyPart.fullBody)),
    ];

    return <PieSeries<LinearRecords, String>>[
      PieSeries<LinearRecords, String>(
        dataSource: data,
        xValueMapper: (LinearRecords sales, _) => sales.label,
        yValueMapper: (LinearRecords sales, _) => sales.totalCount,
        dataLabelMapper: (LinearRecords sales, _) => sales.label,
        dataLabelSettings: const DataLabelSettings(isVisible: true),
      )
    ];
  }

  int _getTotalCount(MainTargetedBodyPart mt) {
    return routines.where((routine) => routine.mainTargetedBodyPart == mt)
        .fold(0, (sum, routine) => sum + routine.completionCount);
  }
}

class LinearRecords {
  final String label;
  final int index;
  final int totalCount;

  LinearRecords(this.label, this.index, this.totalCount);
}
