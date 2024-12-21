
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'ai_data_bloc/ai_repository.dart';
import 'z_ai_ui/ModelDashboardScreen.dart';
import 'z_ai_ui/ModelTrainingScreen.dart';
import 'z_ai_ui/RecommendationTestScreen.dart';



Future<void> initializeDatabaseFactory() async {
  if (kIsWeb) {
    // Web platformu için özel yapılandırma
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    // Desktop platformları için
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

// Özel hata sınıfları
class AIInitializationException implements Exception {
  final String message;
  AIInitializationException(this.message);
  @override
  String toString() => 'AI Başlatma Hatası: $message';
}

class AIStateException implements Exception {
  final String message;
  AIStateException(this.message);
  @override
  String toString() => 'AI Durum Hatası: $message';
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Veritabanı factory'sini platform bazlı yapılandır
    await initializeDatabaseFactory();

    // Logger konfigürasyonu
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });

    FlutterError.onError = (FlutterErrorDetails details) {
      Logger.root.severe('Flutter Hatası', details.exception, details.stack);
    };

    runApp(AIManagerApp());
  } catch (e, stackTrace) {
    Logger.root.severe('Kritik Başlatma Hatası', e, stackTrace);
    rethrow;
  }
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
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              Text('Uygulama Hatası: ${errorDetails.exception}'),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    };

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
  final _logger = Logger('AIHomePage');

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
      _logger.info('AI sistemi başarıyla başlatıldı');
    } on AIInitializationException catch (e) {
      _logger.severe('AI başlatma hatası', e);
      _showErrorDialog('AI Başlatma Hatası', e.toString());
    } on AIStateException catch (e) {
      _logger.severe('AI durum hatası', e);
      _showErrorDialog('AI Durum Hatası', e.toString());
    } catch (e, stackTrace) {
      _logger.severe('Beklenmeyen hata', e, stackTrace);
      _showErrorDialog('Beklenmeyen Hata', 'Sistem başlatılamadı: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeAI();
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
          try {
            if (!snapshot.hasData) {
              return _buildLoadingWidget();
            }

            switch (snapshot.data) {
              case AIRepositoryState.uninitialized:
              case AIRepositoryState.initializing:
                return _buildLoadingWidget();

              case AIRepositoryState.error:
                return _buildErrorWidget();

              case AIRepositoryState.ready:
                return _pages[_currentIndex];

              default:
                throw AIStateException('Bilinmeyen AI durumu');
            }
          } catch (e, stackTrace) {
            _logger.severe('Widget oluşturma hatası', e, stackTrace);
            return _buildErrorWidget();
          }
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('AI Sistemi Başlatılıyor...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
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

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        try {
          setState(() => _currentIndex = index);
        } catch (e) {
          _logger.warning('Sayfa değiştirme hatası', e);
        }
      },
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
    );
  }

  @override
  void dispose() {
    try {
      _repository.dispose();
    } catch (e) {
      _logger.warning('Repository dispose hatası', e);
    }
    super.dispose();
  }
}
