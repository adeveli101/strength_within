import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/BodyPart.dart';
import '../models/PartFocusRoutineExercises.dart';
import '../models/RoutineExercises.dart';
import '../models/WorkoutType.dart';
import '../models/exercises.dart';
import '../models/PartFocusRoutine.dart';
import '../models/routines.dart';
import 'package:logging/logging.dart';

final _logger = Logger('SQLProvider');

class SQLProvider {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String dbPath = join(await getDatabasesPath(), 'esek.db');
    bool dbExists = await databaseExists(dbPath);

    if (!dbExists) {
      try {
        ByteData data = await rootBundle.load(join('database', 'esek.db'));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(dbPath).writeAsBytes(bytes, flush: true);
        _logger.info("Veritabanı assets'ten kopyalandı.");
      } catch (e) {
        _logger.severe("Veritabanı kopyalama hatası", e);
        throw Exception("Veritabanı kopyalanamadı: $e");
      }
    } else {
      _logger.info("Veritabanı zaten mevcut.");
    }

    return await openDatabase(dbPath, version:1, onCreate: (db, version) async {
      await _createTables(db);
      _logger.info("Veritabanı açıldı.");
    });
  }

  Future<void> testDatabaseContent() async {
    try {
      final db = await database;
      final routines = await db.query('Routines');
      _logger.info("Routines tablosundaki kayıt sayısı: ${routines.length}");
      for (var routine in routines) {
        _logger.fine(routine.toString());
      }
    } catch (e) {
      _logger.severe("Veritabanı içerik testi hatası", e);
    }
  }

  Future<List<BodyParts>> getAllBodyParts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('BodyParts');
      _logger.fine("BodyParts ham veri: $maps");
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting all body parts', e);
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

  Future<List<BodyParts>> getBodyPartsByMainTargeted(MainTargetedBodyPart mainTargeted) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'BodyParts',
        where: 'MainTargetedBodyPart = ?',
        whereArgs: [mainTargeted.index],
      );
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting body parts by main targeted', e);
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

  Future<List<Exercises>> getAllExercises() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('Exercises');
      _logger.fine("Exercises ham veri: $maps");
      return List.generate(maps.length, (i) => Exercises.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting all exercises', e);
      return [];
    }
  }

  Future<Exercises?> getExerciseById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Exercises',
        where: 'Id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Exercises.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      _logger.severe('Error getting exercise by id', e);
      return null;
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

  Future<List<Exercises>> getExercisesByMainTargetedBodyPart(int mainTargetedBodyPartId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Exercises',
        where: 'MainTargetedBodyPartId = ?',
        whereArgs: [mainTargetedBodyPartId],
      );
      return List.generate(maps.length, (i) => Exercises.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting exercises by main targeted body part', e);
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
      );
      return List.generate(maps.length, (i) => RoutineExercises.fromMap(maps[i]));
    } catch (e) {
      _logger.severe('Error getting routine exercises by exercise id', e);
      return [];
    }
  }

  Future<List<int>> getExerciseIdsForRoutine(int routineId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'RoutineExercises',
        columns: ['exerciseId'],
        where: 'routineId = ?',
        whereArgs: [routineId],
      );
      return List.generate(maps.length, (i) => maps[i]['exerciseId'] as int);
    } catch (e) {
      _logger.severe('Error getting exercise ids for routine', e);
      return [];
    }
  }

  Future<List<Routines>> getAllRoutines() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('Routines');
      _logger.fine("Routines ham veri: $maps");
      List<Routines> routines = [];
      for (var map in maps) {
        List<RoutineExercises> routineExercises = await getRoutineExercisesByRoutineId(map['id']);
        routines.add(Routines.fromMap({...map, 'routineExercises': routineExercises}));
      }
      return routines;
    } catch (e) {
      _logger.severe('Error getting all routines', e);
      return [];
    }
  }

  Future<Routines?> getRoutineById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Routines',
        where: 'Id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        List<RoutineExercises> routineExercises = await getRoutineExercisesByRoutineId(id);
        return Routines.fromMap({...maps.first, 'routineExercises': routineExercises});
      }
      return null;
    } catch (e) {
      _logger.severe('Error getting routine by id', e);
      return null;
    }
  }

  Future<List<Routines>> getRoutinesByName(String name) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Routines',
        where: 'Name = ?',
        whereArgs: [name],
      );
      List<Routines> routines = [];
      for (var map in maps) {
        List<RoutineExercises> routineExercises = await getRoutineExercisesByRoutineId(map['Id']);
        routines.add(Routines.fromMap({...map, 'routineExercises': routineExercises}));
      }
      return routines;
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

  Future<List<Routines>> getRoutinesByMainTargetedBodyPart(int mainTargetedBodyPartId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Routines',
        where: 'MainTargetedBodyPartId = ?',
        whereArgs: [mainTargetedBodyPartId],
      );
      List<Routines> routines = [];
      for (var map in maps) {
        List<RoutineExercises> routineExercises = await getRoutineExercisesByRoutineId(map['Id']);
        routines.add(Routines.fromMap({...map, 'routineExercises': routineExercises}));
      }
      return routines;
    } catch (e) {
      _logger.severe('Error getting routines by main targeted body part', e);
      return [];
    }
  }
  Future<List<Routines>> getRoutinesByWorkoutType(int workoutTypeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Routines',
      where: 'WorkoutTypeId = ?',
      whereArgs: [workoutTypeId],
    );
    List<Routines> routines = [];
    for (var map in maps) {
      List<RoutineExercises> routineExercises = await getRoutineExercisesByRoutineId(map['Id']);
      routines.add(Routines.fromMap({...map, 'routineExercises': routineExercises}));
    }
    return routines;
  }

  Future<List<Routines>> getRoutinesByBodyPartAndWorkoutType(int mainTargetedBodyPartId, int workoutTypeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Routines',
      where: 'MainTargetedBodyPartId = ? AND WorkoutTypeId = ?',
      whereArgs: [mainTargetedBodyPartId, workoutTypeId],
    );
    List<Routines> routines = [];
    for (var map in maps) {
      List<RoutineExercises> routineExercises = await getRoutineExercisesByRoutineId(map['Id']);
      routines.add(Routines.fromMap({...map, 'routineExercises': routineExercises}));
    }
    return routines;
  }

  Future<List<Routines>> getRoutinesAlphabetically() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Routines',
      orderBy: 'Name ASC',
    );
    List<Routines> routines = [];
    for (var map in maps) {
      List<RoutineExercises> routineExercises = await getRoutineExercisesByRoutineId(map['Id']);
      routines.add(Routines.fromMap({...map, 'routineExercises': routineExercises}));
    }
    return routines;
  }

  Future<List<Routines>> getRandomRoutines(int count) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM Routines ORDER BY RANDOM() LIMIT ?',
      [count],
    );
    List<Routines> routines = [];
    for (var map in maps) {
      List<RoutineExercises> routineExercises = await getRoutineExercisesByRoutineId(map['Id']);
      routines.add(Routines.fromMap({...map, 'routineExercises': routineExercises}));
    }
    return routines;
  }

  Future<List<WorkoutTypes>> getAllWorkoutTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('WorkoutTypes');
    print("WorkoutTypes ham veri: $maps");
    return List.generate(maps.length, (i) => WorkoutTypes.fromMap(maps[i]));
  }

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

  Future<int> getWorkoutTypesCount() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM WorkoutTypes')) ?? 0;}


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

  /// PartsRt işlemleri
  Future<List<Parts>> getAllParts() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> partMaps = await db.query('Parts');
      print("Raw Parts data from database: $partMaps"); // Hata ayıklama için eklendi
      final List<Map<String, dynamic>> partExerciseMaps = await db.query('PartExercises');
      final List<PartExercise> partExercises = partExerciseMaps.map((map) => PartExercise.fromMap(map)).toList();

      List<Parts> parts = [];
      for (var map in partMaps) {
        try {
          final exerciseIds = partExercises
              .where((pe) => pe.partId == map['id'])
              .map((pe) => pe.exerciseId)
              .toList();
          parts.add(Parts.fromMap(map, exerciseIds));
        } catch (e) {
          print('Error creating Parts object: $e');
          print('Problematic map: $map');
        }
      }
      print("Successfully created ${parts.length} Parts objects"); // Hata ayıklama için eklendi
      return parts;
    } catch (e) {
      print('Error getting all parts: $e');
      throw Exception('Failed to get parts: $e');
    }
  }





  Future<Parts?> getPartById(int id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> partMaps = await db.query(
        'Parts',
        where: 'Id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (partMaps.isNotEmpty) {
        final List<Map<String, dynamic>> partExerciseMaps = await db.query(
          'PartExercises',
          where: 'partId = ?',
          whereArgs: [id],
        );
        final List<PartExercise> partExercises = partExerciseMaps.map((map) => PartExercise.fromMap(map)).toList();
        return Parts.fromMap(partMaps.first, partExercises.cast<dynamic>());
      }
      return null;
    } catch (e) {
      print('Error getting part by id: $e');
      return null;
    }
  }

  Future<List<Parts>> getPartsByBodyPart(int bodyPartId) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> partMaps = await db.query(
        'Parts',
        where: 'BodyPartId = ?',
        whereArgs: [bodyPartId],
      );
      final List<Map<String, dynamic>> partExerciseMaps = await db.query('PartExercises');
      final List<PartExercise> partExercises = partExerciseMaps.map((map) => PartExercise.fromMap(map)).toList();
      return partMaps.map((map) => Parts.fromMap(map, partExercises.cast<dynamic>())).toList();
    } catch (e) {
      print('Error getting parts by body part: $e');
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
      return partMaps.map((map) => Parts.fromMap(map, partExercises.cast<dynamic>())).toList();
    } catch (e) {
      print('Error getting parts by set type: $e');
      return [];
    }
  }

  Future<List<Parts>> searchPartsByName(String name) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> partMaps = await db.query(
        'Parts',
        where: 'Name LIKE ?',
        whereArgs: ['%$name%'],
      );
      final List<Map<String, dynamic>> partExerciseMaps = await db.query('PartExercises');
      final List<PartExercise> partExercises = partExerciseMaps.map((map) => PartExercise.fromMap(map)).toList();
      return partMaps.map((map) => Parts.fromMap(map, partExercises.cast<dynamic>())).toList();
    } catch (e) {
      print('Error searching parts by name: $e');
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
      return partMaps.map((map) => Parts.fromMap(map, partExercises.cast<dynamic>())).toList();
    } catch (e) {
      print('Error getting parts sorted by name: $e');
      return [];
    }
  }

  Future<List<PartExercise>> getAllPartExercises() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('PartExercises');
      return List.generate(maps.length, (i) => PartExercise.fromMap(maps[i]));
    } catch (e) {
      print('Error getting all part exercises: $e');
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
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'PartExercises',
        where: 'partId = ?',
        whereArgs: [partId],
      );
      return List.generate(maps.length, (i) => PartExercise.fromMap(maps[i]));
    } catch (e) {
      print('Error getting part exercises by part id: $e');
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
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'PartExercises',
        columns: ['exerciseId'],
        where: 'partId = ?',
        whereArgs: [partId],
      );
      return List.generate(maps.length, (i) => maps[i]['exerciseId'] as int);
    } catch (e) {
      print('Error getting exercise ids for part: $e');
      return [];
    }
  }

  Future<List<int>> getPartIdsForExercise(int exerciseId) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'PartExercises',
        columns: ['partId'],
        where: 'exerciseId = ?',
        whereArgs: [exerciseId],
      );
      return List.generate(maps.length, (i) => maps[i]['partId'] as int);
    } catch (e) {
      print('Error getting part ids for exercise: $e');
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











  Future<void> _createTables(Database db) async {
    await db.execute('''
    CREATE TABLE BodyParts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      mainTargetedBodyPart INTEGER NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE Exercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      defaultWeight REAL NOT NULL,
      defaultSets INTEGER NOT NULL,
      defaultReps INTEGER NOT NULL,
      workoutTypeId INTEGER NOT NULL,
      mainTargetedBodyPartId INTEGER NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE PartExercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      partId INTEGER NOT NULL,
      exerciseId INTEGER NOT NULL,
      FOREIGN KEY (partId) REFERENCES Parts (id),
      FOREIGN KEY (exerciseId) REFERENCES Exercises (id)
    )
  ''');

    await db.execute('''
    CREATE TABLE Parts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      bodyPartId INTEGER NOT NULL,
      setType INTEGER NOT NULL,
      additionalNotes TEXT,
      FOREIGN KEY (bodyPartId) REFERENCES BodyParts (id)
    )
  ''');

    await db.execute('''
    CREATE TABLE RoutineExercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      routineId INTEGER NOT NULL,
      exerciseId INTEGER NOT NULL,
      FOREIGN KEY (routineId) REFERENCES Routines (id),
      FOREIGN KEY (exerciseId) REFERENCES Exercises (id)
    )
  ''');

    await db.execute('''
    CREATE TABLE Routines (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      mainTargetedBodyPartId INTEGER,
      workoutTypeId INTEGER,
      FOREIGN KEY (mainTargetedBodyPartId) REFERENCES BodyParts (id),
      FOREIGN KEY (workoutTypeId) REFERENCES WorkoutTypes (id)
    )
  ''');

    await db.execute('''
    CREATE TABLE WorkoutTypes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    )
  ''');
  }

}

