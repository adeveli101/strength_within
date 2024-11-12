// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/root_controller.dart';
import 'package:workout/data_bloc_routine/routines_bloc.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/ui/routine_ui/routine_card.dart';

import '../../models/exercises.dart';
import '../../z.app_theme/app_theme.dart';
import '../exercises_ui/exercise_card.dart';
import '../exercises_ui/exercise_details.dart';

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


  @override
  void initState() {
    super.initState();
    _routinesBloc = context.read<RoutinesBloc>();
    _routinesBloc.add(FetchRoutineExercises(routineId: widget.routineId));
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) return;

        final state = _routinesBloc.state;
        if (state is RoutineExercisesLoaded) {
          _routinesBloc.add(FetchRoutines());
        }

        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
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
                BlocBuilder<RoutinesBloc, RoutinesState>(
                  buildWhen: (previous, current) {
                    return current is RoutinesLoading ||
                        current is RoutineExercisesLoaded ||
                        current is RoutinesError;
                  },
                  builder: (context, state) {
                    if (state is RoutinesLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppTheme.primaryRed),
                        ),
                      );
                    }

                    if (state is RoutineExercisesLoaded) {
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

                    if (state is RoutinesError) {
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
                        'Veriler yükleniyor...',
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
    );
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
          // Üst Bilgi Bölümü
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  routine.name,
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: AppTheme.paddingMedium),
                Row(
                  children: [
                    _buildStatItem(
                      Icons.fitness_center,
                      'Hedef',
                      routine.mainTargetedBodyPartId.toString(),
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
              ],
            ),
          ),

          // Açıklama Bölümü
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingMedium,
              vertical: AppTheme.paddingSmall,
            ),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              border: Border.all(
                color: AppTheme.primaryRed.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true, // İlk açılışta otomatik açık olması için
                maintainState: true, // İçeriği hafızada tutmak için
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.paddingSmall),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  'Rutin Açıklaması',
                  style: AppTheme.headingSmall,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(AppTheme.borderRadiusSmall),
                        bottomRight: Radius.circular(AppTheme.borderRadiusSmall),
                      ),
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
                        const SizedBox(height: AppTheme.paddingMedium),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppTheme.primaryRed,
                            ),
                            const SizedBox(width: AppTheme.paddingSmall),
                            Text(
                              'Son Güncelleme: ',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.primaryRed,
                              ),
                            ),
                            Text(
                              routine.lastUsedDate?.toString() ?? 'Henüz kullanılmadı',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // İlerleme Çubuğu
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingMedium,
              vertical: AppTheme.paddingSmall,
            ),
            height: AppTheme.progressBarHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              child: LinearProgressIndicator(
                value: (routine.userProgress ?? 0) / 100,
                backgroundColor: AppTheme.progressBarBackground,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(routine.userProgress ?? 0),
                ),
              ),
            ),
          ),

          // Egzersiz Başlığı
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.paddingMedium,
              AppTheme.paddingSmall,
              AppTheme.paddingMedium,
              AppTheme.paddingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Egzersizler',
                  style: AppTheme.headingSmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingMedium,
                    vertical: AppTheme.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Text(
                    '${_getTotalExerciseCount(exerciseListByBodyPart)} egzersiz',
                    style: AppTheme.bodySmall.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Egzersiz Listesi
          ...exerciseListByBodyPart.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.symmetric(
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
                    padding: const EdgeInsets.all(AppTheme.paddingSmall),
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
                    padding: const EdgeInsets.symmetric(
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
                      margin: const EdgeInsets.all(AppTheme.paddingSmall),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        border: Border.all(
                          color: AppTheme.primaryRed.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.paddingSmall,
                          vertical: AppTheme.paddingSmall,
                        ),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildExerciseInfo(
                                Icons.repeat,
                                '${exercise.value['defaultSets']} set',
                              ),
                              const SizedBox(width: AppTheme.paddingMedium),
                              _buildExerciseInfo(
                                Icons.fitness_center,
                                '${exercise.value['defaultReps']} tekrar',
                              ),
                              const SizedBox(width: AppTheme.paddingMedium),
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
          }),
          const SizedBox(height: AppTheme.paddingSmall),
        ],
      ),
    );
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
      padding: const EdgeInsets.all(AppTheme.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingSmall),
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
              const SizedBox(width: AppTheme.paddingMedium),
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
          _buildExerciseInfo(Icons.track_changes, 'Hedef: ${routine.mainTargetedBodyPartId}'),
          const SizedBox(height: AppTheme.paddingSmall),
          _buildExerciseInfo(Icons.category, 'Tip: ${routine.workoutTypeId}'),
        ],
      ),
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
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
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
                    padding: const EdgeInsets.all(AppTheme.paddingSmall),
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
                  const SizedBox(width: AppTheme.paddingMedium),
                  Text(
                    'İlerleme',
                    style: AppTheme.headingSmall,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
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
          const SizedBox(height: AppTheme.paddingMedium),
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
      padding: const EdgeInsets.symmetric(
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
              const SizedBox(width: AppTheme.paddingSmall),
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
      margin: const EdgeInsets.symmetric(
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
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
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
                                    padding: const EdgeInsets.symmetric(
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



  Widget _buildInfoSection(Routines routine) {
    return Container(
      margin: const EdgeInsets.symmetric(
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
        padding: const EdgeInsets.all(AppTheme.paddingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingSmall),
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
                const SizedBox(width: AppTheme.paddingMedium),
                Text(
                  'Rutin Bilgileri',
                  style: AppTheme.headingSmall,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            _buildInfoRow(Icons.fitness_center, 'Hedef Bölge', routine.mainTargetedBodyPartId.toString()),
            _buildInfoRow(Icons.category, 'Antrenman Tipi', routine.workoutTypeId.toString()),
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

  Widget _buildProgressSection(Routines routine) {
    final progress = routine.userProgress ?? 0;
    final color = _getProgressColor(progress);

    return Container(
      margin: const EdgeInsets.symmetric(
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
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingSmall),
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
            const SizedBox(width: AppTheme.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'İlerleme',
                    style: AppTheme.headingSmall,
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
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
            const SizedBox(width: AppTheme.paddingMedium),
            Container(
              padding: const EdgeInsets.symmetric(
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
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      padding: const EdgeInsets.symmetric(
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
              const SizedBox(width: AppTheme.paddingSmall),
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