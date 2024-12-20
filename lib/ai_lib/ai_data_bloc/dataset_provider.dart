import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// DatasetDBProvider, fitness veritabanı işlemlerini yöneten sınıf
class DatasetDBProvider {
  // Singleton pattern implementation
  static final DatasetDBProvider _instance = DatasetDBProvider._internal();
  factory DatasetDBProvider() => _instance;
  DatasetDBProvider._internal();

  // Logger instance
  final _logger = Logger('DatasetDBProvider');

  // Database constants
  static const String DB_NAME = 'dataset_1.db';
  static const int DB_VERSION = 1;

  // Database instance
  static Database? _database;

  /// Veritabanı instance'ını döndürür, yoksa oluşturur
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Veritabanını initialize eder
  Future<Database> _initDatabase() async {
    final dbPath = join(await getDatabasesPath(), DB_NAME);

    try {
      // Veritabanı var mı kontrol et
      if (await databaseExists(dbPath)) {
        _logger.info('Veritabanı mevcut: $dbPath');
        return await openDatabase(dbPath, version: DB_VERSION);
      }

      // Veritabanı yoksa asset'ten kopyala
      _logger.info('Veritabanı oluşturuluyor...');
      await _copyDatabaseFromAsset(dbPath);

      // Veritabanını aç ve şemayı oluştur
      return await openDatabase(
        dbPath,
        version: DB_VERSION,
        onCreate: (db, version) async {
          await _createDatabaseSchema(db);
          await _validateDatabase(db);
        },
      );
    } catch (e) {
      final error = 'Veritabanı başlatma hatası: $e';
      _logger.severe(error);
      throw DatabaseException(error);
    }
  }

  /// Asset'ten veritabanını kopyalar
  Future<void> _copyDatabaseFromAsset(String dbPath) async {
    try {
      // Asset'ten veritabanı dosyasını oku
      final data = await rootBundle.load(join('database', DB_NAME));
      final bytes = data.buffer.asUint8List();

      // Dosyayı belirtilen konuma yaz
      await File(dbPath).writeAsBytes(bytes, flush: true);
      _logger.info('Veritabanı asset\'ten başarıyla kopyalandı');
    } catch (e) {
      throw DatabaseException('Veritabanı kopyalama hatası: $e');
    }
  }

