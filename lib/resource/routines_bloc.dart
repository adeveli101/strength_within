import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../models/parts.dart';
import '../resource/shared_prefs_provider.dart';
import '../models/routines.dart';
import '../models/exercises.dart';
import '../models/BodyPart.dart';
import '../models/RoutinePart.dart';
import '../models/WorkoutType.dart';
import '../firebase_class/firebase_routines.dart';
import 'sql_provider.dart';
import 'firebase_provider.dart';

class RoutinesBloc {
  final _allRoutinesFetcher = BehaviorSubject<List<Routine>>();
  final _allRecRoutinesFetcher = BehaviorSubject<List<Routine>>();
  final _currentRoutineFetcher = BehaviorSubject<Routine?>();

  Stream<Routine?> get currentRoutine => _currentRoutineFetcher.stream;
  Stream<List<Routine>> get allRoutines => _allRoutinesFetcher.stream;
  Stream<List<Routine>> get allRecRoutines => _allRecRoutinesFetcher.stream;

  List<Routine> _allRoutines = [];
  List<Routine> _allRecRoutines = [];
  Routine? _currentRoutine;

  final SQLProvider _sqlProvider = SQLProvider();
  final FirebaseProvider _firebaseProvider;
  final SharedPrefsProvider _sharedPrefsProvider = SharedPrefsProvider();

  RoutinesBloc(this._firebaseProvider) {
    initialize();
  }

  Future<void> initialize() async {
    await fetchAllRoutines();
    await fetchAllRecRoutines();
    startPeriodicSync();
  }

  void startPeriodicSync() {
    Timer.periodic(Duration(minutes: 15), (_) => syncData());
  }

  Future<void> syncData() async {
    String? userId = await _sharedPrefsProvider.getUserId();
    if (userId != null) {
      await _firebaseProvider.syncLocalAndFirebaseData(userId);
      await fetchAllRoutines();
      await fetchAllRecRoutines();
    }
  }

  Future<void> fetchAllRoutines() async {
    _allRoutines = await _sqlProvider.getAllRoutines();
    String? userId = await _sharedPrefsProvider.getUserId();
    if (userId != null) {
      List<FirebaseRoutine> firebaseRoutines = await _firebaseProvider.getUserRoutines(userId);
      for (var fbRoutine in firebaseRoutines) {
        int index = _allRoutines.indexWhere((r) => r.id == fbRoutine.routine.id);
        if (index == -1) {
          _allRoutines.add(fbRoutine.routine);
        }
      }
    }
    _allRoutinesFetcher.add(_allRoutines);
  }

  Future<void> fetchAllRecRoutines() async {
    _allRecRoutines = await _sqlProvider.getRecommendedRoutines();
    _allRecRoutinesFetcher.add(_allRecRoutines);
  }

  Future<void> addUserRoutine(Routine routine) async {
    String? userId = await _sharedPrefsProvider.getUserId();
    if (userId != null) {
      FirebaseRoutine fbRoutine = FirebaseRoutine.fromRoutine(routine);
      await _firebaseProvider.addOrUpdateUserRoutine(userId, fbRoutine);
      await fetchAllRoutines();
    }
  }

  Future<void> updateUserRoutine(FirebaseRoutine routine) async {
    String? userId = await _sharedPrefsProvider.getUserId();
    if (userId != null) {
      await _firebaseProvider.addOrUpdateUserRoutine(userId, routine);
      await fetchAllRoutines();
    }
  }

  Future<void> deleteUserRoutine(String routineId) async {
    String? userId = await _sharedPrefsProvider.getUserId();
    if (userId != null) {
      await _firebaseProvider.deleteUserRoutine(userId, routineId);
      await fetchAllRoutines();
    }
  }

  void setCurrentRoutine(Routine routine) {
    _currentRoutine = routine;
    _currentRoutineFetcher.add(_currentRoutine);
  }

  /// SQL Provider metodları

