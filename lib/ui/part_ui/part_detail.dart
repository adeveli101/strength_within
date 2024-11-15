// ignore_for_file: unused_element


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/data_bloc_part/part_bloc.dart';
import 'package:workout/models/Parts.dart';
import 'package:workout/ui/part_ui/part_card.dart';
import 'package:logging/logging.dart';

import '../../data_schedule_bloc/schedule_bloc.dart';
import '../../firebase_class/user_schedule.dart';
import '../../models/exercises.dart';
import '../../z.app_theme/app_theme.dart';
import '../exercises_ui/exercise_card.dart';
import '../exercises_ui/exercise_details.dart';

class PartDetailBottomSheet extends StatefulWidget {
  final int partId;
  final String userId;

  const PartDetailBottomSheet({
    super.key,
    required this.partId,
    required this.userId
  });

  @override
  _PartDetailBottomSheetState createState() => _PartDetailBottomSheetState();
}


class _PartDetailBottomSheetState extends State<PartDetailBottomSheet> {

  late PartsBloc _partsBloc;
  final _logger = Logger('PartDetailBottomSheet');
  int _selectedDay = 1;




  @override
  void initState() {
    super.initState();
    _partsBloc = context.read<PartsBloc>();
    _logger.info("PartDetailBottomSheet initialized with partId: ${widget.partId}");

    // Schedule verilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final scheduleBloc = context.read<ScheduleBloc>();
        scheduleBloc.add(LoadUserSchedules(widget.userId)); // Event'i doğru şekilde gönder
        _logger.info("Schedule verileri yükleniyor: ${widget.userId}");
      } catch (e) {
        _logger.severe("Schedule bloc erişim hatası", e);
      }
    });

    if (widget.partId > 0) {
      _partsBloc.add(FetchPartExercises(partId: widget.partId));
    } else {
      _logger.warning("Invalid partId: ${widget.partId}");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçersiz part ID. Lütfen tekrar deneyin.')),
        );
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final state = _partsBloc.state;
        if (state is PartExercisesLoaded) {
          _partsBloc.add(UpdatePart(state.part));
          _partsBloc.add(FetchParts());
        }
        Navigator.of(context).pop();
      },
      child: BlocListener<PartsBloc, PartsState>(
        listener: (context, state) {
          if (state is PartsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.primaryRed,
              ),
            );
          }
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.borderRadiusLarge),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Süsleme elementleri
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryRed.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Ana içerik
                  BlocBuilder<PartsBloc, PartsState>(
                    builder: (context, state) {
                      _logger.info('PartDetailBottomSheet state: $state');

                      if (state is PartsLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryRed,
                            ),
                          ),
                        );
                      }

                      if (state is PartExercisesLoaded) {
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppTheme.borderRadiusLarge),
                          ),
                          child: _buildLoadedContent(state, controller),
                        );
                      }

                      if (state is PartsError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppTheme.primaryRed,
                                size: 48,
                              ),
                              const SizedBox(height: AppTheme.paddingMedium),
                              Text(
                                'Hata: ${state.message}',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.primaryRed,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return Center(
                        child: Text(
                          'Beklenmeyen durum: ${state.runtimeType }',
                          style: AppTheme.bodyMedium,
                        ),
                      );
                    },
                  ),
                  // Üst kısım çubuğu
                  Positioned(
                    top: AppTheme.paddingSmall,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildLoadedContent(PartExercisesLoaded state, ScrollController controller) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: ListView(
        controller: controller,
        padding: EdgeInsets.zero,
        children: [
          // Üst Bilgi Bölümü
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve Schedule Butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.part.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    BlocBuilder<ScheduleBloc, ScheduleState>(
                      builder: (context, scheduleState) {
                        bool hasSchedule = false;
                        if (scheduleState is SchedulesLoaded) {
                          hasSchedule = scheduleState.schedules.any(
                                  (schedule) =>
                              schedule.itemId == state.part.id &&
                                  schedule.type == 'part'
                          );
                        }
                        return InkWell(
                          onTap: () => _showScheduleModal(context, state.part,state.exerciseListByBodyPart,),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: hasSchedule
                                  ? AppTheme.primaryRed
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: hasSchedule
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  hasSchedule ? 'Programı Düzenle' : 'Programa Ekle',
                                  style: TextStyle(
                                    color: hasSchedule
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem(
                      Icons.fitness_center,
                      'Egzersiz Sayısı',
                      _getTotalExerciseCount(state.exerciseListByBodyPart).toString(),
                    ),
                    _buildStatItem(
                      Icons.category,
                      '',
                      state.part.name,
                    ),
                    _buildStatItem(
                      Icons.trending_up,
                      'İlerleme',
                      '${state.part.userProgress ?? 0}%',
                      color: _getProgressColor(state.part.userProgress ?? 0),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // İlerleme Çubuğu
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (state.part.userProgress ?? 0) / 100,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(state.part.userProgress ?? 0),
                ),
              ),
            ),
          ),

          // Egzersiz Başlığı
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Egzersizler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_getTotalExerciseCount(state.exerciseListByBodyPart)} egzersiz',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Egzersiz Listesi
          ..._buildExerciseList(state.exerciseListByBodyPart),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  String _getBodyPartName(int bodyPartId) {
    switch (bodyPartId) {
      case 1:
        return 'Göğüs';
      case 2:
        return 'Sırt';
      case 3:
        return 'Bacak';
      case 4:
        return 'Omuz';
      case 5:
        return 'Kol';
      case 6:
        return 'Karın';
      default:
        return 'Bilinmeyen';
    }
  }

  void _showScheduleModal(BuildContext context, Parts part, Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    try {
      // Egzersizleri günlere böl
      final dailyExercises = _groupExercisesByDay(exerciseListByBodyPart);

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Modal başlığı
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Antrenman Programı',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),

                // Gün seçici
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: ElevatedButton(
                          onPressed: () => setState(() => _selectedDay = day),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedDay == day
                                ? AppTheme.primaryRed
                                : Colors.white.withOpacity(0.1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text('Day $day'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Seçili günün egzersiz listesi
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: dailyExercises[_selectedDay]?.length ?? 0,
                    itemBuilder: (context, index) {
                      final exercise = dailyExercises[_selectedDay]![index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                color: AppTheme.primaryRed,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise['name'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${exercise['defaultSets']} set × ${exercise['defaultReps']} tekrar',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${exercise['defaultWeight']}kg',
                                style: TextStyle(
                                  color: AppTheme.primaryRed,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _logger.severe('Modal açılırken hata oluştu', e);
    }
  }

  // Egzersizleri günlere bölme yardımcı metodu
  Map<int, List<Map<String, dynamic>>> _groupExercisesByDay(
      Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart
      ) {
    final allExercises = exerciseListByBodyPart.values
        .expand((exercises) => exercises)
        .toList();

    final exercisesPerDay = (allExercises.length / 3).ceil();
    Map<int, List<Map<String, dynamic>>> dailyExercises = {};

    for (int day = 1; day <= 3; day++) {
      final startIndex = (day - 1) * exercisesPerDay;
      var endIndex = startIndex + exercisesPerDay;

      if (endIndex > allExercises.length) {
        endIndex = allExercises.length;
      }

      dailyExercises[day] = allExercises.sublist(startIndex, endIndex);
    }

    return dailyExercises;
  }


  List<Widget> _buildExerciseList(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    return exerciseListByBodyPart.entries.map((entry) {
      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingMedium,
          vertical: AppTheme.paddingSmall,
        ),
        child: Stack(
          children: [
            // Ana Container
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cardShadowColor,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Theme(
                data: ThemeData(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  backgroundColor: Colors.transparent,
                  collapsedBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  ),
                  title: Row(
                    children: [
                      // İkon Container
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryRed.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getBodyPartIcon(entry.key),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: AppTheme.paddingMedium),
                      // Başlık ve Alt Başlık
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: AppTheme.headingSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.value.length} egzersiz',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // Egzersiz Sayısı Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.paddingSmall,
                          vertical: AppTheme.paddingSmall / 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryRed.withOpacity(0.2),
                              AppTheme.secondaryRed.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                          border: Border.all(
                            color: AppTheme.primaryRed.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${entry.value.length}',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(AppTheme.borderRadiusLarge),
                          bottomRight: Radius.circular(AppTheme.borderRadiusLarge),
                        ),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppTheme.paddingMedium),
                        itemCount: entry.value.length,
                        itemBuilder: (context, index) {
                          final exerciseMap = entry.value[index];
                          final exerciseData = Exercises.fromMap(exerciseMap);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.cardGradient,
                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                                border: Border.all(
                                  color: AppTheme.primaryRed.withOpacity(0.1),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.shadowColor,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ExerciseCard(
                                exercise: exerciseData,
                                userId: widget.userId,
                                onCompletionChanged: (isCompleted) {
                                  _updateExerciseCompletion(
                                    exerciseData.id,
                                    isCompleted,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Süs Elementleri
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRed.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryRed.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _updateExerciseCompletion(int exerciseId, bool isCompleted) {
    FirebaseFirestore.instance
        .collection('exerciseProgress')
        .doc('${widget.userId}_$exerciseId')
        .set({
      'userId': widget.userId,
      'exerciseId': exerciseId,
      'isCompleted': isCompleted,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }


  IconData _getBodyPartIcon(String bodyPartName) {
    switch (bodyPartName.toLowerCase()) {
      case 'göğüs':
        return Icons.fitness_center;
      case 'sırt':
        return Icons.accessibility_new;
      case 'bacak':
        return Icons.directions_walk;
      case 'omuz':
        return Icons.sports_gymnastics;
      case 'kol':
        return Icons.sports_handball;
      case 'karın':
        return Icons.straighten;
      default:
        return Icons.fitness_center;
    }
  }

  Widget _buildStatItem(IconData icon, String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardShadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingSmall),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              label,
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTheme.headingSmall.copyWith(
                color: color ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryRed,
          ),
          const SizedBox(width: AppTheme.paddingSmall),
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Color _getProgressColor(int progress) {
    if (progress >= 80) return Colors.green;
    if (progress >= 60) return Colors.lightGreen;
    if (progress >= 40) return Colors.orange;
    if (progress >= 20) return Colors.deepOrange;
    return Colors.white70.withRed(15);
  }

  int _getTotalExerciseCount(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    return exerciseListByBodyPart.values
        .fold(0, (sum, exercises) => sum + exercises.length);
  }





  Widget _buildExerciseListTile(Map<String, dynamic> exercise) {
    return ListTile(
      title: Text(exercise['name']),
      subtitle: Text(
        'Set: ${exercise['defaultSets']}, '
            'Tekrar: ${exercise['defaultReps']}, '
            'Ağırlık: ${exercise['defaultWeight']}',
      ),
      trailing: Text(exercise['workoutType']),
    );
  }
}