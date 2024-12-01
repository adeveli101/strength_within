// program_merger_bottom_sheet.dart
import 'package:flutter/material.dart';

class ProgramMergerBottomSheet extends StatelessWidget {
  final int currentStep;
  final List<int> selectedDays;
  final List<int> selectedPartIds;

  const ProgramMergerBottomSheet({
    super.key,
    required this.currentStep,
    required this.selectedDays,
    required this.selectedPartIds,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStep == 0 || selectedDays.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Program Özeti',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressItem(
                  context,
                  'Antrenman',
                  '${selectedDays.length} gün',
                  Icons.calendar_today,
                ),
                _buildProgressItem(
                  context,
                  'Dinlenme',
                  '${7 - selectedDays.length} gün',
                  Icons.bedtime,
                ),
                if (selectedPartIds.isNotEmpty)
                  _buildProgressItem(
                    context,
                    'Program',
                    '${selectedPartIds.length}',
                    Icons.fitness_center,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      ) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}