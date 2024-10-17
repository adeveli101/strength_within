import 'package:flutter/material.dart';
import '../../models/parts.dart';
import '../../models/BodyPart.dart';
import '../../models/exercises.dart';
import '../../resource/routines_bloc.dart';

class PartEditCard extends StatefulWidget {
  final Parts part;
  final RoutinesBloc routinesBloc;
  final Function(Parts) onSave;

  const PartEditCard({
    Key? key,
    required this.part,
    required this.routinesBloc,
    required this.onSave,
  }) : super(key: key);

  @override
  _PartEditCardState createState() => _PartEditCardState();
}

class _PartEditCardState extends State<PartEditCard> {
  late TextEditingController _nameController;
  late MainTargetedBodyPart _selectedBodyPart;
  late SetType _selectedSetType;
  late TextEditingController _notesController;
  List<Exercises> _exercises = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.part.name);
    _selectedBodyPart = widget.part.mainTargetedBodyPart;
    _selectedSetType = widget.part.setType;
    _notesController = TextEditingController(text: widget.part.additionalNotes);
    _loadExercises();
  }

  void _loadExercises() async {
    final exercises = await widget.routinesBloc.getExercisesByBodyPart(_selectedBodyPart);
    setState(() {
      _exercises = exercises;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Part Name',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<MainTargetedBodyPart>(
              value: _selectedBodyPart,
              onChanged: (newValue) {
                setState(() {
                  _selectedBodyPart = newValue!;
                  _loadExercises();
                });
              },
              items: MainTargetedBodyPart.values.map((bodyPart) {
                return DropdownMenuItem(
                  value: bodyPart,
                  child: Text(bodyPart.toString().split('.').last),
                );
              }).toList(),
              dropdownColor: Color(0xFF2C2C2C),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<SetType>(
              value: _selectedSetType,
              onChanged: (newValue) {
                setState(() {
                  _selectedSetType = newValue!;
                });
              },
              items: SetType.values.map((setType) {
                return DropdownMenuItem(
                  value: setType,
                  child: Text(setType.toString().split('.').last),
                );
              }).toList(),
              dropdownColor: Color(0xFF2C2C2C),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Exercises:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      _exercises[index].name,
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _notesController,
              style: TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Additional Notes',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
