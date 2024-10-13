import 'package:flutter/material.dart';
import 'package:workout/ui/part_history_page.dart';
import 'package:workout/ui/routine_edit_page.dart';
import 'package:workout/ui/routine_step_page.dart';
import '../controllers/routines_bloc.dart';
import '../models/routine.dart';
import '../models/part.dart';
import '../resource/db_provider.dart';
import '../utils/routine_helpers.dart';
import 'components/part_card.dart';

class RoutineDetailPage extends StatefulWidget {
  final bool isRecRoutine;
  final Routine routine;

  const RoutineDetailPage({Key? key, this.isRecRoutine = false, required this.routine}) : super(key: key);

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Routine _routine;
  List<Part> _parts = [];
  Map<String, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    _routine = widget.routine;
    _loadParts();
  }

  Future<void> _loadParts() async {
    try {
      final loadedParts = await Future.wait(
          _routine.partIds.map((id) => DBProvider.db.getPart(id))
      );
      setState(() {
        _parts = loadedParts.whereType<Part>().toList();
        _expandedState = Map.fromIterable(_parts, key: (part) => part.id, value: (_) => false);
      });
    } catch (e) {
      print('Error loading parts: $e');
      // Hata durumunda kullanıcıya bilgi verebilirsiniz
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      body: ListView(
        children: [
          _buildRoutineOverview(),
          if (_parts.isEmpty)
            const Center(child: Text('No parts found'))
          else
            ..._parts.map(_buildPartCard),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: true,
      title: Text(targetedBodyPartToStringConverter(_routine.mainTargetedBodyPart)),
      actions: [
        if (!widget.isRecRoutine) ...[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditPage,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _navigateToRoutineStepPage,
          ),
        ],
        if (widget.isRecRoutine)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _onAddRecPressed,
          ),
      ],
    );
  }

  Widget _buildRoutineOverview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade300, Colors.blue.shade600],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _routine.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.calendar_today, 'Created', _routine.createdDate.toString().split(' ')[0]),
                if (_routine.lastCompletedDate != null)
                  _buildInfoRow(Icons.check_circle_outline, 'Last completed', _routine.lastCompletedDate.toString().split(' ')[0]),
                _buildInfoRow(Icons.repeat, 'Completion count', _routine.completionCount.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPartCard(Part part) {
    return PartCard(
      onDelete: () {}, // RoutineDetailPage'de silme işlemi yok
      onPartTap: widget.isRecRoutine ? null : () => _navigateToPartHistoryPage(part),
      part: part,
      isExpanded: _expandedState[part.id.toString()] ?? false,
      onExpandToggle: (bool expanded) {
        setState(() {
          _expandedState[part.id.toString()] = expanded;
        });
      },
    );
  }

  void _navigateToEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineEditPage(
          addOrEdit: AddOrEdit.edit,
          mainTargetedBodyPart: _routine.mainTargetedBodyPart,
          routine: _routine,
        ),
      ),
    ).then((_) => _loadParts());
  }

  void _navigateToRoutineStepPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineStepPage(routine: _routine),
      ),
    );
  }

  void _navigateToPartHistoryPage(Part part) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PartHistoryPage(part: part)),
    );
  }

  void _onAddRecPressed() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to your routines?'),
        actions: [
          TextButton(
            child: const Text('No'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ).then((val) {
      if (val == true) {
        routinesBloc.addRoutine(_routine);
        Navigator.pop(context);
      }
    });
  }
}