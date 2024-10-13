import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/part.dart';
import '../models/routine.dart';
import '../utils/routine_helpers.dart';
import '../resource/db_provider.dart';

class PartEditPage extends StatefulWidget {
  final Part part;
  final AddOrEdit addOrEdit;
  final Routine curRoutine;

  PartEditPage({required this.addOrEdit, required this.part, required this.curRoutine});

  @override
  State<PartEditPage> createState() => _PartEditPageState();
}

class _PartEditPageState extends State<PartEditPage> {
  final additionalNotesTextEditingController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Routine curRoutine;
  int radioValueTargetedBodyPart = 0;
  int radioValueSetType = 0;
  late bool additionalNotesIsExpanded;
  bool isNewlyCreated = false;
  late List<Item> items;
  List<Exercise> selectedExercises = [];
  late SetType setType;
  List<Exercise> allExercises = [];

  @override
  void initState() {
    super.initState();
    additionalNotesIsExpanded = false;
    additionalNotesTextEditingController.text = widget.part.additionalNotes;
    curRoutine = widget.curRoutine;

    setType = widget.part.setType;
    radioValueTargetedBodyPart = _getRadioValueForTargetedBodyPart(widget.part.targetedBodyPart);
    radioValueSetType = _getRadioValueForSetType(widget.part.setType);

    _loadExercises();

    items = [
      Item(
        isExpanded: true,
        header: 'Targeted Muscle Group',
        callback: buildTargetedBodyPartRadioList,
        iconpic: Icon(Icons.accessibility_new),
        body: Container(),
      ),
      Item(
        isExpanded: false,
        header: 'Set Type',
        callback: buildSetTypeList,
        iconpic: Icon(Icons.blur_linear),
        body: Container(),
      ),
      Item(
        isExpanded: true,
        header: 'Exercise Selection',
        callback: buildExerciseSelectionList,
        iconpic: Icon(Icons.fitness_center),
        body: Container(),
      ),
    ];
  }

  Future<void> _loadExercises() async {
    if (widget.part.exerciseIds.isNotEmpty) {
      final exercises = await DBProvider.db.getExercisesForPart(widget.part);
      setState(() {
        selectedExercises = exercises.values.toList();
      });
    }
  }


  int _getRadioValueForTargetedBodyPart(TargetedBodyPart part) {
    return part.index;
  }

  int _getRadioValueForSetType(SetType type) {
    return type.index;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Text("Edit Part"),
          actions: [
            IconButton(
              icon: Icon(Icons.done),
              onPressed: _onDone,
            ),
          ],
        ),
        body: ListView(
          children: [
            Form(
              key: formKey,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: items.map((Item item) {
                    return Column(
                      children: [
                        ListTile(
                          leading: item.iconpic,
                          title: Text(
                            item.header,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                          ),
                        ),
                        item.callback(),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?'),
        content: Text('Your changes will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              if (widget.addOrEdit == AddOrEdit.add) widget.curRoutine.partIds.removeLast();
              Navigator.of(context).pop(true);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _onDone() {
    if (formKey.currentState!.validate()) {
      widget.part.targetedBodyPart = PartEditPageHelper.radioValueToTargetedBodyPartConverter(radioValueTargetedBodyPart);
      widget.part.setType = setType;
      widget.part.exerciseIds = selectedExercises.map((e) => e.id).toList();
      widget.part.additionalNotes = additionalNotesTextEditingController.text;
      Navigator.pop(context, widget.part);
    }
  }

  Widget buildTargetedBodyPartRadioList() {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: TargetedBodyPart.values.map((part) {
            return RadioListTile<int>(
              value: part.index,
              groupValue: radioValueTargetedBodyPart,
              onChanged: (value) => setState(() => radioValueTargetedBodyPart = value!),
              title: Text(part.toString().split('.').last),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildSetTypeList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<SetType>(
          children: SetType.values.asMap().map((i, type) => MapEntry(type, Text(type.toString().split('.').last))),
          onValueChanged: (value) {
            setState(() {
              setType = value!;
            });
          },
          groupValue: setType,
        ),
      ),
    );
  }

  Widget buildExerciseSelectionList() {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...allExercises.map((exercise) => CheckboxListTile(
              title: Text(exercise.name),
              value: selectedExercises.contains(exercise),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedExercises.add(exercise);
                  } else {
                    selectedExercises.remove(exercise);
                  }
                });
              },
            )),
          ],
        ),
      ),
    );
  }
}

class Item {
  bool isExpanded;
  final String header;
  final Widget body;
  final Icon iconpic;
  final Widget Function() callback;

  Item({
    required this.isExpanded,
    required this.header,
    required this.body,
    required this.iconpic,
    required this.callback,
  });
}

class PartEditPageHelper {
  static SetType radioValueToSetTypeConverter(int radioValue) {
    return SetType.values[radioValue];
  }

  static TargetedBodyPart radioValueToTargetedBodyPartConverter(int radioValue) {
    return TargetedBodyPart.values[radioValue];
  }
}