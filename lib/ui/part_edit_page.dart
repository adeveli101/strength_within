import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workout/utils/routine_helpers.dart';
import 'package:workout/models/routine.dart';
import '../models/exercise.dart';
import '../models/part.dart';
import 'components/part_edit_card.dart';

class PartEditPage extends StatefulWidget {
  final Part part;
  final AddOrEdit addOrEdit;
  final Routine curRoutine;

  const PartEditPage({
    super.key,
    required this.addOrEdit,
    required this.part,
    required this.curRoutine,
  });

  @override
  State<PartEditPage> createState() => _PartEditPageState();
}

class Item {
  bool isExpanded;
  final String header;
  final Widget Function() callback;
  final Icon iconpic;

  Item({
    required this.isExpanded,
    required this.header,
    required this.callback,
    required this.iconpic,
  });
}

class _PartEditPageState extends State<PartEditPage> {
  final additionalNotesTextEditingController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late List<TextEditingController> textControllers;
  late List<FocusNode> focusNodes;
  int radioValueTargetedBodyPart = 0;
  late SetType setType;
  bool additionalNotesIsExpanded = false;
  bool isNewlyCreated = false;
  late List<Item> items;
  List<Exercise> tempExs = [];
  List<bool> enabledList = List.filled(4, false);

  @override
  void initState() {
    super.initState();
    additionalNotesTextEditingController.text = widget.part.additionalNotes;
    initializeExercises();
    initializeControllers();
    initializeItems();
  }

  void initializeExercises() {
    if (widget.part.exercises.isEmpty) {
      for (int i = 0; i < 4; i++) {
        tempExs.add(Exercise(name: '', weight: 0, sets: 0, reps: '', exHistory: {}));
      }
      isNewlyCreated = true;
      setType = SetType.regular;
    } else {
      for (int i = 0; i < 4; i++) {
        if (i < widget.part.exercises.length) {
          var ex = widget.part.exercises[i];
          tempExs.add(Exercise(
            name: ex.name,
            weight: ex.weight,
            sets: ex.sets,
            reps: ex.reps,
            workoutType: ex.workoutType,
            exHistory: ex.exHistory,
          ));
        } else {
          tempExs.add(Exercise(name: '', weight: 0, sets: 0, reps: '', exHistory: {}));
        }
      }
      isNewlyCreated = false;
      setType = widget.part.setType;
    }
    radioValueTargetedBodyPart = getRadioValueForTargetedBodyPart(widget.part.targetedBodyPart);
  }

  void initializeControllers() {
    textControllers = List.generate(16, (_) => TextEditingController());
    focusNodes = List.generate(16, (_) => FocusNode());

    for (int i = 0, j = 0; i < 4; i++, j += 4) {
      if (i < widget.part.exercises.length) {
        textControllers[j].text = widget.part.exercises[i].name;
        textControllers[j + 1].text = widget.part.exercises[i].weight.toString();
        textControllers[j + 2].text = widget.part.exercises[i].sets.toString();
        textControllers[j + 3].text = widget.part.exercises[i].reps;
      }
    }
  }

  void initializeItems() {
    items = [
      Item(
        isExpanded: true,
        header: 'Targeted Muscle Group',
        callback: buildTargetedBodyPartRadioList,
        iconpic: const Icon(Icons.accessibility_new),
      ),
      Item(
        isExpanded: false,
        header: 'Set Type',
        callback: buildSetTypeList,
        iconpic: const Icon(Icons.blur_linear),
      ),
      Item(
        isExpanded: true,
        header: 'Set Details',
        callback: buildSetDetailsList,
        iconpic: const Icon(Icons.fitness_center),
      ),
    ];
  }

  int getRadioValueForTargetedBodyPart(TargetedBodyPart targetedBodyPart) {
    switch (targetedBodyPart) {
      case TargetedBodyPart.abs:
        return 0;
      case TargetedBodyPart.arm:
        return 1;
      case TargetedBodyPart.back:
        return 2;
      case TargetedBodyPart.chest:
        return 3;
      case TargetedBodyPart.leg:
        return 4;
      case TargetedBodyPart.shoulder:
        return 5;
      case TargetedBodyPart.bicep:
        return 6;
      case TargetedBodyPart.tricep:
        return 7;
      case TargetedBodyPart.fullBody:
        return 8;
      default:
        return 0;
    }
  }

  Future<bool> onWillPop() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Your editing will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              if (widget.addOrEdit == AddOrEdit.add) {
                widget.curRoutine.parts.removeLast();
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget buildTargetedBodyPartRadioList() {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            RadioListTile<int>(
              value: 0,
              groupValue: radioValueTargetedBodyPart,
              onChanged: onRadioValueChanged,
              title: const Text('Abs'),
            ),
            RadioListTile<int>(
              value: 1,
              groupValue: radioValueTargetedBodyPart,
              onChanged: onRadioValueChanged,
              title: const Text('Arm'),
            ),
            // ... Add other RadioListTile widgets for remaining body parts
          ],
        ),
      ),
    );
  }

  Widget buildSetTypeList() {
    var selectedTextStyle = const TextStyle(fontSize: 16);
    var unselectedTextStyle = const TextStyle(fontSize: 14);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<SetType>(
          children: {
            SetType.regular: Text('Regular', style: setType == SetType.regular ? selectedTextStyle : unselectedTextStyle),
            SetType.super_: Text('Super', style: setType == SetType.super_ ? selectedTextStyle : unselectedTextStyle),
            SetType.tri: Text('Tri', style: setType == SetType.tri ? selectedTextStyle : unselectedTextStyle),
            SetType.giant: Text('Giant', style: setType == SetType.giant ? selectedTextStyle : unselectedTextStyle),
            SetType.drop: Text('Drop', style: setType == SetType.drop ? selectedTextStyle : unselectedTextStyle),
          },
          onValueChanged: (SetType? value) {
            if (value != null) {
              setState(() {
                setType = value;
              });
            }
          },
          thumbColor: setTypeToColorConverter(setType),
          groupValue: setType,
        ),
      ),
    );
  }

  Widget buildSetDetailsList() {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: buildSetDetails()),
      ),
    );
  }

