import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:workout/models/routine.dart';

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();

  Database? _database;
  static const String _dbPassword = '9003'; // Database password

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

  Future<Database> initDB({bool refresh = false}) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = join(appDocDir.path, "data.db");

    if (await File(path).exists() && !refresh) {
      return openDatabase(
        path,
        password: _dbPassword,
        version: 2,
        onOpen: (db) async {
          _log(await db.query("sqlite_master").toString());
        },
        onUpgrade: _onUpgrade,
      );
    } else {
      ByteData data = await rootBundle.load("database/data.db");
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
      return openDatabase(
        path,
        password: _dbPassword,
        version: 2,
        onCreate: _onCreate,
        onOpen: (db) async {
          _log(await db.query("sqlite_master").toString());
        },
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Routines (
        Id INTEGER PRIMARY KEY,
        RoutineName TEXT,
        MainPart TEXT,
        Parts TEXT,
        LastCompletedDate TEXT,
        CreatedDate TEXT,
        Count INTEGER,
        RoutineHistory TEXT,
        Weekdays TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Handle database upgrade logic if needed
    }
  }

  Future<int> getLastId() async {
    final db = await database;
    try {
      var table = await db.rawQuery('SELECT MAX(Id)+1 as Id FROM Routines');
      return table.first['Id'] as int? ?? 0;
    } catch (e) {
      _log('Error: $e');
      return 0;
    }
  }

  bool _isValidRoutine(Routine routine) {
    return routine.routineName.isNotEmpty;
  }

  String _sanitizeInput(String input) {
    return input.replaceAll(RegExp(r'[^\w\s]+'), '');
  }

  Future<int> newRoutine(Routine routine) async {
    if (!_isValidRoutine(routine)) {
      throw ArgumentError('Invalid routine');
    }

    final db = await database;
    try {
      int id = await getLastId();
      var map = routine.toMap();
      return await db.insert('Routines', {
        'Id': id,
        'RoutineName': _sanitizeInput(map['RoutineName']),
        'MainPart': _sanitizeInput(map['MainPart']),
        'Parts': _sanitizeInput(map['Parts']),
        'LastCompletedDate': map['LastCompletedDate'],
        'CreatedDate': map['CreatedDate'],
        'Count': map['Count'],
        'RoutineHistory': _sanitizeInput(map['RoutineHistory']),
        'Weekdays': _sanitizeInput(map['Weekdays']),
      });
    } catch (e) {
      _log('Error: $e');
      return -1;
    }
  }

  Future<int> updateRoutine(Routine routine) async {
    final db = await database;
    try {
      return await db.update("Routines", routine.toMap(), where: "id = ?", whereArgs: [routine.id]);
    } catch (e) {
      _log('Error: $e');
      return -1;
    }
  }

  Future<int> deleteRoutine(Routine routine) async {
    final db = await database;
    try {
      return await db.delete("Routines", where: "id = ?", whereArgs: [routine.id]);
    } catch (e) {
      _log('Error: $e');
      return -1;
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
          if (!_isValidRoutine(routine)) continue;
          int id = await getLastId();
          var map = routine.toMap();
          await txn.insert('Routines', {
            'Id': id,
            'RoutineName': _sanitizeInput(map['RoutineName']),
            'MainPart': _sanitizeInput(map['MainPart']),
            'Parts': _sanitizeInput(map['Parts']),
            'LastCompletedDate': map['LastCompletedDate'],
            'CreatedDate': map['CreatedDate'],
            'Count': map['Count'],
            'RoutineHistory': _sanitizeInput(map['RoutineHistory']),
            'Weekdays': _sanitizeInput(map['Weekdays']),
          });
        }
      });
    } catch (e) {
      _log('Error: $e');
    }
  }

  Future<List<Routine>> getAllRoutines() async {
    final db = await database;
    try {
      var res = await db.query('Routines');
      return res.map((r) => Routine.fromMap(r.cast<String, dynamic>())).toList();
    } catch (e) {
      _log('Error: $e');
      return [];
    }
  }
  Future<List<Routine>> getRoutinesPaginated(int page, int pageSize) async {
    final db = await database;
    final routines = await db.query(
      'routines',
      offset: page * pageSize,
      limit: pageSize,
    );
    return routines.map((json) => Routine.fromMap(json)).toList();
  }

  Future<List<Routine>> getAllRecRoutines() async {
    final db = await database;
    try {
      var res = await db.query('RecommendedRoutines');
      return res.map((r) => Routine.fromMap(r.cast<String, dynamic>())).toList();
    } catch (e) {
      _log('Error: $e');
      return [];
    }
  }
}
