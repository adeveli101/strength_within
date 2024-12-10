// ignore_for_file: unused_element


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/data_bloc_part/part_bloc.dart';
import 'package:workout/models/Parts.dart';
import 'package:workout/ui/part_ui/part_card.dart';
import 'package:logging/logging.dart';

import '../../data_schedule_bloc/schedule_bloc.dart';
import '../../data_schedule_bloc/schedule_repository.dart';
import '../../firebase_class/user_schedule.dart';
import '../../models/exercises.dart';
import '../../z.app_theme/app_theme.dart';
import '../exercises_ui/exercise_card.dart';
import '../exercises_ui/exercise_details.dart';
import '../list_pages/schedule_modal.dart';

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




  @override
  void initState() {
    super.initState();
    _partsBloc = context.read<PartsBloc>();
    _logger.info("PartDetailBottomSheet initialized with partId: ${widget.partId}");

    // Schedule verilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final scheduleBloc = context.read<ScheduleBloc>();
        scheduleBloc.add(LoadUserSchedules(widget.userId));
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
                borderRadius:  BorderRadius.vertical(
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
                          borderRadius: BorderRadius.vertical(
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
                              SizedBox(height: AppTheme.paddingMedium),
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
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: const BorderRadius.only(
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
                                schedule.type == 'part',
                          );
                        }
                        return InkWell(
                          onTap: () => _showScheduleModal(
                            context,
                            state.part,
                            state.exerciseListByBodyPart,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: hasSchedule ? AppTheme.primaryGradient : null,
                              color: hasSchedule ? null : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: hasSchedule
                                  ? null
                                  : Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: hasSchedule ? Colors.white : Colors.white70,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  hasSchedule ? 'Programı Düzenle' : 'Programa Ekle',
                                  style: TextStyle(
                                    color: hasSchedule ? Colors.white : Colors.white70,
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
              ],
            ),
          ),

          // Açılıp Kapanabilir Bölümler
          // 2. İstatistikler
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(
              'İstatistikler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.analytics_outlined,
                color: AppTheme.primaryRed,
                size: 20,
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildStatItem(
                      Icons.fitness_center,
                      'Egzersiz Sayısı',
                      _getTotalExerciseCount(state.exerciseListByBodyPart).toString(),
                    ),
                    _buildStatItem(
                      Icons.category,
                      'Bölge',
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
              ),
            ],
          ),

          if (state.part.additionalNotes != null &&
              state.part.additionalNotes.isNotEmpty)
            ExpansionTile(
              initiallyExpanded: true,
              title: Text(
                'Açıklama',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryRed,
                  size: 20,
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.part.additionalNotes,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

          // 4. Egzersizler
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(
              'Egzersizler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: Container(
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
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_getTotalExerciseCount(state.exerciseListByBodyPart)} egzersiz',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            children: [
              ..._buildExerciseList(state.exerciseListByBodyPart),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<List<String>> _getBodyPartName(List<int> bodyPartIds) async {
    // BLoC'dan repository'yi kullanarak body part isimlerini al
    final bodyPartNames = await BlocProvider.of<PartsBloc>(context).repository.getBodyPartNamesByIds(bodyPartIds);
    if (bodyPartNames.isEmpty) {
      return List.filled(bodyPartIds.length, 'Bilinmiyor');
    }

    return bodyPartNames;
  }


  void _showScheduleModal(
      BuildContext context,
      Parts part,
      Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart,
      ) async {
    try {
      final scheduleBloc = context.read<ScheduleBloc>();

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => ScheduleModal(
          userId: 'currentUserId', // Kullanıcı ID'sini buradan geçirin
          type: 'part',
          itemId: part.id,
          itemName: part.name,
          description: part.additionalNotes,
          exerciseListByBodyPart: exerciseListByBodyPart,
        ),
      );
    } catch (e) {
      _logger.severe('Modal açılırken hata oluştu', e);
    }
  }


  Map<int, List<Map<String, dynamic>>> groupExercisesByDay(
      Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart,
      int recommendedFrequency,
      ) {
    try {
      // Tüm egzersizleri tek bir listede topla ve sırala
      final allExercises = exerciseListByBodyPart.values
          .expand((exercises) => exercises)
          .toList()
        ..sort((a, b) => (a['orderIndex'] as int).compareTo(b['orderIndex'] as int));

      Map<int, List<Map<String, dynamic>>> dailyExercises = {};
      int exercisesPerDay = (allExercises.length / recommendedFrequency).ceil();

      for (int day = 1; day <= recommendedFrequency; day++) {
        int startIndex = (day - 1) * exercisesPerDay;
        int endIndex = startIndex + exercisesPerDay;

        // Son indeksi kontrol et
        if (endIndex > allExercises.length) {
          endIndex = allExercises.length;
        }

        // Günlük egzersizleri al ve listeye ekle
        dailyExercises[day] = allExercises
            .sublist(startIndex, endIndex)
            .map((exercise) => {
          'exerciseId': exercise['id'],
          'name': exercise['name'],
          'sets': exercise['defaultSets'],
          'reps': exercise['defaultReps'],
          'weight': exercise['defaultWeight'],
          'orderIndex': exercise['orderIndex'],
          'type': 'part',
          'isCompleted': false,
          'completedAt': null,
          'mainTargetedBodyPartId': exercise['mainTargetedBodyPartId'],
          'workoutTypeId': exercise['workoutTypeId'],
          'description': exercise['description'],
          'gifUrl': exercise['gifUrl'],
        })
            .toList();
      }

      return dailyExercises;
    } catch (e) {
      _logger.severe('Egzersizler günlere bölünürken hata oluştu', e);
      throw ScheduleException('Egzersizler günlere bölünürken hata oluştu: $e');
    }
  }


  List<Widget> _buildExerciseList(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    if (exerciseListByBodyPart.isEmpty) {
      return [
        Center(
          child: Text(
            'Egzersiz bulunamadı.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ];
    }

    return exerciseListByBodyPart.entries.map((entry) {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppTheme.paddingMedium,
          vertical: AppTheme.paddingSmall,
        ),
        child: ExpansionTile(
          title: Text(
            entry.key,
            style: AppTheme.headingSmall,
          ),
          children: entry.value.map((exercise) {
            return ListTile(
              title: Text(exercise['name']),
              subtitle: Text(
                'Setler: ${exercise['defaultSets']}, Tekrarlar: ${exercise['defaultReps']}',
              ),
              trailing: Text('${exercise['defaultWeight']} kg'),
            );
          }).toList(),
        ),
      );
    }).toList();
  }
// Başlık ve Alt Başlık için yardımcı metod
  Widget _buildExpansionTileTitle(MapEntry<String, List<Map<String, dynamic>>> entry) {
    return Row(
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
            _getBodyPartIcon(entry.key), // Ana kas grubunun ikonunu al
            color: Colors.white,
            size: 30,
          ),
        ),
        SizedBox(width: AppTheme.paddingMedium),
        // Başlık ve Alt Başlık
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: AppTheme.headingSmall), // Ana kas grubunun adı
              const SizedBox(height: 4),
              Text('${entry.value.length} egzersiz', style: AppTheme.bodySmall), // Egzersiz sayısı
            ],
          ),
        ),
      ],
    );
  }