  ///workout type
  Future<List<WorkoutType>> getAllWorkoutTypes() => _sqlProvider.getAllWorkoutTypes();
  Future<WorkoutType?> getWorkoutType(int id) => _sqlProvider.getWorkoutType(id);
  ///routines
  Future<Routine?> getRoutine(int id) => _sqlProvider.getRoutine(id);
  Future<List<Routine>> getRoutinesByWorkoutType(int workoutTypeId) => _sqlProvider.getRoutinesByWorkoutType(workoutTypeId);
  Future<List<Routine>> getRoutinesPaginated(int page, int pageSize) => _sqlProvider.getRoutinesPaginated(page, pageSize);
  Future<List<RoutinePart>> getRoutinePartsByRoutineId(int routineId) => _sqlProvider.getRoutinePartsByRoutineId(routineId);
  Future<List<RoutinePart>> getRoutinePartsForRoutine(int routineId) => _sqlProvider.getRoutinePartsForRoutine(routineId);
  ///exercises
  Future<List<Exercise>> getAllExercises() => _sqlProvider.getAllExercises();
  Future<Exercise?> getExerciseById(int id) => _sqlProvider.getExerciseById(id);
  Future<List<Exercise>> getExercisesByWorkoutType(int workoutTypeId) => _sqlProvider.getExercisesByWorkoutType(workoutTypeId);
  Future<List<Exercise>> searchExercisesByName(String name) => _sqlProvider.searchExercisesByName(name);
  Future<List<Exercise>> getExercisesPaginated(int page, int pageSize) => _sqlProvider.getExercisesPaginated(page, pageSize);
  Future<List<Exercise>> getExercisesByBodyPart(MainTargetedBodyPart bodyPart) => _sqlProvider.getExercisesByBodyPart(bodyPart);
  Future<List<Exercise>> getExercisesForRoutine(int routineId) => _sqlProvider.getExercisesForRoutine(routineId);
  Future<List<BodyPart>> getAllBodyParts() => _sqlProvider.getAllBodyParts();
  ///bodypart
  Future<BodyPart?> getBodyPartById(int id) => _sqlProvider.getBodyPartById(id);
  Future<List<BodyPart>> getBodyPartsByMainTargetedBodyPart(MainTargetedBodyPart mainTargetedBodyPart) => _sqlProvider.getBodyPartsByMainTargetedBodyPart(mainTargetedBodyPart);
  Future<List<BodyPart>> searchBodyPartsByName(String query) => _sqlProvider.searchBodyPartsByName(query);
  Future<List<String>> getAllBodyPartNames() => _sqlProvider.getAllBodyPartNames();
  ///parts
  Future<Part?> getPartById(int id) async {return await _sqlProvider.getPartById(id);}
  Future<List<Part>> getPartsByMainTargetedBodyPart(MainTargetedBodyPart bodyPart) async {return await _sqlProvider.getPartsByMainTargetedBodyPart(bodyPart);}
  Future<List<Part>> getPartsBySetType(SetType setType) async {return await _sqlProvider.getPartsBySetType(setType);}
  Future<List<Part>> searchPartsByName(String query) async {return await _sqlProvider.searchPartsByName(query);}
  Future<List<Part>> getPartsPaginated(int page, int pageSize) async {return await _sqlProvider.getPartsPaginated(page, pageSize);}


  /// Firebase Provider metodları
  Future<String?> signInAnonymously() => _firebaseProvider.signInAnonymously();
  Future<void> addOrUpdateUserRoutine(String userId, FirebaseRoutine routine) => _firebaseProvider.addOrUpdateUserRoutine(userId, routine);
  Future<void> updateUserRoutineProgress(String userId, String routineId, int progress) => _firebaseProvider.updateUserRoutineProgress(userId, routineId, progress);
  Future<void> updateUserRoutineLastUsedDate(String userId, String routineId) => _firebaseProvider.updateUserRoutineLastUsedDate(userId, routineId);
  Future<List<Exercise>> getUserCustomExercises(String userId) => _firebaseProvider.getUserCustomExercises(userId);
  Future<void> addOrUpdateUserCustomExercise(String userId, Exercise exercise) => _firebaseProvider.addOrUpdateUserCustomExercise(userId, exercise);
  Future<void> deleteUserCustomExercise(String userId, String exerciseId) => _firebaseProvider.deleteUserCustomExercise(userId, exerciseId);

  /// SharedPrefsProvider metodları
  Future<void> prepareData() => _sharedPrefsProvider.prepareData();
  Future<double> getWeeklyAmount() => _sharedPrefsProvider.getWeeklyAmount();
  Future<void> setWeeklyAmount(double amt) => _sharedPrefsProvider.setWeeklyAmount(amt);
  Future<DateTime?> getFirstRunDate() => _sharedPrefsProvider.getFirstRunDate();
  Future<void> setLastSyncDate(DateTime date) => _sharedPrefsProvider.setLastSyncDate(date);
  Future<DateTime?> getLastSyncDate() => _sharedPrefsProvider.getLastSyncDate();
  Future<void> setUserId(String userId) => _sharedPrefsProvider.setUserId(userId);
  Future<String?> getUserId() => _sharedPrefsProvider.getUserId();
  Future<void> clearUserId() => _sharedPrefsProvider.clearUserId();
  Future<void> clearAllData() => _sharedPrefsProvider.clearAllData();






  Future<List<FirebaseRoutine>> getRecommendedRoutines() async {
    List<Routine> recommendedRoutines = await _sqlProvider.getRecommendedRoutines();
    String? userId = await _sharedPrefsProvider.getUserId();
    List<FirebaseRoutine> firebaseRecommendedRoutines = [];

    if (userId != null) {
      for (var routine in recommendedRoutines) {
        FirebaseRoutine fbRoutine = FirebaseRoutine.fromRoutine(routine);
        firebaseRecommendedRoutines.add(fbRoutine);
      }
    }

    return firebaseRecommendedRoutines;
  }




  Future<bool> hasStartedAnyRoutine() async {
    String? userId = await _sharedPrefsProvider.getUserId();
    if (userId == null) {
      return false; // User is not logged in, so they haven't started any routine
    }

    List<FirebaseRoutine> userRoutines = await _firebaseProvider.getUserRoutines(userId);

    // Check if any routine has a non-null lastUsedDate or a progress greater than 0
    return userRoutines.any((routine) =>
    routine.lastUsedDate != null || (routine.userProgress != null && routine.userProgress! > 0)
    );
  }







  void dispose() {
    _allRoutinesFetcher.close();
    _allRecRoutinesFetcher.close();
    _currentRoutineFetcher.close();
  }
}