// KeyboardActionsConfig _buildConfig(BuildContext context) fonksiyonunu kaldırın

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }
        final shouldPop = await onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: const Text("Criteria Selection"),
          actions: [
            IconButton(
              icon: const Icon(Icons.done),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  savePartData();
                  if (context.mounted) {
                    Navigator.pop(context, widget.part);
                  }
                }
              },
            ),
          ],
        ),
        body: Form(
          key: formKey,
          child: ListView(
            children: items.expand((item) => [
              ListTile(
                leading: item.iconpic,
                title: Text(
                  item.header,
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w400),
                ),
              ),
              item.callback(),
            ]).toList(),
          ),
        ),
      ),
    );
  }

  List<Widget> buildSetDetails() {
    List<Widget> widgets = [];
    int exCount = setTypeToExerciseCountConverter(setType);

    for (int i = 0; i < 4; i++) {
      enabledList[i] = i < exCount;
      if (enabledList[i]) {
        widgets.addAll([
          Text('Exercise ${i + 1}'),
          buildExerciseTypeSwitch(i),
          buildExerciseNameField(i),
          buildExerciseDetailsRow(i),
          const SizedBox(height: 24),
        ]);
      }
    }

    return widgets;
  }

  Widget buildExerciseTypeSwitch(int index) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Expanded(child: Text('Rep', textAlign: TextAlign.center)),
          Expanded(
            child: Switch(
              value: tempExs[index].workoutType == WorkoutType.cardio,
              onChanged: (bool value) {
                setState(() {
                  tempExs[index].workoutType = value ? WorkoutType.cardio : WorkoutType.weight;
                });
              },
              inactiveThumbColor: Colors.red,
              inactiveTrackColor: Colors.redAccent,
            ),
          ),
          const Expanded(child: Text('Sec', textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget buildExerciseNameField(int index) {
    return TextFormField(
      controller: textControllers[index * 4],
      focusNode: focusNodes[index * 4],
      style: const TextStyle(fontSize: 18),
      decoration: const InputDecoration(labelText: 'Name'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the name of exercise';
        }
        tempExs[index].name = value;
        return null;
      },
    );
  }

  Widget buildExerciseDetailsRow(int index) {
    return Row(
      children: [
        Flexible(
          child: TextFormField(
            controller: textControllers[index * 4 + 1],
            focusNode: focusNodes[index * 4 + 1],
            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
            decoration: const InputDecoration(labelText: 'Weight'),
            style: const TextStyle(fontSize: 20),
            validator: (value) {
              if (value == null || value.isEmpty) {
                tempExs[index].weight = 0;
                return null;
              }
              if (value.contains(RegExp(r'[,\-]'))) {
                return "Weight can only contain numbers and decimal point";
              }
              try {
                double tempWeight = double.parse(value);
                tempExs[index].weight = tempWeight < 20 ? tempWeight : tempWeight.floorToDouble();
              } catch (e) {
                return "Invalid number";
              }
              return null;
            },
          ),
        ),
        Flexible(
          child: TextFormField(
            controller: textControllers[index * 4 + 2],
            focusNode: focusNodes[index * 4 + 2],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Sets'),
            style: const TextStyle(fontSize: 20),
            validator: (value) {
              if (value == null || value.isEmpty) {
                tempExs[index].sets = 1;
                return null;
              }
              if (value.contains(RegExp(r'[,.\-]'))) {
                return "Sets can only contain whole numbers";
              }
              tempExs[index].sets = int.tryParse(value) ?? 1;
              return null;
            },
          ),
        ),
        Flexible(
          child: TextFormField(
            controller: textControllers[index * 4 + 3],
            focusNode: focusNodes[index * 4 + 3],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: tempExs[index].workoutType == WorkoutType.weight ? 'Reps' : 'Seconds',
            ),
            style: const TextStyle(fontSize: 20),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Cannot be empty';
              }
              tempExs[index].reps = value;
              return null;
            },
          ),
        ),
      ],
    );
  }


  void savePartData() {
    widget.part.targetedBodyPart = PartEditPageHelper.radioValueToTargetedBodyPartConverter(radioValueTargetedBodyPart);
    widget.part.setType = setType;
    widget.part.exercises = tempExs.where((ex) => ex.name.isNotEmpty).toList();
    widget.part.additionalNotes = additionalNotesTextEditingController.text;
  }

  void onRadioValueChanged(int? value) {
    if (value != null) {
      setState(() {
        radioValueTargetedBodyPart = value;
      });
    }
  }

  @override
  void dispose() {
    additionalNotesTextEditingController.dispose();
    for (var controller in textControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Color setTypeToColorConverter(SetType setType) {
    switch (setType) {
      case SetType.regular:
        return Colors.blue;
      case SetType.super_:
        return Colors.green;
      case SetType.tri:
        return Colors.orange;
      case SetType.giant:
        return Colors.purple;
      case SetType.drop:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int setTypeToExerciseCountConverter(SetType setType) {
    switch (setType) {
      case SetType.regular:
      case SetType.drop:
        return 1;
      case SetType.super_:
        return 2;
      case SetType.tri:
        return 3;
      case SetType.giant:
        return 4;
      default:
        return 1;
    }
  }}