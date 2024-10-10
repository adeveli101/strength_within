import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:workout/ui/recommend_page.dart';
import 'package:workout/ui/home_page.dart';
import 'package:workout/ui/statistics_page.dart';
import 'package:workout/ui/setting_page.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'controllers/routines_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Get.put(RoutinesBloc());
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Workout App',
      theme: FluentThemeData(
        accentColor: Colors.blue,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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

  final List<NavigationPaneItem> _items = [
    PaneItem(
      icon: const Icon(FluentIcons.favorite_star),
      title: const Text('Recommend'),
      body: RecommendPage(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.health),
      title: const Text('Home'),
      body: HomePage(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.line_chart),
      title: const Text('Statistics'),
      body: const StatisticsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text('Workout'),
        actions: Row(
          children: [
            IconButton(
              icon: const Icon(FluentIcons.settings),
              onPressed: () => _showSettingsPopup(context),
            ),
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
        items: _items,
        displayMode:
        PaneDisplayMode.auto, // Automatically switches between modes
      ),
    );
  }

  void _showSettingsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ContentDialog(
          title: const Text('Settings'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SettingsPage(),
          ),
          actions: [
            Button(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}

// Function to save anonymous data
void saveAnonymousData() {
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> data = {
    "timestamp": DateTime.now().toIso8601String(),
    "someData": "exampleValue" // Replace with actual data fields
  };

  database.child("anonymousUsers").child(uniqueId).set(data).then((_) {
    print("Data saved successfully.");
  }).catchError((error) {
    print("Failed to save data: $error");
  });
}
