import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:workout/ui/home_page.dart';
import 'package:workout/ui/for_you_page.dart';
import 'package:workout/data_bloc/RoutineRepository.dart';
import 'package:workout/data_bloc/routines_bloc.dart';
import 'package:workout/data_provider/firebase_provider.dart';
import 'package:workout/data_provider/sql_provider.dart';
import 'package:workout/ui/setting_pages.dart';
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

  final firebaseProvider = FirebaseProvider();
  final routineRepository = RoutineRepository(sqlProvider, firebaseProvider);
  await sqlProvider.testDatabaseContent();

  String? userId = await firebaseProvider.signInAnonymously();

  if (userId != null) {
    runApp(
      BlocProvider<RoutinesBloc>(
        create: (context) => RoutinesBloc(repository: routineRepository, userId: userId),
        child: App(userId: userId),
      ),
    );
  } else {
    print('Anonim giriş başarısız oldu.');
    // TODO: Anonim giriş başarısız olduğunda yapılacaklar
  }
}

class App extends StatelessWidget {
  final String userId;

  const App({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Fitness App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
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

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final RoutinesBloc routinesBloc = BlocProvider.of<RoutinesBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Ana Sayfa' : 'Senin İçin'),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            routinesBloc.add(FetchHomeData(userId: widget.userId));
          } else if (index == 1) {
            routinesBloc.add(FetchForYouData(userId: widget.userId));
          }
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
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}