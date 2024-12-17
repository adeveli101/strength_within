// schedule_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:strength_within/ui/exercises_ui/exercise_details.dart';
import '../../blocs/data_schedule_bloc/schedule_bloc.dart';
import '../../z.app_theme/app_theme.dart';

class ScheduleModal extends StatefulWidget {
  final String userId;
  final String type;
  final int itemId;
  final String itemName;
  final String? description;
  final Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart;

  const ScheduleModal({
    super.key,
    required this.userId,
    required this.type,
    required this.itemId,
    required this.itemName,
    this.description,
    required this.exerciseListByBodyPart,
  });

  @override
  State<ScheduleModal> createState() => _ScheduleModalState();
}

class _ScheduleModalState extends State<ScheduleModal> with SingleTickerProviderStateMixin {
  final Logger _logger = Logger('ScheduleModal');
  late TabController _tabController;
  int selectedDay = 1;
  List<int> recommendedDays = [];
  Map<String, dynamic>? frequency;
  Map<String, List<Map<String, dynamic>>>? dailyExercises;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);

      final scheduleBloc = context.read<ScheduleBloc>();
      frequency = await scheduleBloc.repository.getFrequencyInfo(
        widget.itemId,
        widget.type,
      );

      recommendedDays = _calculateRecommendedDays(
        frequency!['recommendedFrequency'] as int,
        frequency!['minRestDays'] as int,
      );

      _tabController = TabController(
        length: recommendedDays.length,
        vsync: this,
      );

      dailyExercises = await scheduleBloc.repository.groupExercisesByFrequency(
        widget.itemId,
        widget.type,
        recommendedDays,
      );

      setState(() => isLoading = false);
    } catch (e) {
      _logger.severe('Modal verisi yüklenirken hata oluştu', e);
      setState(() {
        isLoading = false;
        errorMessage = 'Veriler yüklenirken bir hata oluştu';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  // Önerilen günleri hesaplayan metod
  List<int> _calculateRecommendedDays(int recommendedFrequency, int minRestDays) {
  List<int> days = [];
  int currentDay = 1;

  for (int i = 0; i < recommendedFrequency; i++) {
  days.add(currentDay);
  // Sonraki gün için minimum dinlenme günü ekle
  currentDay += minRestDays + 1;
  }

  return days;
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (frequency == null || dailyExercises == null) {
      return _buildEmptyState();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildFrequencyInfo(),
          _buildDaySelector(),
          _buildExerciseList(),
        ],
      ),
    );
  }

  // ... Diğer widget metodları aynı kalacak, sadece bazı iyileştirmeler yapacağız

  Widget _buildLoadingState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Program yükleniyor...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Center(
        child: Text(
          'Program bulunamadı',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Drag Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Title and Close Button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.type == 'part' ? Icons.fitness_center : Icons.schedule,
                            color: AppTheme.primaryRed,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.itemName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (widget.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.description!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.15),
            Colors.orange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Program Bilgileri',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          '${frequency!['recommendedFrequency']} gün/hafta',
                          Icons.calendar_today,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          '${frequency!['minRestDays']} gün dinlenme',
                          Icons.bedtime_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final recommendedDays = _calculateRecommendedDays(
      frequency!['recommendedFrequency'] as int,
      frequency!['minRestDays'] as int,
    );

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recommendedDays.length,
        itemBuilder: (context, index) {
          final day = recommendedDays[index];
          final isSelected = selectedDay == day;
          final isRestDay = index > 0 &&
              (recommendedDays[index] - recommendedDays[index - 1]) > 1;

          return GestureDetector(
            onTap: () => setState(() => selectedDay = day),
            child: Container(
              width: 85,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: [
                    AppTheme.primaryRed,
                    AppTheme.primaryRed.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryRed
                      : Colors.white.withOpacity(0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'GÜN',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$day',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isRestDay) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),

                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseList() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(30),
          ),
          child: dailyExercises!['day$selectedDay'] == null
              ? _buildEmptyExerciseList()
              : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: dailyExercises!['day$selectedDay']!.length,
            itemBuilder: (context, index) {
              final exercise = dailyExercises!['day$selectedDay']![index];
              return _buildExerciseCard(exercise);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyExerciseList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Bu gün için egzersiz bulunamadı',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseDetails(
                exerciseId: exercise['exerciseId'],
                userId: widget.userId,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: AppTheme.primaryRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildMetricChip(
                                '${exercise['sets']} Set',
                                Icons.repeat,
                              ),
                              const SizedBox(width: 8),
                              _buildMetricChip(
                                '${exercise['reps']} Tekrar',
                                Icons.timer,
                              ),
                              const SizedBox(width: 8),
                              _buildMetricChip(
                                '${exercise['weight']}kg',
                                Icons.fitness_center,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                  ],
                ),
                if (exercise['description'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercise['description'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }


}