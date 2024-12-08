// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/root_controller.dart';
import 'package:logging/logging.dart';
import 'package:workout/data_bloc_routine/routines_bloc.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/ui/routine_ui/routine_card.dart';

import '../../data_schedule_bloc/schedule_bloc.dart';
import '../../models/RoutinetargetedBodyParts.dart';
import '../../models/exercises.dart';
import '../../z.app_theme/app_theme.dart';
import '../exercises_ui/exercise_card.dart';
import '../exercises_ui/exercise_details.dart';
import '../list_pages/schedule_modal.dart';

class RoutineDetailBottomSheet extends StatefulWidget {
  final int routineId;
  final String userId;


  const RoutineDetailBottomSheet({
    super.key,
    required this.routineId,
    required this.userId,

  });

  @override
  _RoutineDetailBottomSheetState createState() => _RoutineDetailBottomSheetState();
}

class _RoutineDetailBottomSheetState extends State<RoutineDetailBottomSheet> {
  late RoutinesBloc _routinesBloc;
  final Logger _logger = Logger('RoutineDetailBottomSheet');
  Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart = {};
  Map<int, String> workoutTypeNames = {};
  Map<int, String> bodyPartNames = {};

  @override


  @override
  void initState() {
    super.initState();
    _routinesBloc = context.read<RoutinesBloc>();
    _loadInitialData();
  }

  void _loadInitialData() {
    try {
      // Rutin egzersizlerini yükle
      _routinesBloc.add(FetchRoutineExercises(routineId: widget.routineId));
    } catch (e) {
      _logger.severe('Error loading initial data', e);
    }
  }

  String getWorkoutTypeName(int workoutTypeId) {
    return workoutTypeNames[workoutTypeId] ?? 'Yükleniyor...';
  }


  String getBodyPartName(int bodyPartId) {
    return bodyPartNames[bodyPartId] ?? 'Yükleniyor...';
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: _handlePop,
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => _buildMainContainer(controller),
      ),
    );
  }

// Pop işlemini yönet
  Future<void> _handlePop(bool didPop, dynamic result) async {
    if (!didPop) return;

    final state = _routinesBloc.state;
    if (state is RoutineExercisesLoaded) {
      _routinesBloc.add(FetchRoutines());
    }

    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

// Ana container yapısı
  Widget _buildMainContainer(ScrollController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.borderRadiusSmall),
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
          _buildDecorationElement(),
          _buildContent(controller),
          _buildDragHandle(),
        ],
      ),
    );
  }

// Süsleme elementi
  Widget _buildDecorationElement() {
    return Positioned(
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
    );
  }

// Ana içerik
  Widget _buildContent(ScrollController controller) {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      buildWhen: (previous, current) {
        return current is RoutinesLoading ||
            current is RoutineExercisesLoaded ||
            current is RoutinesError;
      },
      builder: (context, state) {
        if (state is RoutinesLoading) {
          return _buildLoadingState();
        }

        if (state is RoutineExercisesLoaded) {
          return _buildLoadedState(state, controller);
        }

        if (state is RoutinesError) {
          return _buildErrorState(state.message);
        }

        return _buildInitialState();
      },
    );
  }

// Loading durumu
  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(AppTheme.primaryRed),
      ),
    );
  }

// Loaded durumu
  Widget _buildLoadedState(RoutineExercisesLoaded state, ScrollController controller) {
    final routine = state.routine;
    if (routine.id != widget.routineId) {
      return Center(
        child: Text(
          'Rutin bulunamadı',
          style: AppTheme.bodyMedium,
        ),
      );
    }
    return _buildRoutineDetails(
      routine,
      state.exerciseListByBodyPart,
      controller,
    );
  }

// Error durumu
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

// Initial durumu
  Widget _buildInitialState() {
    return Center(
      child: Text(
        'Veriler yükleniyor...',
        style: AppTheme.bodyMedium,
      ),
    );
  }