  /// Veritabanı şemasını oluşturur
  Future<void> _createDatabaseSchema(Database db) async {
    await db.transaction((txn) async {
      // BMI Dataset tablosu
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS final_dataset (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          Weight REAL NOT NULL,
          Height REAL NOT NULL,
          BMI REAL NOT NULL,
          Gender TEXT NOT NULL,
          Age INTEGER NOT NULL,
          BMIcase TEXT NOT NULL,
          "Exercise Recommendation Plan" INTEGER NOT NULL
        )
      ''');

      // BFP Dataset tablosu
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS final_dataset_BFP (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          Weight REAL NOT NULL,
          Height REAL NOT NULL,
          BMI REAL NOT NULL,
          "Body Fat Percentage" REAL NOT NULL,
          BFPcase TEXT NOT NULL,
          Gender TEXT NOT NULL,
          Age INTEGER NOT NULL,
          BMIcase TEXT NOT NULL,
          "Exercise Recommendation Plan" INTEGER NOT NULL
        )
      ''');

      // Exercise Tracking tablosu
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS gym_members_exercise_tracking (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          Age INTEGER NOT NULL,
          Gender TEXT NOT NULL,
          "Weight (kg)" REAL NOT NULL,
          "Height (m)" REAL NOT NULL,
          Max_BPM INTEGER,
          Avg_BPM INTEGER,
          Resting_BPM INTEGER,
          "Session_Duration (hours)" REAL,
          Calories_Burned REAL,
          Workout_Type TEXT,
          Fat_Percentage REAL,
          "Water_Intake (liters)" REAL,
          "Workout_Frequency (days/week)" INTEGER,
          Experience_Level INTEGER NOT NULL,
          BMI REAL NOT NULL
        )
      ''');

      // Performans indeksleri
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_bmi_matching ON final_dataset(Weight, Height, BMI, Gender, Age)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_bfp_matching ON final_dataset_BFP(Weight, Height, BMI, Gender, Age)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_exercise_tracking ON gym_members_exercise_tracking(Experience_Level, BMI)');
    });

    _logger.info('Veritabanı şeması başarıyla oluşturuldu');
  }

  /// Veritabanı bütünlüğünü kontrol eder
  Future<void> _validateDatabase(Database db) async {
    try {
      // Her tablodan örnek veri kontrolü
      final bmiData = await db.query('final_dataset', limit: 1);
      final bfpData = await db.query('final_dataset_BFP', limit: 1);
      final exerciseData = await db.query('gym_members_exercise_tracking', limit: 1);

      // Veri kontrolü
      if (bmiData.isEmpty || bfpData.isEmpty || exerciseData.isEmpty) {
        throw DatabaseException('Veritabanı boş veya eksik veri içeriyor');
      }

      _logger.info('Veritabanı doğrulama başarılı');
    } catch (e) {
      throw DatabaseException('Veritabanı doğrulama hatası: $e');
    }
  }

  /// BMI verilerini getirir
  Future<List<Map<String, dynamic>>> getBMIDataset() async {
    final db = await database;
    try {
      final result = await db.query('final_dataset');
      _logger.info('BMI veri sayısı: ${result.length}');
      return result;
    } catch (e) {
      throw DatabaseException('BMI veri çekme hatası: $e');
    }
  }

  /// BFP verilerini getirir
  Future<List<Map<String, dynamic>>> getBFPDataset() async {
    final db = await database;
    try {
      final result = await db.query('final_dataset_BFP');
      _logger.info('BFP veri sayısı: ${result.length}');
      return result;
    } catch (e) {
      throw DatabaseException('BFP veri çekme hatası: $e');
    }
  }

  /// Exercise tracking verilerini getirir
  Future<List<Map<String, dynamic>>> getExerciseTrackingData() async {
    final db = await database;
    try {
      final result = await db.query('gym_members_exercise_tracking');
      _logger.info('Exercise tracking veri sayısı: ${result.length}');
      return result;
    } catch (e) {
      throw DatabaseException('Exercise tracking veri çekme hatası: $e');
    }
  }

  /// Tüm veri setlerini birleştirir
  Future<List<Map<String, dynamic>>> getCombinedTrainingData() async {
    try {
      // Tüm veri setlerini al
      final bmiData = await getBMIDataset();
      final bfpData = await getBFPDataset();
      final exerciseData = await getExerciseTrackingData();

      // Birleştirilmiş veri seti
      final combinedData = <Map<String, dynamic>>[];

      // BMI ve BFP verilerini eşleştir
      for (final bmi in bmiData) {
        final matchingBfp = bfpData.firstWhere(
              (bfp) => _matchRecords(bmi, bfp),
          orElse: () => <String, dynamic>{},
        );

        if (matchingBfp.isNotEmpty) {
          combinedData.add({
            ...bmi,
            'Body Fat Percentage': matchingBfp['Body Fat Percentage'],
            'BFPcase': matchingBfp['BFPcase'],
          });
        }
      }

      // Exercise tracking verilerini ekle
      combinedData.addAll(exerciseData);

      _logger.info('Toplam birleştirilmiş veri sayısı: ${combinedData.length}');
      return combinedData;
    } catch (e) {
      throw DatabaseException('Veri birleştirme hatası: $e');
    }
  }

  /// İki kaydın eşleşip eşleşmediğini kontrol eder
  bool _matchRecords(Map<String, dynamic> bmi, Map<String, dynamic> bfp) {
    return bmi['Weight'] == bfp['Weight'] &&
        bmi['Height'] == bfp['Height'] &&
        bmi['BMI'] == bfp['BMI'] &&
        bmi['Gender'] == bfp['Gender'] &&
        bmi['Age'] == bfp['Age'];
  }

  /// Veritabanını yeniden yükler
  Future<void> reloadDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await _initDatabase();
    _logger.info('Veritabanı yeniden yüklendi');
  }
}

/// Özel veritabanı exception sınıfı
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}