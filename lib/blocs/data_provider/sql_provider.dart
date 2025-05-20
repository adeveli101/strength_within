import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:strength_within/models/sql_models/part_frequency.dart';
import '../../models/sql_models/BodyPart.dart';
import '../../models/sql_models/ExerciseTargetedBodyParts.dart';
import '../../models/sql_models/PartExercises.dart';
import '../../models/sql_models/PartTargetedBodyParts.dart';
import '../../models/sql_models/Parts.dart';
import '../../models/sql_models/RoutineExercises.dart';
import '../../models/sql_models/RoutinetargetedBodyParts.dart';
import '../../models/sql_models/WorkoutType.dart';
import '../../models/sql_models/exercises.dart';
import '../../models/sql_models/routine_frequency.dart';
import '../../models/sql_models/routines.dart';
import '../../models/sql_models/workoutGoals.dart';
import '../../models/sql_models/workoutType_goals.dart';
import '../../utils/routine_helpers.dart';
import '../data_provider_cache/app_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data_provider/firebase_provider.dart';
import '../data_provider/sql_provider.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'database_helpers.dart';



final _logger = Logger('SQLProvider');

class SQLProvider {



  static final SQLProvider _instance = SQLProvider._internal();
  factory SQLProvider() => _instance;
  SQLProvider._internal();

  static Database? _database;
  static const String DB_NAME = 'esek.db';
  static const int DB_VERSION = 1; // Veritabanı versiyonu

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String dbPath = join(await getDatabasesPath(), DB_NAME);
    try {
      if (await databaseExists(dbPath)) {
        await deleteDatabase(dbPath);
        _logger.info("Eski veritabanı silindi.");
      }
      ByteData data = await rootBundle.load(join('database', DB_NAME));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(dbPath).writeAsBytes(bytes, flush: true);

      return await openDatabase(
        dbPath,
        version: DB_VERSION,
        onCreate: (db, version) async {
          await _createTables(db);
          await _createIndexes(db); // Index oluşturma eklendi
          _logger.info("Veritabanı tabloları ve indexler oluşturuldu.");
        },
      );
    } catch (e) {
      _logger.severe("Veritabanı başlatma hatası", e);
      throw ("Veritabanı başlatılamadı", code: "DB_INIT_ERROR", details: e);
    }
  }

  Future<void> testDatabaseContent() async {
    try {
      final db = await database;
      final routines = await db.query('Routines');
      _logger.info("Routines tablosundaki kayıt sayısı: ${routines.length}");

      // Exercises tablosunu da kontrol et
      final exercises = await db.query('Exercises');
      _logger.info("Exercises tablosundaki kayıt sayısı: ${exercises.length}");

      // Tablo yapısını kontrol et
      final tableInfo = await db.rawQuery('PRAGMA table_info(Exercises)');
      _logger.info("Exercises tablo yapısı: $tableInfo");

    } catch (e) {
      _logger.severe("Veritabanı içerik testi hatası", e);
    }
  }

  // Veritabanını yeniden yükle
  Future<void> reloadDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await initDatabase();
    _logger.info("Veritabanı yeniden yüklendi.");
  }

  Future _createTables(Database db) async {
    await db.execute('''
    CREATE TABLE WorkoutTypes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE BodyParts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      parentBodyPartId INTEGER REFERENCES BodyParts(id),
      isCompound BOOLEAN DEFAULT FALSE
    )
  ''');

    await db.execute('''
    CREATE TABLE "Parts" (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      setType INTEGER NOT NULL,
      additionalNotes TEXT,
      difficulty INTEGER
    )
  ''');

    await db.execute('''
    CREATE TABLE "Exercises" (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      defaultWeight REAL NOT NULL,
      defaultSets INTEGER NOT NULL,
      defaultReps INTEGER NOT NULL,
      workoutTypeId INTEGER NOT NULL,
      description TEXT,
      gifUrl TEXT,
      FOREIGN KEY(workoutTypeId) REFERENCES WorkoutTypes(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE "Routines" (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      workoutTypeId INTEGER,
      difficulty INTEGER,
      FOREIGN KEY(workoutTypeId) REFERENCES WorkoutTypes(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE "ExerciseTargetedBodyParts" (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      exerciseId INTEGER NOT NULL,
      bodyPartId INTEGER NOT NULL,
      isPrimary BOOLEAN DEFAULT FALSE,
      targetPercentage INTEGER NOT NULL DEFAULT 100,
      FOREIGN KEY(exerciseId) REFERENCES Exercises(id),
      FOREIGN KEY(bodyPartId) REFERENCES BodyParts(id),
      CHECK (targetPercentage BETWEEN 0 AND 100)
    )
  ''');

    await db.execute('''
    CREATE TABLE "RoutineTargetedBodyParts" (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      routineId INTEGER NOT NULL,
      bodyPartId INTEGER NOT NULL,
      targetPercentage INTEGER NOT NULL DEFAULT 100,
      FOREIGN KEY(routineId) REFERENCES Routines(id),
      FOREIGN KEY(bodyPartId) REFERENCES BodyParts(id),
      CHECK (targetPercentage BETWEEN 0 AND 100)
    )
  ''');

    await db.execute('''
    CREATE TABLE PartExercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      partId INTEGER NOT NULL,
      exerciseId INTEGER NOT NULL,
      orderIndex INTEGER,
      FOREIGN KEY (partId) REFERENCES Parts(id),
      FOREIGN KEY (exerciseId) REFERENCES Exercises(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE RoutineExercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      routineId INTEGER NOT NULL,
      exerciseId INTEGER NOT NULL,
      orderIndex INTEGER,
      FOREIGN KEY (routineId) REFERENCES Routines(id),
      FOREIGN KEY (exerciseId) REFERENCES Exercises(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE PartFrequency (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      partId INTEGER NOT NULL,
      recommendedFrequency INTEGER NOT NULL,
      minRestDays INTEGER NOT NULL,
      FOREIGN KEY (partId) REFERENCES Parts(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE RoutineFrequency (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      routineId INTEGER NOT NULL,
      recommendedFrequency INTEGER NOT NULL,
      minRestDays INTEGER NOT NULL,
      FOREIGN KEY (routineId) REFERENCES Routines(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE PartTargetedBodyParts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      partId INTEGER NOT NULL,
      bodyPartId INTEGER NOT NULL,
      isPrimary BOOLEAN DEFAULT FALSE,
      targetPercentage INTEGER DEFAULT 100,
      FOREIGN KEY(partId) REFERENCES Parts(id),
      FOREIGN KEY(bodyPartId) REFERENCES BodyParts(id)
    )
  ''');
  }

  Future _createIndexes(Database db) async {
    // Primary Foreign Key Indexes
    await db.execute('CREATE INDEX idx_exercises_workout ON Exercises(workoutTypeId)');
    await db.execute('CREATE INDEX idx_routines_workout ON Routines(workoutTypeId)');
    await db.execute('CREATE INDEX idx_bodyparts_parent ON BodyParts(parentBodyPartId)');

    // Composite Indexes for Exercise Relations
    await db.execute('CREATE INDEX idx_part_exercises_order ON PartExercises(partId, orderIndex)');
    await db.execute('CREATE INDEX idx_routine_exercises_order ON RoutineExercises(routineId, orderIndex)');

    // Frequency Table Indexes
    await db.execute('CREATE INDEX idx_part_frequency ON PartFrequency(partId, recommendedFrequency)');
    await db.execute('CREATE INDEX idx_routine_frequency ON RoutineFrequency(routineId, recommendedFrequency)');

    // Targeted BodyParts Indexes
    await db.execute('CREATE INDEX idx_part_targeted ON PartTargetedBodyParts(partId, isPrimary, targetPercentage)');
    await db.execute('CREATE INDEX idx_exercise_targeted ON ExerciseTargetedBodyParts(exerciseId, isPrimary, targetPercentage)');
    await db.execute('CREATE INDEX idx_routine_targeted ON RoutineTargetedBodyParts(routineId, targetPercentage)');

    // Search Optimization Indexes
    await db.execute('CREATE INDEX idx_parts_search ON Parts(name COLLATE NOCASE, setType, difficulty)');
    await db.execute('CREATE INDEX idx_exercises_search ON Exercises(name COLLATE NOCASE, workoutTypeId)');
    await db.execute('CREATE INDEX idx_routines_search ON Routines(name COLLATE NOCASE, workoutTypeId, difficulty)');
    await db.execute('CREATE INDEX idx_bodyparts_search ON BodyParts(name COLLATE NOCASE, isCompound)');
  }


