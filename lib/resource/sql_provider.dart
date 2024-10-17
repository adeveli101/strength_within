import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/BodyPart.dart';
import '../models/RoutinePart.dart';
import '../models/WorkoutType.dart';
import '../models/exercises.dart';
import '../models/parts.dart';
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
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "db_workout.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
        CREATE TABLE BodyParts (
          Id INTEGER PRIMARY KEY,
          Name TEXT NOT NULL
        )
      ''');

        await db.execute('''
        CREATE TABLE Exercises (
          Id INTEGER PRIMARY KEY,
          Name TEXT NOT NULL,
          DefaultWeight REAL,
          DefaultSets INTEGER,
          DefaultReps TEXT,
          WorkoutType INTEGER NOT NULL,
          MainTargetedBodyPart INTEGER NOT NULL
        )
      ''');

        await db.execute('''
        CREATE TABLE PartExercises (
          PartId INTEGER,
          ExerciseId INTEGER,
          OrderIndex INTEGER NOT NULL,
          PRIMARY KEY (PartId, ExerciseId),
          FOREIGN KEY (PartId) REFERENCES Parts(Id),
          FOREIGN KEY (ExerciseId) REFERENCES Exercises(Id)
        )
      ''');

        await db.execute('''
        CREATE TABLE Parts (
          Id INTEGER PRIMARY KEY,
          Name TEXT NOT NULL,
          MainTargetedBodyPart INTEGER NOT NULL,
          SetType INTEGER NOT NULL,
          AdditionalNotes TEXT
        )
      ''');

        await db.execute('''
        CREATE TABLE RoutineParts (
          RoutineId INTEGER,
          PartId INTEGER,
          OrderIndex INTEGER NOT NULL,
          PRIMARY KEY (RoutineId, PartId),
          FOREIGN KEY (RoutineId) REFERENCES Routines(Id),
          FOREIGN KEY (PartId) REFERENCES Parts(Id)
        )
      ''');

        await db.execute('''
        CREATE TABLE Routines (
          Id INTEGER PRIMARY KEY,
          Name TEXT NOT NULL,
          MainTargetedBodyPart INTEGER NOT NULL,
          WorkoutType INTEGER NOT NULL,
          IsRecommended INTEGER NOT NULL,
          Difficulty INTEGER NOT NULL,
          EstimatedTime INTEGER NOT NULL
        )
      ''');

        await db.execute('''
        CREATE TABLE WorkoutTypes (
          Id INTEGER PRIMARY KEY,
          Name TEXT NOT NULL
        )
      ''');
      },
      onOpen: (Database db) async {
        // Veritabanı açıldığında yapılacak işlemler
        print("Veritabanı açıldı ");

        // Örnek: Tabloların varlığını kontrol etme
        var tables = ['BodyParts', 'Exercises', 'PartExercises', 'Parts', 'RoutineParts', 'Routines', 'WorkoutTypes'];
        for (var table in tables) {
          var result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$table'");
          if (result.isNotEmpty) {
            print("$table tablosu mevcut");
          } else {
            print("$table tablosu bulunamadı!");
          }
        }
      },
    );
  }




  // WorkoutType işlemleri// WorkoutType işlemleri// WorkoutType işlemleri
  // WorkoutType işlemleri// WorkoutType işlemleri// WorkoutType işlemleri
  // WorkoutType işlemleri// WorkoutType işlemleri// WorkoutType işlemleri
  // WorkoutType işlemleri// WorkoutType işlemleri// WorkoutType işlemleri


  Future<List<WorkoutTypes>> getAllWorkoutTypes() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('WorkoutTypes');
      return List.generate(maps.length, (i) {
        return WorkoutTypes.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getAllWorkoutTypes - $e');
      return [];
    }
  }

  Future<WorkoutTypes?> getWorkoutType(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'WorkoutTypes',
        where: 'Id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return WorkoutTypes.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Hata: getWorkoutType - $e');
      return null;
    }
  }








  /// Routine işlemleri// Routine işlemleri// Routine işlemleri
  /// Routine işlemleri// Routine işlemleri// Routine işlemleri
  /// Routine işlemleri// Routine işlemleri// Routine işlemleri
  /// Routine işlemleri// Routine işlemleri// Routine işlemleri



  Future<List<Routines>> getAllRoutines() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('Routines');
      return List.generate(maps.length, (i) {
        return Routines.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getAllRoutines - $e');
      return [];
    }
  }

  Future<Routines?> getRoutine(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Routines',
        where: 'Id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Routines.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Hata: getRoutine - $e');
      return null;
    }
  }

  Future<List<Routines>> getRecommendedRoutines() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Routines',
        where: 'IsRecommended = ?',
        whereArgs: [1],
      );
      return List.generate(maps.length, (i) {
        return Routines.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getRecommendedRoutines - $e');
      return [];
    }
  }

  Future<List<Routines>> getRoutinesByWorkoutType(int workoutTypeId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Routines',
        where: 'WorkoutType = ?',
        whereArgs: [workoutTypeId],
      );
      return List.generate(maps.length, (i) {
        return Routines.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getRoutinesByWorkoutType - $e');
      return [];
    }
  }

  Future<List<Routines>> getRoutinesPaginated(int page, int pageSize) async {
    try {
      final db = await database;
      final offset = (page - 1) * pageSize;
      final List<Map<String, dynamic>> maps = await db.query(
          'Routines',
          limit: pageSize,
          offset: offset,
          orderBy: 'Id ASC'
      );
      return List.generate(maps.length, (i) {
        return Routines.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getRoutinesPaginated - $e');
      return [];
    }
  }




  /// RoutinePart işlemleri// RoutinePart işlemleri// RoutinePart işlemleri
  /// RoutinePart işlemleri// RoutinePart işlemleri// RoutinePart işlemleri
  /// RoutinePart işlemleri// RoutinePart işlemleri// RoutinePart işlemleri
  /// RoutinePart işlemleri// RoutinePart işlemleri// RoutinePart işlemleri


  Future<List<RoutineParts>> getRoutinePartsByRoutineId(int routineId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'RoutineParts',
        where: 'routineId = ?',
        whereArgs: [routineId],
      );
      return List.generate(maps.length, (i) {
        return RoutineParts.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getRoutinePartsByRoutineId - $e');
      return [];
    }
  }

  /// Belirli bir Routine'e ait tüm RoutinePart'ları getirir.
  /// Bu metod, bir rutinin tüm parçalarını sıralı bir şekilde döndürür.
  Future<List<RoutineParts>> getRoutinePartsForRoutine(int routineId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'RoutineParts',
        where: 'RoutineId = ?',
        whereArgs: [routineId],
        orderBy: 'OrderIndex ASC',
      );
      return List.generate(maps.length, (i) => RoutineParts.fromMap(maps[i]));
    } catch (e) {
      print('Hata: getRoutinePartsForRoutine - $e');
      return [];
    }
  }






  /// Exercise işlemleri // Exercise işlemleri // Exercise işlemleri
  /// Exercise işlemleri // Exercise işlemleri // Exercise işlemleri
  /// Exercise işlemleri // Exercise işlemleri // Exercise işlemleri
  /// Exercise işlemleri // Exercise işlemleri // Exercise işlemleri



  Future<List<Exercises>> getAllExercises() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('Exercises');
      return List.generate(maps.length, (i) {
        return Exercises.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getAllExercises - $e');
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
      );
      if (maps.isNotEmpty) {
        return Exercises.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Hata: getExerciseById - $e');
      return null;
    }
  }

  Future<List<Exercises>> getExercisesByWorkoutType(int workoutTypeId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Exercises',
        where: 'WorkoutType = ?',
        whereArgs: [workoutTypeId],
      );
      return List.generate(maps.length, (i) {
        return Exercises.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getExercisesByWorkoutType - $e');
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
      return List.generate(maps.length, (i) {
        return Exercises.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: searchExercisesByName - $e');
      return [];
    }
  }

  Future<List<Exercises>> getExercisesPaginated(int page, int pageSize) async {
    try {
      final db = await database;
      final offset = (page - 1) * pageSize;
      final List<Map<String, dynamic>> maps = await db.query(
          'Exercises',
          limit: pageSize,
          offset: offset,
          orderBy: 'Id ASC'
      );
      return List.generate(maps.length, (i) {
        return Exercises.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getExercisesPaginated - $e');
      return [];
    }
  }

  Future<List<Exercises>> getExercisesByBodyPart(MainTargetedBodyPart bodyPart) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Exercises',
        where: 'MainTargetedBodyPart = ?',
        whereArgs: [bodyPart.index],
      );
      return List.generate(maps.length, (i) {
        return Exercises.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getExercisesByBodyPart - $e');
      return [];
    }
  }

  Future<List<Exercises>> getExercisesForRoutine(int routineId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.* FROM Exercises e
      INNER JOIN RoutineParts rp ON e.id = rp.partId
      WHERE rp.routineId = ?
    ''', [routineId]);
      return List.generate(maps.length, (i) {
        return Exercises.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getExercisesForRoutine - $e');
      return [];
    }
  }





  ///BodyPart İşlemleri//BodyPart İşlemleri//BodyPart İşlemleri
