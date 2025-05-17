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
import 'package:strength_within/generated/assets.dart';
import 'package:strength_within/sw_app_theme/app_theme.dart';
import 'package:strength_within/sw_app_theme/circular_logo.dart';
import 'package:strength_within/sw_app_theme/splash_screen.dart';
import 'package:strength_within/ui/ai_setup_page.dart';
import 'package:strength_within/ui/home_page.dart';
import 'package:strength_within/ui/for_you_page.dart';
import 'package:strength_within/ui/library.dart';
import 'package:strength_within/ui/list_pages/program_merger/program_merger_page.dart';
import 'package:strength_within/ui/test/recommend_page.dart';
import 'package:strength_within/ui/setting_pages.dart';
import 'package:strength_within/ui/userpprofilescreen.dart';
import 'package:provider/provider.dart';

import 'ai_predictors/ai_bloc/ai_module.dart';
import 'ai_predictors/ai_bloc/ai_repository.dart';
import 'ai_predictors/ai_bloc/exercisetype_classifier.dart';
import 'ai_predictors/exercise_plan_predictor.dart';
import 'ai_predictors/fitness_predictor.dart';
import 'blocs/data_bloc_part/PartRepository.dart';
import 'blocs/data_bloc_part/part_bloc.dart';
import 'blocs/data_bloc_routine/RoutineRepository.dart';
import 'blocs/data_bloc_routine/routines_bloc.dart';
import 'blocs/data_exercise_bloc/ExerciseRepository.dart';
import 'blocs/data_provider/firebase_provider.dart';
import 'blocs/data_provider/sql_provider.dart';
import 'blocs/data_schedule_bloc/schedule_bloc.dart';
import 'blocs/data_schedule_bloc/schedule_repository.dart';
import 'blocs/for_you_bloc.dart';
import 'firebase_options.dart';
import 'package:logging/logging.dart';

import 'models/firebase_models/user_ai_profile.dart';

final _logger = Logger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Firebase'i başlat
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized');
    } else {
      debugPrint('Firebase initialization error: $e');
      return; // Ciddi hata durumunda uygulamayı başlatma
    }
  }

  // 2) Anonim giriş yap
  final firebaseProvider = FirebaseProvider();
  String? userId;
  try {
    userId = await firebaseProvider.signInAnonymously();
  } catch (e) {
    _logger.severe('Anonim giriş sırasında hata oluştu: $e');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: Text('Giriş yapılamadı. Lütfen tekrar deneyin.')),
        ),
      ),
    );
    return; // Giriş yapılamadıysa uygulamaya devam etmeyelim
  }

  // 3) SplashScreen'e geç: onInitComplete tetiklendikten sonra asıl uygulamayı başlat
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(
        onInitComplete: (String? userId) async {
          if (userId != null) {
            try {
              // Singleton instance kullan
              final sqlProvider = SQLProvider();
              final firebaseProvider = FirebaseProvider();
              // Provider ve Repository'leri başlat
              final routineRepository = RoutineRepository(sqlProvider, firebaseProvider);
              final partRepository = PartRepository(sqlProvider, firebaseProvider);
              final exerciseRepository = ExerciseRepository(
                sqlProvider: sqlProvider,
                firebaseProvider: firebaseProvider,
              );
              final scheduleRepository = ScheduleRepository(firebaseProvider, sqlProvider);
              final aiModule = AIModule(
                sqlProvider: sqlProvider,
                firebaseProvider: firebaseProvider,
                fitnessPredictor: FitnessPredictor(),
                exercisePlanPredictor: ExercisePlanPredictor(),
                exerciseTypeClassifier: ExerciseTypeClassifier(routineRepository),
              );
              runApp(
                MultiRepositoryProvider(
                  providers: [
                    RepositoryProvider(create: (context) => sqlProvider),
                    RepositoryProvider(create: (context) => firebaseProvider),
                    RepositoryProvider(create: (context) => exerciseRepository),
                    RepositoryProvider(create: (context) => scheduleRepository),
                    RepositoryProvider(create: (context) => partRepository),
                    RepositoryProvider(create: (context) => routineRepository),
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
                      BlocProvider(
                        create: (context) => ScheduleBloc(
                          repository: scheduleRepository,
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
                    ],
                    child: App(userId: userId),
                  ),
                ),
              );
            } catch (e) {
              _logger.severe('Uygulama başlatma hatası: $e');
              runApp(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  home: Scaffold(
                    body: Center(child: Text('Uygulama başlatılamadı. Lütfen tekrar deneyin.')),
                  ),
                ),
              );
            }
          } else {
            _logger.severe('Anonim giriş başarısız oldu. (userId == null)');
            runApp(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  body: Center(child: Text('Giriş yapılamadı. Lütfen tekrar deneyin.')),
                ),
              ),
            );
          }
        },
      ),
    ),
  );
}





class App extends StatelessWidget {
  final String userId;

