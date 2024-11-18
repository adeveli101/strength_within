// ignore_for_file: deprecated_member_use, use_super_parameters
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:workout/generated/assets.dart';
import 'package:workout/ui/home_page.dart';
import 'package:workout/ui/for_you_page.dart';
import 'package:workout/data_provider/firebase_provider.dart';
import 'package:workout/data_provider/sql_provider.dart';
import 'package:workout/ui/library.dart';
import 'package:workout/ui/list_pages/custom_page.dart';
import 'package:workout/ui/setting_pages.dart';
import 'package:workout/z.app_theme/app_theme.dart';
import 'package:workout/z.app_theme/circular_logo.dart';
import 'ai_services/ai_bloc/ai_bloc.dart';
import 'blocs/for_you_bloc.dart';
import 'data_bloc_part/PartRepository.dart';
import 'data_bloc_part/part_bloc.dart';
import 'data_bloc_routine/RoutineRepository.dart';
import 'data_bloc_routine/routines_bloc.dart';
import 'data_exercise_bloc/ExerciseRepository.dart';
import 'data_schedule_bloc/schedule_bloc.dart';
import 'data_schedule_bloc/schedule_repository.dart';
import 'firebase_options.dart';
import 'package:logging/logging.dart';

final _logger = Logger('Main');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlatma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // Providers
  final sqlProvider = SQLProvider();
  await sqlProvider.initDatabase();
  final firebaseProvider = FirebaseProvider();

  // Repositories
  final routineRepository = RoutineRepository(sqlProvider, firebaseProvider);
  final partRepository = PartRepository(sqlProvider, firebaseProvider);
  final exerciseRepository = ExerciseRepository(
    sqlProvider: sqlProvider,
    firebaseProvider: firebaseProvider,
  );
  final scheduleRepository = ScheduleRepository(firebaseProvider, sqlProvider);
  // Anonim giriş
  String? userId = await firebaseProvider.signInAnonymously();

  if (userId != null) {
    runApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SQLProvider>(
            create: (context) => sqlProvider,
          ),
          RepositoryProvider<FirebaseProvider>(
            create: (context) => firebaseProvider,
          ),
          RepositoryProvider<ExerciseRepository>(
            create: (context) => exerciseRepository,
          ),
          RepositoryProvider<ScheduleRepository>(
            create: (context) => scheduleRepository,
          ),
          RepositoryProvider<PartRepository>(
            create: (context) => partRepository,
          ),
          RepositoryProvider<RoutineRepository>(
            create: (context) => routineRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => RoutinesBloc(
                repository: routineRepository,
                scheduleRepository: scheduleRepository,
                userId: userId,
              ),
            ),
            BlocProvider(
              create: (context) => PartsBloc(
                repository: partRepository,
                scheduleRepository: scheduleRepository,
                userId: userId,
              )..add(FetchParts()),
            ),
            // main.dart içinde

            BlocProvider(
              create: (context) => ScheduleBloc(
                repository: scheduleRepository, // scheduleRepository yerine repository
                userId: userId,
              ),
            ),
            BlocProvider(
              create: (context) => ForYouBloc(
                partRepository: partRepository,
                routineRepository: routineRepository,
                scheduleRepository: scheduleRepository,
                userId: userId,
              ),
            ),
            BlocProvider(
              create: (context) => AIBloc(),
            ),
          ],
          child: App(userId: userId),
        ),
      ),
    );
  } else {
    _logger.severe('Anonim giriş başarısız oldu.');
    // Hata durumunda basit bir hata ekranı göster
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Giriş yapılamadı. Lütfen tekrar deneyin.'),
          ),
        ),
      ),
    );
  }
}

class App extends StatelessWidget {
  final String userId;

  const App({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      title: 'Fitness App',
      theme: AppTheme.darkTheme, // custom theme
      home: MainScreen(userId: userId),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String userId;
  const MainScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future _refreshData() async {
    final routinesBloc = context.read<RoutinesBloc>();
    final partsBloc = context.read<PartsBloc>();
    routinesBloc.add(FetchRoutines());
    partsBloc.add(FetchParts());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: GestureDetector(
        onTap: _refreshData,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            CircularLogo(
              size: 40,
              showBorder: true,
              onTap: _refreshData,
            ),
            SizedBox(width: AppTheme.paddingMedium),

            // App Title
            _buildAnimatedTitle(),
          ],
        ),
      ),
      actions: [
        _buildSettingsButton(),
        IconButton(
          icon: Icon(Icons.add_chart),
          tooltip: 'Özel Program Oluştur',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => PartsBloc(
                    repository: PartRepository(
                      context.read<SQLProvider>(),
                      context.read<FirebaseProvider>(),
                    ),
                    userId: widget.userId,
                    scheduleRepository: context.read<ScheduleRepository>(),
                  ),
                  child: CustomProgramPage(),
                ),
              ),
            );
          },
        ),
      ],

    );
  }

  Widget _buildAnimatedTitle() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: _isHovered ? 1.05 : 1.0),
        duration: AppTheme.quickAnimation,
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00B4D8),
                  const Color(0xFF0077B6),
                  const Color(0xFFFF4D6D),
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: Text(
                'Workout App',
                style: AppTheme.headingSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF00B4D8).withOpacity(0.3),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsButton() {
    return Container(
      margin: EdgeInsets.only(right: AppTheme.paddingSmall),
      child: IconButton(
        icon: Icon(
          Icons.settings_outlined,
          color: AppTheme.primaryRed.withOpacity(0.5),
        ),
        onPressed: () => _showSettingsSheet(),
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SettingsPage(),
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.borderRadiusLarge),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Providers
    final sqlProvider = SQLProvider();
    final firebaseProvider = FirebaseProvider();

    // Repositories
    final routineRepository = RoutineRepository(sqlProvider, firebaseProvider);
    final partRepository = PartRepository(sqlProvider, firebaseProvider);
    final scheduleRepository = ScheduleRepository(firebaseProvider, sqlProvider);

    return IndexedStack(
      index: _currentIndex,
      children: [
        HomePage(userId: widget.userId),
        ForYouPage(userId: widget.userId),
        LibraryPage(
          userId: widget.userId,
          routineRepository: routineRepository,
          partRepository: partRepository,
          scheduleRepository: scheduleRepository, // Eklendi
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceColor.withOpacity(0.95),
            AppTheme.darkBackground.withOpacity(0.98),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryRed.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
              _refreshData();
              // Haptic feedback ekleyelim
              HapticFeedback.lightImpact();
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppTheme.primaryRed,
            unselectedItemColor: Colors.grey.withOpacity(0.7),
            selectedLabelStyle: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.normal,
            ),
            items: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Ana Sayfa',
              ),
              _buildNavItem(
                icon: Icons.recommend_outlined,
                activeIcon: Icons.recommend_rounded,
                label: 'Senin İçin',
              ),
              _buildNavItem(
                icon: Icons.library_books_outlined,
                activeIcon: Icons.library_books_rounded,
                label: 'Kütüphane',
              ),
            ],
            type: BottomNavigationBarType.fixed,
            selectedIconTheme: IconThemeData(
              size: 28,
              shadows: [
                Shadow(
                  color: AppTheme.primaryRed.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            unselectedIconTheme: const IconThemeData(
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: AppTheme.quickAnimation,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Icon(icon),
          );
        },
      ),
      activeIcon: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.1),
        duration: AppTheme.quickAnimation,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Icon(activeIcon),
          );
        },
      ),
      label: label,
    );
  }

}
