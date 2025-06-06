import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/sql_models/BodyPart.dart';
import '../../models/sql_models/ExerciseTargetedBodyParts.dart';
import '../../models/sql_models/PartExercises.dart';
import '../../models/sql_models/exercises.dart';
import '../../models/sql_models/workoutGoals.dart';
import '../data_provider/firebase_provider.dart';
import '../data_provider/sql_provider.dart';
import '../data_provider_cache/app_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/cupertino.dart';



class ExerciseRepository {
  final SQLProvider sqlProvider;
  final FirebaseProvider firebaseProvider;
  // ignore: unused_field
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger;

  ExerciseRepository({
    required this.sqlProvider,
    required this.firebaseProvider,
  }) : _logger = Logger('ExerciseRepository') {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }


  static const String EXERCISES_CACHE_KEY = 'all_exercises';
  static const String BODYPARTS_CACHE_KEY = 'all_bodyparts';


  final _bodyPartNamesCache = <int, String>{};
  // ignore: unused_field
  final AppCache _cache = AppCache();

  // Tüm egzersizleri getir
  Future<List<Exercises>> getAllExercises() async {
    try {
      return await sqlProvider.getAllExercises();
    } catch (e) {
      _logger.severe('Egzersizler alınırken hata oluştu', e);
      throw Exception("Egzersizler alınırken hata oluştu: $e");
    }
  }

  Future<List<Exercises>> getExercisesByPartId(int partId) async {
    try {
      // Önce PartExercises tablosundan ilgili part'a ait egzersiz ID'lerini al
      final List<PartExercise> partExercises = await sqlProvider
          .getPartExercisesByPartId(partId);

      if (partExercises.isEmpty) {
        _logger.warning('Part ID: $partId için egzersiz bulunamadı');
        return [];
      }

      // Egzersiz ID'lerini çıkar
      final List<int> exerciseIds = partExercises
          .map((pe) => int.parse(pe.exerciseId.toString()))
          .toList();

      // Bu ID'lere sahip egzersizleri al
      final List<Exercises> exercises = await sqlProvider.getExercisesByIds(
          exerciseIds);

      if (exercises.isEmpty) {
        _logger.warning('Belirtilen ID\'ler için egzersiz bulunamadı');
        return [];
      }

      // Egzersizleri orderIndex'e göre sırala
      exercises.sort((a, b) {
        final aIndex = partExercises
            .firstWhere((pe) => pe.exerciseId == a.id)
            .orderIndex;
        final bIndex = partExercises
            .firstWhere((pe) => pe.exerciseId == b.id)
            .orderIndex;
        return aIndex.compareTo(bIndex);
      });

      _logger.info('${exercises.length} egzersiz başarıyla getirildi ve sıralandı');
      return exercises;
    } catch (e) {
      _logger.severe('Part ID\'sine göre egzersizler alınırken hata: $e');
      throw Exception("Part ID'sine göre egzersizler alınırken hata oluştu: $e");
    }
  }

  Future<List<Exercises>> getExercisesByIds(List<int> ids) async {
    try {
      return await sqlProvider.getExercisesByIds(ids);
    } catch (e) {
      _logger.severe('ID\'lere göre egzersizler alınırken hata', e);
      throw Exception("Egzersizler alınırken hata oluştu: $e");
    }
  }

  Future<List<ExerciseTargetedBodyParts>> getTargetedBodyParts(int exerciseId) async {
    final db = await sqlProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ExerciseTargetedBodyParts',
      where: 'exerciseId = ?',
      whereArgs: [exerciseId],
    );

