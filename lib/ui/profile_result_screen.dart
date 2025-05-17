import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:logging/logging.dart';
import 'package:strength_within/ui/routine_ui/routine_card.dart';
import 'package:strength_within/ui/routine_ui/routine_detail.dart';
import '../ai_predictors/ai_bloc/ai_module.dart';
import '../blocs/data_bloc_routine/RoutineRepository.dart';
import '../blocs/data_bloc_routine/routines_bloc.dart';
import '../blocs/data_schedule_bloc/schedule_bloc.dart';
import '../blocs/data_schedule_bloc/schedule_repository.dart';
import '../main.dart';
import '../models/firebase_models/user_ai_profile.dart';
import '../models/sql_models/routines.dart';
import '../sw_app_theme/app_theme.dart';

class RoutineWithSuitability {
  final Routines routine;
  final String suitability;
  final int recommendedFrequency;
  final int minRestDays;
  RoutineWithSuitability({required this.routine, required this.suitability, required this.recommendedFrequency, required this.minRestDays});
}

Future<List<RoutineWithSuitability>> analyzeRoutineSuitability({
  required List<Routines> routines,
  required int userFrequency,
  required int userDifficulty,
  required RoutineRepository routineRepository,
}) async {
  List<RoutineWithSuitability> result = [];
  for (final routine in routines) {
    try {
      final freq = await routineRepository.getRoutineFrequency(routine.id);
      if (freq == null) continue;
      if (freq.minRestDays >= freq.recommendedFrequency) continue; // Mantıksız veri atlanır
      int freqDiff = (freq.recommendedFrequency - userFrequency).abs();
      int diffDiff = (routine.difficulty - userDifficulty).abs();
      String suitability;
      if (freqDiff == 0 && diffDiff == 0) {
        suitability = 'En Uygun';
      } else if (freqDiff <= 1 && diffDiff <= 1) {
        suitability = 'Kısmen Uygun';
      } else {
        suitability = 'Düşük Uygunluk';
      }
      result.add(RoutineWithSuitability(
        routine: routine,
        suitability: suitability,
        recommendedFrequency: freq.recommendedFrequency,
        minRestDays: freq.minRestDays,
      ));
    } catch (e) {
      // Hatalı veri/log atla
      continue;
    }
  }
  return result;
}

class ProfileResultBottomSheet extends StatefulWidget {
  final String userId;
  final UserAIProfile userProfile;
  final List<Routines> recommendedRoutines;
  final List<int> selectedDays;

  const ProfileResultBottomSheet({
    super.key,
    required this.userId,
    required this.userProfile,
    required this.recommendedRoutines,
    required this.selectedDays,
  });

  static Future<void> show(
      BuildContext context, {
        required String userId,
        required UserAIProfile userProfile,
        required List<Routines> recommendedRoutines,
        required RoutineRepository routineRepository,
        required ScheduleRepository scheduleRepository,
        required List<int> selectedDays,  // Yeni eklenen parametre
      }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider(
        create: (context) => RoutinesBloc(
          repository: routineRepository,
          scheduleRepository: scheduleRepository,
          userId: userId,
        ),
        child: ProfileResultBottomSheet(
          userId: userId,
          userProfile: userProfile,
          recommendedRoutines: recommendedRoutines,
          selectedDays: selectedDays,  // Parametre aktarımı
        ),
      ),
    );
  }


  @override
  State<ProfileResultBottomSheet> createState() => _ProfileResultBottomSheetState();
}

