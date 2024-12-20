// lib/ai_lib/main_ai.dart

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'ai_data_bloc/ai_repository.dart';
import 'z_ai_ui/ModelDashboardScreen.dart';
import 'z_ai_ui/ModelTrainingScreen.dart';
import 'z_ai_ui/RecommendationTestScreen.dart';

void main() {
  // Logger konfigürasyonu
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(AIManagerApp());
}

class AIManagerApp extends StatelessWidget {
  final AIRepository _repository = AIRepository();

  AIManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Model Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: AIHomePage(),
    );
  }
}

class AIHomePage extends StatefulWidget {
  const AIHomePage({super.key});

  @override
  _AIHomePageState createState() => _AIHomePageState();
}

class _AIHomePageState extends State<AIHomePage> {
  final AIRepository _repository = AIRepository();
  int _currentIndex = 0;

  final List<Widget> _pages = [
    ModelDashboardScreen(),
    ModelTrainingScreen(),
    RecommendationTestScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      await _repository.initialize();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI başlatma hatası: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<AIRepositoryState>(
        stream: _repository.stateStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data == AIRepositoryState.uninitialized ||
              snapshot.data == AIRepositoryState.initializing) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == AIRepositoryState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  Text('AI sistemi başlatılamadı'),
                  ElevatedButton(
                    onPressed: _initializeAI,
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          return _pages[_currentIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Eğitim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: 'Test',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
