// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:workout/ui/home_page.dart';
import 'package:workout/ui/for_you_page.dart';
import 'package:workout/data_provider/firebase_provider.dart';
import 'package:workout/data_provider/sql_provider.dart';
import 'package:workout/ui/library.dart';
import 'package:workout/ui/setting_pages.dart';
import 'ai_services/ai_bloc/ai_bloc.dart';
import 'blocs/for_you_bloc.dart';
import 'data_bloc_part/PartRepository.dart';
import 'data_bloc_part/part_bloc.dart';
import 'data_bloc_routine/RoutineRepository.dart';
import 'data_bloc_routine/routines_bloc.dart';
import 'data_exercise_bloc/ExerciseRepository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  final sqlProvider = SQLProvider();
  await sqlProvider.initDatabase();
  final firebaseProvider = FirebaseProvider(sqlProvider);

  // Repository'leri oluştur
  final routineRepository = RoutineRepository(sqlProvider, firebaseProvider);
  final partRepository = PartRepository(sqlProvider, firebaseProvider);
  final exerciseRepository = ExerciseRepository(sqlProvider: sqlProvider, firebaseProvider: firebaseProvider);

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
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => RoutinesBloc(
                repository: routineRepository,
                userId: userId,
              ),
            ),
            BlocProvider(
              create: (context) => PartsBloc(
                repository: partRepository,
                userId: userId,
              )..add(FetchParts()),
            ),
            BlocProvider(
              create: (context) => ForYouBloc(
                partRepository: partRepository,
                routineRepository: routineRepository,
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
    print('Anonim giriş başarısız oldu.');
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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0.3,
          shape: Border.symmetric(),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF282828),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      ),
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
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
        appBar: AppBar(
          title: ResponsiveRowColumn(
            rowMainAxisAlignment: MainAxisAlignment.start,
            layout: ResponsiveBreakpoints.of(context).smallerThan(TABLET)
                ? ResponsiveRowColumnType.COLUMN
                : ResponsiveRowColumnType.ROW,
            children: [
              ResponsiveRowColumnItem(
                child: Icon(Icons.sports_score_rounded, color: Colors.red),
              ),
              ResponsiveRowColumnItem(
                child: SizedBox(width: 10),
              ),
              ResponsiveRowColumnItem(
                child: Text('Workout App', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SettingsPage();
                  },
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                );
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomePage(userId: widget.userId),
            ForYouPage(userId: widget.userId),
            LibraryPage(),
          ],
        ),
        bottomNavigationBar: ResponsiveVisibility(
          visible: true,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              _refreshData();
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Ana Sayfa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.recommend),
                label: 'Senin İçin',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_books),
                label: 'Kütüphane',
              ),
            ],
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}