///ai services update

  // BMI kategorisine göre hedefleri getir
  Future<List<WorkoutGoals>> getGoalsByBMIRange(double minBMI, double maxBMI) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'WorkoutGoals',
      where: 'minBMI <= ? AND maxBMI >= ?',
      whereArgs: [maxBMI, minBMI],
    );

    return List.generate(maps.length, (i) {
      return WorkoutGoals.fromMap(maps[i]);
    });
  }

// Hedef bazlı program önerileri için
  Future<List<Routines>> getRecommendedRoutinesByGoal({
    required int goalId,
    required int difficulty,
    required double confidence,
    int limit = 5
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT r.*, 
           wtg.recommendedPercentage as goalMatch,
           ? as aiConfidence
    FROM Routines r
    INNER JOIN WorkoutTypeGoals wtg 
      ON r.workoutTypeId = wtg.workoutTypeId 
      AND wtg.goalId = ?
    WHERE r.difficulty BETWEEN ? AND ?
    ORDER BY (wtg.recommendedPercentage * ?) DESC
    LIMIT ?
  ''', [confidence, goalId, difficulty - 1, difficulty + 1, confidence, limit]);

    return List.generate(maps.length, (i) {
      return Routines.fromMap(maps[i]);
    });
  }

// Hedef ve WorkoutType uyumluluğu için
  Future<double> getGoalWorkoutTypeCompatibility(
      int goalId,
      int workoutTypeId
      ) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT recommendedPercentage 
    FROM WorkoutTypeGoals
    WHERE goalId = ? AND workoutTypeId = ?
  ''', [goalId, workoutTypeId]);

    return result.isNotEmpty ? result.first['recommendedPercentage'] as double : 0.0;
  }


  Future<List<Map<String, dynamic>>> getWorkoutTypeGoalPercentages(int goalId) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT wt.id, wt.name, wtg.recommendedPercentage 
    FROM WorkoutTypes wt
    INNER JOIN WorkoutTypeGoals wtg ON wt.id = wtg.workoutTypeId
    WHERE wtg.goalId = ?
  ''', [goalId]);
  }

  Future<List<Routines>> getRoutinesByGoalAndType(
      int goalId,
      int workoutTypeId
      ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Routines',
      where: 'goalId = ? AND workoutTypeId = ?',
      whereArgs: [goalId, workoutTypeId],
    );

    return List.generate(maps.length, (i) {
      return Routines.fromMap(maps[i]);
    });
  }




  Future<List<Routines>> getRoutinesByDifficultyRange(
      int minDifficulty,
      int maxDifficulty
      ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Routines',
      where: 'difficulty BETWEEN ? AND ?',
      whereArgs: [minDifficulty, maxDifficulty],
    );

    return List.generate(maps.length, (i) {
      return Routines.fromMap(maps[i]);
    });
  }


  Future<List<Routines>> getRoutinesByGoalAndDifficulty(
      int goalId,
      int difficulty,
      int range
      ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Routines',
      where: 'goalId = ? AND difficulty BETWEEN ? AND ?',
      whereArgs: [goalId, difficulty - range, difficulty + range],
    );

    return List.generate(maps.length, (i) {
      return Routines.fromMap(maps[i]);
    });
  }





  Future<List<WorkoutTypeGoals>> getWorkoutTypeGoalsForGoals(List<int> goalIds) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT wtg.*, wt.name as workoutTypeName 
      FROM WorkoutTypeGoals wtg
      INNER JOIN WorkoutTypes wt ON wtg.workoutTypeId = wt.id
      WHERE wtg.goalId IN (${goalIds.join(',')})
      ORDER BY wtg.recommendedPercentage DESC
    ''');

    return List.generate(maps.length, (i) {
      return WorkoutTypeGoals(
        id: maps[i]['id'],
        workoutTypeId: maps[i]['workoutTypeId'],
        goalId: maps[i]['goalId'],
        recommendedPercentage: maps[i]['recommendedPercentage'],
      );
    });
  }

  Future<List<Routines>> getRoutinesByGoalsAndDifficulty({
    required List<int> goalIds,
    required int minDifficulty,
    required int maxDifficulty,
  }) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT r.*, wt.name as workoutTypeName
      FROM Routines r
      INNER JOIN WorkoutTypes wt ON r.workoutTypeId = wt.id
      WHERE r.goalId IN (${goalIds.join(',')})
      AND r.difficulty BETWEEN ? AND ?
      ORDER BY r.difficulty ASC
    ''', [minDifficulty, maxDifficulty]);

    return List.generate(maps.length, (i) {
      return Routines(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        workoutTypeId: maps[i]['workoutTypeId'],
        difficulty: maps[i]['difficulty'],
        goalId: maps[i]['goalId'],
      );
    });
  }





  // ana sorgular

  Future<List<Exercises>> getAllExercises() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('Exercises');
      return List.generate(maps.length, (i) => Exercises.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting all exercises', e);
      return [];
    }
  }

  Future<List<BodyParts>> getAllBodyParts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('BodyParts');
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting all body parts', e);
      return [];
    }
  }

  Future<List<Parts>> getAllParts() async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT p.*,
          GROUP_CONCAT(DISTINCT pe.exerciseId) as exerciseIds,
          GROUP_CONCAT(DISTINCT ptb.bodyPartId || '|' || 
            ptb.isPrimary || '|' || ptb.targetPercentage) as targetedBodyParts
        FROM Parts p
        LEFT JOIN PartExercises pe ON p.id = pe.partId
        LEFT JOIN PartTargetedBodyParts ptb ON p.id = ptb.partId
        GROUP BY p.id
      ''');

        return _generatePartsFromMaps(maps);
      });
    } catch (e) {
      _logger.severe('Error getting all parts', e);
      throw Exception('Parts alınırken hata oluştu: $e');
    }
  }

  Future<List<Routines>> getAllRoutines() async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT r.*, 
          GROUP_CONCAT(re.exerciseId) as exerciseIds,
          GROUP_CONCAT(rtb.bodyPartId || ':' || rtb.targetPercentage) as targetedBodyParts
        FROM Routines r
        LEFT JOIN RoutineExercises re ON r.id = re.routineId
        LEFT JOIN RoutineTargetedBodyParts rtb ON r.id = rtb.routineId
        GROUP BY r.id
        ORDER BY r.id
      ''');

        return Future.wait(maps.map((map) async {
          final targetedBodyParts = await txn.query(
              'RoutineTargetedBodyParts',
              where: 'routineId = ?',
              whereArgs: [map['id']]
          );

          return Routines.fromMap({
            ...map,
            'routineExercises': map['exerciseIds']?.split(',')
                .map((e) => {'exerciseId': int.parse(e)}).toList() ?? [],
            'targetedBodyParts': targetedBodyParts
          });
        }));
      });
    } catch (e, stackTrace) {
      _logger.severe('Error getting all routines', e, stackTrace);
      rethrow;
    }
  }







  ///exercises


  Future<List<ExerciseTargetedBodyParts>> getExerciseTargetedBodyParts(int exerciseId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT etb.*, b.name as bodyPartName
        FROM ExerciseTargetedBodyParts etb
        LEFT JOIN BodyParts b ON etb.bodyPartId = b.id
        WHERE etb.exerciseId = ?
        ORDER BY etb.targetPercentage DESC
      ''', [exerciseId]);

        return List.generate(maps.length, (i) =>
            ExerciseTargetedBodyParts.fromMap(maps[i])
        );
      });
    } catch (e) {
      _logger.severe('Error getting exercise targeted body parts', e);
      return [];
    }
  }

  Future<Exercises?> getExerciseById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Exercises',
        columns: ['id', 'name', 'description', 'defaultWeight', 'defaultSets', 'defaultReps', 'workoutTypeId', 'gifUrl'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        _logger.fine("Exercise data: ${maps.first}");
        return Exercises.fromMap(maps.first);
      } else {
        _logger.warning('No exercise found for ID: $id');
        return null;
      }
    } catch (e) {
      _logger.severe('Error getting exercise by id', e);
      return null;
    }
  }

  Future<List<Exercises>> getExercisesByIds(List<int> ids) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'exercises',
        columns: ['id', 'name', 'description', 'defaultWeight', 'defaultSets', 'defaultReps', 'workoutTypeId', 'gifUrl'], // Tüm gerekli alanları belirtin
        where: 'id IN (${List.filled(ids.length, '?').join(',')})',
        whereArgs: ids,
      );

      return List.generate(maps.length, (i) {
        return Exercises.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('ID\'lere göre egzersizler alınırken hata: $e');
    }
  }


  Future<List<Exercises>> getExercisesByWorkoutType(int workoutTypeId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Exercises',
        where: 'WorkoutTypeId = ?',
        whereArgs: [workoutTypeId],
      );
      return List.generate(maps.length, (i) => Exercises.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting exercises by workout type', e);
      return [];
    }
  }

  Future<List<Exercises>> searchExercisesByName(String name) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Exercises',
        where: 'Name LIKE ?',
        whereArgs: ['%$name%'],
      );
      return List.generate(maps.length, (i) => Exercises.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error searching exercises by name', e);
      return [];
    }
  }

  Future<List<Exercises>> getExercisesByWeightRange(double minWeight, double maxWeight) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Exercises',
        where: 'DefaultWeight BETWEEN ? AND ?',
        whereArgs: [minWeight, maxWeight],
      );
      return List.generate(maps.length, (i) => Exercises.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting exercises by weight range', e);
      return [];
    }
  }

  Future<Map<int, double>> getTargetPercentagesForExercise(int exerciseId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'ExerciseTargetedBodyParts',
        where: 'exerciseId = ?',
        whereArgs: [exerciseId],
      );
      return Map.fromEntries(
          maps.map((m) => MapEntry(m['bodyPartId'] as int, m['targetPercentage'] as double))
      );
    } catch (e) {
      _logger.severe('Error getting target percentages for exercise', e);
      return {};
    }
  }

  Future<List<Exercises>> getExercisesByBodyPart(int bodyPartId, {bool isPrimary = true}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT e.* FROM Exercises e
      INNER JOIN ExerciseTargetedBodyParts etb ON e.id = etb.exerciseId
      WHERE etb.bodyPartId = ? AND etb.isPrimary = ?
    ''', [bodyPartId, isPrimary ? 1 : 0]);
      return List.generate(maps.length, (i) => Exercises.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting exercises by body part', e);
      return [];
    }
  }

  Future<List<ExerciseTargetedBodyParts>> getPrimaryTargetedBodyParts(int exerciseId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'ExerciseTargetedBodyParts',
        where: 'exerciseId = ? AND isPrimary = 1',
        whereArgs: [exerciseId],
      );
      return List.generate(maps.length, (i) => ExerciseTargetedBodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting primary targeted body parts', e);
      return [];
    }
  }

  Future<List<ExerciseTargetedBodyParts>> getSecondaryTargetedBodyParts(int exerciseId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'ExerciseTargetedBodyParts',
        where: 'exerciseId = ? AND isPrimary = 0',
        whereArgs: [exerciseId],
      );
      return List.generate(maps.length, (i) => ExerciseTargetedBodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting secondary targeted body parts', e);
      return [];
    }
  }



  ///bodyparts///  ///bodyparts///  ///bodyparts///
  ///bodyparts///  ///bodyparts///  ///bodyparts///

  Future<String> getBodyPartName(int bodyPartId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'BodyParts',
        where: 'id = ?',
        whereArgs: [bodyPartId],
      );

      if (maps.isNotEmpty) {
        return maps.first['name'] as String;
      }
      return 'Bilinmiyor';
    } catch (e) {
      _logger.severe('Error getting body part name', e);
      return 'Bilinmiyor';
    }
  }

  Future<List<BodyParts>> getPrimaryTargetedBodyPartsForExercise(int exerciseId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.* FROM BodyParts b
      INNER JOIN ExerciseTargetedBodyParts etb ON b.id = etb.bodyPartId
      WHERE etb.exerciseId = ? AND etb.isPrimary = 1
    ''', [exerciseId]);
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting primary targeted body parts for exercise', e);
      return [];
    }
  }

  Future<List<String>> getBodyPartNamesByIds(List<int> bodyPartIds) async {
    try {
      if (bodyPartIds.isEmpty) return [];

      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT id, name 
      FROM BodyParts 
      WHERE id IN (${bodyPartIds.join(',')})
      ORDER BY CASE 
        WHEN parentBodyPartId IS NULL THEN 0 
        ELSE 1 
      END, id
    ''');

      _logger.info('Body part names fetched for IDs: ${bodyPartIds.length} items');

      if (maps.isEmpty) {
        _logger.warning('No body parts found for IDs: $bodyPartIds');
        return List.filled(bodyPartIds.length, 'Bilinmiyor');
      }

      // ID'lere göre sıralı liste oluştur
      final nameMap = {for (var map in maps) map['id'] as int: map['name'] as String};
      return bodyPartIds.map((id) => nameMap[id] ?? 'Bilinmiyor').toList();

    } catch (e) {
      _logger.severe('Error getting body part names by IDs', e);
      return List.filled(bodyPartIds.length, 'Bilinmiyor');
    }
  }

  Future<List<BodyParts>> getMainBodyParts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'BodyParts',
        where: 'parentBodyPartId IS NULL',
      );
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting main body parts', e);
      return [];
    }
  }

  Future<BodyParts?> getBodyPartById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'BodyParts',
        where: 'Id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return BodyParts.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      _logger.severe('Error getting body part by id', e);
      return null;
    }
  }

  Future<List<BodyParts>> getBodyPartsByParentId(int? parentId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'BodyParts',
        where: parentId == null ? 'parentBodyPartId IS NULL' : 'parentBodyPartId = ?',
        whereArgs: parentId == null ? [] : [parentId],
      );
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting body parts by parent id', e);
      return [];
    }
  }

  Future<List<BodyParts>> searchBodyPartsByName(String name) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'BodyParts',
        where: 'Name LIKE ?',
        whereArgs: ['%$name%'],
      );
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error searching body parts by name', e);
      return [];
    }
  }

  Future<List<BodyParts>> getSecondaryTargetedBodyPartsForExercise(int exerciseId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.* FROM BodyParts b
      INNER JOIN ExerciseTargetedBodyParts etb ON b.id = etb.bodyPartId
      WHERE etb.exerciseId = ? AND etb.isPrimary = 0
    ''', [exerciseId]);
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting secondary targeted body parts for exercise', e);
      return [];
    }
  }

  Future<List<BodyParts>> getCompoundBodyParts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'BodyParts',
        where: 'isCompound = 1',
      );
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting compound body parts', e);
      return [];
    }
  }

  Future<List<BodyParts>> getTargetedBodyPartsWithPercentage(int routineId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.*, rtb.targetPercentage 
      FROM BodyParts b
      INNER JOIN RoutineTargetedBodyParts rtb ON b.id = rtb.bodyPartId
      WHERE rtb.routineId = ?
      ORDER BY rtb.targetPercentage DESC
    ''', [routineId]);
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting targeted body parts with percentage', e);
      return [];
    }
  }

  Future<List<BodyParts>> getRelatedBodyParts(int bodyPartId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT b.* 
      FROM BodyParts b
      LEFT JOIN PartTargetedBodyParts ptb ON b.id = ptb.bodyPartId
      WHERE b.parentBodyPartId = (
        SELECT parentBodyPartId FROM BodyParts WHERE id = ?
      )
      OR b.id IN (
        SELECT bodyPartId FROM PartTargetedBodyParts 
        WHERE partId IN (
          SELECT partId FROM PartTargetedBodyParts WHERE bodyPartId = ?
        )
      )
    ''', [bodyPartId, bodyPartId]);
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting related body parts', e);
      return [];
    }
  }

  Future<List<BodyParts>> getCompoundExercises() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'BodyParts',
        where: 'isCompound = 1',
      );
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting compound exercises', e);
      return [];
    }
  }







  ///routines ///routines ///routines ///routines
  ///routines ///routines ///routines ///routines


  Future<List<BodyParts>> getTargetedBodyPartsForRoutine(int routineId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.*, rtb.targetPercentage 
      FROM BodyParts b
      INNER JOIN RoutineTargetedBodyParts rtb ON b.id = rtb.bodyPartId
      WHERE rtb.routineId = ?
    ''', [routineId]);
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting targeted body parts for routine', e);
      return [];
    }
  }

  Future<List<Routines>> getRoutinesByBodyPartAndWorkoutType(
      int bodyPartId,
      int workoutTypeId,
      ) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT DISTINCT r.*, 
          rtb.targetPercentage,
          GROUP_CONCAT(re.exerciseId) as exerciseIds
        FROM Routines r
        INNER JOIN RoutineTargetedBodyParts rtb ON r.id = rtb.routineId
        LEFT JOIN RoutineExercises re ON r.id = re.routineId
        WHERE rtb.bodyPartId = ? 
        AND r.workoutTypeId = ?
        AND rtb.targetPercentage >= 50
        GROUP BY r.id
        ORDER BY rtb.targetPercentage DESC, r.difficulty ASC
      ''', [bodyPartId, workoutTypeId]);

        return Future.wait(maps.map((map) async {
          final targetedBodyParts = await txn.query(
              'RoutineTargetedBodyParts',
              where: 'routineId = ?',
              whereArgs: [map['id']]
          );

          return Routines.fromMap({
            ...map,
            'routineExercises': map['exerciseIds']?.split(',')
                .map((e) => {'exerciseId': int.parse(e)}).toList() ?? [],
            'targetedBodyParts': targetedBodyParts
          });
        }));
      });
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutinesByBodyPartAndWorkoutType', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Routines>> getRoutinesByMainTargetedBodyPart(int bodyPartId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT DISTINCT r.*, 
          rtb.targetPercentage,
          GROUP_CONCAT(re.exerciseId) as exerciseIds
        FROM Routines r
        INNER JOIN RoutineTargetedBodyParts rtb ON r.id = rtb.routineId
        LEFT JOIN RoutineExercises re ON r.id = re.routineId
        WHERE rtb.bodyPartId = ? 
        AND rtb.isPrimary = 1
        GROUP BY r.id
        ORDER BY rtb.targetPercentage DESC
      ''', [bodyPartId]);

        return Future.wait(maps.map((map) async {
          final targetedBodyParts = await txn.query(
              'RoutineTargetedBodyParts',
              where: 'routineId = ?',
              whereArgs: [map['id']]
          );

          return Routines.fromMap({
            ...map,
            'routineExercises': map['exerciseIds']?.split(',')
                .map((e) => {'exerciseId': int.parse(e)}).toList() ?? [],
            'targetedBodyParts': targetedBodyParts
          });
        }));
      });
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutinesByMainTargetedBodyPart', e, stackTrace);
      rethrow;
    }
  }

  Future<RoutineFrequency?> getRoutineFrequency(int routineId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'RoutineFrequency',
      where: 'routineId = ?',
      whereArgs: [routineId],
    );

    if (maps.isNotEmpty) {
      return RoutineFrequency.fromMap(maps.first);
    }
    return null;
  }

  Future<List<int>> getExerciseIdsForRoutine(int routineId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'RoutineExercises',
        columns: ['exerciseId'],
        where: 'routineId = ?',
        whereArgs: [routineId],
        orderBy: 'orderIndex ASC', // Egzersizleri sıralı getirmek için eklendi
      );
      return List.generate(maps.length, (i) => maps[i]['exerciseId'] as int);
    } catch (e) {
      _logger.severe('Error getting exercise ids for routine', e);
      return [];
    }
  }

  Future<RoutineExercises?> getRoutineExerciseById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'RoutineExercises',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return RoutineExercises.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      _logger.severe('Error getting routine exercise by id', e);
      return null;
    }
  }

  Future<List<RoutineExercises>> getRoutineExercisesByExerciseId(int exerciseId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'RoutineExercises',
        where: 'exerciseId = ?',
        whereArgs: [exerciseId],
        orderBy: 'orderIndex ASC', // Sıralama eklendi
      );
      return List.generate(maps.length, (i) => RoutineExercises.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting routine exercises by exercise id', e);
      return [];
    }
  }

  Future<List<RoutineExercises>> getRoutineExercisesByRoutineId(int routineId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'RoutineExercises',
        where: 'routineId = ?',
        whereArgs: [routineId],
      );
      return List.generate(maps.length, (i) => RoutineExercises.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting routine exercises by routine id', e);
      return [];
    }
  }

  Future<List<RoutineTargetedBodyParts>> getRoutineTargetedBodyParts(int routineId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'RoutineTargetedBodyParts',
        where: 'routineId = ?',
        whereArgs: [routineId],
        orderBy: 'targetPercentage DESC', // Hedef yüzdesine göre sıralama eklendi
      );
      return List.generate(maps.length, (i) => RoutineTargetedBodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting routine targeted body parts', e);
      return [];
    }
  }

  Future<List<RoutineTargetedBodyParts>> getRoutinesForBodyPart(int bodyPartId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'RoutineTargetedBodyParts',
        where: 'bodyPartId = ?',
        whereArgs: [bodyPartId],
        orderBy: 'targetPercentage DESC', // Hedef yüzdesine göre sıralama eklendi
      );
      return List.generate(maps.length, (i) => RoutineTargetedBodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting routines for body part', e);
      return [];
    }
  }


  Future<Routines?> getRoutineById(int id) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT r.*, GROUP_CONCAT(re.exerciseId) as exerciseIds
        FROM Routines r
        LEFT JOIN RoutineExercises re ON r.id = re.routineId
        WHERE r.id = ?
        GROUP BY r.id
      ''', [id]);

        if (maps.isEmpty) return null;

        final targetedBodyParts = await txn.query(
            'RoutineTargetedBodyParts',
            where: 'routineId = ?',
            whereArgs: [id]
        );

        return Routines.fromMap({
          ...maps.first,
          'routineExercises': maps.first['exerciseIds']?.split(',')
              .map((e) => {'exerciseId': int.parse(e)}).toList() ?? [],
          'targetedBodyParts': targetedBodyParts
        });
      });
    } catch (e) {
      _logger.severe('Error getting routine by id', e);
      return null;
    }
  }




  Future<List<Routines>> getRoutinesByName(String name) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT r.*, 
          GROUP_CONCAT(re.exerciseId) as exerciseIds
        FROM Routines r
        LEFT JOIN RoutineExercises re ON r.id = re.routineId
        WHERE r.name = ?
        GROUP BY r.id
      ''', [name]);

        return Future.wait(maps.map((map) async {
          final targetedBodyParts = await txn.query(
              'RoutineTargetedBodyParts',
              where: 'routineId = ?',
              whereArgs: [map['id']]
          );

          return Routines.fromMap({
            ...map,
            'routineExercises': map['exerciseIds']?.split(',')
                .map((e) => {'exerciseId': int.parse(e)}).toList() ?? [],
            'targetedBodyParts': targetedBodyParts
          });
        }));
      });
    } catch (e) {
      _logger.severe('Error getting routines by name', e);
      return [];
    }
  }

  Future<List<Routines>> getRoutinesByPartialName(String partialName) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Routines',
        where: 'Name LIKE ?',
        whereArgs: ['%$partialName%'],
      );
      List<Routines> routines = [];
      for (var map in maps) {
        List<RoutineExercises> routineExercises = await getRoutineExercisesByRoutineId(map['Id']);
        routines.add(Routines.fromMap({...map, 'routineExercises': routineExercises}));
      }
      return routines;
    } catch (e) {
      _logger.severe('Error getting routines by partial name', e);
      return [];
    }
  }

  Future<List<Routines>> getRoutinesByBodyPart(int bodyPartId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT DISTINCT r.*, rtb.targetPercentage,
        GROUP_CONCAT(re.exerciseId) as exerciseIds
        FROM Routines r
        INNER JOIN RoutineTargetedBodyParts rtb ON r.id = rtb.routineId
        LEFT JOIN RoutineExercises re ON r.id = re.routineId
        WHERE rtb.bodyPartId = ?
        GROUP BY r.id
        ORDER BY rtb.targetPercentage DESC
      ''', [bodyPartId]);

        return Future.wait(maps.map((map) async {
          final targetedBodyParts = await txn.query(
              'RoutineTargetedBodyParts',
              where: 'routineId = ?',
              whereArgs: [map['id']]
          );

          return Routines.fromMap({
            ...map,
            'routineExercises': map['exerciseIds']?.split(',').map((e) => {'exerciseId': int.parse(e)}).toList() ?? [],
            'targetedBodyParts': targetedBodyParts
          });
        }));
      });
    } catch (e) {
      _logger.severe('Error getting routines by body part', e);
      return [];
    }
  }

  Future<List<Routines>> getRoutinesByWorkoutType(int workoutTypeId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT r.*, 
          GROUP_CONCAT(re.exerciseId) as exerciseIds
        FROM Routines r
        LEFT JOIN RoutineExercises re ON r.id = re.routineId
        WHERE r.workoutTypeId = ?
        GROUP BY r.id
      ''', [workoutTypeId]);

        return Future.wait(maps.map((map) async {
          final targetedBodyParts = await txn.query(
              'RoutineTargetedBodyParts',
              where: 'routineId = ?',
              whereArgs: [map['id']]
          );

          return Routines.fromMap({
            ...map,
            'routineExercises': map['exerciseIds']?.split(',')
                .map((e) => {'exerciseId': int.parse(e)}).toList() ?? [],
            'targetedBodyParts': targetedBodyParts
          });
        }));
      });
    } catch (e) {
      _logger.severe('Error getting routines by workout type', e);
      return [];
    }
  }

  Future<List<Routines>> getRoutinesAlphabetically() async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT r.*, 
          GROUP_CONCAT(re.exerciseId) as exerciseIds
        FROM Routines r
        LEFT JOIN RoutineExercises re ON r.id = re.routineId
        GROUP BY r.id
        ORDER BY r.name ASC
      ''');

        return Future.wait(maps.map((map) async {
          final targetedBodyParts = await txn.query(
              'RoutineTargetedBodyParts',
              where: 'routineId = ?',
              whereArgs: [map['id']]
          );

          return Routines.fromMap({
            ...map,
            'routineExercises': map['exerciseIds']?.split(',')
                .map((e) => {'exerciseId': int.parse(e)}).toList() ?? [],
            'targetedBodyParts': targetedBodyParts
          });
        }));
      });
    } catch (e) {
      _logger.severe('Error getting routines alphabetically', e);
      return [];
    }
  }

  Future<List<Routines>> getRandomRoutines(int count) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT r.*, 
          GROUP_CONCAT(re.exerciseId) as exerciseIds
        FROM Routines r
        LEFT JOIN RoutineExercises re ON r.id = re.routineId
        GROUP BY r.id
        ORDER BY RANDOM()
        LIMIT ?
      ''', [count]);

        return Future.wait(maps.map((map) async {
          final targetedBodyParts = await txn.query(
              'RoutineTargetedBodyParts',
              where: 'routineId = ?',
              whereArgs: [map['id']]
          );

          return Routines.fromMap({
            ...map,
            'routineExercises': map['exerciseIds']?.split(',')
                .map((e) => {'exerciseId': int.parse(e)}).toList() ?? [],
            'targetedBodyParts': targetedBodyParts
          });
        }));
      });
    } catch (e) {
      _logger.severe('Error getting random routines', e);
      return [];
    }
  }

  Future<Map<int, int>> getTargetPercentagesForRoutine(int routineId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
          'RoutineTargetedBodyParts',
          columns: ['bodyPartId', 'targetPercentage'],
          where: 'routineId = ?',
          whereArgs: [routineId],
          orderBy: 'targetPercentage DESC'
      );

      return Map.fromEntries(
          maps.map((m) => MapEntry(m['bodyPartId'] as int, m['targetPercentage'] as int))
      );
    } catch (e) {
      _logger.severe('Error getting target percentages', e);
      return {};
    }
  }



  Future<List<Routines>> getRoutinesByTargetPercentage(int bodyPartId, int minPercentage) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT r.*, rtb.targetPercentage 
      FROM Routines r
      INNER JOIN RoutineTargetedBodyParts rtb ON r.id = rtb.routineId
      WHERE rtb.bodyPartId = ? AND rtb.targetPercentage >= ?
      ORDER BY rtb.targetPercentage DESC, r.difficulty ASC
    ''', [bodyPartId, minPercentage]);

      List<Routines> routines = [];
      for (var map in maps) {
        // Rutin için egzersizleri al
        final routineExercises = await db.query(
            'RoutineExercises',
            where: 'routineId = ?',
            whereArgs: [map['id']],
            orderBy: 'orderIndex ASC'
        );

        // Hedef vücut bölümlerini al
        final targetedBodyParts = await db.query(
            'RoutineTargetedBodyParts',
            where: 'routineId = ?',
            whereArgs: [map['id']]
        );

        routines.add(Routines.fromMap({
          ...map,
          'routineExercises': routineExercises,
          'targetedBodyParts': targetedBodyParts
        }));
      }
      return routines;
    } catch (e) {
      _logger.severe('Error getting routines by target percentage', e);
      return [];
    }
  }

  Future<List<Routines>> getRoutinesByDifficulty(int difficulty) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT r.*, 
          GROUP_CONCAT(re.exerciseId) as exerciseIds
        FROM Routines r
        LEFT JOIN RoutineExercises re ON r.id = re.routineId
        WHERE r.difficulty = ?
        GROUP BY r.id
      ''', [difficulty]);

        return Future.wait(maps.map((map) async {
          final targetedBodyParts = await txn.query(
              'RoutineTargetedBodyParts',
              where: 'routineId = ?',
              whereArgs: [map['id']]
          );

          return Routines.fromMap({
            ...map,
            'routineExercises': map['exerciseIds']?.split(',')
                .map((e) => {'exerciseId': int.parse(e)}).toList() ?? [],
            'targetedBodyParts': targetedBodyParts
          });
        }));
      });
    } catch (e) {
      _logger.severe('Error getting routines by difficulty', e);
      return [];
    }
  }

  Future<List<Routines>> getRoutinesByExerciseCount(int minCount, int maxCount) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT r.*, 
          GROUP_CONCAT(re.exerciseId) as exerciseIds,
          COUNT(re.exerciseId) as exerciseCount
        FROM Routines r
        LEFT JOIN RoutineExercises re ON r.id = re.routineId
        GROUP BY r.id
        HAVING exerciseCount BETWEEN ? AND ?
      ''', [minCount, maxCount]);

        return Future.wait(maps.map((map) async {
          final targetedBodyParts = await txn.query(
              'RoutineTargetedBodyParts',
              where: 'routineId = ?',
              whereArgs: [map['id']]
          );

          return Routines.fromMap({
            ...map,
            'routineExercises': map['exerciseIds']?.split(',')
                .map((e) => {'exerciseId': int.parse(e)}).toList() ?? [],
            'targetedBodyParts': targetedBodyParts
          });
        }));
      });
    } catch (e) {
      _logger.severe('Error getting routines by exercise count', e);
      return [];
    }
  }

  Future<List<Routines>> getRoutinesContainingExercises(List<int> exerciseIds) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT r.*, 
          GROUP_CONCAT(re.exerciseId) as exerciseIds
        FROM Routines r
        INNER JOIN RoutineExercises re ON r.id = re.routineId
        WHERE re.exerciseId IN (${exerciseIds.join(',')})
        GROUP BY r.id
      ''');

        return Future.wait(maps.map((map) async {
          final targetedBodyParts = await txn.query(
              'RoutineTargetedBodyParts',
              where: 'routineId = ?',
              whereArgs: [map['id']]
          );

          return Routines.fromMap({
            ...map,
            'routineExercises': map['exerciseIds']?.split(',')
                .map((e) => {'exerciseId': int.parse(e)}).toList() ?? [],
            'targetedBodyParts': targetedBodyParts
          });
        }));
      });
    } catch (e) {
      _logger.severe('Error getting routines containing exercises', e);
      return [];
    }
  }


// Yardımcı metod
  Map<String, dynamic> _processRoutineMap(Map<String, dynamic> map) {
    final exerciseIds = map['exerciseIds']?.toString().split(',') ?? [];
    final targetedParts = map['targetedBodyParts']?.toString().split(',') ?? [];

    return {
      ...map,
      'routineExercises': exerciseIds.where((e) => e.isNotEmpty)
          .map((e) => {'exerciseId': int.parse(e)}).toList(),
      'targetedBodyParts': targetedParts.where((t) => t.isNotEmpty).map((t) {
        final parts = t.split(':');
        return {
          'bodyPartId': int.parse(parts[0]),
          'targetPercentage': int.parse(parts[1]),
        };
      }).toList(),
    };
  }




  /// PartsRt işlemleri  /// PartsRt işlemleri  /// PartsRt işlemleri
  /// PartsRt işlemleri  /// PartsRt işlemleri  /// PartsRt işlemleri

  Future<List<PartTargetedBodyParts>> getPartTargets(int partId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT ptb.*, b.name as bodyPartName
        FROM PartTargetedBodyParts ptb
        LEFT JOIN BodyParts b ON ptb.bodyPartId = b.id
        WHERE ptb.partId = ?
        ORDER BY ptb.targetPercentage DESC, ptb.isPrimary DESC
      ''', [partId]);

        return List.generate(maps.length, (i) =>
            PartTargetedBodyParts.fromMap(maps[i])
        );
      });
    } catch (e) {
      _logger.severe('Error getting part targets', e);
      return [];
    }
  }

  Future<List<Parts>> getPartsByTargetPercentage(int bodyPartId, int minPercentage) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT p.*, 
          GROUP_CONCAT(pe.exerciseId) as exerciseIds,
          GROUP_CONCAT(ptb.bodyPartId) as targetedBodyPartIds,
          ptb.targetPercentage
        FROM Parts p
        INNER JOIN PartTargetedBodyParts ptb ON p.id = ptb.partId
        LEFT JOIN PartExercises pe ON p.id = pe.partId
        WHERE ptb.bodyPartId = ? AND ptb.targetPercentage >= ?
        GROUP BY p.id
        ORDER BY ptb.targetPercentage DESC
      ''', [bodyPartId, minPercentage]);

        return _generatePartsFromMaps(maps);
      });
    } catch (e) {
      _logger.severe('Error getting parts by target percentage', e);
      return [];
    }
  }

  Future<List<Parts>> getPartsWithExercise(int exerciseId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT p.*, 
          GROUP_CONCAT(pe.exerciseId) as exerciseIds,
          GROUP_CONCAT(ptb.bodyPartId) as targetedBodyPartIds
        FROM Parts p
        INNER JOIN PartExercises pe ON p.id = pe.partId
        LEFT JOIN PartTargetedBodyParts ptb ON p.id = ptb.partId
        WHERE pe.exerciseId = ?
        GROUP BY p.id
        ORDER BY pe.orderIndex ASC
      ''', [exerciseId]);

        return List.generate(maps.length, (i) {
          List<dynamic> exerciseIds = [];
          List<dynamic> targetedBodyPartIds = [];

          if (maps[i]['exerciseIds'] != null) {
            exerciseIds = maps[i]['exerciseIds']
                .toString()
                .split(',')
                .map((e) => int.parse(e))
                .toList();
          }

          if (maps[i]['targetedBodyPartIds'] != null) {
            targetedBodyPartIds = maps[i]['targetedBodyPartIds']
                .toString()
                .split(',')
                .map((e) => int.parse(e))
                .toList();
          }

          return Parts.fromMap(maps[i], exerciseIds);
        });
      });
    } catch (e) {
      _logger.severe('Error getting parts with exercise', e);
      return [];
    }
  }

  Future<List<BodyParts>> getTargetedBodyPartsForPart(int partId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT b.*, 
          ptb.isPrimary, 
          ptb.targetPercentage,
          COUNT(pe.exerciseId) as exerciseCount
        FROM BodyParts b
        INNER JOIN PartTargetedBodyParts ptb ON b.id = ptb.bodyPartId
        LEFT JOIN PartExercises pe ON ptb.partId = pe.partId
        WHERE ptb.partId = ?
        GROUP BY b.id
        ORDER BY ptb.targetPercentage DESC, ptb.isPrimary DESC
      ''', [partId]);

        return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
      });
    } catch (e) {
      _logger.severe('Error getting targeted body parts for part', e);
      return [];
    }
  }

  Future<PartFrequency?> getPartFrequency(int partId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT pf.*, COUNT(pe.exerciseId) as totalExercises
      FROM PartFrequency pf
      LEFT JOIN PartExercises pe ON pf.partId = pe.partId
      WHERE pf.partId = ?
      GROUP BY pf.id
    ''', [partId]);

      if (maps.isNotEmpty) {
        return PartFrequency.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      _logger.severe('Error getting part frequency', e);
      return null;
    }
  }

  Future<List<PartTargetedBodyParts>> getPartTargetedBodyParts(int partId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'PartTargetedBodyParts',
        where: 'partId = ?',
        whereArgs: [partId],
      );
      return List.generate(maps.length, (i) => PartTargetedBodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting part targeted body parts', e);
      return [];
    }
  }

  Future<List<String>> getPartTargetedBodyPartsName(int partId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT b.name
        FROM BodyParts b
        INNER JOIN PartTargetedBodyParts ptb ON b.id = ptb.bodyPartId
        WHERE ptb.partId = ?
        ORDER BY ptb.targetPercentage DESC
      ''', [partId]);

        return maps.map((map) => map['name'] as String).toList();
      });
    } catch (e) {
      _logger.severe('Error getting part targeted body parts names', e);
      return [];
    }
  }

  Future<List<PartTargetedBodyParts>> getPrimaryTargetedPartsForBodyPart(int bodyPartId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'PartTargetedBodyParts',
        where: 'bodyPartId = ? AND isPrimary = 1',
        whereArgs: [bodyPartId],
      );
      return List.generate(maps.length, (i) => PartTargetedBodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting primary targeted parts', e);
      return [];
    }
  }

  Future<List<PartTargetedBodyParts>> getSecondaryTargetedPartsForBodyPart(int bodyPartId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'PartTargetedBodyParts',
        where: 'bodyPartId = ? AND isPrimary = 0',
        whereArgs: [bodyPartId],
      );
      return List.generate(maps.length, (i) => PartTargetedBodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting secondary targeted parts', e);
      return [];
    }
  }


  Future<Parts?> getPartById(int id) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT p.*, 
          GROUP_CONCAT(DISTINCT pe.exerciseId) as exerciseIds,
          GROUP_CONCAT(DISTINCT ptb.bodyPartId || '|' || 
            ptb.isPrimary || '|' || ptb.targetPercentage) as targetedBodyParts
        FROM Parts p
        LEFT JOIN PartExercises pe ON p.id = pe.partId
        LEFT JOIN PartTargetedBodyParts ptb ON p.id = ptb.partId
        WHERE p.id = ?
        GROUP BY p.id
      ''', [id]);

        if (maps.isEmpty) return null;
        return _generatePartsFromMaps(maps).first;
      });
    } catch (e) {
      _logger.severe('Error getting part by id', e);
      throw Exception('Part alınırken hata oluştu: $e');
    }
  }

  List<Parts> _generatePartsFromMaps(List<Map<String, dynamic>> maps) {
    return maps.map((map) {
      // Egzersiz ID'lerini parse et
      final exerciseIds = map['exerciseIds'] != null
          ? (map['exerciseIds'] as String)
          .split(',')
          .where((e) => e.isNotEmpty)
          .map((e) => int.parse(e))
          .toList()
          : <int>[];

      // Hedef kas grupları ID'lerini parse et
      final targetedBodyPartIds = map['targetedBodyParts'] != null
          ? (map['targetedBodyParts'] as String)
          .split(',')
          .where((e) => e.isNotEmpty)
          .map((data) {
        final parts = data.split('|');
        return int.parse(parts[0]); // Sadece bodyPartId'yi al
      })
          .toList()
          : <int>[];

      return Parts(
        id: map['id'] as int,
        name: map['name'] as String,
        targetedBodyPartIds: targetedBodyPartIds,
        setType: SetType.values[map['setType'] as int],
        additionalNotes: map['additionalNotes'] as String? ?? '',
        difficulty: map['difficulty'] as int? ?? 1,
        exerciseIds: exerciseIds,
        isFavorite: false,
        isCustom: false,
      );
    }).toList();
  }

  Future<List<Parts>> getPartsByBodyPart(int bodyPartId) async {
    try {
      final db = await database;

      // Önce Parts tablosundan verileri al
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, GROUP_CONCAT(pe.exerciseId) as exerciseIds 
      FROM Parts p
      INNER JOIN PartTargetedBodyParts ptb ON p.id = ptb.partId
      LEFT JOIN PartExercises pe ON p.id = pe.partId
      WHERE ptb.bodyPartId = ?
      GROUP BY p.id
    ''', [bodyPartId]);

      // Her bir part için exerciseIds listesini oluştur ve Parts nesnesini döndür
      return List.generate(maps.length, (i) {
        List<int> exerciseIds = [];
        if (maps[i]['exerciseIds'] != null) {
          exerciseIds = maps[i]['exerciseIds']
              .toString()
              .split(',')
              .map((e) => int.parse(e))
              .toList();
        }
        return Parts.fromMap(maps[i], exerciseIds);
      });
    } catch (e) {
      _logger.severe('Error getting parts by body part', e);
      return [];
    }
  }

  Future<List<Parts>> getPartsBySetType(SetType setType) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> partMaps = await db.query(
        'Parts',
        where: 'SetType = ?',
        whereArgs: [setType.index],
      );
      final List<Map<String, dynamic>> partExerciseMaps = await db.query('PartExercises');
      final List<PartExercise> partExercises = partExerciseMaps.map((map) => PartExercise.fromMap(map)).toList();
      return partMaps.map((map) => Parts.fromMap(map, partExercises.cast<int>())).toList();
    } catch (e) {
      print('Error getting parts by set type: $e');
      return [];
    }
  }

  Future<List<Parts>> searchPartsByName(String name) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, GROUP_CONCAT(pe.exerciseId) as exerciseIds
      FROM Parts p
      LEFT JOIN PartExercises pe ON p.id = pe.partId
      WHERE p.name LIKE ?
      GROUP BY p.id
    ''', ['%$name%']);

      return _generatePartsFromMaps(maps);
    } catch (e) {
      _logger.severe('Error searching parts by name', e);
      return [];
    }
  }

  Future<List<Parts>> getPartsSortedByName({bool ascending = true}) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> partMaps = await db.query(
        'Parts',
        orderBy: 'Name ${ascending ? 'ASC' : 'DESC'}',
      );
      final List<Map<String, dynamic>> partExerciseMaps = await db.query('PartExercises');
      final List<PartExercise> partExercises = partExerciseMaps.map((map) => PartExercise.fromMap(map)).toList();
      return partMaps.map((map) => Parts.fromMap(map, partExercises.cast<int>())).toList();
    } catch (e) {
      print('Error getting parts sorted by name: $e');
      return [];
    }
  }

  Future<List<Parts>> getPartsByDifficulty(int difficulty) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Parts',
      where: 'difficulty = ?',
      whereArgs: [difficulty],
    );

    return List.generate(maps.length, (i) {
      return Parts.fromMap(maps[i], []);  // exerciseIds'i boş liste olarak geçiyoruz
    });
  }

  Future<List<Parts>> getPartsByBodyPartId(int bodyPartId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Parts',
      where: 'bodyPartId = ?',
      whereArgs: [bodyPartId],
    );

    return List.generate(maps.length, (i) {
      return Parts.fromMap(maps[i], []);  // exerciseIds'i boş liste olarak geçiyoruz
    });
  }

  Future<List<PartExercise>> getAllPartExercises() async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT pe.*, p.name as partName, e.name as exerciseName
        FROM PartExercises pe
        LEFT JOIN Parts p ON pe.partId = p.id
        LEFT JOIN Exercises e ON pe.exerciseId = e.id
        ORDER BY pe.orderIndex ASC
      ''');

        return List.generate(maps.length, (i) => PartExercise.fromMap(maps[i]));
      });
    } catch (e) {
      _logger.severe('Error getting all part exercises', e);
      return [];
    }
  }

  Future<PartExercise?> getPartExerciseById(int id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'PartExercises',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return PartExercise.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting part exercise by id: $e');
      return null;
    }
  }

  Future<List<PartExercise>> getPartExercisesByPartId(int partId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT pe.*, e.name as exerciseName
        FROM PartExercises pe
        LEFT JOIN Exercises e ON pe.exerciseId = e.id
        WHERE pe.partId = ?
        ORDER BY pe.orderIndex ASC
      ''', [partId]);

        return List.generate(maps.length, (i) => PartExercise.fromMap(maps[i]));
      });
    } catch (e) {
      _logger.severe('Error getting part exercises by part id', e);
      return [];
    }
  }

  Future<List<PartExercise>> getPartExercisesByExerciseId(int exerciseId) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'PartExercises',
        where: 'exerciseId = ?',
        whereArgs: [exerciseId],
      );
      return List.generate(maps.length, (i) => PartExercise.fromMap(maps[i]));
    } catch (e) {
      print('Error getting part exercises by exercise id: $e');
      return [];
    }
  }

  Future<List<int>> getExerciseIdsForPart(int partId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT exerciseId 
        FROM PartExercises 
        WHERE partId = ? 
        ORDER BY orderIndex ASC
      ''', [partId]);

        return maps.map((map) => map['exerciseId'] as int).toList();
      });
    } catch (e) {
      _logger.severe('Error getting exercise ids for part', e);
      return [];
    }
  }

  Future<List<int>> getPartIdsForExercise(int exerciseId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT DISTINCT partId 
        FROM PartExercises 
        WHERE exerciseId = ?
      ''', [exerciseId]);

        return maps.map((map) => map['partId'] as int).toList();
      });
    } catch (e) {
      _logger.severe('Error getting part ids for exercise', e);
      return [];
    }
  }

  Future<int> getPartExercisesCount() async {
    final db = await database;
    try {
      final result = await db.rawQuery('SELECT COUNT(*) FROM PartExercises');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting part exercises count: $e');
      return 0;
    }

  }

  Future<void> updatePartExercisesOrder(int partId, List<PartExercise> newOrder) async {
    final db = await database;
    final batch = db.batch();

    try {
      // Önce mevcut sıralamayı temizle
      await db.delete(
        'PartExercises',
        where: 'partId = ?',
        whereArgs: [partId],
      );

      // Yeni sıralamayı ekle
      for (var exercise in newOrder) {
        batch.insert('PartExercises', {
          'partId': partId,
          'exerciseId': exercise.exerciseId,
          'orderIndex': exercise.orderIndex,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Egzersiz sıralaması güncellenirken hata: $e');
    }
  }

  Future<int?> getDifficultyForPart(int partId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Parts',
      columns: ['difficulty'],
      where: 'id = ?',
      whereArgs: [partId],
    );

    if (maps.isNotEmpty) {
      return maps.first['difficulty'] as int?;
    }
    return null;
  }

  Future<List<Parts>> getPartsByWorkoutType(int workoutTypeId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT DISTINCT p.*, 
          GROUP_CONCAT(pe.exerciseId) as exerciseIds,
          GROUP_CONCAT(ptb.bodyPartId) as targetedBodyPartIds
        FROM Parts p
        INNER JOIN PartExercises pe ON p.id = pe.partId
        INNER JOIN Exercises e ON pe.exerciseId = e.id
        LEFT JOIN PartTargetedBodyParts ptb ON p.id = ptb.partId
        WHERE e.workoutTypeId = ?
        GROUP BY p.id
        ORDER BY p.name ASC
      ''', [workoutTypeId]);

        final parts = _generatePartsFromMaps(maps);
        _logger.info('Fetched ${parts.length} parts for workout type: $workoutTypeId');
        return parts;
      });
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartsByWorkoutType', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> getPartsWithTargetedBodyParts(int bodyPartId, {bool isPrimary = true}) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT p.*, 
          GROUP_CONCAT(pe.exerciseId) as exerciseIds,
          GROUP_CONCAT(ptb.bodyPartId) as targetedBodyPartIds,
          MAX(ptb.targetPercentage) as maxTargetPercentage
        FROM Parts p
        INNER JOIN PartTargetedBodyParts ptb ON p.id = ptb.partId
        LEFT JOIN PartExercises pe ON p.id = pe.partId
        WHERE ptb.bodyPartId = ? AND ptb.isPrimary = ?
        GROUP BY p.id
        ORDER BY maxTargetPercentage DESC
      ''', [bodyPartId, isPrimary ? 1 : 0]);

        return _generatePartsFromMaps(maps);
      });
    } catch (e) {
      _logger.severe('Error getting parts with targeted body parts', e);
      return [];
    }
  }


  Future<List<Parts>> getPartsWithTargetPercentage(int bodyPartId, int minPercentage) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT p.*, 
          GROUP_CONCAT(pe.exerciseId) as exerciseIds,
          GROUP_CONCAT(ptb.bodyPartId) as targetedBodyPartIds,
          ptb.targetPercentage
        FROM Parts p
        INNER JOIN PartTargetedBodyParts ptb ON p.id = ptb.partId
        LEFT JOIN PartExercises pe ON p.id = pe.partId
        WHERE ptb.bodyPartId = ? AND ptb.targetPercentage >= ?
        GROUP BY p.id
        ORDER BY ptb.targetPercentage DESC
      ''', [bodyPartId, minPercentage]);

        return _generatePartsFromMaps(maps);
      });
    } catch (e) {
      _logger.severe('Error getting parts with target percentage', e);
      return [];
    }
  }

  Future<List<Parts>> getPartsWithMultipleTargets() async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT p.*, 
          GROUP_CONCAT(pe.exerciseId) as exerciseIds,
          GROUP_CONCAT(DISTINCT ptb.bodyPartId) as targetedBodyPartIds,
          COUNT(DISTINCT ptb.bodyPartId) as targetCount
        FROM Parts p
        INNER JOIN PartTargetedBodyParts ptb ON p.id = ptb.partId
        LEFT JOIN PartExercises pe ON p.id = pe.partId
        GROUP BY p.id
        HAVING targetCount > 1
        ORDER BY targetCount DESC
      ''');

        return _generatePartsFromMaps(maps);
      });
    } catch (e) {
      _logger.severe('Error getting parts with multiple targets', e);
      return [];
    }
  }

  Future<Map<int, List<Parts>>> getPartsGroupedByBodyPart() async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        // Ana vücut bölümlerini al (isCompound = 1 olanlar)
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        WITH MainBodyParts AS (
          SELECT id, name
          FROM BodyParts
          WHERE parentBodyPartId IS NULL
          ORDER BY id
        )
        SELECT 
          mbp.id as mainBodyPartId,
          p.*,
          GROUP_CONCAT(DISTINCT pe.exerciseId) as exerciseIds,
          ptb.isPrimary,
          ptb.targetPercentage
        FROM MainBodyParts mbp
        LEFT JOIN PartTargetedBodyParts ptb ON ptb.bodyPartId = mbp.id
        LEFT JOIN Parts p ON ptb.partId = p.id
        LEFT JOIN PartExercises pe ON p.id = pe.partId
        WHERE ptb.isPrimary = 1
        GROUP BY mbp.id, p.id
        HAVING p.id IS NOT NULL
        ORDER BY 
          mbp.id ASC,
          p.difficulty DESC
        ''');

        if (maps.isEmpty) {
          _logger.warning('Hiç program bulunamadı');
          return {};
        }

        // Sonuçları grupla
        final Map<int, List<Parts>> groupedParts = {};
        for (var map in maps) {
          final mainBodyPartId = map['mainBodyPartId'] as int;

          // Egzersiz ID'lerini parse et
          final exerciseIds = map['exerciseIds']?.toString()
              .split(',')
              .where((e) => e.isNotEmpty)
              .map((e) => int.parse(e))
              .toList() ?? [];

          final part = Parts.fromMap(map, exerciseIds);

          groupedParts.putIfAbsent(mainBodyPartId, () => []).add(part);
        }

        _logger.info('${groupedParts.length} ana vücut bölümü için programlar getirildi');
        return groupedParts;
      });
    } catch (e, stackTrace) {
      _logger.severe('Parts gruplandırılırken hata oluştu', e, stackTrace);
      throw Exception('Veri tabanı hatası: $e');
    }
  }

  Future<List<Parts>> getPartsWithExerciseCount(int minCount, int maxCount) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT p.*, 
          GROUP_CONCAT(pe.exerciseId) as exerciseIds,
          GROUP_CONCAT(ptb.bodyPartId) as targetedBodyPartIds,
          COUNT(pe.exerciseId) as exerciseCount
        FROM Parts p
        LEFT JOIN PartExercises pe ON p.id = pe.partId
        LEFT JOIN PartTargetedBodyParts ptb ON p.id = ptb.partId
        GROUP BY p.id
        HAVING exerciseCount BETWEEN ? AND ?
        ORDER BY exerciseCount DESC
      ''', [minCount, maxCount]);

        return _generatePartsFromMaps(maps);
      });
    } catch (e) {
      _logger.severe('Error getting parts with exercise count', e);
      return [];
    }
  }

  Future<List<Parts>> getRelatedParts(int partId) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT DISTINCT p.*, 
          GROUP_CONCAT(pe.exerciseId) as exerciseIds,
          GROUP_CONCAT(ptb2.bodyPartId) as targetedBodyPartIds,
          COUNT(DISTINCT ptb1.bodyPartId) as commonTargets
        FROM Parts p
        INNER JOIN PartTargetedBodyParts ptb1 ON p.id = ptb1.partId
        LEFT JOIN PartTargetedBodyParts ptb2 ON p.id = ptb2.partId
        LEFT JOIN PartExercises pe ON p.id = pe.partId
        WHERE ptb1.bodyPartId IN (
          SELECT bodyPartId 
          FROM PartTargetedBodyParts 
          WHERE partId = ?
        )
        AND p.id != ?
        GROUP BY p.id
        ORDER BY commonTargets DESC, ptb1.targetPercentage DESC
      ''', [partId, partId]);

        return _generatePartsFromMaps(maps);
      });
    } catch (e) {
      _logger.severe('Error getting related parts', e);
      return [];
    }
  }



//yardımcı
  Map<String, dynamic> _processPartMap(Map<String, dynamic> map) {
    // Egzersiz ID'lerini parse et
    final exerciseIds = map['exerciseIds']?.toString().split(',')
        .where((e) => e.isNotEmpty)
        .map((e) => int.parse(e))
        .toList() ?? <int>[];

    // Hedef kas grupları bilgilerini parse et
    final targetedBodyParts = map['targetedBodyParts']?.toString().split(',')
        .where((t) => t.isNotEmpty)
        .map((t) {
      final parts = t.split(':');
      return {
        'bodyPartId': int.parse(parts[0]),
        'targetPercentage': int.parse(parts[1]),
        'isPrimary': parts[2] == '1'
      };
    }).toList() ?? [];

    return {
      ...map,
      'exerciseIds': exerciseIds,
      'targetedBodyPartIds': targetedBodyParts.map((t) => t['bodyPartId'] as int).toList(),
    };
  }




  ///workouttypes  ///workouttypes  ///workouttypes
  ///workouttypes  ///workouttypes  ///workouttypes


  Future<WorkoutTypes?> getWorkoutTypeById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'WorkoutTypes',
      where: 'Id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return WorkoutTypes.fromMap(maps.first);
    }
    return null;
  }

  Future<List<WorkoutTypes>> getAllWorkoutTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('WorkoutTypes');
    print("WorkoutTypes ham veri: $maps");
    return List.generate(maps.length, (i) => WorkoutTypes.fromMap(maps[i]));
  }

  Future<List<WorkoutTypes>> getWorkoutTypesByName(String name) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'WorkoutTypes',
        where: 'Name LIKE ?',
        whereArgs: ['%$name%'],
      );
      return List.generate(maps.length, (i) => WorkoutTypes.fromMap(maps[i]));
    } catch (e) {
      print('Error getting workout types by name: $e');
      return [];
    }
  }

  Future<int> getWorkoutTypesCount() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM WorkoutTypes')) ?? 0;}

  /// Tüm WorkoutGoals kayıtlarını getirir
  Future<List<WorkoutGoals>> getAllWorkoutGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('WorkoutGoals');
    return List.generate(maps.length, (i) => WorkoutGoals.fromMap(maps[i]));
  }

  Future<List<Exercises>> getExercisesByMainBodyPart(int mainBodyPartId) async {
    try {
      final db = await database;
      // Alt kas gruplarını bul
      final List<Map<String, dynamic>> subParts = await db.query(
        'BodyParts',
        columns: ['id'],
        where: 'parentBodyPartId = ?',
        whereArgs: [mainBodyPartId],
      );
      final List<int> subPartIds = subParts.map((e) => e['id'] as int).toList();
      if (subPartIds.isEmpty) return [];
      // Alt kas gruplarına bağlı egzersizleri getir
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT DISTINCT e.*
        FROM Exercises e
        INNER JOIN ExerciseTargetedBodyParts etb ON e.id = etb.exerciseId
        WHERE etb.bodyPartId IN (${subPartIds.join(',')})
      ''');
      return List.generate(maps.length, (i) => Exercises.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting exercises by main body part', e);
      return [];
    }
  }








}

