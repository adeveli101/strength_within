import 'package:flutter/material.dart';
import '../../blocs/data_schedule_bloc/schedule_repository.dart';
import '../../sw_app_theme/app_theme.dart';
import '../userpprofilescreen.dart';
import 'profile_step_widgets.dart';
import 'package:provider/provider.dart';

class TrainingDaysStep extends StatefulWidget {
  final UserProfileFormModel model;
  final String description;
  final VoidCallback onNext;
  const TrainingDaysStep({required this.model, required this.description, required this.onNext, super.key});
  @override
  State<TrainingDaysStep> createState() => _TrainingDaysStepState();
}

class _TrainingDaysStepState extends State<TrainingDaysStep> {
  String? error;
  final List<String> weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  bool manualEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.model.recommendedFrequency != null) {
      final freq = widget.model.recommendedFrequency!;
      if (widget.model.trainingFrequency != freq) {
        widget.model.setTrainingFrequency(freq);
      }
      if (widget.model.selectedDays.length != freq) {
        widget.model.setSelectedDays(List.generate(freq, (i) => i + 1));
      }
    }
  }

  void _autoSelectDays() {
    final freq = widget.model.trainingFrequency;
    final start = widget.model.startDay;
    List<int> days = [];
    for (int i = 0; i < freq; i++) {
      days.add(((start - 1 + i * (7 ~/ freq)) % 7) + 1);
    }
    widget.model.setSelectedDays(days);
  }

  void _onFrequencyChanged(int value) {
    widget.model.setTrainingFrequency(value);
    setState(() {});
  }

  void _onStartDayChanged(int value) {
    widget.model.setStartDay(value);
    setState(() {});
  }

  void _onManualEdit() {
    setState(() => manualEdit = !manualEdit);
  }

  String _getFrequencyAdvice(int difficulty) {
    switch (difficulty) {
      case 1: return 'Yeni başlayanlar için haftada 2-3 gün önerilir.';
      case 2: return 'Temel seviye için haftada 3-4 gün uygundur.';
      case 3: return 'Orta seviye için haftada 4-5 gün idealdir.';
      case 4: return 'İleri seviye için haftada 5-6 gün önerilir.';
      case 5: return 'Çok ileri seviye için haftada 6-7 gün uygundur.';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final freq = widget.model.trainingFrequency;
    final start = widget.model.startDay;
    final difficulty = int.tryParse(widget.model.difficulty) ?? 3;
    final advice = _getFrequencyAdvice(difficulty);
    return MetricPage(
      title: 'Antrenman Tercihleri',
      description: widget.description,
      isLastPage: false,
      input: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (advice.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  advice,
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            Text('Haftada kaç gün çalışmak istersiniz?', style: AppTheme.bodyLarge),
            SizedBox(height: AppTheme.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle, color: AppTheme.primaryRed),
                  onPressed: freq > 2 ? () => _onFrequencyChanged(freq - 1) : null,
                ),
                Text('$freq', style: AppTheme.headingLarge),
                IconButton(
                  icon: Icon(Icons.add_circle, color: AppTheme.primaryRed),
                  onPressed: freq < 6 ? () => _onFrequencyChanged(freq + 1) : null,
                ),
                SizedBox(width: AppTheme.paddingMedium),
                Text('gün', style: AppTheme.bodyLarge),
              ],
            ),
            SizedBox(height: AppTheme.paddingMedium),
            Text('Hangi günden başlamak istersiniz?', style: AppTheme.bodyLarge),
            SizedBox(height: AppTheme.paddingSmall),
            Wrap(
              spacing: AppTheme.paddingSmall,
              children: List.generate(7, (i) {
                final dayNum = i + 1;
                return ChoiceChip(
                  label: Text(weekDays[i]),
                  selected: start == dayNum,
                  onSelected: (sel) => _onStartDayChanged(dayNum),
                  selectedColor: AppTheme.primaryRed,
                  backgroundColor: AppTheme.surfaceColor,
                  labelStyle: TextStyle(color: start == dayNum ? Colors.white : Colors.white70),
                );
              }),
            ),
            SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton.icon(
              onPressed: () async {
                final scheduleRepository = context.read<ScheduleRepository>();
                int minRestDays = 1;
                final days = scheduleRepository.calculateTrainingDays(
                  startDay: widget.model.startDay,
                  frequency: widget.model.trainingFrequency,
                  minRestDays: minRestDays,
                );
                widget.model.setSelectedDays(days);
                widget.onNext();
              },
              icon: Icon(Icons.auto_awesome, color: Colors.white),
              label: Text('Otomatik Günleri Oluştur', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
      onNext: null, // Sadece buton ile ilerleniyor
    );
  }
} 