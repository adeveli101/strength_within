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




  class SQLProvider {
  static Database? _database;

  Future<Database> get database async {
  if (_database != null) return _database!;

  return _database!;
  }

  Future<void> initDatabase() async {
    String dbPath = join(await getDatabasesPath(), 'esek.db');
    bool dbExists = await databaseExists(dbPath);

    if (!dbExists) {
      // Veritabanı yoksa, assets'ten kopyala
      ByteData data = await rootBundle.load(join('database', 'esek.db'));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(dbPath).writeAsBytes(bytes, flush: true);
      print("Veritabanı assets'ten kopyalandı.");
    } else {
      print("Veritabanı zaten mevcut.");
    }

    _database = await openDatabase(dbPath);
    print("Veritabanı açıldı.");
  }
  Future<void> testDatabaseContent() async {
    final db = await database;
    final routines = await db.query('Routines');
    print("Routines tablosundaki kayıt sayısı: ${routines.length}");
    for (var routine in routines) {
      print(routine);
    }
  }



  Future<List<BodyParts>> getAllBodyParts() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('BodyParts');
      print("BodyParts ham veri: $maps"); // Hata ayıklama için
      return List.generate(maps.length, (i) {
        return BodyParts.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting all body parts: $e');
      return [];
    }
  }

  Future<BodyParts?> getBodyPartById(int id) async {
  final db = await database;
  try {
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
  print('Error getting body part by id: $e');
  return null;
  }
  }

  Future<List<BodyParts>> getBodyPartsByMainTargeted(MainTargetedBodyPart mainTargeted) async {
  final db = await database;
  try {
  final List<Map<String, dynamic>> maps = await db.query(
  'BodyParts',
  where: 'MainTargetedBodyPart = ?',
  whereArgs: [mainTargeted.index],
  );
  return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
  } catch (e) {
  print('Error getting body parts by main targeted: $e');
  return [];
  }
  }

  Future<List<BodyParts>> searchBodyPartsByName(String name) async {
  final db = await database;
  try {
  final List<Map<String, dynamic>> maps = await db.query(
  'BodyParts',
  where: 'Name LIKE ?',
  whereArgs: ['%$name%'],
  );
  return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
  } catch (e) {
  print('Error searching body parts by name: $e');
  return [];
  }
  }


  /// Exercise işlemleri// Exercise işlemleri// Exercise işlemleri
  /// Exercise işlemleri// Exercise işlemleri// Exercise işlemleri
  /// Exercise işlemleri// Exercise işlemleri// Exercise işlemleri


  Future<List<Exercises>> getAllExercises() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('Exercises');
      print("Exercises ham veri: $maps"); // Hata ayıklama için
      return List.generate(maps.length, (i) {
        return Exercises.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting all exercises: $e');
      return [];
    }
  }
  Future<Exercises?> getExerciseById(int id) async {
  final db = await database;
  try {
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
  print('Error getting exercise by id: $e');
  return null;
  }
  }

  Future<List<Exercises>> getExercisesByWorkoutType(int workoutTypeId) async {
  final db = await database;
  try {
  final List<Map<String, dynamic>> maps = await db.query(
  'Exercises',
  where: 'WorkoutTypeId = ?',
  whereArgs: [workoutTypeId],
  );
  return List.generate(maps.length, (i) => Exercises.fromMap(maps[i]));
  } catch (e) {
  print('Error getting exercises by workout type: $e');
  return [];
  }
  }

  Future<List<Exercises>> getExercisesByMainTargetedBodyPart(int mainTargetedBodyPartId) async {
  final db = await database;
  try {
  final List<Map<String, dynamic>> maps = await db.query(
  'Exercises',
  where: 'MainTargetedBodyPartId = ?',
  whereArgs: [mainTargetedBodyPartId],
  );
  return List.generate(maps.length, (i) => Exercises.fromMap(maps[i]));
  } catch (e) {
  print('Error getting exercises by main targeted body part: $e');
  return [];
  }
  }

  Future<List<Exercises>> searchExercisesByName(String name) async {
  final db = await database;
  try {
  final List<Map<String, dynamic>> maps = await db.query(
  'Exercises',
  where: 'Name LIKE ?',
  whereArgs: ['%$name%'],
  );
  return List.generate(maps.length, (i) => Exercises.fromMap(maps[i]));
  } catch (e) {
  print('Error searching exercises by name: $e');
  return [];
  }
  }

  Future<List<Exercises>> getExercisesByWeightRange(double minWeight, double maxWeight) async {
  final db = await database;
  try {
  final List<Map<String, dynamic>> maps = await db.query(
  'Exercises',
  where: 'DefaultWeight BETWEEN ? AND ?',
  whereArgs: [minWeight, maxWeight],
  );
  return List.generate(maps.length, (i) => Exercises.fromMap(maps[i]));
  } catch (e) {
  print('Error getting exercises by weight range: $e');
  return [];
  }
  }

  ///routine exercisesroutine exercisesroutine exercises
  /// routine exercisesroutine exercisesroutine exercises


  Future<List<RoutineExercises>> getRoutineExercisesByRoutineId(int routineId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'RoutineExercises',
      where: 'routineId = ?',
      whereArgs: [routineId],
    );
    return List.generate(maps.length, (i) => RoutineExercises.fromMap(maps[i]));
  }



  Future<RoutineExercises?> getRoutineExerciseById(int id) async {
  final db = await database;
  try {
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
  print('Error getting routine exercise by id: $e');
  return null;
  }
  }


  Future<List<RoutineExercises>> getRoutineExercisesByExerciseId(int exerciseId) async {
  final db = await database;
  try {
  final List<Map<String, dynamic>> maps = await db.query(
  'RoutineExercises',
  where: 'exerciseId = ?',
  whereArgs: [exerciseId],
  );
  return List.generate(maps.length, (i) => RoutineExercises.fromMap(maps[i]));
  } catch (e) {
  print('Error getting routine exercises by exercise id: $e');
  return [];
  }
  }


  Future<List<int>> getExerciseIdsForRoutine(int routineId) async {
  final db = await database;
  try {
  final List<Map<String, dynamic>> maps = await db.query(
  'RoutineExercises',
  columns: ['exerciseId'],
  where: 'routineId = ?',
  whereArgs: [routineId],
  );
  return List.generate(maps.length, (i) => maps[i]['exerciseId'] as int);
  } catch (e) {
  print('Error getting exercise ids for routine: $e');
  return [];
  }
  }

  /// Routines işlemleri// Routines işlemleri// Routines işlemleri
  /// Routines işlemleri// Routines işlemleri// Routines işlemleri
  /// Routines işlemleri// Routines işlemleri// Routines işlemleri


  Future<List<Routines>> getAllRoutines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Routines');
    print("Routines ham veri: $maps"); // Bu satırı ekleyin

    List<Routines> routines = [];
    for (var map in maps) {
      List<RoutineExercises> routineExercises = await getRoutineExercisesByRoutineId(map['id']);
      routines.add(Routines.fromMap({...map, 'routineExercises': routineExercises}));
    }

    return routines;
  }

  Future<Routines?> getRoutineById(int id) async {
    final db = await database;
    try {
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
      print('Error getting routine by id: $e');
      return null;
    }
  }

  Future<List<Routines>> getRoutinesByName(String name) async {
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
  }


  ///for searching///for searching
  Future<List<Routines>> getRoutinesByPartialName(String partialName) async {
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
  }




  ///for searching///for searching
  Future<List<Routines>> getRoutinesByMainTargetedBodyPart(int mainTargetedBodyPartId) async {
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
  return List.generate(maps.length, (i) => Routines.fromMap(maps[i]));
  }

  Future<List<Routines>> getRoutinesAlphabetically() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
  'Routines',
  orderBy: 'Name ASC',
  );
  return List.generate(maps.length, (i) => Routines.fromMap(maps[i]));
  }

  Future<List<Routines>> getRandomRoutines(int count) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.rawQuery(
  'SELECT * FROM Routines ORDER BY RANDOM() LIMIT ?',
  [count],
  );
  return List.generate(maps.length, (i) => Routines.fromMap(maps[i]));
  }

  /// WorkoutType işlemleri/// WorkoutType işlemleri
  /// WorkoutType işlemleri/// WorkoutType işlemleri
  /// WorkoutType işlemleri/// WorkoutType işlemleri


  Future<List<WorkoutTypes>> getAllWorkoutTypes() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('WorkoutTypes');
      print("WorkoutTypes ham veri: $maps"); // Hata ayıklama için
      return List.generate(maps.length, (i) {
        return WorkoutTypes.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting all workout types: $e');
      return [];
    }
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
  return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM WorkoutTypes')) ?? 0;
  }


  getWorkoutTypesByName(String name) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
  'WorkoutTypes',
  where: 'Name LIKE ?',
  whereArgs: ['%$name%'],
  );

  return List.generate(maps.length, (i) {
  return WorkoutTypes.fromMap(maps[i]);
  });
  }


  ///PartsRt///PartsRt///PartsRt///PartsRt///PartsRt
  ///PartsRt///PartsRt///PartsRt///PartsRt///PartsRt///PartsRt
  ///
  Future<List<Parts>> getAllParts() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> partMaps = await db.query('Parts');
      final List<Map<String, dynamic>> partExerciseMaps = await db.query('PartExercises');
      final List<PartExercise> partExercises = partExerciseMaps.map((map) => PartExercise.fromMap(map)).toList();

      return partMaps.map((map) {
        final exerciseIds = partExercises
            .where((pe) => pe.partId == map['Id'])
            .map((pe) => pe.exerciseId)
            .toList();

        return Parts.fromMap(map, exerciseIds);
      }).toList();
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
        return Parts.fromMap(partMaps.first, partExercises.cast<int>());
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
      return partMaps.map((map) => Parts.fromMap(map, partExercises.cast<int>())).toList();
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
      return partMaps.map((map) => Parts.fromMap(map, partExercises.cast<int>())).toList();
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
      return partMaps.map((map) => Parts.fromMap(map, partExercises.cast<int>())).toList();
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
      return partMaps.map((map) => Parts.fromMap(map, partExercises.cast<int>())).toList();
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


  }