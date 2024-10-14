import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:workout/resource/shared_prefs_provider.dart';
import '../models/routine.dart';
import 'db_provider.dart';
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

  RoutinesBloc() {
    initialize();
  }

  void initialize() {
    fetchAllRoutines();
    fetchAllRecRoutines();
  }

  Future<void> fetchAllRoutines() async {
    try {
      final localRoutines = await DBProvider.db.getAllRoutines();
      List<Map<String, dynamic>> userRoutines = [];
      try {
        userRoutines = await firebaseProvider.getUserRoutines();
      } catch (e) {
        if (e is Exception && e.toString().contains("User not authenticated")) {
          print('User not authenticated. Only local routines will be fetched.');
        } else {
          rethrow;
        }
      }
      _allRoutines = _mergeRoutines(localRoutines, userRoutines);
      _allRoutines.sort((a, b) => b.isRecommended ? 1 : -1);
      _allRoutinesFetcher.add(_allRoutines);
    } catch (exp) {
      print('Error fetching routines: $exp');
      if (!_allRoutinesFetcher.isClosed) {
        _allRoutinesFetcher.addError('Failed to fetch routines: $exp');
      }
    }
  }

  List<Routine> _mergeRoutines(List<Routine> localRoutines, List<Map<String, dynamic>> userRoutines) {
    final mergedRoutines = <Routine>[];
    final userRoutineMap = {for (var r in userRoutines) r['id'].toString(): r};
    for (var localRoutine in localRoutines) {
      if (userRoutineMap.containsKey(localRoutine.id.toString())) {
        mergedRoutines.add(_mergeRoutineData(localRoutine, userRoutineMap[localRoutine.id.toString()]!));
      } else {
        mergedRoutines.add(localRoutine);
      }
    }
    return mergedRoutines;
  }

  void startPeriodicSync() {
    Timer.periodic(Duration(hours: 12), (_) => syncRoutines());
  }

  Future<void> updateRoutineProgress(int routineId, int progress) async {
    try {
      await firebaseProvider.updateRoutineProgress(routineId, progress);
      final routine = _allRoutines.firstWhere((r) => r.id == routineId);
      final updatedRoutine = routine.copyWith(userProgress: progress);
      int index = _allRoutines.indexWhere((r) => r.id == routineId);
      if (index != -1) {
        _allRoutines[index] = updatedRoutine;
        _allRoutinesFetcher.add(_allRoutines);
      }
      if (_currentRoutine?.id == routineId) {
        _currentRoutine = updatedRoutine;
        _currentRoutineFetcher.add(_currentRoutine);
      }
      await fetchAllRoutines();
    } catch (e) {
      print('Error updating routine progress: $e');
      rethrow;
    }
  }

  Future<List<Routine>> searchRoutines(String query) async {
    final allRoutines = await DBProvider.db.getAllRoutines();
    return allRoutines.where((routine) =>
        routine.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  Future<void> syncRoutines() async {
    final localRoutines = await DBProvider.db.getAllRoutines();
    final userRoutines = await firebaseProvider.getUserRoutines();
    final mergedRoutines = _mergeRoutines(localRoutines, userRoutines);
    for (var routine in mergedRoutines) {
      await firebaseProvider.saveUserRoutine(routine);
    }
    await sharedPrefsProvider.setLastSyncDate(DateTime.now());
  }

  Routine _mergeRoutineData(Routine localRoutine, Map<String, dynamic> userRoutineData) {
    return localRoutine.copyWith(
      isRecommended: userRoutineData['isRecommended'] as bool? ?? false,
      userProgress: userRoutineData['progress'] as int? ?? 0,
    );
  }

  Future<void> fetchAllRecRoutines() async {
    try {
      _allRecRoutines = await DBProvider.db.getAllRecRoutines();
      _allRecRoutinesFetcher.add(_allRecRoutines);
    } catch (error) {
      _allRecRoutinesFetcher.addError(error);
    }
  }

  Future<bool> hasStartedAnyRoutine() async {
    final routines = await DBProvider.db.getAllRoutines();
    final userRoutines = await firebaseProvider.getUserRoutines();
    final mergedRoutines = _mergeRoutines(routines, userRoutines);
    return mergedRoutines.any((routine) => routine.isRecommended);
  }

  Future<List<Routine>> getRecommendedRoutines() async {
    final allRoutines = await DBProvider.db.getAllRoutines();
    final userRoutines = await firebaseProvider.getUserRoutines();
    final mergedRoutines = _mergeRoutines(allRoutines, userRoutines);
    return mergedRoutines.where((routine) => routine.isRecommended).take(5).toList();
  }

  Future<List<Routine>> fetchRoutinesPaginated(int page, int pageSize) async {
    return await DBProvider.db.getRoutinesPaginated(page, pageSize);
  }

  Future<void> deleteRoutine({required int routineId}) async {
    _allRoutines.removeWhere((routine) => routine.id == routineId);
    _allRoutinesFetcher.add(_allRoutines);
    await firebaseProvider.deleteUserRoutine(routineId);
  }

  Future<void> addRoutine(Routine routine) async {
    await firebaseProvider.saveUserRoutine(routine);
    await fetchAllRoutines();
  }

  Future<void> updateRoutine(Routine routine) async {
    await firebaseProvider.saveUserRoutine(routine);
    await fetchAllRoutines();
  }

  void setCurrentRoutine(Routine routine) {
    _currentRoutine = routine;
    _currentRoutineFetcher.add(_currentRoutine);
  }

  Future<void> toggleRoutineFavorite(int routineId) async {
    await firebaseProvider.toggleRoutineFavorite(routineId);
    await fetchAllRoutines();
  }

  void dispose() {
    _allRoutinesFetcher.close();
    _allRecRoutinesFetcher.close();
    _currentRoutineFetcher.close();
  }
}

final routinesBloc = RoutinesBloc();
