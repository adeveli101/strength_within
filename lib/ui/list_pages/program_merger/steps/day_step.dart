import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../program_merger_form_model.dart';
import '../../../../sw_app_theme/app_theme.dart';

class DayStep extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const DayStep({required this.onNext, this.onBack, super.key});

  static const weekDays = [1, 2, 3, 4, 5, 6, 7];
  static const weekDayNames = {
    1: 'Pzt', 2: 'Sal', 3: 'Çrş', 4: 'Per', 5: 'Cum', 6: 'Cmt', 7: 'Paz',
  };
  static const weekDayFullNames = {
    1: 'Pazartesi', 2: 'Salı', 3: 'Çarşamba', 4: 'Perşembe', 5: 'Cuma', 6: 'Cumartesi', 7: 'Pazar',
  };

  static const List<List<int>> suggestions = [
    [1, 3, 5], // Pzt-Çrş-Cuma
    [1, 2, 4, 5], // Pzt-Sal-Per-Cuma
    [2, 4, 6], // Sal-Per-Cmt
    [1, 3, 5, 7], // Pzt-Çrş-Cuma-Pazar
    [1, 2, 3, 4, 5], // Hafta içi
  ];

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ProgramMergerFormModel>(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 12),
          Icon(Icons.calendar_month_rounded, size: 48, color: AppTheme.accentBlue),
          SizedBox(height: 8),
          Text('Haftanı Planla!', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 24)),
          SizedBox(height: 8),
          Text('Hangi günler antrenman yapmak istersin? Hedefine uygun günleri seç veya aşağıdaki önerilerden ilham al!', style: AppTheme.bodyMedium.copyWith(color: Colors.white70), textAlign: TextAlign.center),
          SizedBox(height: 24),
          // Gün barı (toggle)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: weekDays.map((day) {
              final isSelected = model.selectedDays.contains(day);
              return GestureDetector(
                onTap: () => model.toggleDay(day),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: isSelected ? 56 : 44,
                  height: isSelected ? 56 : 44,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.getPartGradient(difficulty: 2, secondaryColor: AppTheme.accentBlue) : AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isSelected ? [BoxShadow(color: AppTheme.accentBlue.withOpacity(0.18), blurRadius: 10, offset: Offset(0, 2))] : [],
                    border: Border.all(
                      color: isSelected ? AppTheme.accentBlue : Colors.grey[700]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekDayNames[day]!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: isSelected ? 18 : 15,
                          ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.check_circle, color: Colors.white, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Önerilen kombinasyonlar:', style: AppTheme.bodyMedium.copyWith(color: Colors.white70)),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: suggestions.map((combo) {
              final isActive = _listEquals(combo, model.selectedDays);
              return Container(
                decoration: isActive ? BoxDecoration(
                  gradient: AppTheme.getPartGradient(difficulty: 2, secondaryColor: AppTheme.accentBlue),
                  borderRadius: BorderRadius.circular(16),
                ) : null,
                child: ActionChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on, color: isActive ? Colors.white : AppTheme.accentBlue, size: 18),
                      SizedBox(width: 4),
                      Text(combo.map((d) => weekDayNames[d]).join('-')),
                    ],
                  ),
                  backgroundColor: isActive ? Colors.transparent : Colors.white10,
                  labelStyle: TextStyle(color: isActive ? Colors.white : Colors.white70),
                  elevation: isActive ? 4 : 0,
                  onPressed: () {
                    model.selectedDays
                      ..clear()
                      ..addAll(combo);
                    model.notifyListeners();
                  },
                ),
              );
            }).toList(),
          ),
          Spacer(),
          Row(
            children: [
              if (onBack != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onBack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: AppTheme.accentBlue,
                      minimumSize: Size(0, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 2,
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) => null),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    label: Text('Geri Dön', style: TextStyle(fontSize: 16)),
                  ),
                ),
              if (onBack != null) SizedBox(width: 12),
              Expanded(
                child: AnimatedOpacity(
                  opacity: model.selectedDays.isNotEmpty ? 1 : 0.5,
                  duration: Duration(milliseconds: 200),
                  child: ElevatedButton.icon(
                    onPressed: model.selectedDays.isNotEmpty ? onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: AppTheme.accentBlue,
                      minimumSize: Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) => null),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    icon: Icon(Icons.arrow_forward, color: Colors.white),
                    label: Text('Devam Et', style: TextStyle(fontSize: 19)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }
} 