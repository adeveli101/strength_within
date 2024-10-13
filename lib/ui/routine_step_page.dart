import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/part.dart';
import '../resource/db_provider.dart';
import 'components/part_card.dart';

class RoutineStepPage extends StatefulWidget {
  final Routine routine;

  const RoutineStepPage({Key? key, required this.routine}) : super(key: key);

  @override
  _RoutineStepPageState createState() => _RoutineStepPageState();
}

class _RoutineStepPageState extends State<RoutineStepPage> {
  late Routine _routine;
  List<Part> _parts = [];
  int _currentPartIndex = 0;
  Map<int, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    _routine = widget.routine;
    _loadParts();
  }

  Future<void> _loadParts() async {
    final parts = await Future.wait(
      _routine.partIds.map((id) => DBProvider.db.getPart(id)),
    );
    setState(() {
      _parts = parts.whereType<Part>().toList();
      _expandedState = Map.fromIterable(_parts, key: (part) => part.id, value: (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_routine.name),
      ),
      body: _parts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(child: _buildCurrentPartCard()),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildCurrentPartCard() {
    return PartCard(
      part: _parts[_currentPartIndex],
      isExpanded: _expandedState[_parts[_currentPartIndex].id] ?? false,
      onExpandToggle: (bool expanded) {
        setState(() {
          _expandedState[_parts[_currentPartIndex].id] = expanded;
        });
      },
      onDelete: () {}, // Boş bir fonksiyon
      onPartTap: null, // RoutineStepPage'de part'a tıklama işlevi yok
    );
  }


  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentPartIndex > 0 ? _previousPart : null,
            child: const Text('Previous'),
          ),
          ElevatedButton(
            onPressed: _currentPartIndex < _parts.length - 1 ? _nextPart : _finishRoutine,
            child: Text(_currentPartIndex < _parts.length - 1 ? 'Next' : 'Finish'),
          ),
        ],
      ),
    );
  }

  void _previousPart() {
    if (_currentPartIndex > 0) {
      setState(() {
        _currentPartIndex--;
      });
    }
  }

  void _nextPart() {
    if (_currentPartIndex < _parts.length - 1) {
      setState(() {
        _currentPartIndex++;
      });
    }
  }

  void _finishRoutine() async {
    _routine.completionCount++;
    _routine.lastCompletedDate = DateTime.now();
    await DBProvider.db.updateRoutine(_routine);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Routine Completed'),
        content: Text('Great job! You have completed the routine.\n\nTotal completions: ${_routine.completionCount}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