    return List.generate(maps.length, (i) {
      return ExerciseTargetedBodyParts.fromMap(maps[i]);
    });
  }

      // İsme göre egzersiz ara
      Future<List<Exercises>> searchExercisesByName(String name) async {
        try {
          return await sqlProvider.searchExercisesByName(name);
        } catch (e) {
          _logger.severe('Egzersiz arama hatası', e);
          throw Exception("Egzersiz arama hatası: $e");
        }
      }

      // Antrenman tipine göre egzersizleri getir
      Future<List<Exercises>> getExercisesByWorkoutType(
          int workoutTypeId) async {
        try {
          return await sqlProvider.getExercisesByWorkoutType(workoutTypeId);
        } catch (e) {
          _logger.severe('Çalışma türüne göre egzersizler alınırken hata', e);
          throw Exception(
              "Çalışma türüne göre egzersizler alınırken hata oluştu: $e");
        }
      }

      // Egzersiz tamamlanma durumunu güncelle
      Future<void> updateExerciseCompletion(String userId, int exerciseId,
          bool isCompleted) async {
        try {
          await firebaseProvider.updateExerciseCompletion(
            userId,
            exerciseId.toString(),
            isCompleted,
            DateTime.now(),
          );
          _logger.info(
              'Egzersiz tamamlanma durumu güncellendi: $exerciseId - $isCompleted');
        } catch (e) {
          _logger.severe('Tamamlanma durumu güncellenirken hata', e);
          throw Exception("Tamamlanma durumu güncellenirken hata oluştu: $e");
        }
      }

      // Part için egzersiz sıralamasını güncelle
      Future<void> updateExerciseOrder(int partId,
          List<PartExercise> newOrder) async {
        try {
          await sqlProvider.updatePartExercisesOrder(partId, newOrder);
          _logger.info('Egzersiz sıralaması güncellendi: Part $partId');
        } catch (e) {
          _logger.severe('Egzersiz sıralaması güncellenirken hata', e);
          throw Exception("Egzersiz sıralaması güncellenirken hata oluştu: $e");
        }
      }

      Future<String> getBodyPartName(int bodyPartId) async {
    if (_bodyPartNamesCache.containsKey(bodyPartId)) {
      return _bodyPartNamesCache[bodyPartId]!;
    }

    final name = await sqlProvider.getBodyPartName(bodyPartId);
    _bodyPartNamesCache[bodyPartId] = name;
    return name;
  }

  // Tüm vücut bölgelerini getir
  Future<List<BodyParts>> getAllBodyParts() async {
    try {
      return await sqlProvider.getAllBodyParts();
    } catch (e) {
      _logger.severe('Vücut bölgeleri alınırken hata oluştu', e);
      throw Exception("Vücut bölgeleri alınırken hata oluştu: $e");
    }
  }

  // Tüm antrenman hedeflerini getir
  Future<List<WorkoutGoals>> getAllWorkoutGoals() async {
    try {
      return await sqlProvider.getAllWorkoutGoals();
    } catch (e) {
      _logger.severe('Antrenman hedefleri alınırken hata oluştu', e);
      throw Exception("Antrenman hedefleri alınırken hata oluştu: $e");
    }
  }

  Future<List<Exercises>> getExercisesByBodyPartIds(List<int> bodyPartIds) async {
    print('[DEBUG] getExercisesByBodyPartIds called with: $bodyPartIds');
    final Set<int> allExerciseIds = {};
    for (final partId in bodyPartIds) {
      final exercises = await sqlProvider.getExercisesByBodyPart(partId);
      allExerciseIds.addAll(exercises.map((e) => e.id));
    }
    if (allExerciseIds.isEmpty) return [];
    final result = await getExercisesByIds(allExerciseIds.toList());
    print('[DEBUG] getExercisesByBodyPartIds result count: ${result.length}');
    return result;
  }

  Future<List<BodyParts>> getMainBodyParts() async {
    try {
      return await sqlProvider.getMainBodyParts();
    } catch (e) {
      _logger.severe('Error getting main body parts', e);
      return [];
    }
  }

  Future<List<Exercises>> getExercisesByMainBodyPart(int mainBodyPartId) async {
    try {
      return await sqlProvider.getExercisesByMainBodyPart(mainBodyPartId);
    } catch (e) {
      _logger.severe('Error getting exercises by main body part', e);
      return [];
    }
  }

}