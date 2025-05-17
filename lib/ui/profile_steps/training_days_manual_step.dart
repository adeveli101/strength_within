import 'package:flutter/material.dart';
import '../../sw_app_theme/app_theme.dart';
import '../userpprofilescreen.dart';
import 'profile_step_widgets.dart';

class TrainingDaysManualStep extends StatefulWidget {
  final UserProfileFormModel model;
  final VoidCallback onNext;
  const TrainingDaysManualStep({required this.model, required this.onNext, super.key});
  @override
  State<TrainingDaysManualStep> createState() => _TrainingDaysManualStepState();
}

class _TrainingDaysManualStepState extends State<TrainingDaysManualStep> {
  String? error;
  final List<String> weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  bool manualEdit = false;

  @override
  void initState() {
    super.initState();
    // Otomatik günler zaten modelde olmalı, burada tekrar hesaplamıyoruz.
  }

  void _onManualEdit() {
    setState(() => manualEdit = !manualEdit);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.model.selectedDays;
    error = (selected.length < 2) ? 'En az 2 gün seçmelisiniz.' : (selected.length > 6 ? 'En fazla 6 gün seçebilirsiniz.' : null);
    return MetricPage(
      title: 'Antrenman Günleri (Manuel)',
      description: 'Otomatik oluşturulan günleri inceleyin, isterseniz düzenleyin.',
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Seçili günler:', style: AppTheme.bodyLarge),
          SizedBox(height: AppTheme.paddingSmall),
          Wrap(
            spacing: AppTheme.paddingSmall,
            children: List.generate(7, (i) {
              final dayNum = i + 1;
              final isSelected = selected.contains(dayNum);
              return FilterChip(
                label: Text(weekDays[i], style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                selected: isSelected,
                onSelected: manualEdit
                  ? (sel) {
                      final days = List<int>.from(selected);
                      if (sel) {
                        if (days.length < 6 && !days.contains(dayNum)) days.add(dayNum);
                      } else {
                        if (days.length > 2 && days.contains(dayNum)) days.remove(dayNum);
                      }
                      days.sort();
                      widget.model.setSelectedDays(days);
                      setState(() {});
                    }
                  : null,
                backgroundColor: AppTheme.surfaceColor,
                selectedColor: AppTheme.primaryRed,
                checkmarkColor: Colors.white,
              );
            }),
          ),
          SizedBox(height: AppTheme.paddingSmall),
          TextButton.icon(
            onPressed: _onManualEdit,
            icon: Icon(manualEdit ? Icons.lock_open : Icons.lock, color: AppTheme.primaryRed),
            label: Text(manualEdit ? 'Manuel düzenlemeyi kapat' : 'Günleri manuel düzenle', style: TextStyle(color: AppTheme.primaryRed)),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(error!, style: TextStyle(color: Colors.redAccent)),
            ),
          SizedBox(height: AppTheme.paddingLarge),
          ElevatedButton.icon(
            onPressed: error == null
                ? () {
                    // Günleri otomatik oluştur (gerekirse) ve ilerle
                    if (widget.model.selectedDays.length < 2) {
                      // Otomatik oluşturma mantığı eklenebilir
                    }
                    widget.onNext();
                  }
                : null,
            icon: Icon(Icons.check, color: Colors.white),
            label: Text('Devam Et', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
            ),
          ),
        ],
      ),
      onNext: null,
    );
  }
} 