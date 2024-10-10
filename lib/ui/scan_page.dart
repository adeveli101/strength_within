import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:workout/ui/routine_detail_page.dart';
import '../models/routine.dart';
import '../resource/db_provider.dart';
import 'components/custom_snack_bars.dart';

class ScanPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final textEditingController = TextEditingController();
  String routineId = "";
  late Routine routine;

  @override
  void initState() {
    super.initState();
    textEditingController.addListener(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Enter Routine'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton(
                onPressed: inputRoutineId,
                child: Text('Enter routine ID'),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
              child: isValidRoutineId(routineId)
                  ? FutureBuilder(
                future: getRoutineOverview(routineId),
                builder: (_, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data as RoutineDetailPage;
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              )
                  : Container(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
              child: isValidRoutineId(routineId)
                  ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                ),
                onPressed: () {
                  addRoutineToDatabase();
                },
                child: const Text('Add to my routines'),
              )
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> inputRoutineId() async {
    if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(noNetworkSnackBar);
    } else {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('Enter Routine ID'),
            content: TextField(
              controller: textEditingController,
              decoration: InputDecoration(hintText: 'Routine ID'),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Submit'),
                onPressed: () {
                  setState(() {
                    routineId = textEditingController.text;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  bool isValidRoutineId(String id) {
    return id.isNotEmpty;
  }

  Future<RoutineDetailPage> getRoutineOverview(String id) async {
    var snapshot = await FirebaseFirestore.instance.collection("userShares").doc(id).get();
    String routineStr = snapshot.data()!['routine'];
    routine = Routine.fromMap(jsonDecode(routineStr));
    return RoutineDetailPage(routine: routine);
  }

  void addRoutineToDatabase() {
    DBProvider.db.newRoutine(routine);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.done),
            ),
            Text('Added to my routines.'),
          ],
        ),
      ),
    );
  }
}
