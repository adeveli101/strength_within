import 'package:flutter/material.dart';
import '../controllers/routines_bloc.dart';
import '../models/routine.dart';
import '../utils/routine_helpers.dart';
import 'components/routine_card.dart';

class RecommendPage extends StatefulWidget {
  @override
  _RecommendPageState createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final scrollController = ScrollController();
  bool showShadow = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (this.mounted) {
        if (scrollController.offset <= 0) {
          setState(() {
            showShadow = false;
          });
        } else if (!showShadow) {
          setState(() {
            showShadow = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recommended"),
        elevation: showShadow ? 8 : 0,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: StreamBuilder<List<Routine>>(
          stream: routinesBloc.allRecRoutines,
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading data'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No recommended routines available.'));
            } else {
              var routines = snapshot.data!;
              return ListView(
                controller: scrollController,
                children: buildChildren(routines),
              );
            }
          },
        ),
      ),
    );
  }

  List<Widget> buildChildren(List<Routine> routines) {
    var map = <MainTargetedBodyPart, List<Routine>>{};
    var children = <Widget>[];

    var textColor = Colors.black;
    var style = TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: textColor);

    for (var routine in routines) {
      map.putIfAbsent(routine.mainTargetedBodyPart, () => []).add(routine);
    }

    map.forEach((bodyPart, routinesList) {
      children.add(Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text(mainTargetedBodyPartToStringConverter(bodyPart), style: style),
      ));
      children.addAll(routinesList.map((routine) => RoutineCard(routine: routine, isRecRoutine: true)));
      children.add(Divider());
    });

    return children;
  }
}