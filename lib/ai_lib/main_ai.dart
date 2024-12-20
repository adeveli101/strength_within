import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../z.app_theme/app_theme.dart';
import 'ai_data_bloc/ai_repository.dart';
import 'core/ai_constants.dart';
import 'core/ai_exceptions.dart';
import 'z_ai_ui/ModelTrainingScreen.dart';
import 'z_ai_ui/ModelDashboardScreen.dart';
import 'z_ai_ui/RecommendationTestScreen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web ortamında sqflite fabrikasını ayarlayın
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    // Diğer platformlar için normal ayar
    sqfliteFfiInit();
  }

  runApp(MainAIApp(repository: AIRepository()));}


class MainAIApp extends StatelessWidget {
  final AIRepository repository;

  const MainAIApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Fitness System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: DesktopAIHome(repository: repository),
    );
  }
}

class DesktopAIHome extends StatefulWidget {
  final AIRepository repository;

  const DesktopAIHome({super.key, required this.repository});

  @override
  _DesktopAIHomeState createState() => _DesktopAIHomeState();
}

class _DesktopAIHomeState extends State<DesktopAIHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sol Menü
          NavigationRail(
            backgroundColor: AppTheme.surfaceColor,
            selectedIndex: _selectedIndex,
            extended: true,
            minExtendedWidth: 200,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            leading: Padding(
              padding: EdgeInsets.all(AppTheme.paddingLarge),
              child: Text(
                'AI System',
                style: AppTheme.headingMedium,
              ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.fitness_center),
                label: Text('Model Eğitimi'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Performans'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.recommend),
                label: Text('Öneri Testi'),
              ),
            ],
          ),

          // Dikey Çizgi
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppTheme.surfaceColor,
          ),

          // Ana İçerik
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                ModelTrainingScreen(),
                ModelDashboardScreen(),
                RecommendationTestScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