///BodyPart İşlemleri//BodyPart İşlemleri//BodyPart İşlemleri
///BodyPart İşlemleri//BodyPart İşlemleri//BodyPart İşlemleri



  Future<List<BodyParts>> getAllBodyParts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('BodyParts');
      return List.generate(maps.length, (i) {
        return BodyParts.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getAllBodyParts - $e');
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
      );
      if (maps.isNotEmpty) {
        return BodyParts.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Hata: getBodyPartById - $e');
      return null;
    }
  }

  Future<List<BodyParts>> getBodyPartsByMainTargetedBodyPart(MainTargetedBodyPart mainTargetedBodyPart) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'BodyParts',
        where: 'MainTargetedBodyPart = ?',
        whereArgs: [mainTargetedBodyPart.index],
      );
      return List.generate(maps.length, (i) {
        return BodyParts.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getBodyPartsByMainTargetedBodyPart - $e');
      return [];
    }
  }

  Future<List<BodyParts>> searchBodyPartsByName(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'BodyParts',
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
      );
      return List.generate(maps.length, (i) => BodyParts.fromMap(maps[i]));
    } catch (e) {
      print('Hata: searchBodyPartsByName - $e');
      return [];
    }
  }

  Future<List<String>> getAllBodyPartNames() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'BodyParts',
        columns: ['name'],
      );
      return List.generate(maps.length, (i) => maps[i]['name'] as String);
    } catch (e) {
      print('Hata: getAllBodyPartNames - $e');
      return [];
    }
  }


    ///Part İşlemleri///Part İşlemleri///Part İşlemleri
    ///Part İşlemleri///Part İşlemleri///Part İşlemleri
    ///Part İşlemleri///Part İşlemleri///Part İşlemleri
