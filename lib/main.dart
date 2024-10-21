import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:workout/ui/home_page.dart';
import 'package:workout/ui/for_you_page.dart';
import 'package:workout/data_provider/firebase_provider.dart';
import 'package:workout/data_provider/sql_provider.dart';
import 'package:workout/ui/setting_pages.dart';
import 'data_bloc_part/PartRepository.dart';
import 'data_bloc_part/part_bloc.dart';
import 'data_bloc_routine/RoutineRepository.dart';
import 'data_bloc_routine/routines_bloc.dart';
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
  final partRepository = PartRepository(sqlProvider, firebaseProvider);  // Yeni eklenen satır
  await sqlProvider.testDatabaseContent();

  String? userId = await firebaseProvider.signInAnonymously();

  if (userId != null) {
    runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<RoutinesBloc>(
            create: (context) => RoutinesBloc(repository: routineRepository, userId: userId),
          ),
          BlocProvider<PartsBloc>(
            create: (context) => PartsBloc(repository: partRepository, userId: userId)..add(FetchParts()),          ),
        ],
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

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final RoutinesBloc routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    final PartsBloc partsBloc = BlocProvider.of<PartsBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [

            Icon(Icons.sports_score_rounded, color: Colors.red,), // İkon
            SizedBox(width: 10), // İkon ve metin arasında boşluk
            Text('Workout App',selectionColor: Colors.red), // Uygulama başlığı

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
            partsBloc.add(FetchParts()); // Eklenen satır
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