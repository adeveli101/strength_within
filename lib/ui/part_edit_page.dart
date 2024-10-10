import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import  'package:keyboard_actions/keyboard_actions.dart';

import '../models/exercise.dart';
import '../models/part.dart';
import '../models/routine.dart';
import '../utils/routine_helpers.dart';

class PartEditPage extends StatefulWidget {
  final Part part;
  final AddOrEdit addOrEdit;
  final Routine curRoutine;

  PartEditPage({required this.addOrEdit, required this.part, required this.curRoutine});

  @override
  State<StatefulWidget> createState() => _PartEditPageState();
}

typedef Widget MaterialCallback();

class Item {
  bool isExpanded;
  final String header;
  final Widget body;
  final Icon iconpic;
  final MaterialCallback callback;
  Item({required this.isExpanded, required this.header, required this.body, required this.iconpic, required this.callback});
}

class _PartEditPageState extends State<PartEditPage> {
  final additionalNotesTextEditingController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Routine curRoutine;
  List<TextEditingController> textControllers = <TextEditingController>[];
  List<FocusNode> focusNodes = <FocusNode>[];
  int radioValueTargetedBodyPart = 0;
  int radioValueSetType = 0;
  late bool additionalNotesIsExpanded;
  bool isNewlyCreated = false;
  late List<Item> items;
  List<Exercise> tempExs = <Exercise>[];
  late SetType setType;

  ///the widgets that are gonna be displayed in the expansionPanel of exercise detail
  List<bool> enabledList = <bool>[true, false, false, false];

  @override
  void initState() {
    ///copy the content of exercises of the Part
    additionalNotesIsExpanded = false;

    additionalNotesTextEditingController.text = widget.part.additionalNotes;

    //Determine whether or not the exercise is newly created.
    if (widget.part.exercises.length == 0) {
      for (int i = 0; i < 4; i++) {
        var exCopy = Exercise(
          name: 'Default Name', // Provide a default string
          weight: 0.0,          // Provide a default double
          sets: 1,              // Provide a default integer
          reps: '0',            // Provide a default string
          exHistory: {},
        );
        tempExs.add(exCopy);
      }
      isNewlyCreated = true;
    } else {
      //if the part is an existing part that's been editing, then copy the whole thing to _tempExs
      for (int i = 0; i < 4; i++) {
        if (i < widget.part.exercises.length) {
          var ex = widget.part.exercises[i];
          var exCopy = Exercise(
            name: ex.name,
            weight: ex.weight,
            sets: ex.sets,
            reps: ex.reps,
            workoutType: ex.workoutType,
            exHistory: Map.from(ex.exHistory), // Ensure deep copy if needed
          );
          tempExs.add(exCopy);
        } else {
          tempExs.add(Exercise(
            name: 'Default Name',
            weight: 0.0,
            sets: 1,
            reps: '0',
            exHistory: {},
          ));
        }
      }
      isNewlyCreated = false;
    }

    setType = isNewlyCreated ? SetType.regular : widget.part.setType;

    switch (widget.part.targetedBodyPart) {
      case TargetedBodyPart.abs:
        radioValueTargetedBodyPart = 0;
        break;
      case TargetedBodyPart.arm:
        radioValueTargetedBodyPart = 1;
        break;
      case TargetedBodyPart.back:
        radioValueTargetedBodyPart = 2;
        break;
      case TargetedBodyPart.chest:
        radioValueTargetedBodyPart = 3;
        break;
      case TargetedBodyPart.leg:
        radioValueTargetedBodyPart = 4;
        break;
      case TargetedBodyPart.shoulder:
        radioValueTargetedBodyPart = 5;
        break;
      case TargetedBodyPart.bicep:
        radioValueTargetedBodyPart = 6;
        break;
      case TargetedBodyPart.tricep:
        radioValueTargetedBodyPart = 7;
        break;
      case TargetedBodyPart.fullBody:
        radioValueTargetedBodyPart = 8;
        break;
    }

    switch (widget.part.setType) {
      case SetType.regular:
        radioValueSetType = 0;
        break;
      case SetType.drop:
        radioValueSetType = 1;
        break;
      case SetType.super_:
        radioValueSetType = 2;
        break;
      case SetType.tri:
        radioValueSetType = 3;
        break;
      case SetType.giant:
        radioValueSetType = 4;
        break;
      case SetType.normal:break;
    }

    for (int i = 0; i < 16; i++) {
      textControllers.add(TextEditingController());
    }

    for (int i = 0, j = 0; i < widget.part.exercises.length && j < textControllers.length; i++, j += 4) {
      textControllers[j].text = widget.part.exercises[i].name;
      textControllers[j + 1].text = widget.part.exercises[i].weight.toString();
      textControllers[j + 2].text = widget.part.exercises[i].sets.toString();
      textControllers[j + 3].text = widget.part.exercises[i].reps;
    }

    textControllers.forEach((_) {
      focusNodes.add(FocusNode());
    });

    items = <Item>[
      Item(
          isExpanded: true,
          header: 'Targeted Muscle Group',
          callback: buildTargetedBodyPartRadioList,
          iconpic: Icon(Icons.accessibility_new), body: Container()),
      Item(isExpanded: false, header: 'Set Type', callback: buildSetTypeList, iconpic: Icon(Icons.blur_linear), body: Container()), // Provide an empty Container() if body can be null

      Item(isExpanded: true, header: 'Set Details', callback: buildSetDetailsList, iconpic: Icon(Icons.fitness_center), body: Container())
    ];

    super.initState();
  }


