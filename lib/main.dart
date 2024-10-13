import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workout/ui/recommend_page.dart';
import 'package:workout/ui/home_page.dart';
import 'package:workout/ui/setting_page.dart';
import 'package:workout/ui/statistics_page.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'controllers/routines_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Get.put(RoutinesBloc());
  routinesBloc.initialize();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout App',
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF1E1E1E), // Koyu arka plan rengi
        scaffoldBackgroundColor: Color(0xFF121212), // Daha koyu arka plan rengi
        cardColor: Color(0xFF2C2C2C), // Kart rengi
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFFE91E63), // Pembe vurgu rengi
          unselectedItemColor: Colors.grey[600],
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white60),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Color(0xFFE91E63), // Pembe buton rengi
          textTheme: ButtonTextTheme.primary,
        ),
        // Ek özellikler için yorum satırları:
        // colorScheme: ColorScheme.dark(
        //   primary: Color(0xFFE91E63),
        //   secondary: Color(0xFF03DAC6),
        //   surface: Color(0xFF1E1E1E),
        //   background: Color(0xFF121212),
        //   error: Color(0xFFCF6679),
        // ),
        // inputDecorationTheme: InputDecorationTheme(
        //   fillColor: Color(0xFF2C2C2C),
        //   filled: true,
        //   border: OutlineInputBorder(
        //     borderRadius: BorderRadius.circular(8),
        //     borderSide: BorderSide.none,
        //   ),
        // ),
      ),
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
        ],
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    RecommendPage(),
    HomePage(),
    StatisticsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showSettingsPopup(context),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Recommend',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }

  void _showSettingsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SettingsPage(),
          ),
          actions: [
            TextButton(
              child: Text('Close', style: TextStyle(color: Color(0xFFE91E63))),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
