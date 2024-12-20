import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final _logger = Logger('database/dataset_1.db');

class DatasetDBProvider {
  static final DatasetDBProvider _instance = DatasetDBProvider._internal();

  factory DatasetDBProvider() => _instance;

  DatasetDBProvider._internal();

  static Database? _database;

  static const String DB_NAME = 'dataset_1.db';
  static const int DB_VERSION = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String dbPath = join(await getDatabasesPath(), DB_NAME);

    // Veritabanının var olup olmadığını kontrol et
    if (await databaseExists(dbPath)) {
      // Eğer veritabanı varsa, aç
      return await openDatabase(
        dbPath,
        version: DB_VERSION,
      );
    } else {
      // Eğer veritabanı yoksa, asset'ten yükle
      try {
        ByteData data = await rootBundle.load(join('database', DB_NAME));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

        // Veritabanı dosyasını oluştur
        await writeBytes(dbPath, bytes);

        // Veritabanını aç ve tabloları oluştur
        return await openDatabase(
          dbPath,
          version: DB_VERSION,
          onCreate: (db, version) async {
            await _createTables(db);
            await _createIndexes(db);
            await testDatabaseContent(); // Tablolar oluşturulduktan sonra içerik testi yap
          },
        );
      } catch (e) {
        throw Exception("Dataset veritabanı başlatılamadı: $e");
      }
    }
  }

  Future<void> writeBytes(String path, List<int> bytes) async {
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
  }




  Future<void> _createTables(Database db) async {
    // Tabloların oluşturulması
    await db.execute('''
      CREATE TABLE IF NOT EXISTS final_dataset (
        Weight REAL,
        Height REAL,
        BMI REAL,
        Gender TEXT,
        Age INTEGER,
        BMIcase TEXT,
        "Exercise Recommendation Plan" INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS final_dataset_BFP (
        Weight REAL,
        Height REAL,
        BMI REAL,
        "Body Fat Percentage" REAL,
        BFPcase TEXT,
        Gender TEXT,
        Age INTEGER,
        BMIcase TEXT,
        "Exercise Recommendation Plan" INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS gym_members_exercise_tracking (
        Age INTEGER,
        Gender TEXT,
        "Weight (kg)" REAL,
        "Height (m)" REAL,
        Max_BPM INTEGER,
        Avg_BPM INTEGER,
        Resting_BPM INTEGER,
        "Session_Duration (hours)" REAL,
        Calories_Burned REAL,
        Workout_Type TEXT,
        Fat_Percentage REAL,
        "Water_Intake (liters)" REAL,
        "Workout_Frequency (days/week)" INTEGER,
        Experience_Level INTEGER,
        BMI REAL
      )
    ''');
  }


