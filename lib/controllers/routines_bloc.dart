import 'package:rxdart/rxdart.dart';


import '../models/part.dart';
import '../models/routine.dart';
import '../resource/db_provider.dart';
import '../resource/firebase_provider.dart';

enum UpdateType {
  parts,
}

class RoutinesBloc {
  final _allRoutinesFetcher = BehaviorSubject<List<Routine>>();
  final _allRecRoutinesFetcher = BehaviorSubject<List<Routine>>();
  final _currentRoutineFetcher = BehaviorSubject<Routine>();

  Stream<Routine> get currentRoutine => _currentRoutineFetcher.stream;
  Stream<List<Routine>> get allRoutines => _allRoutinesFetcher.stream;
  Stream<List<Routine>> get allRecRoutines => _allRecRoutinesFetcher.stream;
  List<Routine> get routines => _allRoutines;

  List<Routine> _allRoutines = <Routine>[];
  List<Routine> _allRecRoutines = <Routine>[];
  late Routine _currentRoutine;

  void fetchAllRoutines() {
    DBProvider.db.getAllRoutines().then((routines) {
      _allRoutines = routines;
      if (!_allRoutinesFetcher.isClosed) _allRoutinesFetcher.sink.add(_allRoutines);
    }).catchError((exp) {
      _allRoutinesFetcher.sink.addError(Exception());
    });
  }
  Future<List<Routine>> fetchRoutinesPaginated(int page, int pageSize) async {
    final routines = await DBProvider.db.getRoutinesPaginated(page, pageSize);
    return routines;
  }
  void fetchAllRecRoutines() {
    DBProvider.db.getAllRecRoutines().then((routines) {
      _allRecRoutines = routines;
      if (!_allRecRoutinesFetcher.isClosed) _allRecRoutinesFetcher.sink.add(_allRecRoutines);
    });
  }

  void deleteRoutine({required int routineId, required Routine routine}) {
    if (routineId == null) {
      _allRoutines.removeWhere((r) => r.id == routine.id);
    } else {
      _allRoutines.removeWhere((routine) => routine.id == routineId);
    }
    if (!_allRoutinesFetcher.isClosed) _allRoutinesFetcher.sink.add(_allRoutines);
    DBProvider.db.deleteRoutine(routine);
    firebaseProvider.uploadRoutines(_allRoutines).catchError((Object err) {
      print(err);
    });
  }

  void addRoutine(Routine routine) {
    DBProvider.db.newRoutine(routine).then((routineId) {
      routine.id = routineId;

      _allRoutines.add(routine);

      firebaseProvider.uploadRoutines(_allRoutines);

      if (!_allRoutinesFetcher.isClosed) _allRoutinesFetcher.sink.add(_allRoutines);
      if (!_currentRoutineFetcher.isClosed) _currentRoutineFetcher.sink.add(routine);
    });
  }

  void updateRoutine(Routine routine) {
    int index = _allRoutines.indexWhere((r) => r.id == routine.id);
    _allRoutines[index] = Routine.copyFromRoutine(routine);
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

  void addPartToRoutine({required int routineId, required Part part}){
    var routine = this.routines.singleWhere((r) => r.id == routineId);
    routine.parts.add(part);
  }

  void updatePartInRoutine({required int routineId, required Part part}){

  }

  void setCurrentRoutine(Routine routine) {
    _currentRoutine = routine;
    _currentRoutineFetcher.sink.add(_currentRoutine);
  }

  void dispose() {
    _allRoutinesFetcher.close();
    _allRecRoutinesFetcher.close();
    _currentRoutineFetcher.close();
  }
}


final routinesBloc = RoutinesBloc();