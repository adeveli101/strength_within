import 'package:flutter/material.dart';
import '../../sw_app_theme/app_theme.dart';
import '../userpprofilescreen.dart';

class MetricPage extends StatelessWidget {
  final String title;
  final String description;
  final Widget input;
  final bool isLastPage;
  final VoidCallback? onNext;
  const MetricPage({required this.title, required this.description, required this.input, required this.isLastPage, required this.onNext, super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headingMedium),
          SizedBox(height: AppTheme.paddingMedium),
          Text(description, style: AppTheme.bodyMedium.copyWith(color: Colors.white70)),
          Expanded(child: Center(child: input)),
          if (onNext != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastPage ? AppTheme.primaryGreen : AppTheme.primaryRed,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
              ),
              onPressed: onNext,
              child: Text(isLastPage ? 'Profil Oluştur' : 'Devam Et', style: AppTheme.bodyLarge),
            ),
        ],
      ),
    );
  }
}

class GenderButton extends StatelessWidget {
  final UserProfileFormModel model;
  final int value;
  final IconData icon;
  final String label;
  const GenderButton({required this.model, required this.value, required this.icon, required this.label, super.key});
  @override
  Widget build(BuildContext context) {
    final isSelected = model.gender == value;
    return GestureDetector(
      onTap: () {
        model.setGender(value);
        if (value == 0) {
          model.setWeight(75);
          model.setHeight(175);
        } else if (value == 1) {
          model.setWeight(55);
          model.setHeight(160);
        }
      },
      child: Container(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            SizedBox(height: AppTheme.paddingSmall),
            Text(label, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class DayCheckbox extends StatelessWidget {
  final UserProfileFormModel model;
  final String label;
  final int day;
  const DayCheckbox({required this.model, required this.label, required this.day, super.key});
  @override
  Widget build(BuildContext context) {
    final isSelected = model.selectedDays.contains(day);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        final days = List<int>.from(model.selectedDays);
        if (selected) {
          if (days.length < 6 && !days.contains(day)) {
            days.add(day);
          }
        } else {
          if (days.length > 2 && days.contains(day)) {
            days.remove(day);
          }
        }
        days.sort();
        model.setSelectedDays(days);
      },
      backgroundColor: AppTheme.surfaceColor,
      selectedColor: AppTheme.primaryRed,
      checkmarkColor: Colors.white,
    );
  }
}

class SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const SummaryItem({required this.icon, required this.label, required this.value, super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryRed),
          SizedBox(width: AppTheme.paddingMedium),
          Text(label, style: AppTheme.bodyMedium),
          Spacer(),
          Text(value, style: AppTheme.bodyLarge),
        ],
      ),
    );
  }
} 