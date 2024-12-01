// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data_exercise_bloc/ExerciseRepository.dart';
import '../../data_exercise_bloc/exercise_bloc.dart';
import '../../data_provider/firebase_provider.dart';
import '../../data_provider/sql_provider.dart';
import '../../models/exercises.dart';

class ExerciseDetails extends StatefulWidget {
  final int exerciseId;
  final String userId;

  const ExerciseDetails({
    super.key,
    required this.exerciseId,
    required this.userId,
  });

  @override
  State<ExerciseDetails> createState() => _ExerciseDetailsState();
}

class _ExerciseDetailsState extends State<ExerciseDetails> {
  bool isCompleted = false;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();

  final Map<String, bool> _expandedSections = {
    'details': true,
    'history': false,
    'notes': false,
    'tips': false,
  };

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus();
  }

  Future<void> _loadCompletionStatus() async {
    try {
      final status = await FirebaseFirestore.instance
          .collection('exerciseProgress')
          .doc('${widget.userId}_${widget.exerciseId}')
          .get();

      if (mounted && status.exists) {
        setState(() {
          isCompleted = status.data()?['isCompleted'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading completion status: $e');
    }
  }

  void _initializeControllers(Exercises exercise) {
    _weightController.text = exercise.defaultWeight.toString();
    _setsController.text = exercise.defaultSets.toString();
    _repsController.text = exercise.defaultReps.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) {
        final exerciseRepository = ExerciseRepository(
          sqlProvider: context.read<SQLProvider>(),
          firebaseProvider: context.read<FirebaseProvider>(),
        );
        return ExerciseBloc(
          exerciseRepository: exerciseRepository,
          sqlProvider: context.read<SQLProvider>(),
          firebaseProvider: context.read<FirebaseProvider>(),
        )..add(FetchExercisesByPartId(widget.exerciseId));
      },
      child: Theme(
        data: Theme.of(context).copyWith(
          cardTheme: CardTheme(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          ),
        ),
        child: Scaffold(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
          appBar: _buildAppBar(),
          body: _buildBody(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showLogDialog,
            icon: const Icon(Icons.add),
            label: const Text('Antrenman Kaydet'),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: const Text('Egzersiz Detayları'),
      actions: [
        IconButton(
          icon: Icon(
            isCompleted ? Icons.check_circle : Icons.check_circle_outline,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
          onPressed: _toggleCompletion,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return BlocBuilder<ExerciseBloc, ExerciseState>(
      builder: (context, state) {
        if (state is ExerciseLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ExerciseLoaded && state.exercises.isNotEmpty) {
          final exercise = state.exercises.first;
          _initializeControllers(exercise);
          return _buildExerciseDetail(exercise);
        } else if (state is ExerciseError) {
          return Center(child: Text(state.message));
        }
        return const Center(child: Text('Egzersiz bulunamadı'));
      },
    );
  }


  Widget _buildGifCard(Exercises exercise) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              exercise.gifUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {/* GIF kontrolleri */},
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {/* GIF kontrolleri */},
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () {/* GIF kontrolleri */},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Exercises exercise) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isCompleted ? Colors.green.withOpacity(0.7) : Colors.blue.withOpacity(0.7),
              isCompleted ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Workout Type: ${exercise.workoutTypeId}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDetailsCard(Exercises exercise) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exercise Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Default Sets', exercise.defaultSets.toString()),
            _buildDetailRow('Default Reps', exercise.defaultReps.toString()),
            _buildDetailRow('Default Weight', '${exercise.defaultWeight} kg'),
          ],
        ),
      ),
    );
  }


  Widget _buildDescriptionCard(Exercises exercise) {
    if (exercise.description == null || exercise.description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Açıklama',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              exercise.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHistoryCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Antrenman Geçmişi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text('Antrenman ${index + 1}'),
          subtitle: Text('Tarih: ${DateTime.now().subtract(Duration(days: index)).toString().split(' ')[0]}'),
          trailing: Text('${12 + index} kg × ${3 + index} set'),
        );
      },
    );
  }

  Widget _buildNotesCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notlarım',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Egzersiz hakkında notlarınızı buraya yazın...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saveNotes,
              child: const Text('Notları Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İpuçları ve Teknik',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTipItem('Doğru Duruş', 'Sırtınızı düz tutun ve omuzlarınızı geriye çekin.'),
            _buildTipItem('Nefes Tekniği', 'Kaldırırken nefes verin, indirirken nefes alın.'),
            _buildTipItem('Güvenlik', 'Ağır kilolarda mutlaka yardımcı ile çalışın.'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Antrenman Kaydet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'Ağırlık (kg)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _setsController,
              decoration: const InputDecoration(labelText: 'Set Sayısı'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _repsController,
              decoration: const InputDecoration(labelText: 'Tekrar Sayısı'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: _saveWorkoutLog,
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _saveWorkoutLog() async {
    try {
      await FirebaseFirestore.instance
          .collection('workoutLogs')
          .add({
        'userId': widget.userId,
        'exerciseId': widget.exerciseId,
        'weight': double.parse(_weightController.text),
        'sets': int.parse(_setsController.text),
        'reps': int.parse(_repsController.text),
        'date': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antrenman kaydedildi')),
      );
    } catch (e) {
      print('Error saving workout log: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt sırasında bir hata oluştu')),
      );
    }
  }

  void _saveNotes() async {
    try {
      await FirebaseFirestore.instance
          .collection('exerciseNotes')
          .doc('${widget.userId}_${widget.exerciseId}')
          .set({
        'userId': widget.userId,
        'exerciseId': widget.exerciseId,
        'notes': _notesController.text,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notlar kaydedildi')),
      );
    } catch (e) {
      print('Error saving notes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notlar kaydedilirken bir hata oluştu')),
      );
    }
  }

  void _toggleCompletion() async {
    try {
      setState(() {
        isCompleted = !isCompleted;
      });

      await FirebaseFirestore.instance
          .collection('exerciseProgress')
          .doc('${widget.userId}_${widget.exerciseId}')
          .set({
        'userId': widget.userId,
        'exerciseId': widget.exerciseId,
        'isCompleted': isCompleted,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      context.read<ExerciseBloc>().add(
        UpdateExerciseCompletion(
          widget.userId,
          widget.exerciseId,
          isCompleted,
        ),
      );
    } catch (e) {
      print('Error updating completion status: $e');
    }
  }

  Widget _buildExerciseDetail(Exercises exercise) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildExpandableCard(
              'gif',
              'Hareket',
              _buildGifCard(exercise),
              initiallyExpanded: true,
              leadingIcon: Icons.video_library,
            ),
            _buildExpandableCard(
              'details',
              'Detaylar',
              _buildDetailsCard(exercise),
              initiallyExpanded: true,
              leadingIcon: Icons.info_outline,
            ),
            if (exercise.description.isNotEmpty)
              _buildExpandableCard(
                'description',
                'Açıklama',
                _buildDescriptionCard(exercise),
                leadingIcon: Icons.description,
              ),
            _buildExpandableCard(
              'history',
              'Antrenman Geçmişi',
              _buildHistoryCard(),
              leadingIcon: Icons.history,
            ),
            _buildExpandableCard(
              'notes',
              'Notlarım',
              _buildNotesCard(),
              leadingIcon: Icons.note_add,
            ),
            _buildExpandableCard(
              'tips',
              'İpuçları ve Teknik',
              _buildTipsCard(),
              leadingIcon: Icons.lightbulb_outline,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableCard(
      String key,
      String title,
      Widget content, {
        bool initiallyExpanded = false,
        IconData? leadingIcon,
      }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: _expandedSections[key] ?? initiallyExpanded,
        onExpansionChanged: (expanded) {
          setState(() => _expandedSections[key] = expanded);
        },
        leading: Icon(leadingIcon),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }



  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showLogDialog,
      icon: const Icon(Icons.add),
      label: const Text('Antrenman Kaydet'),
    );
  }
  @override
  void dispose() {
    _notesController.dispose();
    _weightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }}