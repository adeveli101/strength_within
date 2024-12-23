// lib/ai_lib/ai_data_bloc/dataset_provider.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:idb_shim/idb_browser.dart';
import 'package:idb_shim/idb.dart' as idb;

// Veri sağlayıcı sınıfı
class DatasetProvider {
  static final DatasetProvider _instance = DatasetProvider._internal();
  factory DatasetProvider() => _instance;
  DatasetProvider._internal();

  final _logger = Logger('DatasetProvider');

  // JSON dosyalarının yolları
  static const String DATASET_PATH = 'database/final_dataset.json';
  static const String DATASET_BFP_PATH = 'database/final_dataset_BFP.json';
  static const String GYM_MEMBERS_TRACKING_PATH = 'database/gym_members_tracking.json';

  // IndexedDB için yapılandırma
  late idb.Database? _db;
  static const String DB_NAME = 'fitness_db';
  static const int DB_VERSION = 1;

  Future<void> initDB() async {
    if (!kIsWeb) return;

    try {
      final factory = getIdbFactory();
      _db = await factory!.open(DB_NAME, version: DB_VERSION,
          onUpgradeNeeded: (idb.VersionChangeEvent event) {
            final db = event.database;
            if (!db.objectStoreNames.contains('model_data')) {
              db.createObjectStore('model_data', autoIncrement: true);
            }
          });
      _logger.info('IndexedDB initialized successfully');
    } catch (e) {
      _logger.severe('IndexedDB initialization failed: $e');
      throw Exception('IndexedDB initialization failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> readJson(String path) async {
    try {
      if (kIsWeb) {
        return await _readJsonWeb(path);
      } else {
        return await _readJsonLocal(path);
      }
    } catch (e) {
      _logger.severe("JSON dosyası okunurken hata: $e");
      throw Exception("JSON dosyası okunamadı: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _readJsonWeb(String path) async {
    try {
      final String jsonString = await rootBundle.loadString(path);
      if (jsonString.isEmpty) {
        throw Exception('JSON dosyası boş');
      }
      List<dynamic> jsonData = json.decode(jsonString);
      return jsonData.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.severe('Web JSON okuma hatası: $e');
      throw Exception('Web JSON okuma hatası: $e');
    }
  }


  Future<List<Map<String, dynamic>>> _readJsonLocal(String path) async {
    try {
      final file = File(path);
      String jsonString = await file.readAsString();
      List<dynamic> jsonData = json.decode(jsonString);
      return jsonData.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Yerel JSON okuma hatası: $e');
    }
  }

  Future<void> initialize() async {
    try {
      _logger.info('DatasetProvider initialization started');

      if (kIsWeb) {
        await initDB();
        _logger.info('IndexedDB initialized for web platform');
      }

      // Veri yükleme denemesi
      bool dataLoaded = false;
      int retryCount = 0;
      while (!dataLoaded && retryCount < 3) {
        try {
          await copyDataFromJsonFiles();
          dataLoaded = true;
          _logger.info('JSON data loaded successfully');
        } catch (e) {
          retryCount++;
          _logger.warning('Data loading attempt $retryCount failed: $e');
          await Future.delayed(Duration(seconds: 1));
        }
      }

      if (!dataLoaded) {
        throw Exception('Failed to load data after 3 attempts');
      }

      _logger.info('DatasetProvider initialization completed');
    } catch (e) {
      _logger.severe('DatasetProvider initialization failed: $e');
      throw Exception('DatasetProvider initialization failed: $e');
    }
  }




  Future<List<Map<String, dynamic>>> getDataset() async {
    return await readJson(DATASET_PATH);
  }

  Future<List<Map<String, dynamic>>> getDatasetBFP() async {
    return await readJson(DATASET_BFP_PATH);
  }

  Future<List<Map<String, dynamic>>> getGymMembersTracking() async {
    return await readJson(GYM_MEMBERS_TRACKING_PATH);
  }

  Future<void> saveModelData({
    required String modelType,
    required Map<String, dynamic> modelData,
    required DateTime timestamp,
  }) async {
    try {
      if (kIsWeb) {
        await _saveModelDataWeb(modelType, modelData, timestamp);
      } else {
        await _saveModelDataLocal(modelType, modelData, timestamp);
      }
      _logger.info('Model data saved successfully: $modelType');
    } catch (e) {
      _logger.severe('Error saving model data: $e');
      throw Exception('Error saving model data: $e');
    }
  }

  Future<void> _saveModelDataWeb(
      String modelType,
      Map<String, dynamic> modelData,
      DateTime timestamp
      ) async {
    try {
      final txn = _db!.transaction('model_data', 'readwrite');
      final store = txn.objectStore('model_data');

      await store.add({
        'model_type': modelType,
        'model_data': modelData,
        'timestamp': timestamp.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Web model data kaydetme hatası: $e');
    }
  }

  Future<void> _saveModelDataLocal(
      String modelType,
      Map<String, dynamic> modelData,
      DateTime timestamp
      ) async {
    try {
      final filePath = 'database/model_data.json';
      final file = File(filePath);

      List<Map<String, dynamic>> existingData = [];
      if (file.existsSync()) { // Senkron exists kontrolü
        String content = file.readAsStringSync(); // Senkron okuma
        if (content.isNotEmpty) {
          existingData = (json.decode(content) as List)
              .cast<Map<String, dynamic>>();
        }
      }

      existingData.add({
        'model_type': modelType,
        'model_data': modelData,
        'timestamp': timestamp.toIso8601String(),
      });

      file.writeAsStringSync(json.encode(existingData)); // Senkron yazma
    } catch (e) {
      _logger.severe('Yerel model data kaydetme hatası: $e');
      throw Exception('Yerel model data kaydetme hatası: $e');
    }
  }


  Future<void> copyDataFromJsonFiles() async {
    try {
      List<Map<String, dynamic>> dataset = await getDataset();
      List<Map<String, dynamic>> datasetBFP = await getDatasetBFP();
      List<Map<String, dynamic>> gymMembersTracking = await getGymMembersTracking();

      _logger.info('${dataset.length} kayıt final_dataset.json dosyasından yüklendi.');
      _logger.info('${datasetBFP.length} kayıt final_dataset_BFP.json dosyasından yüklendi.');
      _logger.info('${gymMembersTracking.length} kayıt gym_members_tracking.json dosyasından yüklendi.');
    } catch (e) {
      _logger.severe('Veri kopyalama hatası: $e');
      throw Exception('Veri kopyalama hatası: $e');
    }
  }



  Future<void> dispose() async {
    try {
      if (kIsWeb && _db != null) {
        _db?.close();
        _logger.info('IndexedDB connection closed');
      }
    } catch (e) {
      _logger.severe('Error during dispose: $e');
      throw Exception('Dispose failed: $e');
    }
  }

}
