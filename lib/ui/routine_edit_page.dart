import 'dart:async';
import 'package:flutter/material.dart';
import 'package:workout/ui/part_edit_page.dart';
import '../controllers/routines_bloc.dart';
import '../models/part.dart';
import '../models/routine.dart';
import '../resource/db_provider.dart';
import '../utils/routine_helpers.dart';
import 'components/part_edit_card.dart';
import 'components/spring_curve.dart';

class RoutineEditPage extends StatefulWidget {
  final AddOrEdit addOrEdit;
  final MainTargetedBodyPart mainTargetedBodyPart;
  final Routine? routine;

  const RoutineEditPage({
    Key? key,
    required this.addOrEdit,
    required this.mainTargetedBodyPart,
    this.routine,
  }) : super(key: key);

  @override
  _RoutineEditPageState createState() => _RoutineEditPageState();
}

class _RoutineEditPageState extends State<RoutineEditPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final formKey = GlobalKey<FormState>();
  final TextEditingController textEditingController = TextEditingController();
  ScrollController scrollController = ScrollController();
  bool _initialized = false;
  late MainTargetedBodyPart mTB;
  late Routine routineCopy;

  @override
  void initState() {
    super.initState();
    mTB = widget.mainTargetedBodyPart;
    _initializeRoutine();
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

  void _initializeRoutine() {
    if (widget.addOrEdit == AddOrEdit.add) {
      routineCopy = Routine(
        id: DateTime.now().millisecondsSinceEpoch,
        name: '',
        mainTargetedBodyPart: mTB,
        partIds: [],
        createdDate: DateTime.now(),
      );
    } else {
      routinesBloc.currentRoutine.listen((currentRoutine) {
        if (currentRoutine != null && !_initialized) {
          setState(() {
            routineCopy = currentRoutine.copyWith();
            textEditingController.text = routineCopy.name;
            _initialized = true;
          });
        }
      });
    }
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
          title: Text(widget.addOrEdit == AddOrEdit.add ? "Add Routine" : "Edit Routine"),
          actions: [
            if (widget.addOrEdit == AddOrEdit.edit)
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: _showDeleteConfirmation,
              ),
            IconButton(
              icon: const Icon(Icons.done),
              onPressed: _onDonePressed,
            ),
          ],
        ),
        body: FutureBuilder<List<Widget>>(
          future: _buildPartCards(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return ReorderableListView(
              scrollController: scrollController,
              children: snapshot.data!,
              onReorder: _onReorder,
              header: Form(key: formKey, child: _routineDescriptionEditCard()),
              padding: const EdgeInsets.only(bottom: 128),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Theme.of(context).primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('ADD', style: TextStyle(color: Colors.white, fontSize: 16)),
          onPressed: _onAddPartPressed,
          isExtended: true,
        ),
      ),
    );
  }

  Future<List<Widget>> _buildPartCards() async {
    List<Widget> cards = [];
    for (var partId in routineCopy.partIds) {
      final part = await DBProvider.db.getPart(partId);
      if (part != null) {
        cards.add(PartEditCard(
          key: ValueKey(partId),
          onDelete: () => _deletePart(partId),
          part: part,
          curRoutine: routineCopy,
          onTap: () => _navigateToPartEditPage(part),
        ));
      }
    }
    return cards;
  }


  Widget _routineDescriptionEditCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Card(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
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
              routineCopy = routineCopy.copyWith(
                name: str?.isNotEmpty == true
                    ? str!
                    : '${routineCopy.mainTargetedBodyPart.toString().split('.').last} Workout',
              );
            },
          ),
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final int item = routineCopy.partIds.removeAt(oldIndex);
      routineCopy.partIds.insert(newIndex, item);
    });
  }

  void _deletePart(int partId) async {
    await DBProvider.db.deletePart(partId);
    setState(() {
      routineCopy.partIds.remove(partId);
    });
  }

  void _onAddPartPressed() async {
    final newPart = Part(
      id: DateTime.now().millisecondsSinceEpoch,
      name: '',
      targetedBodyPart: TargetedBodyPart.fullBody,
      setType: SetType.regular,
      exerciseIds: [],
    );
    final insertedId = await DBProvider.db.newPart(newPart);
    setState(() {
      routineCopy.partIds.add(insertedId);
    });
    _navigateToPartEditPage(newPart);
  }

  void _navigateToPartEditPage(Part part) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartEditPage(
          addOrEdit: AddOrEdit.edit,
          part: part,
          curRoutine: routineCopy,
        ),
      ),
    ).then((value) {
      if (value != null) {
        setState(() {
          // Update the part in the routine if necessary
          int index = routineCopy.partIds.indexOf(part.id);
          if (index != -1) {
            routineCopy.partIds[index] = value.id;
          }
        });
      }
    });
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('If you go back now, your changes will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this routine'),
        content: const Text("Are you sure? You cannot undo this."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoutine();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _deleteRoutine() async {
    await DBProvider.db.deleteRoutine(routineCopy.id);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _onDonePressed() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (widget.addOrEdit == AddOrEdit.add) {
        await DBProvider.db.newRoutine(routineCopy);
      } else {
        await DBProvider.db.updateRoutine(routineCopy);
      }
      Navigator.pop(context);
    }
  }
}