// Drag handle
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
            borderRadius: BorderRadius.circular(
              AppTheme.borderRadiusSmall,
            ),
          ),
        ),
      ),
    );
  }

  void _showScheduleModal(
      BuildContext context,
      Routines routine,
      Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart,
      ) async {
    try {
      final scheduleBloc = context.read<ScheduleBloc>();

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => ScheduleModal(
          userId: widget.userId,
          type: 'routine',
          itemId: routine.id,
          itemName: routine.name,
          description: routine.description,
          exerciseListByBodyPart: exerciseListByBodyPart,
        ),
      );
    } catch (e) {
      _logger.severe('Modal açılırken hata oluştu', e);
    }
  }

  Widget _buildRoutineDetails(
      Routines routine,
      Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart,
      ScrollController controller,
      ) {
    return Container(
      color: AppTheme.darkBackground,
      child: ListView(
        controller: controller,
        padding: EdgeInsets.zero,
        children: [

          _buildHeaderSection(routine),
          // Stats Section
          _buildExpandableSection(
            title: 'İstatistikler',
            icon: Icons.analytics_outlined,
            content: _buildStatsContent(routine),
            initiallyExpanded: true,
          ),
          // Description Section
          _buildExpandableSection(
            title: 'Rutin Açıklaması',
            icon: Icons.description,
            content: _buildDescriptionContent(routine),
            initiallyExpanded: true,
          ),
          // Progress Section

          // Exercises Section
          _buildExpandableSection(
            title: 'Egzersizler',
            icon: Icons.fitness_center,
            content: _buildExercisesContent(exerciseListByBodyPart),
            initiallyExpanded: true,
            trailing: _buildExerciseCount(exerciseListByBodyPart),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Widget content,
    bool initiallyExpanded = true,
    Widget? trailing,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.1),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          leading: Container(
            padding:  EdgeInsets.all(AppTheme.paddingSmall),
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
          title: Text(title, style: AppTheme.headingSmall),
          trailing: trailing,
          children: [content],
        ),
      ),
    );
  }

// Header Builder
  Widget _buildHeader(Routines routine) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardGradient.colors.first,
            AppTheme.cardGradient.colors.last.withOpacity(0.95),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sol taraf - Başlık
          Expanded(
            child: Row(
              children: [

                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    routine.name,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Sağ taraf - Schedule butonu
          _buildScheduleButton(routine),
        ],
      ),
    );
  }

// Quick Stats Builder
  Widget _buildQuickStats(Routines routine) {
    return Container(
      padding:  EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Row(
        children: [
          _buildStatItem(
            Icons.fitness_center,
            'Egzersiz Sayısı',
            _getTotalExerciseCount(exerciseListByBodyPart).toString(),
          ),
          _buildStatItem(
            Icons.category,
            'Tip',
            routine.workoutTypeId.toString(),
          ),
          _buildStatItem(
            Icons.trending_up,
            'İlerleme',
            '${routine.userProgress ?? 0}%',
            color: _getProgressColor(routine.userProgress ?? 0),
          ),
        ],
      ),
    );
  }

