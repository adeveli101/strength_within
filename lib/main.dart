import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workout/ui/setting_page.dart';
import 'package:workout/ui/statistics_page.dart';
import 'package:workout/ui/home_page.dart';
import 'package:getwidget/getwidget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'resource/db_provider.dart';
import 'resource/firebase_provider.dart';
import 'bloc/routines_bloc.dart';
import 'resource/shared_prefs_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      initialRoute: "/",
      theme: ThemeData(
        primaryColor: Colors.blueGrey[800],
        primarySwatch: Colors.grey,
        fontFamily: 'Staa',
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme.copyWith(
            bodyLarge: const TextStyle(fontSize: 18),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      title: 'Dumbbell',
      routes: {
        '/home_page': (context) => HomePage(
          id: DBProvider.db.generateId(),
          createdAt: DateTime.now(),
          parts: const [],
        ),
      },
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) return const GFLoader();
          return const MainPage();
        },
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  final pageController = PageController(initialPage: 0, keepPage: true);
  final scrollController = ScrollController();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late List<Widget> tabs;

  void signInCallback() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    tabs = [
      HomePage(
        id: DBProvider.db.generateId(),
        createdAt: DateTime.now(),
        parts: const [],
      ),
      const StatisticsPage(),
    ];
    DBProvider.db.initDB().whenComplete(() {
      routinesBloc.fetchAllRoutines();
      routinesBloc.fetchAllRecRoutines();
    });
    firebaseProvider.signInSilently();
    sharedPrefsProvider.prepareData();
  }
  void _showSettingsPopup() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment.topRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.3,
              margin: EdgeInsets.only(top: position.top, right: 9),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: const Text('Settings'),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: SettingPage(signInCallback: signInCallback),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: GFAppBar(
          title: const Text('Dumbbell'),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.bars),
              onPressed: _showSettingsPopup,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: FaIcon(FontAwesomeIcons.dumbbell)),
              Tab(icon: FaIcon(FontAwesomeIcons.chartLine)),
            ],
          ),
        ),
        body: TabBarView(children: tabs),
      ),
    );
  }
}
