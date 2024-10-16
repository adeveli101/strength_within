import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/BodyPart.dart';
import '../models/RoutinePart.dart';
import '../models/WorkoutType.dart';
import '../models/exercises.dart';
import '../models/routines.dart';

//önceden tanımlanmış ve değişmez bir veri seti
//önceden tanımlanmış ve değişmez bir veri seti
//önceden tanımlanmış ve değişmez bir veri seti
//önceden tanımlanmış ve değişmez bir veri seti



class SQLProvider {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'db_workout.db');
    return await openDatabase(path, version: 1);
  }






  // WorkoutType işlemleri// WorkoutType işlemleri// WorkoutType işlemleri
  // WorkoutType işlemleri// WorkoutType işlemleri// WorkoutType işlemleri
  // WorkoutType işlemleri// WorkoutType işlemleri// WorkoutType işlemleri
  // WorkoutType işlemleri// WorkoutType işlemleri// WorkoutType işlemleri


  Future<List<WorkoutType>> getAllWorkoutTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('WorkoutTypes');
    return List.generate(maps.length, (i) {
      return WorkoutType.fromMap(maps[i]);
    });
  }

  Future<WorkoutType?> getWorkoutType(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'WorkoutTypes',
      where: 'Id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return WorkoutType.fromMap(maps.first);
    }
    return null;
  }









  // Routine işlemleri// Routine işlemleri// Routine işlemleri
  // Routine işlemleri// Routine işlemleri// Routine işlemleri
  // Routine işlemleri// Routine işlemleri// Routine işlemleri
  // Routine işlemleri// Routine işlemleri// Routine işlemleri



  Future<List<Routine>> getAllRoutines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Routines');
    return List.generate(maps.length, (i) {
      return Routine.fromMap(maps[i]);
    });
  }

  Future<Routine?> getRoutine(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Routines',
      where: 'Id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Routine.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Routine>> getRecommendedRoutines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Routines',
      where: 'IsRecommended = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) {
      return Routine.fromMap(maps[i]);
    });
  }

  Future<List<Routine>> getRoutinesByWorkoutType(int workoutTypeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Routines',
      where: 'WorkoutType = ?',
      whereArgs: [workoutTypeId],
    );
    return List.generate(maps.length, (i) {
      return Routine.fromMap(maps[i]);
    });
  }


  Future<List<Routine>> getRoutinesPaginated(int page, int pageSize) async {
    final db = await database;
    final offset = (page - 1) * pageSize;
    final List<Map<String, dynamic>> maps = await db.query(
        'Routines',
        limit: pageSize,
        offset: offset,
        orderBy: 'Id ASC'
    );
    return List.generate(maps.length, (i) {
      return Routine.fromMap(maps[i]);
    });
  }





  // RoutinePart işlemleri// RoutinePart işlemleri// RoutinePart işlemleri
  // RoutinePart işlemleri// RoutinePart işlemleri// RoutinePart işlemleri
  // RoutinePart işlemleri// RoutinePart işlemleri// RoutinePart işlemleri
  // RoutinePart işlemleri// RoutinePart işlemleri// RoutinePart işlemleri


  Future<List<RoutinePart>> getRoutinePartsByRoutineId(int routineId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'RoutineParts',
      where: 'routineId = ?',
      whereArgs: [routineId],
    );
    return List.generate(maps.length, (i) {
      return RoutinePart.fromMap(maps[i]);
    });
  }


  /// Belirli bir Routine'e ait tüm RoutinePart'ları getirir.
  /// Bu metod, bir rutinin tüm parçalarını sıralı bir şekilde döndürür.
  ///
  ///
  Future<List<RoutinePart>> getRoutinePartsForRoutine(int routineId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'RoutineParts',
      where: 'RoutineId = ?',
      whereArgs: [routineId],
      orderBy: 'OrderIndex ASC',
    );
    return List.generate(maps.length, (i) => RoutinePart.fromMap(maps[i]));
  }





  // Exercise işlemleri // Exercise işlemleri // Exercise işlemleri
  // Exercise işlemleri // Exercise işlemleri // Exercise işlemleri
  // Exercise işlemleri // Exercise işlemleri // Exercise işlemleri
  // Exercise işlemleri // Exercise işlemleri // Exercise işlemleri



  Future<List<Exercise>> getAllExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Exercises');
    return List.generate(maps.length, (i) {
      return Exercise.fromMap(maps[i]);
    });
  }



  Future<Exercise?> getExerciseById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Exercises',
      where: 'Id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Exercise.fromMap(maps.first);
    }
    return null;
  }



  Future<List<Exercise>> getExercisesByWorkoutType(int workoutTypeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Exercises',
      where: 'WorkoutType = ?',
      whereArgs: [workoutTypeId],
    );
    return List.generate(maps.length, (i) {
      return Exercise.fromMap(maps[i]);
    });
  }



  Future<List<Exercise>> searchExercisesByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Exercises',
      where: 'Name LIKE ?',
      whereArgs: ['%$name%'],
    );
    return List.generate(maps.length, (i) {
      return Exercise.fromMap(maps[i]);
    });
  }



  Future<List<Exercise>> getExercisesPaginated(int page, int pageSize) async {
    final db = await database;
    final offset = (page - 1) * pageSize;
    final List<Map<String, dynamic>> maps = await db.query(
        'Exercises',
        limit: pageSize,
        offset: offset,
        orderBy: 'Id ASC'
    );
    return List.generate(maps.length, (i) {
      return Exercise.fromMap(maps[i]);
    });
  }



  Future<List<Exercise>> getExercisesByBodyPart(MainTargetedBodyPart bodyPart) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Exercises',
      where: 'MainTargetedBodyPart = ?',
      whereArgs: [bodyPart.index],
    );
    return List.generate(maps.length, (i) {
      return Exercise.fromMap(maps[i]);
    });
  }



  Future<List<Exercise>> getExercisesForRoutine(int routineId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.* FROM Exercises e
      INNER JOIN RoutineParts rp ON e.id = rp.partId
      WHERE rp.routineId = ?
    ''', [routineId]);
    return List.generate(maps.length, (i) {
      return Exercise.fromMap(maps[i]);
    });
  }





//BodyPart İşlemleri//BodyPart İşlemleri//BodyPart İşlemleri
//BodyPart İşlemleri//BodyPart İşlemleri//BodyPart İşlemleri
//BodyPart İşlemleri//BodyPart İşlemleri//BodyPart İşlemleri



  Future<List<BodyPart>> getAllBodyParts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('BodyParts');
    return List.generate(maps.length, (i) {
      return BodyPart.fromMap(maps[i]);
    });
  }


  Future<BodyPart?> getBodyPartById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'BodyParts',
      where: 'Id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return BodyPart.fromMap(maps.first);
    }
    return null;
  }



  Future<List<BodyPart>> getBodyPartsByMainTargetedBodyPart(MainTargetedBodyPart mainTargetedBodyPart) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'BodyParts',
      where: 'MainTargetedBodyPart = ?',
      whereArgs: [mainTargetedBodyPart.index],
    );
    return List.generate(maps.length, (i) {
      return BodyPart.fromMap(maps[i]);
    });
  }


  Future<List<BodyPart>> searchBodyPartsByName(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'BodyParts',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return List.generate(maps.length, (i) => BodyPart.fromMap(maps[i]));
  }



  Future<List<String>> getAllBodyPartNames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'BodyParts',
      columns: ['name'],
    );
    return List.generate(maps.length, (i) => maps[i]['name'] as String);
  }







}