// Exercise List Builder
  Widget _buildExerciseList(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    return Column(
      children: exerciseListByBodyPart.entries.map((entry) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppTheme.paddingSmall,
            vertical: AppTheme.paddingSmall,
          ),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
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
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              leading: Container(
                padding: EdgeInsets.all(AppTheme.paddingSmall),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Icon(
                  _getBodyPartIcon(entry.key),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                entry.key,
                style: AppTheme.headingSmall,
              ),
              trailing: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSmall,
                  vertical: AppTheme.paddingSmall / 2,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Text(
                  '${entry.value.length}',
                  style: AppTheme.bodySmall.copyWith(color: Colors.white),
                ),
              ),
              children: entry.value.asMap().entries.map((exercise) {
                return Container(
                  margin: EdgeInsets.only(bottom: AppTheme.paddingSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    border: Border.all(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                    ),
                  ),
                  child: ListTile(
                    contentPadding:  EdgeInsets.all(AppTheme.paddingSmall),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                      child: Text(
                        '${exercise.key + 1}',
                        style: AppTheme.bodySmall.copyWith(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      exercise.value['name'],
                      style: AppTheme.bodyMedium,
                    ),
                    subtitle: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildExerciseInfo(
                            Icons.repeat,
                            '${exercise.value['defaultSets']} set',
                          ),
                          SizedBox(width: AppTheme.paddingMedium),
                          _buildExerciseInfo(
                            Icons.fitness_center,
                            '${exercise.value['defaultReps']} tekrar',
                          ),
                          SizedBox(width: AppTheme.paddingMedium),
                          _buildExerciseInfo(
                            Icons.monitor_weight_outlined,
                            '${exercise.value['defaultWeight']} kg',
                          ),
                        ],
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseDetails(
                          exerciseId: exercise.value['id'],
                          userId: widget.userId,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExerciseGroup(List<Map<String, dynamic>> exercises) {
    return Container(
      padding:  EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: exercises.length,
        separatorBuilder: (context, index) => SizedBox(height: AppTheme.paddingSmall),
        itemBuilder: (context, index) => _buildExerciseCard(exercises[index], index),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.paddingSmall),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding:  EdgeInsets.all(AppTheme.paddingSmall),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
          child: Text(
            '${index + 1}',
            style: AppTheme.bodySmall.copyWith(color: Colors.white),
          ),
        ),
        title: Text(
          exercise['name'],
          style: AppTheme.bodyMedium,
        ),
        subtitle: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildExerciseInfo(
                Icons.repeat,
                '${exercise['defaultSets']} set',
              ),
              SizedBox(width: AppTheme.paddingMedium),
              _buildExerciseInfo(
                Icons.fitness_center,
                '${exercise['defaultReps']} tekrar',
              ),
              SizedBox(width: AppTheme.paddingMedium),
              _buildExerciseInfo(
                Icons.monitor_weight_outlined,
                '${exercise['defaultWeight']} kg',
              ),
            ],
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetails(
              exerciseId: exercise['id'],
              userId: widget.userId,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyPartExercises(String bodyPart, List<Map<String, dynamic>> exercises) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
            child: Text(
              bodyPart,
              style: AppTheme.headingSmall,
            ),
          ),
          SizedBox(height: AppTheme.paddingSmall),
          ...exercises.asMap().entries.map((e) => _buildExerciseCard(e.value, e.key)),
        ],
      ),
    );
  }


  Widget _buildHeaderSection(Routines routine) {
    return Container(
      padding:  EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius:  BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.borderRadiusSmall),
          bottomRight: Radius.circular(AppTheme.borderRadiusSmall),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                routine.name,
                style: AppTheme.headingMedium,
              ),
              _buildScheduleButton(routine),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleButton(Routines routine) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, scheduleState) {
        bool hasSchedule = false;
        if (scheduleState is SchedulesLoaded) {
          hasSchedule = scheduleState.schedules.any(
                (schedule) =>
            schedule.itemId == routine.id && schedule.type == 'routine',
          );
        }

        // RoutineExercisesLoaded state'ini kontrol et
        final routineState = context.watch<RoutinesBloc>().state;
        final exerciseListByBodyPart = routineState is RoutineExercisesLoaded
            ? routineState.exerciseListByBodyPart
            : <String, List<Map<String, dynamic>>>{};

        return InkWell(
          onTap: () {
            // State kontrolü ekle
            if (routineState is RoutineExercisesLoaded) {
              _showScheduleModal(
                context,
                routine,
                exerciseListByBodyPart,
              );
            } else {
              // Hata durumunda kullanıcıya bilgi ver
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Egzersiz verileri yüklenirken bir hata oluştu. Lütfen tekrar deneyin.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.paddingMedium,
              vertical: AppTheme.paddingSmall,
            ),
            decoration: BoxDecoration(
              gradient: hasSchedule ? AppTheme.primaryGradient : null,
              color: hasSchedule ? null : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
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

  Widget _buildExerciseCount(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    final count = exerciseListByBodyPart.values
        .fold(0, (sum, exercises) => sum + exercises.length);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Text(
        '$count egzersiz',
        style: AppTheme.bodySmall.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildDescriptionContent(Routines routine) {
    return Container(
      padding:  EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (routine.description.isNotEmpty)
            Text(
              routine.description,
              style: AppTheme.bodyMedium,
            )
          else
            Text(
              'Bu rutin için henüz bir açıklama eklenmemiş.',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressContent(Routines routine) {
    final progress = routine.userProgress ?? 0;
    return Container(
      padding:  EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: AppTheme.progressBarBackground,
              valueColor: AlwaysStoppedAnimation(_getProgressColor(progress)),
              minHeight: 8,
            ),
          ),
          SizedBox(height: AppTheme.paddingSmall),
          Text(
            'Toplam İlerleme: %$progress',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesContent(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    return Column(
      children: exerciseListByBodyPart.entries.map((entry) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppTheme.paddingSmall,
            vertical: AppTheme.paddingSmall,
          ),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
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
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              leading: Container(
                padding:  EdgeInsets.all(AppTheme.paddingSmall),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Icon(
                  _getBodyPartIcon(entry.key),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                entry.key,
                style: AppTheme.headingSmall,
              ),
              trailing: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSmall,
                  vertical: AppTheme.paddingSmall / 2,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Text(
                  '${entry.value.length}',
                  style: AppTheme.bodySmall.copyWith(color: Colors.white),
                ),
              ),
              children: entry.value.asMap().entries.map((exercise) {
                return Container(
                  margin: EdgeInsets.only(bottom: AppTheme.paddingSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    border: Border.all(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                    ),
                  ),
                  child: ListTile(
                    contentPadding:  EdgeInsets.all(AppTheme.paddingSmall),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                      child: Text(
                        '${exercise.key + 1}',
                        style: AppTheme.bodySmall.copyWith(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      exercise.value['name'],
                      style: AppTheme.bodyMedium,
                    ),
                    subtitle: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildExerciseInfo(
                            Icons.repeat,
                            '${exercise.value['defaultSets']} set',
                          ),
                          SizedBox(width: AppTheme.paddingMedium),
                          _buildExerciseInfo(
                            Icons.fitness_center,
                            '${exercise.value['defaultReps']} tekrar',
                          ),
                          SizedBox(width: AppTheme.paddingMedium),
                          _buildExerciseInfo(
                            Icons.monitor_weight_outlined,
                            '${exercise.value['defaultWeight']} kg',
                          ),
                        ],
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseDetails(
                          exerciseId: exercise.value['id'],
                          userId: widget.userId,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {Color? color}) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 120;
          final iconSize = isSmallScreen ? 20.0 : 24.0;
          final padding = isSmallScreen
              ? EdgeInsets.all(AppTheme.paddingSmall / 2)
              : EdgeInsets.all(AppTheme.paddingSmall);

          return Container(
            padding: padding,
            margin: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 4 : AppTheme.paddingSmall,
            ),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cardShadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    isSmallScreen ? AppTheme.paddingSmall / 2 : AppTheme.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : AppTheme.paddingSmall),
                Text(
                  label,
                  style: isSmallScreen
                      ? AppTheme.bodySmall
                      : AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 2 : 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: (isSmallScreen
                        ? AppTheme.bodyMedium
                        : AppTheme.headingSmall)
                        .copyWith(
                      color: color ?? Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
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

  Widget _buildStatsContent(Routines routine) {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Row(
        children: [

          FutureBuilder<String>(
            future: _routinesBloc.repository.getWorkoutTypeById(routine.workoutTypeId)
                .then((workoutType) => workoutType?.name ?? 'Bilinmeyen'),
            builder: (context, snapshot) {
              return _buildStatItem(
                Icons.category,
                'Tip',
                snapshot.data ?? 'Yükleniyor...',
              );
            },
          ),
          _buildStatItem(
            Icons.trending_up,
            'İlerleme',
            '${routine.userProgress ?? 0}%',
            color: _getProgressColor(routine.userProgress ?? 0),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoCard(Routines routine) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
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
      padding: EdgeInsets.all(AppTheme.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.paddingSmall),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: AppTheme.paddingMedium),
              Text(
                'Detaylar',
                style: AppTheme.headingSmall,
              ),
            ],
          ),
          Divider(
            height: AppTheme.paddingSmall,
            color: AppTheme.primaryRed.withOpacity(0.2),
          ),
          _buildTargetedBodyPartsList(routine.targetedBodyPartIds),
          SizedBox(height: AppTheme.paddingSmall),
          _buildExerciseInfo(Icons.category, 'Tip: ${getWorkoutTypeName(routine.workoutTypeId)}'),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Routines routine) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
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
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.paddingSmall),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppTheme.paddingMedium),
                Text(
                  'Rutin Bilgileri',
                  style: AppTheme.headingSmall,
                ),
              ],
            ),
            SizedBox(height: AppTheme.paddingMedium),
            _buildTargetedBodyPartsInfo(routine.targetedBodyPartIds),
            _buildInfoRow(Icons.category, 'Antrenman Tipi', getWorkoutTypeName(routine.workoutTypeId)),
            if (routine.lastUsedDate != null)
              _buildInfoRow(
                Icons.access_time,
                'Son Kullanım',
                routine.lastUsedDate!.toLocal().toString().split('.')[0],
              ),
          ],
        ),
      ),
    );
  }

// Yardımcı metodlar
  Widget _buildTargetedBodyPartsList(List<dynamic> targetedBodyPartIds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: targetedBodyPartIds.map((bodyPartId) =>
          _buildExerciseInfo(
              Icons.track_changes,
              getBodyPartName(bodyPartId)
          )
      ).toList(),
    );
  }

  Future<String> _buildTargetedBodyPartsText(List<dynamic> bodyPartIds) async {
    if (bodyPartIds.isEmpty) return 'Belirtilmemiş';

    List<String> bodyPartNames = [];
    for (var id in bodyPartIds) {
      final bodyPart = await _routinesBloc.repository.getBodyPartById(id);
      if (bodyPart != null) {
        bodyPartNames.add(bodyPart.name);
      }
    }

    return bodyPartNames.isEmpty ? 'Belirtilmemiş' : bodyPartNames.join(', ');
  }
  Widget _buildTargetedBodyPartsInfo(List<dynamic> targetedBodyPartIds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: targetedBodyPartIds.map((bodyPartId) =>
          _buildInfoRow(
              Icons.fitness_center,
              'Hedef Kas',
              getBodyPartName(bodyPartId)
          )
      ).toList(),
    );
  }

  Widget _buildCompactProgressCard(Routines routine) {
    final progress = routine.userProgress ?? 0;
    final color = _getProgressColor(progress);

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadowColor,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppTheme.paddingSmall),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppTheme.paddingMedium),
                  Text(
                    'İlerleme',
                    style: AppTheme.headingSmall,
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingMedium,
                  vertical: AppTheme.paddingSmall,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Text(
                  '%$progress',
                  style: AppTheme.headingSmall.copyWith(color: color),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.paddingMedium),
          Container(
            height: AppTheme.progressBarHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppTheme.paddingSmall,
        horizontal: AppTheme.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppTheme.primaryRed,
              ),
              SizedBox(width: AppTheme.paddingSmall),
              Text(
                label,
                style: AppTheme.bodySmall,
              ),
            ],
          ),
          Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSection(String bodyPartName, List<Map<String, dynamic>> exercises) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
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
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true, //
          maintainState: true,
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          title: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < AppTheme.mobileBreakpoint;

              return Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      isSmallScreen ? AppTheme.paddingSmall : AppTheme.paddingMedium,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRed.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getBodyPartIcon(bodyPartName),
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? AppTheme.paddingSmall : AppTheme.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bodyPartName,
                          style: isSmallScreen ? AppTheme.bodyMedium : AppTheme.headingSmall,
                        ),
                        if (!isSmallScreen) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${exercises.length} egzersiz',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? AppTheme.paddingSmall : AppTheme.paddingMedium,
                      vertical: AppTheme.paddingSmall / 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: Text(
                      '${exercises.length}',
                      style: (isSmallScreen ? AppTheme.bodySmall : AppTheme.bodyMedium)
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.borderRadiusLarge),
                  bottomRight: Radius.circular(AppTheme.borderRadiusLarge),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppTheme.paddingMedium),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: AppTheme.paddingSmall),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < AppTheme.mobileBreakpoint;

                        return Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.cardGradient,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            border: Border.all(
                              color: AppTheme.primaryRed.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseDetails(
                                  exerciseId: exercise['id'],
                                  userId: widget.userId,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                isSmallScreen ? AppTheme.paddingSmall : AppTheme.paddingMedium,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: isSmallScreen ? 32 : 40,
                                    height: isSmallScreen ? 32 : 40,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryRed.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: (isSmallScreen ? AppTheme.bodySmall : AppTheme.bodyMedium)
                                            .copyWith(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? AppTheme.paddingSmall : AppTheme.paddingMedium),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise['name'],
                                          style: isSmallScreen ? AppTheme.bodySmall : AppTheme.bodyMedium,
                                        ),
                                        if (!isSmallScreen) const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.repeat,
                                              size: isSmallScreen ? 14 : 16,
                                              color: AppTheme.primaryRed,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${exercise['defaultSets']} set',
                                              style: AppTheme.bodySmall,
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.fitness_center,
                                              size: isSmallScreen ? 14 : 16,
                                              color: AppTheme.primaryRed,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${exercise['defaultReps']} tekrar',
                                              style: AppTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppTheme.paddingSmall,
                                      vertical: AppTheme.paddingSmall / 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                                    ),
                                    child: Text(
                                      '${exercise['defaultWeight']} kg',
                                      style: (isSmallScreen ? AppTheme.bodySmall : AppTheme.bodyMedium)
                                          .copyWith(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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

  int _getTotalExerciseCount(Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart) {
    return exerciseListByBodyPart.values
        .fold(0, (sum, exercises) => sum + exercises.length);
  }

  Widget _buildProgressSection(Routines routine) {
    final progress = routine.userProgress ?? 0;
    final color = _getProgressColor(progress);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
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
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.paddingSmall),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: AppTheme.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'İlerleme',
                    style: AppTheme.headingSmall,
                  ),
                  SizedBox(height: AppTheme.paddingSmall),
                  Container(
                    height: AppTheme.progressBarHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppTheme.paddingMedium),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.paddingMedium,
                vertical: AppTheme.paddingSmall,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Text(
                '%$progress',
                style: AppTheme.headingSmall.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.paddingSmall),
      padding: EdgeInsets.symmetric(
        vertical: AppTheme.paddingSmall,
        horizontal: AppTheme.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: AppTheme.primaryRed,
              ),
              SizedBox(width: AppTheme.paddingSmall),
              Text(
                label,
                style: AppTheme.bodySmall,
              ),
            ],
          ),
          Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
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


}