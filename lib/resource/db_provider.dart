import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:workout/models/routine.dart';

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

  Future<Database> initDB({bool refresh = false}) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = join(appDocDir.path, "data.db");

    if (await File(path).exists() && !refresh) {
      return openDatabase(
        path,
        version: 1,
        onOpen: (db) async {
          if (kDebugMode) {
            if (kDebugMode) {
              print(await db.query("sqlite_master"));
            }
          }
        },
      );
    } else {
      ByteData data = await rootBundle.load("database/data.db");
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
      return openDatabase(
        path,
        version: 1,
        onOpen: (db) async {
          if (kDebugMode) {
            print(await db.query("sqlite_master"));
          }
        },
      );
    }
  }

  Future<int> getLastId() async {
    final db = await database;
    var table = await db.rawQuery('SELECT MAX(Id)+1 as Id FROM Routines');
    return table.first['Id'] as int? ?? 0;
  }

  Future<int> newRoutine(Routine routine) async {
    final db = await database;
    int id = await getLastId();
    var map = routine.toMap();
    await db.rawInsert(
        'INSERT Into Routines (Id, RoutineName, MainPart, Parts, LastCompletedDate, CreatedDate, Count, RoutineHistory, Weekdays) VALUES (?,?,?,?,?,?,?,?,?)',
        [
          id,
          map['RoutineName'],
          map['MainPart'],
          map['Parts'],
          map['LastCompletedDate'],
          map['CreatedDate'],
          map['Count'],
          map['RoutineHistory'],
          map['Weekdays'],
        ]);
    return id;
  }

  Future<int> updateRoutine(Routine routine) async {
    final db = await database;
    return await db.update("Routines", routine.toMap(), where: "id = ?", whereArgs: [routine.id]);
  }

  Future<int> deleteRoutine(Routine routine) async {
    final db = await database;
    return await db.delete("Routines", where: "id = ?", whereArgs: [routine.id]);
  }

  Future<int> deleteAllRoutines() async {
    final db = await database;
    return await db.delete("Routines");
  }

  Future<void> addAllRoutines(List<Routine> routines) async {
    final db = await database;

    for (var routine in routines) {
      int id = await getLastId();
      var map = routine.toMap();
      await db.rawInsert(
          'INSERT Into Routines (Id, RoutineName, MainPart, Parts, LastCompletedDate, CreatedDate, Count, RoutineHistory, Weekdays) VALUES (?,?,?,?,?,?,?,?,?)',
          [
            id,
            map['RoutineName'],
            map['MainPart'],
            map['Parts'],
            map['LastCompletedDate'],
            map['CreatedDate'],
            map['Count'],
            map['RoutineHistory'],
            map['Weekdays'],
          ]);
    }
  }

  Future<List<Routine>> getAllRoutines() async {
    final db = await database;
    var res = await db.query('Routines');

    return res.map((r) => Routine.fromMap(r.cast<String, dynamic>())).toList();
  }

  Future<List<Routine>> getAllRecRoutines() async {
    final db = await database;
    var res = await db.query('RecommendedRoutines');

    return res.map((r) => Routine.fromMap(r.cast<String, dynamic>())).toList();
  }
}