Future<void> _createIndexes(Database db) async {
    // BMI ve BFP eşleştirmesi için index
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_bmi_matching 
      ON final_dataset(Weight, Height, BMI, Gender, Age)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_bfp_matching 
      ON final_dataset_BFP(Weight, Height, BMI, Gender, Age)
    ''');

    // Exercise tracking için performans indexi
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercise_tracking 
      ON gym_members_exercise_tracking(Experience_Level, BMI)
    ''');
  }

  Future<void> testDatabaseContent() async {
    try {
      final db = await database;

      // BMI Dataset kontrolü
      final bmiData = await db.query('final_dataset', limit: 1);
      if (bmiData.isNotEmpty) {
        _logger.info("BMI dataset kayıt sayısı: ${bmiData.length}");
      } else {
        _logger.warning("BMI dataset boş.");
      }

      // BFP Dataset kontrolü
      final bfpData = await db.query('final_dataset_BFP', limit: 1);
      if (bfpData.isNotEmpty) {
        _logger.info("BFP dataset kayıt sayısı: ${bfpData.length}");
      } else {
        _logger.warning("BFP dataset boş.");
      }

      // Exercise Tracking Dataset kontrolü
      final exerciseData = await db.query('gym_members_exercise_tracking', limit: 1);
      if (exerciseData.isNotEmpty) {
        _logger.info("Exercise tracking kayıt sayısı: ${exerciseData.length}");
      } else {
        _logger.warning("Exercise tracking dataset boş.");
      }

    } catch (e) {
      _logger.severe("Dataset içerik testi hatası", e);
    }
  }


  Future<void> reloadDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await initDatabase();
    _logger.info("Dataset veritabanı yeniden yüklendi.");
  }



  Future<List<Map<String, dynamic>>> getBMIDataset() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> result = await db.query('final_dataset');

      if (result.isEmpty) {
        print("BMI dataset boş.");
      } else {
        print("BMI dataset kayıt sayısı: ${result.length}");
      }

      return result;
    } catch (e) {
      print("BMI dataset sorgulama hatası: $e");
      return []; // Hata durumunda boş liste döndür
    }
  }

  Future<List<Map<String, dynamic>>> getBFPDataset() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> result = await db.query('final_dataset_BFP');

      if (result.isEmpty) {
        print("BFP dataset boş.");
      } else {
        print("BFP dataset kayıt sayısı: ${result.length}");
      }

      return result;
    } catch (e) {
      print("BFP dataset sorgulama hatası: $e");
      return []; // Hata durumunda boş liste döndür
    }
  }

  Future<List<Map<String, dynamic>>> getExerciseTrackingData() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> result = await db.query('gym_members_exercise_tracking');

      if (result.isEmpty) {
        print("Exercise tracking dataset boş.");
      } else {
        print("Exercise tracking dataset kayıt sayısı: ${result.length}");
      }

      return result;
    } catch (e) {
      print("Exercise tracking dataset sorgulama hatası: $e");
      return []; // Hata durumunda boş liste döndür
    }
  }



  /// Tüm veri setlerini birleştirip normalize edilmiş şekilde getirir
  Future<List<Map<String, dynamic>>> getCombinedTrainingData() async {
    final bmiData = await getBMIDataset();
    final bfpData = await getBFPDataset();
    final exerciseData = await getExerciseTrackingData();

    testDatabaseContent();



    return _normalizeAndCombineDatasets(bmiData, bfpData, exerciseData);
  }



  /// Veri setlerini normalize ederek birleştirir
  List<Map<String, dynamic>> _normalizeAndCombineDatasets(
      List<Map<String, dynamic>> bmiData,
      List<Map<String, dynamic>> bfpData,
      List<Map<String, dynamic>> exerciseData,
      ) {
    final combinedData = <Map<String, dynamic>>[];

    for (var bmiRecord in bmiData) {
      final matchingBfp = bfpData.firstWhere(
            (bfp) => _matchRecords(bmiRecord, bfp),
      );

      if (matchingBfp != null) { // Null kontrolü
        combinedData.add({
          'weight': bmiRecord['Weight'],
          'height': bmiRecord['Height'],
          'bmi': bmiRecord['BMI'],
          'gender': bmiRecord['Gender'],
          'age': bmiRecord['Age'],
          'bmi_case': bmiRecord['BMIcase'],
          'bfp': matchingBfp['Body Fat Percentage'],
          'bfp_case': matchingBfp['BFPcase'],
          'exercise_plan': bmiRecord['Exercise Recommendation Plan'],
        });
      }
    }

    // Exercise tracking verilerini ekle
    for (var exercise in exerciseData) {
      combinedData.add({
        'weight': exercise['Weight (kg)'],
        'height': exercise['Height (m)'],
        'bmi': exercise['BMI'],
        'gender': exercise['Gender'],
        'age': exercise['Age'],
        // Diğer özellikler...
      });
    }

    return combinedData;
  }


  /// İki kaydın eşleşip eşleşmediğini kontrol eder
  bool _matchRecords(Map<String, dynamic> bmi, Map<String, dynamic> bfp) {
    return bmi['Weight'] == bfp['Weight'] &&
        bmi['Height'] == bfp['Height'] &&
        bmi['BMI'] == bfp['BMI'] &&
        bmi['Gender'] == bfp['Gender'] &&
        bmi['Age'] == bfp['Age'];
  }

  /// Feature ranges için min-max değerlerini hesaplar
  Future<Map<String, List<double>>> getFeatureRanges() async {
    final combinedData = await getCombinedTrainingData();

    return {
      'weight': _getRange(combinedData.map((e) => e['weight'] as double).toList()),
      'height': _getRange(combinedData.map((e) => e['height'] as double).toList()),
      'bmi': _getRange(combinedData.map((e) => e['bmi'] as double).toList()),
      'bfp': _getRange(combinedData.where((e) => e['bfp'] != null)
          .map((e) => e['bfp'] as double).toList()),
      'age': _getRange(combinedData.map((e) => e['age'] as double).toList()),
    };
  }

  List<double> _getRange(List<double> values) {
    if (values.isEmpty) return [0.0, 0.0];
    return [
      values.reduce((a, b) => a < b ? a : b),
      values.reduce((a, b) => a > b ? a : b)
    ];
  }

  Future<List<Map<String, dynamic>>> getTrainingDataByBMIRange({
    required double minBMI,
    required double maxBMI
  }) async {
    final db = await database;
    return await db.query(
        'final_dataset',
        where: 'BMI BETWEEN ? AND ?',
        whereArgs: [minBMI, maxBMI]
    );
  }

  Future<List<Map<String, dynamic>>> getTrainingDataByExperience(
      int experienceLevel
      ) async {
    final db = await database;
    return await db.query(
        'gym_members_exercise_tracking',
        where: 'Experience_Level = ?',
        whereArgs: [experienceLevel]
    );
  }




}
