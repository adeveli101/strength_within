// ignore_for_file: unused_element


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strength_within/data_bloc_part/part_bloc.dart';
import 'package:strength_within/models/Parts.dart';
import 'package:strength_within/ui/part_ui/part_card.dart';
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
        _updateAndFetchParts();
        Navigator.of(context).pop();
      },
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          if (notification.extent <= notification.minExtent) {
            _updateAndFetchParts();
            Navigator.of(context).pop();
          }
          return true;
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return _buildMainContainer(controller);
          },
        ),
      ),
    );
  }

  Widget _buildMainContainer(ScrollController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.vertical(
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
          _buildDecorativeElements(),
          _buildContent(controller),
          _buildDragHandle(),
        ],
      ),
    );
  }

  void _updateAndFetchParts() {
    final state = _partsBloc.state;
    if (state is PartExercisesLoaded) {
      _partsBloc.add(UpdatePart(state.part));
      _partsBloc.add(FetchParts());
    }
  }

  Widget _buildDragHandle() {
    return Positioned(
      top: AppTheme.paddingSmall,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ScrollController controller) {
    return BlocBuilder<PartsBloc, PartsState>(
      builder: (context, state) {
        if (state is PartsLoading) {
          return _buildLoadingState();
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
          return _buildErrorState(state.message);
        }
        return _buildUnexpectedState(state);
      },
    );
  }

  Widget _buildLoadedContent(PartExercisesLoaded state, ScrollController controller) {
    return Container(
      color: AppTheme.darkBackground,
      child: ListView(
        controller: controller,
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(state),
          _buildStatisticsSection(state),
          if (state.part.additionalNotes.isNotEmpty)
            _buildDescriptionSection(state),
          _buildExercisesSection(state),
          SizedBox(height: AppTheme.paddingLarge),
        ],
      ),
    );
  }

  Widget _buildDifficultyIndicator() {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: AppTheme.paddingSmall), // Maksimum genişlik sınırı
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.paddingLarge,
          vertical: AppTheme.paddingMedium,
        ),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: AppTheme.buildDifficultyStars(widget.partId),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
          ),
          SizedBox(height: AppTheme.paddingMedium),
          Text(
            'Yükleniyor...',
            style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
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
            'Hata: $message',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryRed,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUnexpectedState(PartsState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warningYellow,
            size: 48,
          ),
          SizedBox(height: AppTheme.paddingMedium),
          Text(
            'Beklenmeyen durum: ${state.runtimeType}',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.warningYellow,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(PartExercisesLoaded state) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingLarge,
        vertical: AppTheme.paddingMedium,
      ),
      decoration: AppTheme.decoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryRed.withOpacity(0.2),
            AppTheme.darkBackground.withOpacity(0.15),
          ],
        ),
        borderRadius: AppTheme.getBorderRadius(
          bottomLeft: AppTheme.borderRadiusLarge,
          bottomRight: AppTheme.borderRadiusLarge,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.paddingSmall),
            decoration: AppTheme.decoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryRed.withOpacity(0.2),
                  AppTheme.darkBackground.withOpacity(0.15),
                ],
              ),
              borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
            ),
            child: Icon(
              Icons.fitness_center,
              color: Colors.white70,
              size: 20,
            ),
          ),
          SizedBox(width: AppTheme.paddingMedium),
          Expanded(
            child: Text(
              state.part.name,
              style: AppTheme.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          _buildScheduleButton(state),
        ],
      ),
    );
  }

  Widget _buildScheduleButton(PartExercisesLoaded state) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, scheduleState) {
        bool hasSchedule = false;

        if (scheduleState is SchedulesLoaded) {
          hasSchedule = scheduleState.schedules.any(
                (schedule) => schedule.itemId == state.part.id && schedule.type == 'part',
          );
        }

        return InkWell(
          onTap: () => _showScheduleModal(
            context,
            state.part,
            state.exerciseListByBodyPart,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.paddingMedium,
              vertical: AppTheme.paddingSmall,
            ),
            decoration: BoxDecoration(
              gradient: hasSchedule ? AppTheme.primaryGradient : null,
              color: hasSchedule ? null : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
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
                SizedBox(width: AppTheme.paddingSmall),
                Text(
                  hasSchedule ? 'Programı Düzenle' : 'Programa Ekle',
                  style: AppTheme.bodySmall.copyWith(
                    color: hasSchedule ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsSection(PartExercisesLoaded state) {
    return _buildExpandableSection(
      title: 'İstatistikler',
      icon: Icons.analytics_outlined,
      initiallyExpanded: true,
      child: Container(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        margin: EdgeInsets.all(AppTheme.paddingMedium),
        decoration: AppTheme.decoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryRed.withOpacity(0.1),
              AppTheme.darkBackground.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusMedium),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
            SizedBox(height: AppTheme.paddingMedium),
            Container(
              padding: EdgeInsets.symmetric(
                vertical: AppTheme.paddingSmall,
                horizontal: AppTheme.paddingMedium,
              ),
              decoration: AppTheme.decoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryRed.withOpacity(0.1),
                    AppTheme.darkBackground.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDifficultyIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(PartExercisesLoaded state) {
    return _buildExpandableSection(
      title: 'Açıklama',
      icon: Icons.insert_drive_file_rounded,
      initiallyExpanded: true,
      child: Container(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        margin: EdgeInsets.all(AppTheme.paddingMedium),
        decoration: AppTheme.decoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryRed.withOpacity(0.2),
              AppTheme.darkBackground.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusMedium),
        ),
        child: Text(
          state.part.additionalNotes,
          style: AppTheme.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildExercisesSection(PartExercisesLoaded state) {
    return _buildExpandableSection(
      title: 'Egzersizler',
      icon: Icons.fitness_center,
      initiallyExpanded: true,
      trailing: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.paddingMedium,
          vertical: AppTheme.paddingSmall,
        ),
        decoration: AppTheme.decoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryRed.withOpacity(0.2),
              AppTheme.darkBackground.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 14,
              color: Colors.white70,
            ),
            SizedBox(width: AppTheme.paddingSmall),
            Text(
              '${_getTotalExerciseCount(state.exerciseListByBodyPart)} egzersiz',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        decoration: AppTheme.decoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryRed.withOpacity(0.01),
              AppTheme.darkBackground.withOpacity(0.01),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppTheme.getBorderRadius(
            bottomLeft: AppTheme.borderRadiusSmall,
            bottomRight: AppTheme.borderRadiusSmall,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.paddingMedium),
              decoration: AppTheme.decoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryRed.withOpacity(0.2),
                    AppTheme.darkBackground.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusMedium),
              ),
              child: Column(
                children: _buildExerciseList(state.exerciseListByBodyPart),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Widget child,
    required bool initiallyExpanded,
    Widget? trailing,
  }) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      title: Text(title, style: AppTheme.headingSmall),
      leading: Container(
        padding: EdgeInsets.all(AppTheme.paddingSmall),
        decoration: AppTheme.decoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryRed.withOpacity(0.1),
              AppTheme.darkBackground.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
      ),
      trailing: trailing,
      children: [child],
    );
  }


  Future<List<String>> _getBodyPartName(List<int> bodyPartIds) async {
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
          userId: widget.userId, // Kullanıcı ID'sini buradan geçirin
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
        Container(
          padding: EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            children: [
              Icon(
                Icons.fitness_center,
                size: 48,
                color: Colors.white.withOpacity(0.3),
              ),
              SizedBox(height: AppTheme.paddingMedium),
              Text(
                'Egzersiz bulunamadı.',
                style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
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
        decoration: AppTheme.decoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusMedium),
        ),
        child: ExpansionTile(
          title: _buildExpansionTileTitle(entry),
          children: [_buildExerciseListView(entry)],
        ),
      );
    }).toList();
  }

  Widget _buildExpansionTileTitle(MapEntry<String, List<Map<String, dynamic>>> entry) {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.paddingMedium),
            decoration: AppTheme.decoration(
              gradient: AppTheme.getPartGradient(
                difficulty: 1,
                secondaryColor: AppTheme.getTargetColor(1),
              ),
              borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
            ),
            child:Image.asset(
              _getBodyPartAsset(entry.key),
              width: 24,
              height: 24,
              color: Colors.white70,
            )

          ),
          SizedBox(width: AppTheme.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: AppTheme.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppTheme.paddingSmall / 2),
                Text(
                  '${entry.value.length} egzersiz',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseListView(MapEntry<String, List<Map<String, dynamic>>> entry) {
    return Container(
      decoration: AppTheme.decoration(
        color: AppTheme.primaryRed.withOpacity(0.2),
        borderRadius: AppTheme.getBorderRadius(
          bottomLeft: AppTheme.borderRadiusLarge,
          bottomRight: AppTheme.borderRadiusLarge,
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        itemCount: entry.value.length,
        itemBuilder: (context, index) {
          final exerciseMap = entry.value[index];
          final exerciseData = Exercises.fromMap(exerciseMap);

          return Container(
            margin: EdgeInsets.only(bottom: AppTheme.paddingSmall),
            decoration: AppTheme.decoration(
              gradient: AppTheme.cardGradient,
              borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusMedium),
            ),
            child: ExerciseCard(
              exercise: exerciseData,
              userId: widget.userId,
              onCompletionChanged: (isCompleted) {
                _updateExerciseCompletion(exerciseData.id, isCompleted);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDecorativeElements() {
    return Positioned(
      top: AppTheme.paddingSmall,
      right: AppTheme.paddingSmall,
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
    );
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

  String _getBodyPartAsset(String bodyPartName) {
    switch (bodyPartName.toLowerCase()) {
      case 'chest':
        return 'assets/chests-modified.png';
      case 'back':
        return 'assets/back-modified.png';
      case 'legs':
        return 'assets/leg-modif.png';
      case 'shoulders':
        return 'assets/shoulder-modified.png';
      case 'arms':
        return 'assets/arm-modified.png';
      case 'abs':
      case 'core':
        return 'assets/core-modified.png';
      default:
        return 'assets/core-modified.png';
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
      decoration: AppTheme.decoration(
        color: Colors.black26,
        borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white70,
          ),
          SizedBox(width: AppTheme.paddingSmall),
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(int progress) {
    if (progress >= 80) return AppTheme.successGreen;
    if (progress >= 60) return AppTheme.warningYellow;
    if (progress >= 40) return AppTheme.warningOrange;
    if (progress >= 20) return AppTheme.errorRed;
    return AppTheme.primaryRed.withOpacity(0.5);
  }

  Widget _buildExerciseListTile(Map<String, dynamic> exercise) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall / 2,
      ),
      decoration: AppTheme.decoration(
        gradient: AppTheme.cardGradient,
        borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusMedium),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(AppTheme.paddingMedium),
        title: Text(
          exercise['name'],
          style: AppTheme.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: AppTheme.paddingSmall),
          child: Row(
            children: [
              _buildExerciseInfo(Icons.repeat, '${exercise['defaultSets']} Set'),
              SizedBox(width: AppTheme.paddingSmall),
              _buildExerciseInfo(Icons.fitness_center, '${exercise['defaultReps']} Tekrar'),
              SizedBox(width: AppTheme.paddingSmall),
              _buildExerciseInfo(Icons.monitor_weight_outlined, '${exercise['defaultWeight']}kg'),
            ],
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.paddingMedium,
            vertical: AppTheme.paddingSmall,
          ),
          decoration: AppTheme.decoration(
            color: AppTheme.primaryRed.withOpacity(0.1),
            borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusLarge),
          ),
          child: Text(
            exercise['workoutType'],
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.primaryRed,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  int _getTotalExerciseCount(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    return exerciseListByBodyPart.values
        .fold(0, (sum, exercises) => sum + exercises.length);
  }


}