///


  Future<Parts?> getPartById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Parts',
        where: 'Id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Parts.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Hata: getPartById - $e');
      return null;
    }
  }

  Future<List<Parts>> getPartsByMainTargetedBodyPart(MainTargetedBodyPart bodyPart) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Parts',
        where: 'MainTargetedBodyPart = ?',
        whereArgs: [bodyPart.index],
      );
      return List.generate(maps.length, (i) {
        return Parts.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getPartsByMainTargetedBodyPart - $e');
      return [];
    }
  }

  Future<List<Parts>> getPartsBySetType(SetType setType) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Parts',
        where: 'SetType = ?',
        whereArgs: [setType.index],
      );
      return List.generate(maps.length, (i) {
        return Parts.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getPartsBySetType - $e');
      return [];
    }
  }

  Future<List<Parts>> searchPartsByName(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Parts',
        where: 'Name LIKE ?',
        whereArgs: ['%$query%'],
      );
      return List.generate(maps.length, (i) => Parts.fromMap(maps[i]));
    } catch (e) {
      print('Hata: searchPartsByName - $e');
      return [];
    }
  }

  Future<List<Parts>> getPartsPaginated(int page, int pageSize) async {
    try {
      final db = await database;
      final offset = (page - 1) * pageSize;
      final List<Map<String, dynamic>> maps = await db.query(
          'Parts',
          limit: pageSize,
          offset: offset,
          orderBy: 'Id ASC'
      );
      return List.generate(maps.length, (i) {
        return Parts.fromMap(maps[i]);
      });
    } catch (e) {
      print('Hata: getPartsPaginated - $e');
      return [];
    }
  }






}







