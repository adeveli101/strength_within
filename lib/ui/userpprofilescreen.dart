// ignore_for_file: deprecated_member_use, unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:logging/logging.dart';
import 'package:strength_within/ui/profile_result_screen.dart';
import 'package:strength_within/ui/routine_ui/routine_card.dart';
import 'package:strength_within/ui/routine_ui/routine_detail.dart';
import '../ai_predictors/ai_bloc/ai_module.dart';
import '../blocs/data_bloc_routine/RoutineRepository.dart';
import '../blocs/data_bloc_routine/routines_bloc.dart';
import '../blocs/data_provider/firebase_provider.dart';
import '../blocs/data_schedule_bloc/schedule_bloc.dart';
import '../blocs/data_schedule_bloc/schedule_repository.dart';
import '../main.dart';
import '../models/firebase_models/user_ai_profile.dart';
import '../models/sql_models/routines.dart';
import '../sw_app_theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'profile_steps/weight_step.dart';
import 'profile_steps/height_step.dart';
import 'profile_steps/gender_step.dart';
import 'profile_steps/age_step.dart';
import 'profile_steps/training_days_step.dart';
import 'profile_steps/training_days_manual_step.dart';
import 'profile_steps/difficulty_step.dart';
import 'profile_steps/welcome_step.dart';

class UserProfileFormModel extends ChangeNotifier {
  double weight;
  double height;
  int gender;
  int age;
  List<int> selectedDays;
  int trainingFrequency;
  int startDay;
  String difficulty;
  int? recommendedFrequency;
  List<int>? goalIds;

  UserProfileFormModel({
    this.weight = 70,
    this.height = 170,
    this.gender = 0,
    this.age = 25,
    List<int>? selectedDays,
    this.trainingFrequency = 3,
    this.startDay = 1,
    this.difficulty = 'Orta',
    this.recommendedFrequency,
    this.goalIds,
  }) : selectedDays = selectedDays ?? [1, 3, 5];

  void setWeight(double value) {
    weight = value;
    notifyListeners();
  }

  void setHeight(double value) {
    height = value;
    notifyListeners();
  }

  void setGender(int value) {
    gender = value;
    notifyListeners();
  }

  void setAge(int value) {
    age = value;
    notifyListeners();
  }

  void setSelectedDays(List<int> days) {
    selectedDays = days;
    notifyListeners();
  }

  void setTrainingFrequency(int value) {
    trainingFrequency = value;
    notifyListeners();
  }

  void setStartDay(int value) {
    startDay = value;
    notifyListeners();
  }

  void setDifficulty(String value) {
    difficulty = value;
    notifyListeners();
  }

  void setRecommendedFrequency(int value) {
    recommendedFrequency = value;
    notifyListeners();
  }

  void setGoalIds(List<int> ids) {
    goalIds = List<int>.from(ids);
    notifyListeners();
  }

