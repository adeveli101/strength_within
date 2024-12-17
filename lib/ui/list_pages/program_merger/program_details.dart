import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/data_exercise_bloc/exercise_bloc.dart';
import '../../../blocs/data_schedule_bloc/schedule_bloc.dart';
import '../../../models/sql_models/PartExercises.dart';
import '../../components/program_merger.dart';

class ProgramDetailPage extends StatelessWidget {
  final MergedProgram program;

  const ProgramDetailPage({
    super.key,
    required this.program,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(program.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveProgram(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgramHeader(),
            const SizedBox(height: 16),
            _buildDaysList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              program.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              program.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  Icons.fitness_center,
                  'Zorluk: ${program.difficulty}/5',
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.sync,
                  program.mergeType.toString().split('.').last,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: program.schedule.entries.map((entry) {
        final day = entry.key;
        final part = entry.value;
        final exercises = program.exercises[day] ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text('Gün $day'),
                subtitle: Text(part.name),
              ),
              const Divider(),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercises.length,
                itemBuilder: (context, index) =>
                    _buildExerciseItem(exercises[index]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExerciseItem(PartExercise exercise) {
    return ListTile(
      leading: const Icon(Icons.fitness_center),
      title: BlocBuilder<ExerciseBloc, ExerciseState>(
        builder: (context, state) {
          if (state is ExerciseLoaded) {
            final exerciseDetails = state.exercises
                .firstWhere((e) => e.id == exercise.exerciseId);
            return Text(exerciseDetails.name);
          }
          return const Text('Yükleniyor...');
        },
      ),
      subtitle: Text(
        '${exercise.targetPercentage}% Hedef Yüzdesi',
      ),
      trailing: exercise.isPrimary
          ? const Icon(Icons.star, color: Colors.amber)
          : null,
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _saveProgram(BuildContext context) async {
    try {
      final scheduleBloc = context.read<ScheduleBloc>();
      final userSchedule = await program.toUserSchedule();

      scheduleBloc.add(CreateScheduleWithExercises(userSchedule));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program başarıyla kaydedildi')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }
}