
// TODO: Eklenecek Metodlar:
// - updateExerciseTracking(GymMembersTracking data)
// - updateBFPData(FinalDatasetBFP data)
// - updateBMIData(FinalDataset data)
// - getRecommendationsByBMI(double bmi)
// - getRecommendationsByExperience(int level)

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:idb_shim/idb_client.dart' as idb;
import 'package:idb_shim/idb_browser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'datasets_models.dart';

class DatasetDBProvider {
  static final DatasetDBProvider _instance = DatasetDBProvider._internal();
  factory DatasetDBProvider() => _instance;
  DatasetDBProvider._internal();

  final _logger = Logger('DatasetDBProvider');

  static const String DB_NAME = 'fitness_dataset.db';
  static const int DB_VERSION = 1;

  static sqflite.Database? _sqliteDb;
  static idb.Database? _indexedDb;

  Future<dynamic> get database async {
    if (kIsWeb) {
      _indexedDb ??= await initWebDatabase();
      return _indexedDb;
    } else {
      _sqliteDb ??= await initNativeDatabase();
      return _sqliteDb;
    }
  }

  Future<List<Map<String, dynamic>>> getBMIDataset() async {
    final db = await database;
    try {
      if (kIsWeb) {
        final transaction = db.transaction('final_dataset', 'readonly');
        final store = transaction.objectStore('final_dataset');
        final List rawResult = await store.getAll();
        return rawResult.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        return await db.query('final_dataset');
      }
    } catch (e) {
      _logger.severe('BMI veri çekme hatası: $e');
      throw DatabaseException('BMI veri çekme hatası: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBFPDataset() async {
    final db = await database;
    try {
      if (kIsWeb) {
        final transaction = db.transaction('final_dataset_BFP', 'readonly');
        final store = transaction.objectStore('final_dataset_BFP');
        final List rawResult = await store.getAll();
        return rawResult.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        return await db.query('final_dataset_BFP');
      }
    } catch (e) {
      _logger.severe('BFP veri çekme hatası: $e');
      throw DatabaseException('BFP veri çekme hatası: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getExerciseTrackingData() async {
    final db = await database;
    try {
      if (kIsWeb) {
        final transaction = db.transaction('gym_members_tracking', 'readonly');
        final store = transaction.objectStore('gym_members_tracking');
        final List rawResult = await store.getAll();
        return rawResult.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        return await db.query('gym_members_tracking');
      }
    } catch (e) {
      _logger.severe('Exercise tracking veri çekme hatası: $e');
      throw DatabaseException('Exercise tracking veri çekme hatası: $e');
    }
  }

  Future<idb.Database> initWebDatabase() async {
    try {
      final factory = getIdbFactory();
      if (factory == null) {
        throw DatabaseException('IndexedDB factory oluşturulamadı');
      }

      final db = await factory.open(DB_NAME, version: DB_VERSION,
          onUpgradeNeeded: (idb.VersionChangeEvent event) {
            final db = event.database;
            _createWebStores(db);
          }
      );

      return db;
    } catch (e) {
      throw DatabaseException('Web veritabanı başlatma hatası: $e');
    }
  }

  Future<sqflite.Database> initNativeDatabase() async {
    try {
      return await sqflite.openDatabase(
        DB_NAME,
        version: DB_VERSION,
        onCreate: (db, version) async {
          await _createNativeTables(db);
        },
      );
    } catch (e) {
      throw DatabaseException('Native veritabanı başlatma hatası: $e');
    }
  }

  void _createWebStores(idb.Database db) {
    if (!db.objectStoreNames.contains('final_dataset')) {
      db.createObjectStore('final_dataset', autoIncrement: true);
    }
    if (!db.objectStoreNames.contains('final_dataset_BFP')) {
      db.createObjectStore('final_dataset_BFP', autoIncrement: true);
    }
    if (!db.objectStoreNames.contains('gym_members_tracking')) {
      db.createObjectStore('gym_members_tracking', autoIncrement: true);
    }
  }

  Future<void> _createNativeTables(sqflite.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS final_dataset (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        height REAL NOT NULL,
        bmi REAL NOT NULL,
        gender TEXT NOT NULL,
        age INTEGER NOT NULL,
        bmi_case TEXT NOT NULL,
        exercise_plan INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS final_dataset_BFP (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        height REAL NOT NULL,
        bmi REAL NOT NULL,
        body_fat_percentage REAL NOT NULL,
        bfp_case TEXT NOT NULL,
        gender TEXT NOT NULL,
        age INTEGER NOT NULL,
        bmi_case TEXT NOT NULL,
        exercise_plan INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS gym_members_tracking (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        height_m REAL NOT NULL,
        max_bpm INTEGER,
        avg_bpm INTEGER,
        resting_bpm INTEGER,
        session_duration REAL,
        calories_burned REAL,
        workout_type TEXT,
        fat_percentage REAL,
        water_intake REAL,
        workout_frequency INTEGER,
        experience_level INTEGER NOT NULL,
        bmi REAL NOT NULL
      )
    ''');
  }


  // lib/ai_lib/dataset_provider.dart içine eklenecek metodlar

  Future<void> updateExerciseTracking(GymMembersTracking data) async {
    final db = await database;
    try {
      if (kIsWeb) {
        final transaction = db.transaction('gym_members_exercise_tracking', 'readwrite');
        final store = transaction.objectStore('gym_members_exercise_tracking');
        await store.put(data.toMap());
      } else {
        await db.update(
          'gym_members_exercise_tracking',
          data.toMap(),
          where: 'age = ? AND gender = ?',
          whereArgs: [data.age, data.gender],
        );
      }
      _logger.info('Exercise tracking verisi güncellendi');
    } catch (e) {
      throw DatabaseException('Exercise tracking güncelleme hatası: $e');
    }
  }

  Future<void> updateBFPData(FinalDatasetBFP data) async {
    final db = await database;
    try {
      if (kIsWeb) {
        final transaction = db.transaction('final_dataset_BFP', 'readwrite');
        final store = transaction.objectStore('final_dataset_BFP');
        await store.put(data.toMap());
      } else {
        await db.update(
          'final_dataset_BFP',
          data.toMap(),
          where: 'weight = ? AND height = ? AND gender = ? AND age = ?',
          whereArgs: [data.weight, data.height, data.gender, data.age],
        );
      }
      _logger.info('BFP verisi güncellendi');
    } catch (e) {
      throw DatabaseException('BFP veri güncelleme hatası: $e');
    }
  }

  Future<void> updateBMIData(FinalDataset data) async {
    final db = await database;
    try {
      if (kIsWeb) {
        final transaction = db.transaction('final_dataset', 'readwrite');
        final store = transaction.objectStore('final_dataset');
        await store.put(data.toMap());
      } else {
        await db.update(
          'final_dataset',
          data.toMap(),
          where: 'weight = ? AND height = ? AND gender = ? AND age = ?',
          whereArgs: [data.weight, data.height, data.gender, data.age],
        );
      }
      _logger.info('BMI verisi güncellendi');
    } catch (e) {
      throw DatabaseException('BMI veri güncelleme hatası: $e');
    }
  }

  Future<List<FinalDataset>> getRecommendationsByBMI(double bmi) async {
    final db = await database;
    try {
      final double bmiRange = 1.0; // BMI için kabul edilebilir sapma

      if (kIsWeb) {
        final transaction = db.transaction('final_dataset', 'readonly');
        final store = transaction.objectStore('final_dataset');
        final List rawResult = await store.getAll();

        return rawResult
            .map((item) => FinalDataset.fromMap(Map<String, dynamic>.from(item)))
            .where((data) => (data.bmi - bmi).abs() <= bmiRange)
            .toList();
      } else {
        final result = await db.query(
          'final_dataset',
          where: 'bmi BETWEEN ? AND ?',
          whereArgs: [bmi - bmiRange, bmi + bmiRange],
        );

        return result.map((item) => FinalDataset.fromMap(item)).toList();
      }
    } catch (e) {
      throw DatabaseException('BMI bazlı öneri getirme hatası: $e');
    }
  }

  Future<List<GymMembersTracking>> getRecommendationsByExperience(int level) async {
    final db = await database;
    try {
      if (kIsWeb) {
        final transaction = db.transaction('gym_members_exercise_tracking', 'readonly');
        final store = transaction.objectStore('gym_members_exercise_tracking');
        final List rawResult = await store.getAll();

        return rawResult
            .map((item) => GymMembersTracking.fromMap(Map<String, dynamic>.from(item)))
            .where((data) => data.experienceLevel == level)
            .toList();
      } else {
        final result = await db.query(
          'gym_members_exercise_tracking',
          where: 'experience_level = ?',
          whereArgs: [level],
        );

        return result.map((item) => GymMembersTracking.fromMap(item)).toList();
      }
    } catch (e) {
      throw DatabaseException('Deneyim seviyesi bazlı öneri getirme hatası: $e');
    }
  }













}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
  @override
  String toString() => 'DatabaseException: $message';
}
