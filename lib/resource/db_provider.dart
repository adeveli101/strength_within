import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:workout/models/routine.dart';
import 'package:workout/models/part.dart';
import 'package:workout/models/exercise.dart';
import '../models/RoutineHistory.dart';
import '../models/RoutinePart.dart';
import '../models/RoutineWeekday.dart';

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();

  Database? _database;

  Future<Database> get database async {
    return _database ??= await initDB();
  }

  String generateId() {
    return const Uuid().v4();
  }

  void _log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  Future<Database> initDB() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = join(appDocDir.path, "newDB.db");
    if (await File(path).exists()) {
      return openDatabase(path);
    } else {
      ByteData data = await rootBundle.load("database/newDB.db");
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
      return openDatabase(path);
    }
  }

  // Routine operations
  Future<List<Routine>> getRoutinesPaginated(int page, int pageSize) async {
    final db = await database;
    final offset = page * pageSize;
    final routines = await db.query(
      'Routines',
      limit: pageSize,
      offset: offset,
    );
    return routines.map((json) => Routine.fromMap(json)).toList();
  }

  Future<List<Routine>> getAllRecRoutines() async {
    final db = await database;
    try {
      var res = await db.query('Routines', where: 'IsRecommended = ?', whereArgs: [1]);
      return res.map((r) => Routine.fromMap(r)).toList();
    } catch (e) {
      _log('Error: $e');
      return [];
    }
  }

  Future<int> deleteAllRoutines() async {
    final db = await database;
    try {
      return await db.delete("Routines");
    } catch (e) {
      _log('Error: $e');
      return -1;
    }
  }

  Future<void> addAllRoutines(List<Routine> routines) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        for (var routine in routines) {
          await txn.insert('Routines', routine.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } catch (e) {
      _log('Error: $e');
    }
  }

  Future<Part?> getPart(int partId) async {
    final db = await database;
    try {
      var res = await db.query('Parts', where: 'Id = ?', whereArgs: [partId]);
      if (res.isNotEmpty) {
        var part = Part.fromMap(res.first);
        var exerciseRes = await db.query(
            'PartExercises',
            where: 'PartId = ?',
            whereArgs: [partId]
        );
        part.exerciseIds = exerciseRes.map((e) => e['ExerciseId'] as int).toList();
        return part;
      }
      return null;
    } catch (e) {
      _log('Error in getPart: $e');
      return null;
    }
  }

  Future<int> newRoutine(Routine routine) async {
    final db = await database;
    return await db.insert('Routines', routine.toMap());
  }

  Future<int> updateRoutine(Routine routine) async {
    final db = await database;
    return await db.update("Routines", routine.toMap(), where: "Id = ?", whereArgs: [routine.id]);
  }

  Future<int> deleteRoutine(int routineId) async {
    final db = await database;
    return await db.delete("Routines", where: "Id = ?", whereArgs: [routineId]);
  }

  Future<List<Routine>> getAllRoutines() async {
    final db = await database;
    try {
      var res = await db.query('Routines');
      print('Fetched ${res.length} routines from database');
      return res.map((r) {
        try {
          return Routine.fromMap(r);
        } catch (e) {
          print('Error converting routine: $e');
          print('Problematic routine data: $r');
          return null;
        }
      }).where((r) => r != null).cast<Routine>().toList();
    } catch (e) {
      print('Error in getAllRoutines: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }



  // Part operations
  Future<int> newPart(Part part) async {
    final db = await database;
    return await db.insert('Parts', part.toMap());
  }

  Future<int> updatePart(Part part) async {
    final db = await database;
    return await db.update("Parts", part.toMap(), where: "Id = ?", whereArgs: [part.id]);
  }

  Future<int> deletePart(int partId) async {
    final db = await database;
    return await db.delete("Parts", where: "Id = ?", whereArgs: [partId]);
  }

  // Exercise operations
  Future<int> newExercise(Exercise exercise) async {
    final db = await database;
    return await db.insert('Exercises', exercise.toMap());
  }

  Future<int> updateExercise(Exercise exercise) async {
    final db = await database;
    return await db.update("Exercises", exercise.toMap(), where: "Id = ?", whereArgs: [exercise.id]);
  }

  Future<int> deleteExercise(int exerciseId) async {
    final db = await database;
    return await db.delete("Exercises", where: "Id = ?", whereArgs: [exerciseId]);
  }

  Future<Map<String, Exercise>> getExercisesForPart(Part part) async {
    final db = await database;
    var exerciseIds = part.exerciseIds;
    var exercises = await Future.wait(
        exerciseIds.map((id) async {
          var result = await db.query('Exercises', where: 'Id = ?', whereArgs: [id]);
          return result.isNotEmpty ? Exercise.fromMap(result.first) : null;
        })
    );
    return Map.fromIterables(
        exerciseIds.map((id) => id.toString()),
        exercises.whereType<Exercise>()
    );
  }


  // RoutinePart operations
  Future<void> addRoutinePart(RoutinePart routinePart) async {
    final db = await database;
    await db.insert('RoutineParts', routinePart.toMap());
  }

  Future<void> removeRoutinePart(int routineId, int partId) async {
    final db = await database;
    await db.delete('RoutineParts', where: 'RoutineId = ? AND PartId = ?', whereArgs: [routineId, partId]);
  }

  // RoutineHistory operations
  Future<int> addRoutineHistory(RoutineHistory history) async {
    final db = await database;
    return await db.insert('RoutineHistory', history.toMap());
  }

  Future<List<RoutineHistory>> getRoutineHistory(int routineId) async {
    final db = await database;
    var res = await db.query('RoutineHistory', where: 'RoutineId = ?', whereArgs: [routineId]);
    return res.map((r) => RoutineHistory.fromMap(r)).toList();
  }

  Future<List<RoutineHistory>> getAllRoutineHistory() async {
    final db = await database;
    try {
      var res = await db.query('RoutineHistory');
      return res.map((r) => RoutineHistory.fromMap(r)).toList();
    } catch (e) {
      _log('Error in getAllRoutineHistory: $e');
      return []; // Boş liste döndür, hata durumunda
    }
  }





  // RoutineWeekday operations
  Future<void> updateRoutineWeekdays(int routineId, List<int> weekdays) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('RoutineWeekdays', where: 'RoutineId = ?', whereArgs: [routineId]);
      for (var weekday in weekdays) {
        await txn.insert('RoutineWeekdays', {'RoutineId': routineId, 'Weekday': weekday});
      }
    });
  }

  Future<List<RoutineWeekday>> getRoutineWeekdays(int routineId) async {
    final db = await database;
    final maps = await db.query('RoutineWeekdays',
        where: 'routineId = ?',
        whereArgs: [routineId]);
    return List.generate(maps.length, (i) {
      return RoutineWeekday.fromMap(maps[i]);
    });
  }

  Future<void> toggleRoutineFavorite(int routineId) async {
    final db = await database;
    var routine = await db.query('Routines', where: 'Id = ?', whereArgs: [routineId]);
    if (routine.isNotEmpty) {
      var currentFavorite = routine.first['IsFavorite'] as int;
      await db.update('Routines', {'IsFavorite': 1 - currentFavorite}, where: 'Id = ?', whereArgs: [routineId]);
    }
  }

  Future<void> updateRoutineDifficulty(int routineId, int difficulty) async {
    final db = await database;
    await db.update('Routines', {'Difficulty': difficulty}, where: 'Id = ?', whereArgs: [routineId]);
  }

  Future<void> updateRoutineEstimatedTime(int routineId, int estimatedTime) async {
    final db = await database;
    await db.update('Routines', {'EstimatedTime': estimatedTime}, where: 'Id = ?', whereArgs: [routineId]);
  }

  Future<List<RoutineHistory>> getRoutineHistoryForExercise(int exerciseId) async {
    final db = await database;
    var res = await db.rawQuery('''
      SELECT rh.* FROM RoutineHistory rh
      JOIN RoutineParts rp ON rh.RoutineId = rp.RoutineId
      JOIN PartExercises pe ON rp.PartId = pe.PartId
      WHERE pe.ExerciseId = ?
    ''', [exerciseId]);
    return res.map((r) => RoutineHistory.fromMap(r)).toList();
  }
}

final dbProvider = DBProvider.db;
