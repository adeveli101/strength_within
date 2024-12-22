import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:idb_shim/idb_browser.dart'; // IndexedDB için gerekli
import 'package:idb_shim/idb.dart' as idb; // IndexedDB'nin temel sınıfları için

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'ai_data_bloc/ai_repository.dart';
import 'z_ai_ui/ModelTestScreen.dart';
import 'z_ai_ui/ModelTrainingScreen.dart';



idb.IdbFactory? indexedDbFactory; // IndexedDB için fabrika
DatabaseFactory? sqliteDbFactory; // SQLite için fabrika

Future<void> initializeDatabaseFactory() async {
  if (kIsWeb) {
    // Web ortamında IndexedDB kullanılıyor
    indexedDbFactory = getIdbFactory();
    print("Web ortamında IndexedDB başlatıldı.");
  } else {
    // Mobil ve masaüstü platformlarda SQLite kullanılıyor
    sqfliteFfiInit();
    sqliteDbFactory = databaseFactoryFfi;
    print("SQLite FFI başlatıldı.");
  }
}



class AIInitializationException implements Exception {
  final String message;
  AIInitializationException(this.message);

  @override
  String toString() => 'AI Başlatma Hatası: $message';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDatabaseFactory();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  FlutterError.onError = (FlutterErrorDetails details) {
    Logger.root.severe('Flutter Hatası', details.exception, details.stack);
  };

  runApp(AIManagerApp());
}

class AIManagerApp extends StatelessWidget {
  final AIRepository _repository;

  AIManagerApp({super.key}) : _repository = AIRepository() {
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    try {
      await _repository.initialize();
    } catch (e, stackTrace) {
      Logger.root.severe('Repository başlatma hatası', e, stackTrace);
      throw AIInitializationException(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Model Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: AIHomePage(),
      builder: (context, child) {
        return child ?? Container();
      },
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
    ModelTestScreen(),
    ModelTrainingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      await _repository.initialize();
      Logger.root.info('AI sistemi başarıyla başlatıldı');
    } on AIInitializationException catch (e) {
      Logger.root.severe('AI başlatma hatası', e);
      _showErrorDialog(context, 'AI Başlatma Hatası', e.toString()); // Burada context'i geçiriyoruz
    } catch (e, stackTrace) {
      Logger.root.severe('Beklenmeyen hata', e, stackTrace);
      _showErrorDialog(context, 'Beklenmeyen Hata', 'Sistem başlatılamadı: $e'); // Burada context'i geçiriyoruz
    }
  }

  void _showErrorDialog(BuildContext dialogContext, String title, String message) {
    if (!mounted) return;

    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeAI(); // Tekrar denemek için
            },
            child: Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<AIRepositoryState>(
        stream: _repository.stateStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == AIRepositoryState.initializing) {
            return Center(child: CircularProgressIndicator());
          }

          switch (snapshot.data) {
            case AIRepositoryState.error:
              return Center(child: Text('AI sistemi başlatılamadı.'));
            case AIRepositoryState.ready:
              return _pages[_currentIndex];
            default:
              return Container(); // Bilinmeyen durum
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Eğitim'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    try {
      _repository.dispose();
    } catch (e) {}

    super.dispose();
  }
}