  void reset() {
    weight = 70;
    height = 170;
    gender = 0;
    age = 25;
    selectedDays = [1, 3, 5];
    trainingFrequency = 3;
    startDay = 1;
    difficulty = 'Orta';
    recommendedFrequency = null;
    goalIds = null;
    notifyListeners();
  }
}

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final AIModule aiModule;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.aiModule,
  });

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with AutomaticKeepAliveClientMixin {
  final _logger = Logger('UserProfileScreen');
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  bool _isLoading = false;
  int _currentPage = 0;

  final List<String> _trainingDayDescriptions = [
    "Haftada kaç gün antrenman yapmak istediğiniz, programınızın yoğunluğunu ve ilerleme hızınızı belirler.",
    "Diğer metriklerinizle beraber sizin için optimum yoğunluğa sahip programı bulmayı amaçlar.",
  ];
  final List<String> _metricDescriptions = [
    "Kilonuz, size özel egzersiz programınızın yoğunluğunu ve kalori hedeflerinizi belirlemede kritik rol oynar.",
    "Boyunuz, vücut kitle indeksinizi hesaplamak ve size en uygun egzersiz türlerini belirlemek için önemlidir.",
    "Cinsiyetiniz, metabolik hızınızı ve kas gelişim potansiyelinizi etkileyen önemli bir faktördür.",
    "Yaşınız, egzersiz programınızın yoğunluğunu ve dinlenme sürelerini optimize etmemize yardımcı olur."
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final steps = [
      'Hoşgeldiniz',
      'Kilo',
      'Boy',
      'Cinsiyet',
      'Yaş',
      'Antrenman Günleri',
      'Zorluk',
      'Günleri Düzenle',
      'Özet',
    ];
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.darkBackground,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildStepper(steps),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryRed),
                  SizedBox(height: AppTheme.paddingLarge),
                  Text('Metrikleriniz hesaplanıyor...', style: AppTheme.bodyLarge.copyWith(color: Colors.white)),
                  SizedBox(height: AppTheme.paddingSmall),
                  Text('Size en uygun rutinler belirleniyor', style: AppTheme.bodySmall.copyWith(color: Colors.white70)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text('Profil Oluştur', style: AppTheme.headingMedium),
      leading: _currentPage > 0
          ? IconButton(
        icon: Icon(Icons.arrow_back, color: AppTheme.primaryRed),
        onPressed: () => _pageController.previousPage(
          duration: AppTheme.normalAnimation,
          curve: Curves.easeInOut,
        ),
      )
          : null,
    );
  }

  Widget _buildStepper(List<String> steps) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryRed),
            tooltip: 'Baştan başla',
            onPressed: () {
              Provider.of<UserProfileFormModel>(context, listen: false).reset();
              setState(() => _currentPage = 0);
              _pageController.jumpToPage(0);
            },
          ),
          Expanded(
            child: Row(
              children: List.generate(steps.length, (i) {
                final isActive = i == _currentPage;
                final isCompleted = i < _currentPage;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (i <= _currentPage) {
                        setState(() => _currentPage = i);
                        _pageController.jumpToPage(i);
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 12,
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primaryRed
                                : isCompleted
                                    ? AppTheme.primaryGreen
                                    : Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        SizedBox(height: 6),
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: isActive
                              ? AppTheme.primaryRed
                              : isCompleted
                                  ? AppTheme.primaryGreen
                                  : Colors.white24,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<UserProfileFormModel>(
      builder: (context, model, child) {
        return PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (page) => setState(() => _currentPage = page),
          children: [
            WelcomeStep(
              onNext: () => _pageController.nextPage(duration: AppTheme.normalAnimation, curve: Curves.easeInOut),
            ),
            WeightStep(
              model: model,
              description: _metricDescriptions[0],
              onNext: () => _pageController.nextPage(duration: AppTheme.normalAnimation, curve: Curves.easeInOut),
            ),
            HeightStep(
              model: model,
              description: _metricDescriptions[1],
              onNext: () => _pageController.nextPage(duration: AppTheme.normalAnimation, curve: Curves.easeInOut),
            ),
            GenderStep(
              model: model,
              description: _metricDescriptions[2],
              onNext: () => _pageController.nextPage(duration: AppTheme.normalAnimation, curve: Curves.easeInOut),
            ),
            AgeStep(
              model: model,
              description: _metricDescriptions[3],
              onNext: () => _pageController.nextPage(duration: AppTheme.normalAnimation, curve: Curves.easeInOut),
            ),
            DifficultyStep(
              model: model,
              onNext: () => _pageController.nextPage(duration: AppTheme.normalAnimation, curve: Curves.easeInOut),
            ),
            TrainingDaysStep(
              model: model,
              description: _trainingDayDescriptions[0],
              onNext: () => _pageController.nextPage(duration: AppTheme.normalAnimation, curve: Curves.easeInOut),
            ),
            TrainingDaysManualStep(
              model: model,
              onNext: () => _pageController.nextPage(duration: AppTheme.normalAnimation, curve: Curves.easeInOut),
            ),
            _buildSummaryPage(model),
          ],
        );
      },
    );
  }

  Widget _buildMetricPage({
    required String title,
    required String description,
    required Widget input,
    required bool isLastPage,
  }) {
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
          Text(
            description,
            style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
          ),
          Expanded(child: Center(child: input)),
          _buildNavigationButton(isLastPage),
        ],
      ),
    );
  }

  Widget _buildWeightPage(UserProfileFormModel model) {
    return _buildMetricPage(
      title: 'Kilonuz',
      description: _metricDescriptions[0],
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${model.weight.round()} kg',
            style: AppTheme.headingLarge,
          ),
          Slider(
            value: model.weight,
            min: 30,
            max: 250,
            divisions: 220,
            activeColor: AppTheme.primaryRed,
            inactiveColor: AppTheme.primaryRed.withOpacity(0.3),
            onChanged: (value) => model.setWeight(value),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightPage(UserProfileFormModel model) {
    return _buildMetricPage(
      title: 'Boyunuz',
      description: _metricDescriptions[1],
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${model.height.round()} cm',
            style: AppTheme.headingLarge,
          ),
          Slider(
            value: model.height,
            min: 120,
            max: 220,
            divisions: 100,
            activeColor: AppTheme.primaryRed,
            inactiveColor: AppTheme.primaryRed.withOpacity(0.3),
            onChanged: (value) => model.setHeight(value),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPage(UserProfileFormModel model) {
    return _buildMetricPage(
      title: 'Cinsiyetiniz',
      description: _metricDescriptions[2],
      isLastPage: false,
      input: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGenderButton(model, 0, Icons.male, 'Erkek'),
          SizedBox(width: AppTheme.paddingLarge),
          _buildGenderButton(model, 1, Icons.female, 'Kadın'),
        ],
      ),
    );
  }

  Widget _buildGenderButton(UserProfileFormModel model, int value, IconData icon, String label) {
    final isSelected = model.gender == value;
    return GestureDetector(
      onTap: () => model.setGender(value),
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

  Widget _buildAgePage(UserProfileFormModel model) {
    return _buildMetricPage(
      title: 'Yaşınız',
      description: _metricDescriptions[3],
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${model.age}',
            style: AppTheme.headingLarge,
          ),
          Slider(
            value: model.age.toDouble(),
            min: 15,
            max: 90,
            divisions: 75,
            activeColor: AppTheme.primaryRed,
            inactiveColor: AppTheme.primaryRed.withOpacity(0.3),
            onChanged: (value) => model.setAge(value.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingDaysPage(UserProfileFormModel model) {
    return _buildMetricPage(
      title: 'Antrenman Günleri',
      description: _trainingDayDescriptions[0],
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${model.selectedDays.length} gün',
            style: AppTheme.headingLarge,
          ),
          SizedBox(height: AppTheme.paddingMedium),
          Wrap(
            spacing: AppTheme.paddingSmall,
            children: [
              _buildDayCheckbox(model, 'Pzt', 1),
              _buildDayCheckbox(model, 'Sal', 2),
              _buildDayCheckbox(model, 'Çar', 3),
              _buildDayCheckbox(model, 'Per', 4),
              _buildDayCheckbox(model, 'Cum', 5),
              _buildDayCheckbox(model, 'Cmt', 6),
              _buildDayCheckbox(model, 'Paz', 7),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCheckbox(UserProfileFormModel model, String label, int day) {
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

  List<int> getSelectedDays(UserProfileFormModel model) {
    return List<int>.from(model.selectedDays);
  }

  Widget _buildSummaryPage(UserProfileFormModel model) {
    return _buildMetricPage(
      title: 'Profil Özeti',
      description: 'Bilgilerinizi kontrol edin ve profilinizi oluşturun.',
      isLastPage: true,
      input: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSummaryItem(Icons.monitor_weight, 'Kilo', '${model.weight.round()} kg'),
          _buildSummaryItem(Icons.height, 'Boy', '${model.height.round()} cm'),
          _buildSummaryItem(
              model.gender == 0 ? Icons.male : Icons.female,
              'Cinsiyet',
              model.gender == 0 ? 'Erkek' : 'Kadın'
          ),
          _buildSummaryItem(Icons.calendar_today, 'Yaş', '${model.age}'),
          _buildSummaryItem(
              Icons.fitness_center,
              'Antrenman',
              '${model.selectedDays.length} gün'
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
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

  Widget _buildNavigationButton(bool isLastPage) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isLastPage ? AppTheme.primaryGreen : AppTheme.primaryRed,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
      ),
      onPressed: isLastPage ? _createProfile : () {
        _pageController.nextPage(
          duration: AppTheme.normalAnimation,
          curve: Curves.easeInOut,
        );
      },
      child: Text(
        isLastPage ? 'Profil Oluştur' : 'Devam Et',
        style: AppTheme.bodyLarge,
      ),
    );
  }

  Future<void> _createProfile() async {
    final model = Provider.of<UserProfileFormModel>(context, listen: false);
    if (_isLoading) return; // Prevent multiple submissions
    _logger.info('START: _createProfile for user: [32m${widget.userId}[0m');

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      _logger.info('Step 1: Validation starting...');
      final validation = widget.aiModule.validateUserInputs(
        weight: model.weight,
        height: model.height,
        gender: model.gender,
        age: model.age,
      );
      _logger.info('Step 1: Validation finished. isValid=[32m${validation.isValid}[0m');

      if (!validation.isValid) {
        _logger.warning('Input validation failed: [31m${validation.message}[0m');
        setState(() => _isLoading = false);
        final retry = await _showErrorDialog(validation.message, retryCallback: _createProfile);
        if (retry == true) return;
        return;
      }

      _logger.info('Step 2: Creating user profile...');
      final userProfile = await widget.aiModule.createUserProfile(
        userId: widget.userId,
        weight: model.weight,
        height: model.height,
        gender: model.gender,
        age: model.age,
      );
      _logger.info('Step 2: User profile created.');

      _logger.info('Step 3: Getting recommended routine IDs from AI...');
      final recommendedRoutineIds = await widget.aiModule.getRecommendedRoutines(
        weight: model.weight,
        height: model.height,
        gender: model.gender,
        age: model.age,
      );
      _logger.info('Step 3: Got recommended routine IDs: $recommendedRoutineIds');

      final routineRepository = context.read<RoutineRepository>();
      final allRoutines = await routineRepository.getAllRoutines();
      _logger.info('AI routine IDs: $recommendedRoutineIds');
      _logger.info('All routine IDs: [36m${allRoutines.map((r) => r.id).toList()}[0m');
      final aiRoutines = allRoutines.where((r) =>
        recommendedRoutineIds.contains(r.id) ||
        // ignore: collection_methods_unrelated_type
        recommendedRoutineIds.contains(r.id.toString())
      ).toList();
      if (aiRoutines.isEmpty) {
        _logger.warning('AI routine IDs did not match any routines. Fallback: showing all routines.');
        aiRoutines.addAll(allRoutines.take(5));
      }
      int difficultyInt = int.tryParse(model.difficulty) ?? 3;
      if (difficultyInt < 1 || difficultyInt > 5) difficultyInt = 3;

      // Zorluk filtresi uygula (±1 tolerans)
      var filteredRoutines = aiRoutines.where((r) => (r.difficulty - difficultyInt).abs() <= 1).toList();
      if (filteredRoutines.isEmpty) {
        filteredRoutines.addAll(aiRoutines);
      }
      // Yüksek uyumluluk/puanlama sıralaması (örnek: score varsa)
      // filteredRoutines.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
      // En yüksek puanlı ilk 5 rutin ID'sini al
      final topRoutineIds = filteredRoutines.take(5).map((r) => r.id.toString()).toList();
      _logger.info('Step 4.1: Top recommended routine IDs: $topRoutineIds');

      // Profil objesini recommendedRoutineIds ile oluştur
      final userProfileWithRecommendedRoutineIds = UserAIProfile(
        userId: widget.userId,
        bmi: null, // AI'dan gelen değerle doldurulabilir
        bfp: null, // AI'dan gelen değerle doldurulabilir
        fitnessLevel: 3, // AI'dan gelen değerle doldurulabilir
        modelScores: null, // AI'dan gelen değerle doldurulabilir
        recommendedRoutineIds: topRoutineIds,
        lastUpdateTime: DateTime.now(),
        metrics: AIMetrics.initial(),
        weight: model.weight,
        height: model.height,
        gender: model.gender,
        goal: 1, // AI'dan gelen değerle doldurulabilir
      );
      // Firestore'a kaydet
      await FirebaseProvider().addUserPrediction(widget.userId, userProfileWithRecommendedRoutineIds.toFirestore());
      _logger.info('Step 4.2: User profile with recommendedRoutineIds saved to Firestore.');

      _logger.info('Step 5: Showing ProfileResultBottomSheet...');
      await ProfileResultBottomSheet.show(
        context,
        userId: widget.userId,
        userProfile: userProfileWithRecommendedRoutineIds,
        recommendedRoutines: filteredRoutines,
        routineRepository: routineRepository,
        scheduleRepository: context.read<ScheduleRepository>(),
        selectedDays: model.selectedDays,
      );
      _logger.info('Step 5: ProfileResultBottomSheet closed.');

    } catch (e, stackTrace) {
      _logger.severe(
          'Profile creation failed. Error: $e\n'
              'Stack trace: $stackTrace\n'
              'Values - Weight: ${model.weight} (${model.weight.runtimeType}), '
              'Height: ${model.height} (${model.height.runtimeType})'
      );
      if (mounted) {
        setState(() => _isLoading = false);
        final retry = await _showErrorDialog('Profil oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.\n\nHata: $e', retryCallback: _createProfile);
        if (retry == true) return;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _logger.info('Profile creation process finished.');
      }
    }
  }

  Future<bool?> _showErrorDialog(String message, {VoidCallback? retryCallback}) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Hata', style: TextStyle(color: AppTheme.primaryRed)),
        content: Text(message, style: TextStyle(color: Colors.white)),
        actions: [
          if (retryCallback != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                retryCallback();
              },
              child: Text('Tekrar Dene', style: TextStyle(color: AppTheme.primaryGreen)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Kapat', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );
  }
}