class _ProfileResultBottomSheetState extends State<ProfileResultBottomSheet>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;
  late RoutinesBloc _routinesBloc;
  late List<int> userSelectedDays = widget.selectedDays;

  @override
  void initState() {
    super.initState();
    _routinesBloc = context.read<RoutinesBloc>();
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);
    final routineRepository = context.read<RoutineRepository>();
    final userFrequency = widget.selectedDays.length;
    final userDifficulty = widget.recommendedRoutines.isNotEmpty ? widget.recommendedRoutines.first.difficulty : 3;
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.9,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryRed,
              backgroundColor: AppTheme.darkBackground,
              onRefresh: _refreshRoutines,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMetricsCard(context),
                          const SizedBox(height: 16),
                          Text('AI ve Seçimlerinize Göre Rutinler', style: AppTheme.headingMedium),
                          const SizedBox(height: 8),
                          _buildRoutineList('', widget.recommendedRoutines, size),
                          const SizedBox(height: 24),
                          Text('Seçtiğiniz gün ve zorluk için en uygun programlar:', style: AppTheme.headingMedium),
                          const SizedBox(height: 8),
                          FutureBuilder<List<RoutineWithSuitability>>(
                            future: analyzeRoutineSuitability(
                              routines: widget.recommendedRoutines,
                              userFrequency: userFrequency,
                              userDifficulty: userDifficulty,
                              routineRepository: routineRepository,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Bir hata oluştu: [31m[1m${snapshot.error}[0m',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Center(child: Text('Uygun program bulunamadı.'));
                              }
                              final routinesWithSuitability = snapshot.data!;
                              return _buildRoutineSuitabilityList(routinesWithSuitability, size);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshRoutines() async {
    if (!_routinesBloc.isClosed) {
      _routinesBloc.add(FetchRoutines());
    }
  }


  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Profil Sonuçları',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
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
    );
  }


  Future<List<Routines>> _filterRecommendedRoutinesByFrequency(List<Routines> routines, List<int> userSelectedDays) async {
    List<Routines> filteredRoutines = [];

    for (var routine in routines) {
      try {
        final frequencyInfo = await context.read<ScheduleRepository>().getFrequencyInfo(routine.id, 'routine');
        final int recommendedFrequency = frequencyInfo['recommendedFrequency'];
        final int minRestDays = frequencyInfo['minRestDays'];

        // Check if the number of selected days is within the recommended frequency
        if (userSelectedDays.length == recommendedFrequency) {
          // Sort the selected days
          userSelectedDays.sort();
          bool isValid = true;

          // Validate that the rest days between selected days meet the minimum requirement
          for (int i = 0; i < userSelectedDays.length - 1; i++) {
            if (userSelectedDays[i + 1] - userSelectedDays[i] < minRestDays) {
              isValid = false;
              break;
            }
          }

          // If valid, add routine to filtered list
          if (isValid) {
            filteredRoutines.add(routine);
          }
        }
      } catch (e) {
        // Log error if needed
      }
    }

    return filteredRoutines;
  }

  Widget _buildRoutineFilteredList(String title, List<Routines> filteredRoutines, Size size) {
    final limitedRoutines = filteredRoutines.take(2).toList();

    return Container(
      margin: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.paddingSmall,
              vertical: AppTheme.paddingSmall,
            ),
            child: Text(
              title,
              style: AppTheme.headingMedium,
            ),
          ),
          SizedBox(
            height: 320,
            child: PageView.builder(
              itemCount: limitedRoutines.length,
              controller: PageController(viewportFraction: 0.9),
              padEnds: true,
              itemBuilder: (context, index) {
                return Container(
                  width: 430,
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingSmall),
                  child: Center(
                    child: _buildRoutineCard(context, limitedRoutines[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> setMainRoutine(BuildContext context, Routines routine) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId);

      await userRef.update({
        'mainRoutineId': routine.id,
        'mainRoutineData': {
          'id': routine.id,
          'name': routine.name,
          'difficulty': routine.difficulty,
          'workoutTypeId': routine.workoutTypeId,
          'selectedDays': widget.selectedDays,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });

      // Haptic feedback
      HapticFeedback.mediumImpact();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ana programınız başarıyla güncellendi',
              style: AppTheme.bodySmall,
            ),
            backgroundColor: AppTheme.successGreen,
            duration: AppTheme.normalAnimation,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Program güncellenirken hata oluştu',
              style: AppTheme.bodySmall,
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }


  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildMetricsCard(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: const Icon(
                    Icons.monitor_weight_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Vücut Metrikleri',
                  style: AppTheme.headingSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricRow('BMI (Vücut Kitle İndeksi)', widget.userProfile.bmi!.toStringAsFixed(1), Icons.accessibility_new),
            _buildMetricRow('Vücut Yağ Oranı', '${widget.userProfile.bfp!.toStringAsFixed(1)}%', Icons.fitness_center),
            _buildMetricRow('Fitness Seviyesi', widget.userProfile.fitnessLevel.toString(), Icons.trending_up),
            _buildMetricRow('Haftalık Frekans', widget.selectedDays.length.toString(), Icons.calendar_view_week),

            const Divider(height: 24),
            _buildMetricRow('AI Güven Skoru', widget.userProfile.modelScores?['confidence'] != null
                ? '${(widget.userProfile.modelScores!['confidence']! * 100 - 4).toStringAsFixed(0)}%'
                : '0%', Icons.security),
          ],
        ),
      ),
    );
  }

  int calculateSuitabilityScore({
    required int routineFrequency,
    required int userFrequency,
    required int routineDifficulty,
    required int userDifficulty,
  }) {
    int freqDiff = (routineFrequency - userFrequency).abs();
    int diffDiff = (routineDifficulty - userDifficulty).abs();
    int score = 99 - (freqDiff * 20) - (diffDiff * 20);
    if (score < 1) score = 1;
    return score;
  }

  Widget _buildRoutineList(String title, List<Routines> routines, Size size) {
    final isWideScreen = size.width > AppTheme.tabletBreakpoint;
    final routineRepository = context.read<RoutineRepository>();
    final userFrequency = widget.selectedDays.length;
    final userDifficulty = routines.isNotEmpty ? routines.first.difficulty : 3;
    final routinesToShow = routines.take(10).toList();
    return FutureBuilder<List<int>>(
      future: Future.wait(routinesToShow.map((routine) async {
        try {
          final freq = await routineRepository.getRoutineFrequency(routine.id);
          if (freq == null) return 1;
          return calculateSuitabilityScore(
            routineFrequency: freq.recommendedFrequency,
            userFrequency: userFrequency,
            routineDifficulty: routine.difficulty,
            userDifficulty: userDifficulty,
          );
        } catch (e) {
          return 1;
        }
      })),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: isWideScreen ? 320 : 270,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final scores = snapshot.data!;
        final highScoreRoutines = <Routines>[];
        final highScores = <int>[];
        final lowScoreRoutines = <Routines>[];
        final lowScores = <int>[];
        for (int i = 0; i < routinesToShow.length; i++) {
          if (scores[i] >= 60) {
            highScoreRoutines.add(routinesToShow[i]);
            highScores.add(scores[i]);
          } else {
            lowScoreRoutines.add(routinesToShow[i]);
            lowScores.add(scores[i]);
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSmall,
                  vertical: AppTheme.paddingSmall,
                ),
                child: Text(
                  title,
                  style: isWideScreen ? AppTheme.headingMedium : AppTheme.headingSmall,
                ),
              ),
            if (highScoreRoutines.isNotEmpty)
              SizedBox(
                height: isWideScreen ? 320 : 270,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingSmall),
                  itemCount: highScoreRoutines.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: isWideScreen ? 300 : 250,
                      child: _buildRoutineCard(context, highScoreRoutines[index], suitabilityScore: highScores[index]),
                    );
                  },
                ),
              ),
            if (lowScoreRoutines.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSmall,
                  vertical: AppTheme.paddingSmall,
                ),
                child: Text(
                  'Diğer Programlar: İnceleyebilirsiniz',
                  style: isWideScreen ? AppTheme.headingMedium : AppTheme.headingSmall,
                ),
              ),
              SizedBox(
                height: isWideScreen ? 320 : 270,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingSmall),
                  itemCount: lowScoreRoutines.length,
                  itemBuilder: (context, index) {
                    // Sort by suitability score descending
                    final sorted = List.generate(lowScoreRoutines.length, (i) => MapEntry(lowScoreRoutines[i], lowScores[i]))
                      ..sort((a, b) => b.value.compareTo(a.value));
                    final routine = sorted[index].key;
                    return SizedBox(
                      width: isWideScreen ? 300 : 250,
                      child: _buildRoutineCard(context, routine), // No suitabilityScore chip
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }


  Widget _buildRoutineCard(BuildContext context, Routines routine, {int? suitabilityScore}) {
    return Stack(
      children: [
        Card(
          margin: EdgeInsets.all(AppTheme.paddingSmall),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Container(
            decoration: AppTheme.decoration(
              gradient: AppTheme.getPartGradient(
                difficulty: routine.difficulty,
                secondaryColor: AppTheme.primaryRed,
              ),
              borderRadius: AppTheme.getBorderRadius(
                  all: AppTheme.borderRadiusMedium
              ),
              shadows: [
                BoxShadow(
                  color: AppTheme.getDifficultyColor(routine.difficulty)
                      .withOpacity(AppTheme.shadowOpacity),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.cardBackground.withOpacity(0.9),
                    AppTheme.cardBackground.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              child: BlocProvider.value(
                value: context.read<RoutinesBloc>(),
                child: RoutineCard(
                  key: ValueKey(routine.id),
                  routine: routine,
                  userId: widget.userId,
                  onTap: () => _showRoutineDetailBottomSheet(context, routine.id),
                ),
              ),
            ),
          ),
        ),
        if (suitabilityScore != null)
          Positioned(
            top: 8,
            right: 16,
            child: Chip(
              label: Text('$suitabilityScore', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.blue.withOpacity(0.15),
              labelStyle: TextStyle(color: Colors.blue[800]),
            ),
          ),
      ],
    );
  }


  Future<void> _showRoutineDetailBottomSheet(BuildContext context, int routineId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: context.read<RoutinesBloc>(),
        child: RoutineDetailBottomSheet(
          routineId: routineId,
          userId: widget.userId,
        ),
      ),
    );
  }

  Widget _buildRoutineSuitabilityList(List<RoutineWithSuitability> routinesWithSuitability, Size size) {
    final isWideScreen = size.width > AppTheme.tabletBreakpoint;
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: SizedBox(
        height: isWideScreen ? 340 : 290,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingSmall),
          itemCount: routinesWithSuitability.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: isWideScreen ? 300 : 250,
              child: _buildRoutineSuitabilityCard(routinesWithSuitability[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoutineSuitabilityCard(RoutineWithSuitability rws) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: _buildRoutineCard(context, rws.routine),
        ),
        Positioned(
          top: 0,
          left: 12,
          child: Chip(
            label: Text(rws.suitability),
            backgroundColor: rws.suitability == 'En Uygun'
                ? Colors.green.withOpacity(0.2)
                : rws.suitability == 'Kısmen Uygun'
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
            labelStyle: TextStyle(
              color: rws.suitability == 'En Uygun'
                  ? Colors.green
                  : rws.suitability == 'Kısmen Uygun'
                      ? Colors.orange
                      : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
