// ignore_for_file: deprecated_member_use, unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:logging/logging.dart';
import 'package:strength_within/ui/profile_result_screen.dart';
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

  // Form değerleri
  double _weight = 70;
  double _height = 170;
  int _gender = 0;
  int _age = 25;

  List<int> userSelectedDays = [1, 3, 5, 7];
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
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildAppBar(),
      body: _buildBody(),
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

  Widget _buildBody() {
    return Column(
      children: [
        _buildProgressIndicator(),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: [
              _buildWeightPage(),
              _buildHeightPage(),
              _buildGenderPage(),
              _buildAgePage(),
              _buildTrainingDaysPage(),
              _buildSummaryPage(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / 5,
            backgroundColor: AppTheme.surfaceColor,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
          ),
          SizedBox(height: AppTheme.paddingSmall),
          Text(
            '${_currentPage + 1}/5',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
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

  Widget _buildWeightPage() {
    return _buildMetricPage(
      title: 'Kilonuz',
      description: _metricDescriptions[0],
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_weight.round()} kg',
            style: AppTheme.headingLarge,
          ),
          Slider(
            value: _weight,
            min: 30,
            max: 250,
            divisions: 220,
            activeColor: AppTheme.primaryRed,
            inactiveColor: AppTheme.primaryRed.withOpacity(0.3),
            onChanged: (value) => setState(() => _weight = value),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightPage() {
    return _buildMetricPage(
      title: 'Boyunuz',
      description: _metricDescriptions[1],
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_height.round()} cm',
            style: AppTheme.headingLarge,
          ),
          Slider(
            value: _height,
            min: 120,
            max: 220,
            divisions: 100,
            activeColor: AppTheme.primaryRed,
            inactiveColor: AppTheme.primaryRed.withOpacity(0.3),
            onChanged: (value) => setState(() => _height = value),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPage() {
    return _buildMetricPage(
      title: 'Cinsiyetiniz',
      description: _metricDescriptions[2],
      isLastPage: false,
      input: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGenderButton(0, Icons.male, 'Erkek'),
          SizedBox(width: AppTheme.paddingLarge),
          _buildGenderButton(1, Icons.female, 'Kadın'),
        ],
      ),
    );
  }

  Widget _buildGenderButton(int value, IconData icon, String label) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
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

  Widget _buildAgePage() {
    return _buildMetricPage(
      title: 'Yaşınız',
      description: _metricDescriptions[3],
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_age',
            style: AppTheme.headingLarge,
          ),
          Slider(
            value: _age.toDouble(),
            min: 15,
            max: 90,
            divisions: 75,
            activeColor: AppTheme.primaryRed,
            inactiveColor: AppTheme.primaryRed.withOpacity(0.3),
            onChanged: (value) => setState(() => _age = value.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingDaysPage() {
    return _buildMetricPage(
      title: 'Antrenman Günleri',
      description: _trainingDayDescriptions[0],
      isLastPage: false,
      input: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${userSelectedDays.length} gün',
            style: AppTheme.headingLarge,
          ),
          SizedBox(height: AppTheme.paddingMedium),
          Wrap(
            spacing: AppTheme.paddingSmall,
            children: [
              _buildDayCheckbox('Pzt', 1),
              _buildDayCheckbox('Sal', 2),
              _buildDayCheckbox('Çar', 3),
              _buildDayCheckbox('Per', 4),
              _buildDayCheckbox('Cum', 5),
              _buildDayCheckbox('Cmt', 6),
              _buildDayCheckbox('Paz', 7),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCheckbox(String label, int day) {
    final isSelected = userSelectedDays.contains(day);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            if (userSelectedDays.length < 6) {
              userSelectedDays.add(day);
            }
          } else {
            if (userSelectedDays.length > 2) {
              userSelectedDays.remove(day);
            }
          }
          userSelectedDays.sort();
        });
      },
      backgroundColor: AppTheme.surfaceColor,
      selectedColor: AppTheme.primaryRed,
      checkmarkColor: Colors.white,
    );
  }

  List<int> getSelectedDays() {
    return List<int>.from(userSelectedDays);
  }


  Widget _buildSummaryPage() {
    return _buildMetricPage(
      title: 'Profil Özeti',
      description: 'Bilgilerinizi kontrol edin ve profilinizi oluşturun.',
      isLastPage: true,
      input: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSummaryItem(Icons.monitor_weight, 'Kilo', '${_weight.round()} kg'),
          _buildSummaryItem(Icons.height, 'Boy', '${_height.round()} cm'),
          _buildSummaryItem(
              _gender == 0 ? Icons.male : Icons.female,
              'Cinsiyet',
              _gender == 0 ? 'Erkek' : 'Kadın'
          ),
          _buildSummaryItem(Icons.calendar_today, 'Yaş', '$_age'),
          _buildSummaryItem(
              Icons.fitness_center,
              'Antrenman',
              '${userSelectedDays.length} gün'
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
    _logger.info('Starting profile creation for user: ${widget.userId}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingDialog(),
    );
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // Input validation
      final validation = widget.aiModule.validateUserInputs(
        weight: _weight,
        height: _height,
        gender: _gender,
        age: _age,
      );

      if (!validation.isValid) {
        _logger.warning('Input validation failed: ${validation.message}');
        Navigator.pop(context); // Close loading dialog
        return;
      }

      // Create user profile
      final userProfile = await widget.aiModule.createUserProfile(
        userId: widget.userId,
        weight: _weight,
        height: _height,
        gender: _gender,
        age: _age,
      );

      // Get recommended routine IDs
      final recommendedRoutineIds = await widget.aiModule.getRecommendedRoutines(
        weight: _weight,
        height: _height,
        gender: _gender,
        age: _age,
      );

      // Fetch routine details by IDs
      final recommendedRoutines = await widget.aiModule.getRoutinesByIds(recommendedRoutineIds);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog before showing bottom sheet
        await ProfileResultBottomSheet.show(
          context,
          userId: widget.userId,
          userProfile: userProfile,
          recommendedRoutines: recommendedRoutines,
          routineRepository: context.read<RoutineRepository>(),
          scheduleRepository: context.read<ScheduleRepository>(),
          selectedDays: userSelectedDays,
        );
      }

    } catch (e, stackTrace) {
      _logger.severe(
          'Profile creation failed. Error: $e\n'
              'Stack trace: $stackTrace\n'
              'Values - Weight: $_weight (${_weight.runtimeType}), '
              'Height: $_height (${_height.runtimeType})'
      );
      if (mounted) {
        Navigator.pop(context); // Close loading dialog on error
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLoadingDialog() {
    return Dialog(
      backgroundColor: AppTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryRed),
            SizedBox(height: AppTheme.paddingMedium),
            Text(
              'Metrikleriniz hesaplanıyor...',
              style: AppTheme.bodyMedium,
            ),
            SizedBox(height: AppTheme.paddingSmall),
            Text(
              'Size en uygun rutinler belirleniyor',
              style: AppTheme.bodySmall.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );

  }
}