  const App({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Providers
    final sqlProvider = SQLProvider();
    final firebaseProvider = FirebaseProvider();

    // Repositories
    final routineRepository = RoutineRepository(sqlProvider, firebaseProvider);
    final partRepository = PartRepository(sqlProvider, firebaseProvider);
    final scheduleRepository = ScheduleRepository(firebaseProvider, sqlProvider);

    return MultiBlocProvider(
      providers: [
        BlocProvider<RoutinesBloc>(
          create: (context) => RoutinesBloc(
            repository: routineRepository,
            scheduleRepository: scheduleRepository,
            userId: userId,
          ),
        ),
        BlocProvider<PartsBloc>(
          create: (context) => PartsBloc(
            repository: partRepository,
            userId: userId,
            scheduleRepository: scheduleRepository,
          ),
        ),
      ],
      child: GetMaterialApp(
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(
                start: 0,
                end: AppTheme.mobileBreakpoint,
                name: MOBILE
            ),
            const Breakpoint(
                start: AppTheme.mobileBreakpoint + 1,
                end: AppTheme.tabletBreakpoint,
                name: TABLET
            ),
            const Breakpoint(
                start: AppTheme.tabletBreakpoint + 1,
                end: AppTheme.desktopBreakpoint,
                name: DESKTOP
            ),
            const Breakpoint(
                start: AppTheme.desktopBreakpoint + 1,
                end: double.infinity,
                name: '4K'
            ),
          ],
        ),
        title: 'Strength Within',
        theme: AppTheme.darkTheme,
        home: MainScreen(userId: userId),
      ),
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

  // Provider ve Repository'leri state olarak tutuyoruz
  late final SQLProvider _sqlProvider;
  late final FirebaseProvider _firebaseProvider;
  late final RoutineRepository _routineRepository;
  late final PartRepository _partRepository;
  late final ScheduleRepository _scheduleRepository;
  late final AIModule _aiModule;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDependencies();
  }

  void _initializeDependencies() {
    // Providers
    _sqlProvider = SQLProvider();
    _firebaseProvider = FirebaseProvider();

    // Repositories
    _routineRepository = RoutineRepository(_sqlProvider, _firebaseProvider);
    _partRepository = PartRepository(_sqlProvider, _firebaseProvider);
    _scheduleRepository = ScheduleRepository(_firebaseProvider, _sqlProvider);

    // AI Module
    _aiModule = AIModule(
      sqlProvider: _sqlProvider,
      firebaseProvider: _firebaseProvider,
      fitnessPredictor: FitnessPredictor(),
      exercisePlanPredictor: ExercisePlanPredictor(),
      exerciseTypeClassifier: ExerciseTypeClassifier(_routineRepository),
    );
  }

  @override
  void dispose() {

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshData() async {
    final routinesBloc = context.read<RoutinesBloc>();
    final partsBloc = context.read<PartsBloc>();

    if (!routinesBloc.isClosed) {
      routinesBloc.add(FetchRoutines());
    }
    if (!partsBloc.isClosed) {
      partsBloc.add(FetchParts());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<RoutinesBloc>()),
        BlocProvider.value(value: context.read<PartsBloc>()),
      ],
      child: WillPopScope(
        onWillPop: () async => true,
        child: Scaffold(
          backgroundColor: AppTheme.darkBackground,
          appBar: _buildAppBar(),
          body: _buildBody(),
          bottomNavigationBar: _buildBottomNav(),
        ),
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
            CircularLogo(
              size: 40,
              showBorder: true,
              onTap: _refreshData,
            ),
            SizedBox(width: AppTheme.paddingMedium),
            _buildAnimatedTitle(),
          ],
        ),
      ),
      actions: [
        _buildSettingsButton(),
        BlocBuilder<RoutinesBloc, RoutinesState>(
          builder: (context, state) {
            return IconButton(
              icon: Icon(Icons.add_chart),
              tooltip: 'Özel Program Oluştur',
              onPressed: () {
                if (state is! RoutinesLoading) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProgramMergerPage(
                        userId: widget.userId,
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
      ],
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsPage()),
          );
        },
      ),
    );
  }



  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        HomePage(userId: widget.userId),
        ForYouPage(userId: widget.userId),
        ChangeNotifierProvider(
          create: (_) => UserProfileFormModel(),
          child: UserProfileScreen(
            userId: widget.userId,
            aiModule: _aiModule,
          ),
        ),
        LibraryPage(
          userId: widget.userId,
          routineRepository: _routineRepository,
          scheduleRepository: _scheduleRepository,
          sqlProvider: _sqlProvider,
          firebaseProvider: _firebaseProvider,
        ),
      ],
    );
  }

  Widget _buildAnimatedTitle() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: _isHovered ? 1.08 : 1.0),
        duration: AppTheme.quickAnimation,
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF590000),
                  AppTheme.primaryRed,
                  const Color(0xFFB71C1C),
                  const Color(0xFF590000),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ).createShader(bounds),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Strength Within',
                    style: AppTheme.headingSmall.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      height: 1.0,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Strength Within',
                    style: AppTheme.headingSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      height: 1.0,
                      fontSize: 20,
                      shadows: [
                        Shadow(
                          color: AppTheme.primaryRed.withOpacity(0.8),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(-1, -1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
              if (!mounted) return;
              _refreshData();
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
                label: 'UserProfileAI',
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


  IconData _getBodyPartIcon(int bodyPartId) {
    switch (bodyPartId) {
      case 1: return Icons.fitness_center; // Göğüs
      case 2: return Icons.accessibility_new; // Sırt
      case 3: return Icons.directions_walk; // Bacak
      case 4: return Icons.sports_martial_arts; // Omuz
      case 5: return Icons.sports_handball; // Kol
      case 6: return Icons.circle; // Karın
      default: return Icons.fitness_center;
    }
  }
}

