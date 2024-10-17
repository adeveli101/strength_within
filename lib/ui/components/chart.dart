import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:workout/models/routines.dart';
import '../../firebase_class/firebase_routines.dart';
import '../../models/exercises.dart';
import '../../resource/routines_bloc.dart';

class StackedAreaLineChart extends StatelessWidget {
  final bool animate;
  final Exercises exercise;
  final String userId;
  final RoutinesBloc routinesBloc;

  const StackedAreaLineChart(this.exercise, {
    Key? key,
    required this.animate,
    required this.userId,
    required this.routinesBloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Exercises>>(
      future: routinesBloc.getExercisesByBodyPart(exercise.mainTargetedBodyPart),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white70)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available', style: TextStyle(color: Colors.white70)));
        } else {
          return SfCartesianChart(
            primaryXAxis: CategoryAxis(
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
            series: <CartesianSeries<Exercises, String>>[
              ColumnSeries<Exercises, String>(
                dataSource: snapshot.data!,
                xValueMapper: (Exercises exercise, _) => exercise.name,
                yValueMapper: (Exercises exercise, _) => exercise.defaultWeight,
                color: Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(5),
              ),
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

  List<LinearWeightCompleted> _getWeightCompletedList(List<FirebaseRoutine> history) {
    List<LinearWeightCompleted> weightCompletedList = [];
    for (var routine in history) {
      if (routine.lastUsedDate != null && routine.userProgress != null) {
        DateTime date = routine.lastUsedDate!;
        int progress = routine.userProgress!;
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
