import 'package:rxdart/rxdart.dart';
import '../models/RoutineHistory.dart';
import '../models/routine.dart';
import '../resource/db_provider.dart';
import '../resource/firebase_provider.dart';


class RoutinesBloc {
  final _allRoutinesFetcher = BehaviorSubject<List<Routine>>();
  final _allRecRoutinesFetcher = BehaviorSubject<List<Routine>>();
  final _currentRoutineFetcher = BehaviorSubject<Routine>();

  Stream<Routine> get currentRoutine => _currentRoutineFetcher.stream;
  Stream<List<Routine>> get allRoutines => _allRoutinesFetcher.stream;
  Stream<List<Routine>> get allRecRoutines => _allRecRoutinesFetcher.stream;

  List<Routine> get routines => _allRoutines;
  List<Routine> _allRoutines = [];
  List<Routine> _allRecRoutines = [];
  late Routine _currentRoutine;

  void fetchAllRoutines() {
    DBProvider.db.getAllRoutines().then((routines) {
      _allRoutines = routines;
      if (!_allRoutinesFetcher.isClosed) _allRoutinesFetcher.sink.add(_allRoutines);
    }).catchError((exp) {
      print('Error fetching routines: $exp');
      if (!_allRoutinesFetcher.isClosed) _allRoutinesFetcher.sink.addError(Exception('Failed to fetch routines: $exp'));
    });
  }





  Future<List<Routine>> fetchRoutinesPaginated(int page, int pageSize) async {
    return await DBProvider.db.getRoutinesPaginated(page, pageSize);
  }

  void initialize() {
    fetchAllRoutines();
    fetchAllRecRoutines();
  }

  void fetchAllRecRoutines() {
    DBProvider.db.getAllRecRoutines().then((routines) {
      _allRecRoutines = routines;
      if (!_allRecRoutinesFetcher.isClosed) {
        _allRecRoutinesFetcher.sink.add(_allRecRoutines);
      }
    }).catchError((error) {
      _allRecRoutinesFetcher.sink.addError(error);
    });
  }



  void deleteRoutine({required int routineId}) {
    _allRoutines.removeWhere((routine) => routine.id == routineId);
    if (!_allRoutinesFetcher.isClosed) _allRoutinesFetcher.sink.add(_allRoutines);
    DBProvider.db.deleteRoutine(routineId);
    firebaseProvider.uploadRoutines(_allRoutines).catchError((Object err) {
      print(err);
    });
  }

  void addRoutine(Routine routine) {
    DBProvider.db.newRoutine(routine).then((routineId) {
      routine = routine.copyWith(id: routineId);
      _allRoutines.add(routine);
      firebaseProvider.uploadRoutines(_allRoutines);
      if (!_allRoutinesFetcher.isClosed) _allRoutinesFetcher.sink.add(_allRoutines);
      if (!_currentRoutineFetcher.isClosed) _currentRoutineFetcher.sink.add(routine);
    }).catchError((error) {
      print('Error adding routine: $error');
    });
  }


  void updateRoutine(Routine routine) {
    int index = _allRoutines.indexWhere((r) => r.id == routine.id);
    _allRoutines[index] = routine;
    if (!_allRoutinesFetcher.isClosed) _allRoutinesFetcher.sink.add(_allRoutines);
    if (!_currentRoutineFetcher.isClosed) _currentRoutineFetcher.sink.add(routine);
    DBProvider.db.updateRoutine(routine);
    firebaseProvider.uploadRoutines(_allRoutines);
  }

  void restoreRoutines() {
    firebaseProvider.restoreRoutines().then((routines) {
      DBProvider.db.deleteAllRoutines();
      DBProvider.db.addAllRoutines(routines);
      _allRoutines = routines;
      if (!_allRoutinesFetcher.isClosed) _allRoutinesFetcher.sink.add(_allRoutines);
    });
  }

  void addPartToRoutine({required int routineId, required int partId}) {
    var routine = this.routines.singleWhere((r) => r.id == routineId);
    routine.partIds.add(partId);
    updateRoutine(routine);
  }

  void removePartFromRoutine({required int routineId, required int partId}) {
    var routine = this.routines.singleWhere((r) => r.id == routineId);
    routine.partIds.remove(partId);
    updateRoutine(routine);
  }

  void setCurrentRoutine(Routine routine) {
    _currentRoutine = routine;
    _currentRoutineFetcher.sink.add(_currentRoutine);
  }

  // RoutineHistory methods
  Future<void> addRoutineHistory(RoutineHistory history) async {
    await DBProvider.db.addRoutineHistory(history);
  }

  Future<List<RoutineHistory>> getRoutineHistory(int routineId) async {
    return await DBProvider.db.getRoutineHistory(routineId);
  }

  // RoutineWeekdays methods
  Future<void> updateRoutineWeekdays(int routineId, List<int> weekdays) async {
    await DBProvider.db.updateRoutineWeekdays(routineId, weekdays);
  }

  Future<List<int>> getRoutineWeekdays(int routineId) async {
    return await DBProvider.db.getRoutineWeekdays(routineId);
  }

  void dispose() {
    _allRoutinesFetcher.close();
    _allRecRoutinesFetcher.close();
    _currentRoutineFetcher.close();
  }
}

final routinesBloc = RoutinesBloc();
