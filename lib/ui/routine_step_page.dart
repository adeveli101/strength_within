import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/routines_bloc.dart';
import '../models/exercise.dart';
import '../models/part.dart';
import '../models/routine.dart';
import '../utils/routine_helpers.dart';
import 'components/custom_snack_bars.dart';
import 'components/number_ticker.dart';
import 'package:intl/intl.dart';


/// Note:
/// Some really bad design decision made in the early stage of this project has led to this incredibly messy code.

class RoutineStepPage extends StatefulWidget {
  final Routine routine;
  final VoidCallback celebrateCallback;
  final VoidCallback onBackPressed;

  RoutineStepPage({required this.routine, required this.celebrateCallback, required this.onBackPressed});

  @override
  State<StatefulWidget> createState() => _RoutineStepPageState();
}

const LabelTextStyle = TextStyle(color: Colors.white70);
const SmallBoldTextStyle = TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold);

class _RoutineStepPageState extends State<RoutineStepPage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ConfettiController confettiController = ConfettiController(duration: Duration(seconds: 10));
  final timerDuration = Duration(milliseconds: 50);
  var stepperKey = GlobalKey();

  late List<Exercise> exercises;
  bool finished = false, initialized = false;

  late Routine routine;
  late String title;

  late Timer incrementTimer;
  late Timer decrementTimer;

  List<int> setsLeft = [];
  List<int> currentPartIndexes = [];
  List<int> stepperIndexes = [];
  int currentStep = 0;

  var timeout = const Duration(seconds: 1);
  var ms = const Duration(milliseconds: 1);

  @override
  void initState() {
    super.initState();
    routine = Routine.copyFromRoutine(widget.routine);

    String tempDateStr = dateTimeToStringConverter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    for (var part in routine.parts) {
      for (var ex in part.exercises) {
        if (ex.exHistory.containsKey(tempDateStr)) {
          ex.exHistory.remove(tempDateStr);
        }
      }
    }

    exercises = widget.routine.parts.expand((p) => p.exercises).toList();
    generateStepperIndexes();
  }

  Widget build(BuildContext context) {
    title = currentStep < stepperIndexes.length
        ? targetedBodyPartToStringConverter(routine.parts[currentPartIndexes[currentStep]].targetedBodyPart) +
        ' - ' +
        setTypeToStringConverter(routine.parts[currentPartIndexes[currentStep]].setType)
        : 'Finished';

    return PopScope<Object?>(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (finished) return;

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.white,
            elevation: 4,
            child: Container(
              height: 200,
              child: Flex(
                direction: Axis.vertical,
                children: <Widget>[
                  Flexible(
                    flex: 7,
                    child: Container(
                      width: double.infinity,
                      color: Theme.of(context).primaryColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Text(
                            'Too soon to quit.😑',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Text(
                            'Your progress will not be saved.',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 3,
                    child: Container(
                      height: double.infinity,
                      width: double.infinity,
                      color: Colors.transparent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'Stay',
                              style:
                              TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            child: Text(
                              'Quit',
                              style:
                              TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );

        if (shouldPop == true) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            title,
            style: TextStyle(color: Colors.white54),
          ),
          bottom: PreferredSize(
            child: LinearProgressIndicator(
              value: currentStep / stepperIndexes.length,
            ),
            preferredSize: Size.fromHeight(12),
          ),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        backgroundColor: Theme.of(context).primaryColor,
        body: buildMainLayout(),
      ),
    );
  }

// ...

// Somewhere else in  code, when creating RoutineStepPage  builder: (_) => RoutineStepPage(
//   routine: routine,
//   onBackPressed: () {
//   Navigator.pop(context);
//   },
//   celebrateCallback: () {
//   // Implement your celebration logic here
//   // For example, you might start a confetti animation or show a congratulatory message.
//   print("perfect!");
//   },
//   )



  Widget buildMainLayout() {
    if (!finished) {
      return buildStepper(exercises);
    }

    return Stack(
      children: [
        Container(
          alignment: Alignment.center,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Theme.of(context).primaryColor,
          child: Container(
            alignment: Alignment.center,
            color: Colors.transparent,
            child: Text(
              'You finished it!',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            // don't specify a direction, blast randomly
            shouldLoop: false,
            // start again as soon as the animation is finished
            blastDirection: 3.14 / 2,
            maxBlastForce: 8,
            // set a lower max blast force
            minBlastForce: 4,
            // set a lower min blast force
            emissionFrequency: 0.05,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple], // manually specify the colors to be used
            // define a custom shape/path.
          ),
        ),
      ],
    );
  }

  void generateStepperIndexes() {
    var parts = widget.routine.parts;
    var indexes = <int>[];

    for (int i = 0, k = 0; k < parts.length; k++) {
      var part = parts[k];
      var ex = exercises[i];
      var sets = ex.sets;
      if (part.setType case SetType.drop) {
        for (var j = 0; j < sets; j++) {
          indexes.add(i);
          currentPartIndexes.add(k);
          setsLeft.add(sets - j - 1);
        }
        i += 1;
        break;
      } else if (part.setType case SetType.regular) {
        for (var j = 0; j < ex.sets; j++) {
          indexes.add(i);
          currentPartIndexes.add(k);
          setsLeft.add(sets - j - 1);
        }
        i += 1;
        break;
      } else if (part.setType case SetType.super_) {
        for (var j = 0; j < ex.sets; j++) {
          indexes.add(i);
          indexes.add(i + 1);
          currentPartIndexes.add(k);
          currentPartIndexes.add(k);
          setsLeft.add(sets - j - 1);
          setsLeft.add(sets - j - 1);
        }
        i += 2;
        break;
      } else if (part.setType case SetType.tri) {
        for (var j = 0; j < ex.sets; j++) {
          indexes.add(i);
          indexes.add(i + 1);
          indexes.add(i + 2);
          currentPartIndexes.add(k);
          currentPartIndexes.add(k);
          currentPartIndexes.add(k);
          setsLeft.add(sets - j - 1);
          setsLeft.add(sets - j - 1);
          setsLeft.add(sets - j - 1);
        }
        i += 3;
        break;
      } else if (part.setType case SetType.giant) {
        for (var j = 0; j < ex.sets; j++) {
          indexes.add(i);
          indexes.add(i + 1);
          indexes.add(i + 2);
          indexes.add(i + 3);
          currentPartIndexes.add(k);
          currentPartIndexes.add(k);
          currentPartIndexes.add(k);
          currentPartIndexes.add(k);
          setsLeft.add(sets - j - 1);
          setsLeft.add(sets - j - 1);
          setsLeft.add(sets - j - 1);
          setsLeft.add(sets - j - 1);
        }
        i += 4;
        break;
      }
    }

    stepperIndexes = indexes;
  }

  void updateExHistory() {
    print("updating ex history: $currentStep");
    String tempDateStr = dateTimeToStringConverter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    var partIndex = currentPartIndexes[currentStep];
    var exIndex = routine.parts[partIndex].exercises.indexWhere((e) => e.name == exercises[stepperIndexes[currentStep]].name);

    print("updating ex history: $currentStep");

    if (routine.parts[partIndex].exercises[exIndex].exHistory.containsKey(tempDateStr)) {
      routine.parts[partIndex].exercises[exIndex].exHistory[tempDateStr] +=
          '/' + routine.parts[partIndex].exercises[exIndex].weight.toString();
    } else {
      routine.parts[partIndex].exercises[exIndex].exHistory[tempDateStr] = routine.parts[partIndex].exercises[exIndex].weight.toString();
    }
  }

  Widget buildStepper(List<Exercise> exs) {
    return SingleChildScrollView(
      child: Stepper(
        key: stepperKey,
        physics: NeverScrollableScrollPhysics(),
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return OverflowBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                  child: Text(
                    'Next',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                onPressed: details.onStepContinue,
              )
            ],
          );
        },

        currentStep: stepperIndexes[currentStep],
        onStepContinue: () {
          if (!finished && currentStep < stepperIndexes.length - 1) {
            updateExHistory();
            setState(() {
              currentStep += 1;
            });
          } else {
            updateExHistory();
            setState(() {
              finished = true;
              currentStep += 1;
            });
            confettiController.play();
            routine.completionCount++;
            if (!routine.routineHistory.contains(getTimestampNow())) {
              routine.routineHistory.add(getTimestampNow());
            }

            routinesBloc.updateRoutine(routine);
          }
        },
        steps: List.generate(exs.length, (index) => index).map((i) {
          Color exNameColor = Colors.black;
          double exNameSize = 16;
          var isCurrent = i == stepperIndexes[currentStep];
          var isNext = stepperIndexes.length == currentStep + 1 ? false : (i == stepperIndexes[currentStep + 1]);
          var isPast = !stepperIndexes.sublist(currentStep).contains(i);

          if (isCurrent) {
            exNameColor = Colors.white;
            exNameSize = 24;
          } else if (isNext) {
            exNameColor = Colors.white60;
            exNameSize = 20;
          }

          return Step(
            title: Text(
              exs[i].name,
              style: TextStyle(fontSize: exNameSize, fontWeight: FontWeight.w300, color: exNameColor, decoration: isPast?TextDecoration.lineThrough:TextDecoration.none),
            ),
            content: buildStep(exs[i]),
          );
        }).toList(),
      ),
    );
  }

  Widget buildStep(Exercise ex) {
    var setType = widget.routine.parts[currentPartIndexes[currentStep]].setType;
    var partIndex = currentPartIndexes[currentStep];
    var exIndex = routine.parts[partIndex].exercises.indexWhere((e) => e.name == exercises[stepperIndexes[currentStep]].name);
    var ex = routine.parts[partIndex].exercises[exIndex];
    var tickerController = NumberTickerController();
    return ListTile(
      title: Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: IconButton(
              icon: Icon(
                Icons.info,
                color: Colors.white,
              ),
              onPressed: () {
                launchURL(ex.name);
              },
            ),
          ),
        ],
      ),
      subtitle: Column(
        children: <Widget>[
          Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: RichText(
                      text: TextSpan(children: <TextSpan>[
                        TextSpan(text: 'Weight: ', style: LabelTextStyle),
                      ]),
                    ),
                  ),
                ),
              ]),
          Row(children: <Widget>[
            Expanded(
                flex: 2,
                child: GestureDetector(
                  onLongPress: () {
                    decreaseWeight(tickerController, ex);
                  },
                  onLongPressUp: () {
                    decrementTimer.cancel();
                  },
                  child: ElevatedButton(
                      child: Text(
                        '-',
                        style: TextStyle(fontSize: 28),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: CircleBorder(),
                      ),
                      onPressed: () {
                        tickerController.number = tickerController.number - 1;
                        ex.weight = tickerController.number;
                      }),
                )),
            Expanded(
              flex: 6,
              child: Center(
                  child: NumberTicker(
                    controller: tickerController,
                    initialNumber: ex.weight,
                    textStyle: TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold),
                  )),
            ),
            Expanded(
                flex: 2,
                child: GestureDetector(
                  onLongPress: () {
                    increaseWeight(tickerController, ex);
                  },
                  onLongPressUp: () {
                    incrementTimer.cancel();
                  },
                  child: ElevatedButton(
                      child: Text(
                        '+',
                        style: TextStyle(fontSize: 24),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: CircleBorder(),
                      ),
                      onPressed: () {
                        tickerController.number = tickerController.number + 1;

                        ex.weight = tickerController.number;
                        //DBProvider.db.updateRoutine(routine);
                      }),
                )),
          ]),
          Row(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: RichText(
                    text: TextSpan(children: <TextSpan>[
                      TextSpan(text: 'Sets left: ', style: LabelTextStyle),
                    ]),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                    child: RichText(
                      text: TextSpan(children: <TextSpan>[
                        TextSpan(text: ex.workoutType == WorkoutType.weight ? 'Reps: ' : 'Seconds: ', style: LabelTextStyle),
                      ]),
                    )),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: RichText(
                    text: TextSpan(children: <TextSpan>[
                      TextSpan(
                          text: setsLeft[currentStep].toString(),
                          style: TextStyle(color: Colors.white, fontSize: getSetRepFontSize(setType), fontWeight: FontWeight.bold))
                    ]),
                  ),
                ),
              ),
              Expanded(
                  child: Center(
                    child: RichText(
                      text: TextSpan(children: <TextSpan>[
                        TextSpan(
                            text: ex.reps,
                            style: TextStyle(color: Colors.white, fontSize: getSetRepFontSize(setType), fontWeight: FontWeight.bold))
                      ]),
                    ),
                  )),
            ],
          )
        ],
      ),
    );
  }

  Future<bool> onWillPop() async {
    if (finished) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        elevation: 4,
        child: Container(
          height: 200,
          child: Flex(
            direction: Axis.vertical,
            children: <Widget>[
              Flexible(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  color: Theme.of(context).primaryColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Text(
                        'Too soon to quit.😑',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        'Your progress will not be saved.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: 3,
                child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: Colors.transparent,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Stay',
                          style:
                          TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: Text(
                          'Quit',
                          style:
                          TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }

  void decreaseWeight(NumberTickerController controller, Exercise ex) {
    decrementTimer = Timer.periodic(timerDuration, (Timer t) {
      controller.number = controller.number - 1;
      ex.weight = controller.number;
    });
  }

  void increaseWeight(NumberTickerController controller, Exercise ex) {
    incrementTimer = Timer.periodic(timerDuration, (Timer t) {
      controller.number = controller.number + 1;
      ex.weight = controller.number;
    });
  }

  String dateTimeToStringConverter(DateTime dateTime) {
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    return dateFormat.format(dateTime);
  }

  double getWeightFontSize(SetType st) {
    switch (st) {
      case SetType.regular:
        return 72;
      case SetType.drop:
        return 72;
      case SetType.super_:
        return 72;
      case SetType.tri:
        return 64;
      case SetType.giant:
        return 72;
      default:
        throw Exception("Inside _getWeightFontSize()");
    }
  }

  double getSetRepFontSize(SetType st) {
    switch (st) {
      case SetType.regular:
        return 36;
      case SetType.drop:
        return 36;
      case SetType.super_:
        return 36;
      case SetType.tri:
        return 28;
      case SetType.giant:
        return 36;
      default:
        throw Exception("Inside _getWeightFontSize()");
    }
  }

  Future<void> launchURL(String ex) async {
    var connectivity = await Connectivity().checkConnectivity();

    if (connectivity == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(noNetworkSnackBar);
    } else {
      final Uri url = Uri.parse('https://www.bodybuilding.com/exercises/search?query=' + Uri.encodeComponent(ex));

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.inAppWebView, // veya LaunchMode.externalApplication
        );
      } else {
        throw Exception('Could not launch $url');
      }
    }
  }
}