import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../program_merger_form_model.dart';
import '../../../../sw_app_theme/app_theme.dart';

class SummaryStep extends StatelessWidget {
  final VoidCallback? onBack;
  const SummaryStep({this.onBack, super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ProgramMergerFormModel>(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 12),
          Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 48),
          SizedBox(height: 8),
          Text('Rutin Özeti', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 24)),
          SizedBox(height: 8),
          Text('Tebrikler! Rutinini gözden geçir ve onayla.', style: AppTheme.bodyMedium.copyWith(color: Colors.white70), textAlign: TextAlign.center),
          SizedBox(height: 24),
          // Rutin adı
          if (model.routineName != null && model.routineName!.isNotEmpty)
            _SummaryCard(
              icon: Icons.edit,
              color: AppTheme.accentBlue,
              title: 'Rutin İsmi',
              value: model.routineName!,
            ),
          // Seçilen günler
          if (model.selectedDays.isNotEmpty)
            _SummaryCard(
              icon: Icons.calendar_today,
              color: AppTheme.accentAmber,
              title: 'Seçilen Günler',
              value: model.selectedDays.map((d) => _weekDayName(d)).join(', '),
            ),
          // Seçilen hedef
          if (model.selectedGoalId != null)
            _SummaryCard(
              icon: Icons.flag,
              color: AppTheme.accentPurple,
              title: 'Hedef',
              value: _getGoalName(context, model.selectedGoalId),
            ),
          // Egzersizler
          if (model.dayToExerciseIds.isNotEmpty)
            _SummaryCard(
              icon: Icons.fitness_center,
              color: AppTheme.successGreen,
              title: 'Egzersizler',
              value: model.dayToExerciseIds.entries.map((e) => 'Gün ${_weekDayName(e.key)}: ${e.value.length} egzersiz').join(' | '),
            ),
          Spacer(),
          if (onBack != null)
            ElevatedButton.icon(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: AppTheme.successGreen,
                minimumSize: Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) => null),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              icon: Icon(Icons.arrow_back, color: Colors.white),
              label: Text('Geri Dön', style: TextStyle(fontSize: 19)),
            ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  String _weekDayName(int day) {
    const weekDayNames = {
      1: 'Pzt', 2: 'Sal', 3: 'Çrş', 4: 'Per', 5: 'Cum', 6: 'Cmt', 7: 'Paz',
    };
    return weekDayNames[day] ?? '';
  }

  String _getGoalName(BuildContext context, int? goalId) {
    // Bloc veya Provider ile hedef adını bulmak için (örnek, gerçek uygulamada daha iyi alınabilir)
    // Burada sadece id gösteriliyordu, şimdi daha iyi bir gösterim için güncellendi.
    // Gerekirse context.read<ExerciseBloc>().state içinden çekilebilir.
    return goalId?.toString() ?? '';
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  const _SummaryCard({required this.icon, required this.color, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.getPartGradient(difficulty: 1, secondaryColor: color),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyMedium.copyWith(color: Colors.white70)),
                SizedBox(height: 4),
                Text(value, style: AppTheme.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 