// Egzersizleri listeleyen view için yardımcı metod
  Widget _buildExerciseListView(MapEntry<String, List<Map<String, dynamic>>> entry) {
    return Container(
      decoration:
      BoxDecoration(color: AppTheme.surfaceColor, borderRadius:
      BorderRadius.only(bottomLeft:
      Radius.circular(AppTheme.borderRadiusLarge), bottomRight:
      Radius.circular(AppTheme.borderRadiusLarge)),
      ),
      child:
      ListView.builder(shrinkWrap:
      true, physics:
      const NeverScrollableScrollPhysics(), padding:
      EdgeInsets.all(AppTheme.paddingMedium), itemCount:
      entry.value.length, itemBuilder:
          (context, index) {
        final exerciseMap = entry.value[index];
        final exerciseData = Exercises.fromMap(exerciseMap);

        return Padding(padding:
        EdgeInsets.only(bottom:
        AppTheme.paddingSmall), child:
        Container(decoration:
        BoxDecoration(gradient:
        AppTheme.cardGradient, borderRadius:
        BorderRadius.circular(AppTheme.borderRadiusMedium), border:
        Border.all(color:
        AppTheme.primaryRed.withOpacity(0.1), width:
        1), boxShadow:[
          BoxShadow(color:
          AppTheme.shadowColor, blurRadius:
          8, offset:
          const Offset(0, 4)),],), child:
        ExerciseCard(exercise:
        exerciseData, userId:
        widget.userId, onCompletionChanged:
            (isCompleted) {
          _updateExerciseCompletion(exerciseData.id, isCompleted);
        }),),);},),);
  }

// Süs elementleri için yardımcı metod
  Widget _buildDecorativeElements() {
    return Positioned(top :12 , right :12 , child :Container (
      width :8 , height :8 , decoration :BoxDecoration (
      color :AppTheme.primaryRed , shape :BoxShape.circle ,
      boxShadow :[ BoxShadow (
        color :AppTheme.primaryRed.withOpacity(0.5) ,
        blurRadius :8 , spreadRadius :2 ,)],),),);
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
        padding: EdgeInsets.all(AppTheme.paddingMedium),
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
              padding: EdgeInsets.all(AppTheme.paddingSmall),
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
            SizedBox(height: AppTheme.paddingSmall),
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
      padding: EdgeInsets.symmetric(
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
          SizedBox(width: AppTheme.paddingSmall),
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