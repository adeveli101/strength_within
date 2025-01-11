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

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                          const SizedBox(height: 16),
                          _buildRoutineList(
                            'Uyumlu Rutin Önerileri',
                            widget.recommendedRoutines,
                            MediaQuery.of(context).size,
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

  Widget _buildRoutineList(String title, List<Routines> routines, Size size) {
    final isWideScreen = size.width > AppTheme.tabletBreakpoint;

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
              style: isWideScreen ? AppTheme.headingMedium : AppTheme.headingSmall,
            ),
          ),
          SizedBox(
            height: isWideScreen ? 320 : 270,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingSmall),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: isWideScreen ? 300 : 250,
                  child: _buildRoutineCard(context, routines[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRoutineCard(BuildContext context, Routines routine) {
    return Card(
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
}
