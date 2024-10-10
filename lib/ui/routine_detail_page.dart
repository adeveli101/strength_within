import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:workout/ui/part_history_page.dart';
import 'package:workout/ui/routine_edit_page.dart';
import 'package:workout/ui/routine_step_page.dart';
import '../controllers/routines_bloc.dart';
import '../models/routine.dart';
import '../resource/firebase_provider.dart';
import '../utils/routine_helpers.dart';
import 'components/custom_snack_bars.dart';
import 'components/part_card.dart';



class RoutineDetailPage extends StatefulWidget {
  final bool isRecRoutine;
  final Routine routine;

  RoutineDetailPage({Key? key, this.isRecRoutine = false, required this.routine}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage>{
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController scrollController = ScrollController();


  GlobalKey globalKey = GlobalKey();
  late String dataString;
  late Routine routine;

  @override
  void initState() {
    dataString = '-r' + FirebaseProvider.generateId();

    routinesBloc.fetchAllRoutines();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //final List<Routine> routines = RoutinesContext.of(context).routines;
    //routine = RoutinesContext.of(context).curRoutine;
    //_dataString = '-r' + jsonEncode(routine.toMap());

    return StreamBuilder(
      stream: routinesBloc.currentRoutine,
      builder: (_, AsyncSnapshot<Routine> snapshot) {
        if (snapshot.hasData) {
          routine = snapshot.data!;
          return Scaffold(
              key: scaffoldKey,
              appBar: AppBar(
                centerTitle: true,
                title: Text(mainTargetedBodyPartToStringConverter(routine.mainTargetedBodyPart)),
                actions: [
                  if (widget.isRecRoutine == false)
                    IconButton(
                      icon: Icon(Icons.calendar_view_day),
                      onPressed: () {
                        showCupertinoModalPopup(
                            context: context,
                            builder: (buildContext) {
                              return Container(
                                height: 600,
                                child: WeekdayModalBottomSheet(
                                  routine.weekdays,
                                  checkedCallback: updateWorkWeekdays,
                                ),
                              );
                            });
                      },
                    ),
                  if (widget.isRecRoutine == false)
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => RoutineEditPage(
                                  addOrEdit: AddOrEdit.edit,
                                  mainTargetedBodyPart: routine.mainTargetedBodyPart,
                                )));
                      },
                    ),
                  if (widget.isRecRoutine == false)
                    IconButton(
                      icon: Icon(Icons.play_arrow),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                fullscreenDialog: true,
                                builder: (_) => RoutineStepPage(
                                  routine: routine,
                                  onBackPressed: () {
                                    Navigator.pop(context);
                                  },
                                  celebrateCallback: () {
                                    // Implement your celebration logic here
                                    // For example, you might start a confetti animation or show a congratulatory message.
                                    print("Perfect!");
                                  },
                                )));
                      },
                    ),
                  if (widget.isRecRoutine)
                    IconButton(
                        icon: Icon(Icons.add),
                        onPressed: onAddRecPressed),
                ],
              ),
              body: ListView(children: buildColumn()));
        } else {
          return Container();
        }
      },
    );
  }

  void onAddRecPressed() {
    showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Add to your routines?'),
            actions: <Widget>[
              TextButton(
                child: Text('No'),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              TextButton(
                child: Text('Yes'),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              )
            ],
          );
        }).then((val) {
      if (val != null && val) {
        routinesBloc.addRoutine(routine);
        Navigator.pop(context);
      }
    });
  }

  Future onSharePressed() async {
    if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(noNetworkSnackBar);
    } else {
      ///update the database
      FirebaseFirestore.instance
          .collection("userShares")
          .doc(dataString.replaceFirst("-r", ""))
          .set({"id": dataString.replaceFirst("-r", ""), "routine": jsonEncode(Routine.copyFromRoutine(routine).toMap())});

      ///show qr code
      showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Center(
                      child: RepaintBoundary(
                        key: globalKey,
                        child: QrImageView(
                          data: dataString,
                          size: 300,
                          version: QrVersions.auto, // QrVersions.auto for automatic version selection
                          gapless: false, // Optional
                          errorStateBuilder: (context, error) {
                            return Center(
                              child: Text(
                                "[QR] ERROR - $error",
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      )),
                  Center(
                    child: OverflowBar(
                      alignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ElevatedButton(
                            child: Text('Send'),
                            onPressed: () async {
                              Share.share("Check out my routine: ${dataString.replaceFirst("-r", "")}");
                            })
                      ],
                    ),
                  )
                ],
              ),
            ),
          ));
    }
  }

  void updateWorkWeekdays(List<int> checkedWeekdays) {
    routine.weekdays.clear();
    routine.weekdays.addAll(checkedWeekdays);
    routinesBloc.updateRoutine(routine);
  }

  void showSyncFailSnackBar() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.yellow,
      content: Row(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(
              Icons.report,
              color: Colors.black,
            ),
          ),
          Text(
            "SYNC FAILED DUE TO NETWORK CONNECTION",
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    ));
  }

  List<Widget> buildColumn() {
    List<Widget> exerciseDetails = <Widget>[];
    //_exerciseDetails.add(RoutineDescriptionCard(routine: routine));
    exerciseDetails.add(Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
        elevation: 12,
        color: Theme.of(context).primaryColor,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 12,
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(routine.routineName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  softWrap: true,
                  style: TextStyle(
                      fontFamily: 'Staa',
                      fontSize: 26,
                      color: Colors.white
                  )),
            ),
            widget.isRecRoutine
                ? Container()
                : Text(
              'You have done this workout',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
            widget.isRecRoutine
                ? Container()
                : Text(
              routine.completionCount.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 36, color: Colors.white),
            ),
            widget.isRecRoutine
                ? Container()
                : Text(
              'times',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
            widget.isRecRoutine
                ? Container()
                : Text(
              'since',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
            widget.isRecRoutine
                ? Container()
                : Text(
              '${routine.createdDate.toString().split(' ').first}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            SizedBox(
              height: 12,
            ),
          ],
        ),
      ),
    ));
    exerciseDetails.addAll(this.routine.parts.map((part) => Builder(
      builder: (context) => PartCard(
        onDelete: () {},
        onPartTap: widget.isRecRoutine ? () {} : () => Navigator.push(context, MaterialPageRoute(builder: (context) => PartHistoryPage(part))),
        part: part,
      ),
    )));
    exerciseDetails.add(Container(
      color: Colors.transparent,
      height: 60,
    ));
    return exerciseDetails;
  }

  double getFontSize(String str) {
    if (str.length > 56) {
      return 14;
    } else if (str.length > 17) {
      return 16;
    } else {
      return 24;
    }
  }
}

