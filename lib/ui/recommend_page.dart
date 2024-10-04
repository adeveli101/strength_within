import 'package:flutter/material.dart';
import 'package:workout/bloc/routines_bloc.dart';
import 'package:workout/utils/routine_helpers.dart';

import '../models/routine.dart';
import 'components/routine_card.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final scrollController = ScrollController();
  bool showShadow = false;

  @override
  void initState() {
    scrollController.addListener(() {
      if (mounted) {
        if (scrollController.offset <= 0) {
          setState(() {
            showShadow = false;
          });
        } else if (showShadow == false) {
          setState(() {
            showShadow = true;
          });
        }
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Dev's Favorite"),
          elevation: showShadow ? 8 : 0,
        ),
        body: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: StreamBuilder(
            stream: routinesBloc.allRecRoutines,
            builder: (_, AsyncSnapshot<List<Routine>> snapshot) {
              if (snapshot.hasData) {
                var routines = snapshot.data;
                return ListView(
                  controller: scrollController,
                  children: buildChildren(routines!),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ));
  }

  List<Widget> buildChildren(List<Routine> routines) {
    var map = <MainTargetedBodyPart, List<Routine>>{};
    var children = <Widget>[];

    var textColor = Colors.black;
    var style = TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: textColor);

    for (var routine in routines) {
      if (map.containsKey(routine.mainTargetedBodyPart) == false) map[routine.mainTargetedBodyPart] = [];
      map[routine.mainTargetedBodyPart]?.add(routine);
    }

    for (var bodyPart in map.keys) {
      children.add(Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Text(mainTargetedBodyPartToStringConverter(bodyPart), style: style),
      ));
      children.addAll(map[bodyPart]!.map((routine) => RoutineCard(routine: routine, isRecRoutine: true)));
      children.add(const Divider());
    }

    return children;
  }
}