  Future<bool> onWillPop() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?'),
        content: Text('Your editing will not be saved.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              if (widget.addOrEdit == AddOrEdit.add) widget.curRoutine.parts.removeLast();
              Navigator.of(context).pop(true);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    ).then((value) {
      if (value == null || value == false) {
        return false;
      } else {
        return true;
      }
    });
  }

  Widget buildTargetedBodyPartRadioList() {
    return Material(
      color: Colors.transparent,
      child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(children: <Widget>[
            RadioListTile(value: 0, groupValue: radioValueTargetedBodyPart, onChanged: onRadioValueChanged, title: Text('Abs')),
            RadioListTile(value: 1, groupValue: radioValueTargetedBodyPart, onChanged: onRadioValueChanged, title: Text('Arm')),
            RadioListTile(value: 2, groupValue: radioValueTargetedBodyPart, onChanged: onRadioValueChanged, title: Text('Back')),
            RadioListTile(value: 3, groupValue: radioValueTargetedBodyPart, onChanged: onRadioValueChanged, title: Text('Chest')),
            RadioListTile(value: 4, groupValue: radioValueTargetedBodyPart, onChanged: onRadioValueChanged, title: Text('Leg')),
            RadioListTile(value: 5, groupValue: radioValueTargetedBodyPart, onChanged: onRadioValueChanged, title: Text('Shoulder')),
            RadioListTile(value: 6, groupValue: radioValueTargetedBodyPart, onChanged: onRadioValueChanged, title: Text('Bicep')),
            RadioListTile(value: 7, groupValue: radioValueTargetedBodyPart, onChanged: onRadioValueChanged, title: Text('Tricep')),
            RadioListTile(value: 8, groupValue: radioValueTargetedBodyPart, onChanged: onRadioValueChanged, title: Text('Full Body')),
          ])),
    );
  }

  Widget buildSetTypeList() {
    var selectedTextStyle = TextStyle(fontSize: 16);
    var unselectedTextStyle = TextStyle(fontSize: 14);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<SetType>(
          children: {
            SetType.regular: Text('Regular', style: this.setType == SetType.regular ? selectedTextStyle : unselectedTextStyle),
            SetType.super_: Text('Super', style: this.setType == SetType.super_ ? selectedTextStyle : unselectedTextStyle),
            SetType.tri: Text('Tri', style: this.setType == SetType.tri ? selectedTextStyle : unselectedTextStyle),
            SetType.giant: Text('Giant', style: this.setType == SetType.giant ? selectedTextStyle : unselectedTextStyle),
            SetType.drop: Text('Drop', style: this.setType == SetType.drop ? selectedTextStyle : unselectedTextStyle)
          },
          onValueChanged: (setType) {
            setState(() {
              this.setType = setType!;
            });
          },
          thumbColor: setTypeToColorConverter(this.setType),
          groupValue: setType,
        ),
      ),
    );
  }

  ///Build the expansion panel for detailed information on exercises
  Widget buildSetDetailsList() {
    return Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(children: buildSetDetails()),
        ));
  }

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
        keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
        keyboardBarColor: Colors.grey[200],
        nextFocus: true,
        actions: focusNodes.map((node) {
          return KeyboardActionsItem(
            focusNode: node,
            onTapAction: () {},
          );
        }).toList());
  }

  List<Widget> buildSetDetails() {
    const count = 4;

    List<Widget> widgets = <Widget>[];

    int exCount = setTypeToExerciseCountConverter(setType);

    for (int i = 0; i < 4; i++) {
      if (i < exCount) {
        enabledList[i] = true;
      } else {
        enabledList[i] = false;
      }
    }

    //setType will not be passed in when initializing this page
    for (int i = 0, j = 0; i < count; i++, j += 4) {
      if (enabledList[i]) {
        widgets.add(Text('Exercise ' + (i + 1).toString()));
        widgets.add(Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                  child: Text(
                    'Rep',
                    textAlign: TextAlign.center,
                  )),
              Expanded(
                child: Switch(
                  value: tempExs[i].workoutType == WorkoutType.cardio,
                  onChanged: (res) {
                    setState(() {
                      tempExs[i].workoutType = res ? WorkoutType.cardio : WorkoutType.weight;
                    });
                  },
                  inactiveThumbColor: Colors.red,
                  inactiveTrackColor: Colors.redAccent,
                ),
              ),
              Expanded(
                child: Text(
                  'Sec',
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        ));
        widgets.add(Builder(
          builder: (context) => TextFormField(
            controller: textControllers[j],
            focusNode: focusNodes[j],
            style: TextStyle(fontSize: 18),
            onFieldSubmitted: (str) {
              setState(() {
                //widget.part.exercises[i].name = str;
              });
            },
            decoration: InputDecoration(labelText: 'Name'),
            validator: (str) {
              if (str!.isEmpty) {
                return 'Please enter the name of exercise';
              } else {
                tempExs[i].name = textControllers[j].text;
                return null;
              }
            },
          ),
        ));
        widgets.add(Row(
          children: <Widget>[
            Flexible(
              child: Builder(
                  builder: (context) => TextFormField(
                    controller: textControllers[j + 1],
                    focusNode: focusNodes[j + 1],
                    onFieldSubmitted: (str) {},
                    keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(labelText: 'Weight'),
                    style: TextStyle(fontSize: 20),
                    validator: (str) {
                      if (str!.isEmpty) {
                        tempExs[i].weight = 0;
                        return null;
                      } else if (str.contains(RegExp(r"([,\-])"))) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: Colors.red,
                          content: Row(
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.report),
                              ),
                              Text("Weight can only contain numbers.")
                            ],
                          ),
                        ));
                        return "Numbers only";
                      } else {
                        try {
                          double tempWeight = double.parse(textControllers[j + 1].text);
                          //the weight below 20 doesn't need floating point, it's just unnecessary
                          if (tempWeight < 20) {
                            tempExs[i].weight = tempWeight;
                          } else {
                            tempExs[i].weight = tempWeight.floorToDouble();
                          }

                          return null;
                        } catch (Exception) {}
                      }
                      return null;
                    },
                  )),
            ),
            Flexible(
              child: TextFormField(
                controller: textControllers[2],
                focusNode: focusNodes[j + 2],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (str) {},
                keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                decoration: InputDecoration(labelText: 'Sets'),
                style: TextStyle(fontSize: 20),
                validator: (str) {
                  if (str!.isEmpty) {
                    tempExs[i].sets = 1; //number of sets must be none zero
                    return null;
                  } else if (str.contains(RegExp(r"([,.\-])"))) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Sets can only contain numbers."),
                    ));
                    return "Numbers only";
                  } else {
                    tempExs[i].sets = int.parse(textControllers[2].text); //before: _textControllers[j + 2],
                    return null;
                  }
                },
              ),
            ),
            Flexible(
              child: TextFormField(
                controller: textControllers[j + 3],
                focusNode: focusNodes[j + 3],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (str) {},
                keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                decoration: InputDecoration(labelText: tempExs[i].workoutType == WorkoutType.weight ? 'Reps' : 'Seconds'),
                style: TextStyle(fontSize: 20),
                validator: (str) {
                  if (str!.isEmpty) {
                    return 'Cannot be empty';
                  } else
                    tempExs[i].reps = textControllers[j + 3].text;
                  return null;
                },
              ),
            )
          ],
        ));
        widgets.add(Container(
          //serve as divider
          height: 24,
        ));
      }
    }
    return widgets;
  }

  late ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];
    items.forEach((Item item) {
      children.add(ListTile(
          leading: item.iconpic,
          title: Text(item.header,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w400,
              ))));
      children.add(item.callback());
    });

    var listView = KeyboardActions(
      config: _buildConfig(context),
      child: Column(
        children: [
          Form(
              key: formKey,
              child: Padding(
                //Targeted Body Part, Type of set, Details
                  padding: EdgeInsets.all(0),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: children,
                    ),
                  ))),
        ],
      ),
    );

    var scaffold = Scaffold(
      key: scaffoldKey,
      appBar: AppBar(title: Text("Criteria Selection"), actions: <Widget>[
        Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.done),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  widget.part.targetedBodyPart = PartEditPageHelper.radioValueToTargetedBodyPartConverter(radioValueTargetedBodyPart);
                  widget.part.setType = setType;
                  widget.part.exercises = <Exercise>[];
                  for (int i = 0; i < enabledList.where((res) => res).length; i++) {
                    widget.part.exercises.add(Exercise(
                        name: tempExs[i].name,
                        weight: tempExs[i].weight,
                        sets: tempExs[i].sets,
                        reps: tempExs[i].reps,
                        workoutType: tempExs[i].workoutType,
                        exHistory: tempExs[i].exHistory));
                  }
                  widget.part.additionalNotes = additionalNotesTextEditingController.text;
                  Navigator.pop(context, widget.part);
                }
              },
            );
          },
        )
      ]),
      body: listView,
    );
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          // t0d0 : Handle the case where pop was not successful
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Action Required'),
              content: Text('Unable to exit. Please ensure all changes are saved or canceled.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Optionally handle the result if needed
          if (result != null) {
            // Process the result if there's any specific logic needed
            print('Result from pop: $result');
          }
        }
      },
      child: scaffold,
    );



  }

  void onRadioValueChanged(int? value) {
    setState(() {
      radioValueTargetedBodyPart = value ?? 0; // Provide a default value if null
    });
  }


  void onRadioSetTypeValueChanged(int value) {
    setState(() {
      radioValueSetType = value;
      setType = PartEditPageHelper.radioValueToSetTypeConverter(value);
    });
  }
}

class PartEditPageHelper {
  static SetType radioValueToSetTypeConverter(int radioValue) {
    switch (radioValue) {
      case 0:
        return SetType.regular;
      case 1:
        return SetType.drop;
      case 2:
        return SetType.super_;
      case 3:
        return SetType.tri;
      case 4:
        return SetType.giant;
      default:
        throw Exception('Inside _radioValueToSetTypeConverter');
    }
  }

  static TargetedBodyPart radioValueToTargetedBodyPartConverter(int radioValue) {
    switch (radioValue) {
      case 0:
        return TargetedBodyPart.abs;
      case 1:
        return TargetedBodyPart.arm;
      case 2:
        return TargetedBodyPart.back;
      case 3:
        return TargetedBodyPart.chest;
      case 4:
        return TargetedBodyPart.leg;
      case 5:
        return TargetedBodyPart.shoulder;
      case 6:
        return TargetedBodyPart.bicep;
      case 7:
        return TargetedBodyPart.tricep;
      case 8:
        return TargetedBodyPart.fullBody;
      default:
        throw Exception('Inside _radioValueToTargetedBodyPartConverter, radioValue: ${radioValue.toString()}');
    }
  }
}