import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:workout/resource/firebase_provider.dart';
import 'package:workout/ui/home_page.dart';
import 'package:workout/ui/recommend_page.dart';
import 'package:workout/ui/statistics_page.dart';
import 'firebase_options.dart';
import 'resource/routines_bloc.dart';
import 'resource/sql_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
  );

  final sqlProvider = SQLProvider();
  await sqlProvider.initDatabase();
  final firebaseProvider = FirebaseProvider(sqlProvider);

  String? userId = await firebaseProvider.signInAnonymously();
  if (userId == null) {
    print('Anonim giriş başarısız oldu.');
  }

  runApp(
    BlocProvider(
      create: (context) => RoutinesBloc(
        firebaseProvider: firebaseProvider,
        sqlProvider: sqlProvider,
      ),
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Fitness App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late RoutinesBloc _routinesBloc;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    _pages.add(HomePage(routinesBloc: _routinesBloc));
    _pages.add(RecommendPage(routinesBloc: _routinesBloc));
    _pages.add(StatisticsPage(routinesBloc: _routinesBloc));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recommend),
            label: 'Recommend',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
        ],
        backgroundColor: Color(0xFF282828),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