typedef void WeekdaysCheckedCallback(List<int> selectedWeekdays);

class WeekdayModalBottomSheet extends StatefulWidget {
  final List<int> checkedWeekDays;
  final WeekdaysCheckedCallback checkedCallback;

  WeekdayModalBottomSheet(this.checkedWeekDays, {required this.checkedCallback});

  _WeekdayModalBottomSheetState createState() => _WeekdayModalBottomSheetState();
}

class _WeekdayModalBottomSheetState extends State<WeekdayModalBottomSheet> with SingleTickerProviderStateMixin {
  final List<String> weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<IconData> weekDayIcons = [Icons.looks_one, Icons.looks_two, Icons.looks_3, Icons.looks_4, Icons.looks_5, Icons.looks_6, Icons.looks];
  final List<bool> isCheckedList = List.filled(7, false);
  var heightOfModalBottomSheet = 100.0;

  @override
  void initState() {
    for (int i = 1; i <= 7; i++) {
      if (widget.checkedWeekDays.contains(i))
        isCheckedList[i - 1] = true;
      else
        isCheckedList[i - 1] = false;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        child: Padding(
            padding: EdgeInsets.only(top: 0),
            child: ListView.separated(
                physics: NeverScrollableScrollPhysics(),
                itemCount: 8,
                separatorBuilder: (buildContext, index) {
                  if (index == 0) return Container();
                  return Divider();
                },
                itemBuilder: (buildContext, index) {
                  if (index == 0) {
                    return Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: const Text('Choose weekday(s) for this routine'),
                    );
                  }
                  index = index - 1;
                  return CheckboxListTile(
                    checkColor: Colors.white,
                    activeColor: Colors.grey,
                    title: Text(weekDays[index]),
                    value: isCheckedList[index],
                    onChanged: (val) {
                      setState(() {
                        isCheckedList[index] = val!;
                        returnCheckedWeekdays();
                      });
                    },
                    secondary: Icon(weekDayIcons[index]),
                  );
                })));
  }

  void returnCheckedWeekdays() {
    List<int> selectedWeekdays = <int>[];
    for (int i = 0; i < isCheckedList.length; i++) {
      if (isCheckedList[i]) {
        selectedWeekdays.add(i + 1);
      }
    }
    widget.checkedCallback(selectedWeekdays);
  }
}