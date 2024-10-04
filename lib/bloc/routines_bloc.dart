import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:workout/models/routine.dart';
import 'package:workout/resource/db_provider.dart';
import 'package:workout/resource/firebase_provider.dart';

class RoutinesBloc {
  final _allRoutinesFetcher = BehaviorSubject<List<Routine>>();
  final _allRecRoutinesFetcher = BehaviorSubject<List<Routine>>();
  final _currentRoutineFetcher = BehaviorSubject<Routine>();

  Stream<Routine> get currentRoutine => _currentRoutineFetcher.stream;
  Stream<List<Routine>> get allRoutines => _allRoutinesFetcher.stream;
  Stream<List<Routine>> get allRecRoutines => _allRecRoutinesFetcher.stream;

  List<Routine> _allRoutines = [];

  void fetchAllRoutines() {
    DBProvider.db.getAllRoutines().then((routines) {
      _allRoutines = routines;
      _allRoutinesFetcher.add(_allRoutines);
    }).catchError((error) {
      _allRoutinesFetcher.addError(Exception('Failed to fetch routines'));
    });
  }

  Future<List<Routine>> fetchRoutinesPaginated(int page, int pageSize) async {
    final startIndex = page * pageSize;
    final endIndex = startIndex + pageSize;
    final List<Routine> paginatedRoutines = _allRoutines.sublist(
        startIndex,
        endIndex > _allRoutines.length ? _allRoutines.length : endIndex
    );
    return paginatedRoutines;
  }


  void fetchAllRecRoutines() {
    DBProvider.db.getAllRecRoutines().then((routines) {
      _allRecRoutinesFetcher.add(routines);
    });
  }

  void deleteRoutine(int routineId) {
    final routineIndex = _allRoutines.indexWhere((r) => r.id == routineId);
    if (routineIndex != -1) {
      final routineToDelete = _allRoutines.removeAt(routineIndex);
      if (!_allRoutinesFetcher.isClosed) {
        _allRoutinesFetcher.sink.add(_allRoutines);
      }
      DBProvider.db.deleteRoutine(routineToDelete);
      firebaseProvider.uploadRoutines(_allRoutines).catchError((Object err) {
        if (kDebugMode) {
          print('Failed to upload routines to Firebase: $err');
        }
      });
    }
  }

  void addRoutine(Routine routine) {
    DBProvider.db.newRoutine(routine).then((routineId) {
      routine.id = routineId;
      _allRoutines.add(routine);
      _allRoutinesFetcher.add(_allRoutines);
      _currentRoutineFetcher.add(routine);
      _uploadRoutinesToFirebase();
    });
  }

  void updateRoutine(Routine routine) {
    int index = _allRoutines.indexWhere((r) => r.id == routine.id);
    if (index != -1) {
      _allRoutines[index] = routine;
      if (!_allRoutinesFetcher.isClosed) {
        _allRoutinesFetcher.sink.add(_allRoutines);
      }
      if (!_currentRoutineFetcher.isClosed) {
        _currentRoutineFetcher.sink.add(routine);
      }
      DBProvider.db.updateRoutine(routine);
      firebaseProvider.uploadRoutines(_allRoutines);
    }
  }

  void restoreRoutines() {
    firebaseProvider.restoreRoutines().then((routines) {
      DBProvider.db.deleteAllRoutines();
      DBProvider.db.addAllRoutines(routines);
      _allRoutines = routines;
      _allRoutinesFetcher.add(_allRoutines);
    });
  }

  void setCurrentRoutine(Routine routine) {
    _currentRoutineFetcher.add(routine);
  }

  void _uploadRoutinesToFirebase() {
    firebaseProvider.uploadRoutines(_allRoutines).catchError((error) {
      if (kDebugMode) {
        print('Failed to upload routines to Firebase: $error');
      }
    });
  }

  void dispose() {
    _allRoutinesFetcher.close();
    _allRecRoutinesFetcher.close();
    _currentRoutineFetcher.close();
  }
}

final routinesBloc = RoutinesBloc();