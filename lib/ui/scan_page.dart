import 'dart:async';
import 'package:flutter/material.dart';
import 'package:workout/utils/routine_helpers.dart';
import 'package:workout/ui/components/part_edit_card.dart';
import 'package:workout/ui/part_edit_page.dart';
import 'package:workout/bloc/routines_bloc.dart';
import '../models/routine.dart';
import '../models/part.dart';
import 'components/spring_curve.dart';

class RoutineEditPage extends StatefulWidget {
  final AddOrEdit addOrEdit;
  final MainTargetedBodyPart mainTargetedBodyPart;

  const RoutineEditPage({
    super.key,
    required this.addOrEdit,
    required this.mainTargetedBodyPart,
  });

  @override
  State<RoutineEditPage> createState() => _RoutineEditPageState();
}


class _RoutineEditPageState extends State<RoutineEditPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final formKey = GlobalKey<FormState>();
  final TextEditingController textEditingController = TextEditingController();
  ScrollController scrollController = ScrollController();
  bool _initialized = false;
  late Routine routineCopy;
  late Routine routine;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 500), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: SpringCurve.underDamped,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          if (context.mounted) {  // Use context.mounted here
            Navigator.of(context).pop();
          }
        }
      },
      child: StreamBuilder<Routine>(
        stream: routinesBloc.currentRoutine,
        builder: (_, AsyncSnapshot<Routine> snapshot) {
          if (snapshot.hasData) {
            routine = snapshot.data!;
            if (!_initialized) {
              routineCopy = Routine.fromMap(routine.toMap());
              _initialized = true;
            }

            if (widget.addOrEdit == AddOrEdit.edit) {
              textEditingController.text = routineCopy.routineName;
            }

            return Scaffold(
              key: scaffoldKey,
              appBar: AppBar(
                actions: [
                  if (widget.addOrEdit == AddOrEdit.edit)
                    IconButton(
                      icon: const Icon(Icons.delete_forever),
                      onPressed: _showDeleteDialog,
                    ),
                  IconButton(
                    icon: const Icon(Icons.done),
                    onPressed: onDonePressed,
                  ),
                ],
              ),
              body: ReorderableListView(
                scrollController: scrollController,
                onReorder: onReorder,
                header: Form(key: formKey, child: _routineDescriptionEditCard()),
                padding: const EdgeInsets.only(bottom: 128),
                children: buildExerciseDetails(),
              ),
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: Theme.of(context).primaryColor,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('ADD', style: TextStyle(color: Colors.white, fontSize: 16)),
                onPressed: onAddExercisePressed,
                isExtended: true,
              ),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }



  void onDonePressed() {
    if (widget.addOrEdit == AddOrEdit.add && routineCopy.parts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Routine is empty.')));
      return;
    }

    formKey.currentState?.save();
    if (widget.addOrEdit == AddOrEdit.add) {
      routineCopy.mainTargetedBodyPart = widget.mainTargetedBodyPart;
      routinesBloc.addRoutine(routineCopy);
    } else {
      routinesBloc.updateRoutine(routineCopy);
    }

    Navigator.pop(context);
  }

  void onAddExercisePressed() {
    setState(() {
      routineCopy.parts.add(Part(setType: SetType.regular, targetedBodyPart: TargetedBodyPart.chest, exercises: [], partName: ''));
      _startTimeout(300);
    });
  }

  void onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Part item = routineCopy.parts.removeAt(oldIndex);
      routineCopy.parts.insert(newIndex, item);
    });
  }

  List<Widget> buildExerciseDetails() {
    return routineCopy.parts.map((part) {
      return PartEditCard(
        key: ValueKey(part),
        onDelete: () {
          setState(() {
            routineCopy.parts.remove(part);
          });
        },
        part: part,
        curRoutine: routineCopy,
      );
    }).toList();
  }

  Widget _routineDescriptionEditCard() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: TextFormField(
            textInputAction: TextInputAction.done,
            controller: textEditingController,
            style: const TextStyle(color: Colors.black, fontSize: 22),
            decoration: const InputDecoration(
              labelText: 'Routine Title',
            ),
            onSaved: (str) {
              routineCopy.routineName = str?.isNotEmpty == true
                  ? str!
                  : '${mainTargetedBodyPartToStringConverter(routineCopy.mainTargetedBodyPart)} Workout';
            },
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
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
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this routine'),
        content: const Text("Are you sure? You cannot undo this."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (Route r) => r.isFirst);
              if (widget.addOrEdit == AddOrEdit.edit) {
                routinesBloc.deleteRoutine(routineCopy.id);
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _startTimeout([int? milliseconds]) {
    var duration = milliseconds != null ? Duration(milliseconds: milliseconds) : const Duration(seconds: 1);
    Timer(duration, () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PartEditPage(
            addOrEdit: AddOrEdit.add,
            part: routineCopy.parts.last,
            curRoutine: routineCopy,
          ),
        ),
      ).then((value) {
        if (value != null) {
          setState(() {
            routineCopy.parts.last = value;
          });
        }
      });
    });
  }
}