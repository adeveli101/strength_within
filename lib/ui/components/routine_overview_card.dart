import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:workout/ui/components/part_card.dart';
import 'package:workout/ui/part_history_page.dart';
import 'package:workout/ui/routine_edit_page.dart';
import 'package:workout/ui/routine_step_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../resource/routines_bloc.dart';
import '../../models/part.dart';
import '../../models/routine.dart';
import '../../resource/db_provider.dart';
import '../../resource/firebase_provider.dart';
import '../../utils/routine_helpers.dart';

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
  Map<int, bool> _expandedState = {};
  String? userId;

  @override
  void initState() {
    super.initState();
    _routine = widget.routine;
    _loadParts();
    _getAnonymousUserId();
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

  Future<void> _getAnonymousUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      userId = userCredential.user!.uid;
    } else {
      userId = user.uid;
    }
    setState(() {});
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
                _buildInfoRow(Icons.fitness_center, 'Difficulty', _routine.difficulty.toString()),
                _buildInfoRow(Icons.timer, 'Estimated Time', '${_routine.estimatedTime} min'),
                if (userId != null) _buildCompletionInfo(),
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

  Widget _buildCompletionInfo() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseProvider().firestore
          .collection("users")
          .doc(userId)
          .collection("routines")
          .doc(_routine.id.toString())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final completionCount = data['CompletionCount'] ?? 0;
          final lastCompletedDate = data['LastCompletedDate'] != null
              ? (data['LastCompletedDate'] as Timestamp).toDate()
              : null;
          return Column(
            children: [
              _buildInfoRow(Icons.repeat, 'Completion count', completionCount.toString()),
              if (lastCompletedDate != null)
                _buildInfoRow(Icons.calendar_today, 'Last completed', lastCompletedDate.toString().split(' ')[0]),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildPartCard(Part part) {
    return PartCard(
      onDelete: () {}, // RoutineDetailPage'de silme işlemi yok
      onPartTap: widget.isRecRoutine ? null : () => _navigateToPartHistoryPage(part),
      part: part,
      isExpanded: _expandedState[part.id] ?? false,
      onExpandToggle: (bool expanded) {
        setState(() {
          _expandedState[part.id] = expanded;
        });
      },
    );
  }

  void _navigateToEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineEditPage(
          routine: _routine,
          isEditing: true,
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
    showDialog(
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
