import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/ui/part_ui/part_card.dart';
import 'package:workout/ui/part_ui/part_detail.dart';
import 'package:workout/ui/routine_ui/routine_card.dart';
import 'package:logging/logging.dart';
import 'package:workout/ui/routine_ui/routine_detail.dart';
import '../data_bloc_part/part_bloc.dart';
import '../data_bloc_routine/routines_bloc.dart';
import '../models/PartFocusRoutine.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late RoutinesBloc _routinesBloc;
  late PartsBloc _partsBloc;
  final _logger = Logger('HomePage');

  @override
  void initState() {
    super.initState();
    _setupLogging();
    _routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    _partsBloc = BlocProvider.of<PartsBloc>(context);
    _loadAllData();
  }

  // Logging kurulumu için metod
  void _setupLogging() {
    hierarchicalLoggingEnabled = true;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.loggerName}: ${record.level.name}: ${record.message}');
    });
  }

  void _loadAllData() {
    _logger.info('Loading all data for user: ${widget.userId}');
    _partsBloc.add(FetchParts());
    _routinesBloc.add(FetchRoutines());

    if (!mounted) return;

    _routinesBloc.add(FetchRoutines());
    context.read<PartsBloc>().add(FetchParts());

  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          _loadAllData(); // Geri dönüldüğünde verileri yenile
        }
        return;
      },
      canPop: true, // Ana sayfadan çıkışa izin ver
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ana Sayfa'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAllData,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => _loadAllData(),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildParts(context),
                _buildRoutines(),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildParts(BuildContext context) {
    return BlocConsumer<PartsBloc, PartsState>(
      listener: (context, state) {
        if (state is PartsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is PartsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PartsLoaded || state is PartExercisesLoaded) {
          final parts = state is PartsLoaded
              ? state.parts
              : (state as PartExercisesLoaded).parts;

          // Başlanmış partları filtrele
          final startedParts = parts.where((p) => p.lastUsedDate != null).toList()
            ..sort((a, b) => (b.lastUsedDate ?? DateTime(0))
                .compareTo(a.lastUsedDate ?? DateTime(0)));

          return Column(
            children: [
              // Başlanmış partlar varsa göster
              if (startedParts.isNotEmpty) ...[
                _buildPartList('Devam Eden Antrenmanlar', startedParts),
              ],

              // Keşfet bölümü
              _buildPartList('Keşfet', _getRandomParts(parts)),
            ],
          );
        }

        return const Center(child: Text('Veriler yüklenirken bir hata oluştu'));
      },
    );
  }

  Widget _buildPartList(String title, List<Parts> parts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: parts.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final part = parts[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 220,
                  child: PartCard(
                    key: ValueKey(part.id),
                    part: part,
                    userId: widget.userId,
                    onTap: () => _showPartDetailBottomSheet(part.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Parts> _getRandomParts(List<Parts> parts) {
    final randomParts = List<Parts>.from(parts);
    randomParts.shuffle();
    return randomParts.take(5).toList();
  }




  Future<void> _showPartDetailBottomSheet(int partId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PartDetailBottomSheet(
        partId: partId,
        userId: widget.userId,
      ),
    );
  }







  Widget _buildRoutines() {
    return BlocConsumer<RoutinesBloc, RoutinesState>(
      listener: (context, state) {
        if (state is RoutinesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is RoutinesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is RoutinesLoaded) {
          final List<Routines> routines = state.routines;

          if (routines.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Henüz rutin bulunmamaktadır.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          // Başlanmış rutinleri filtrele
          final List<Routines> startedRoutines = routines
              .where((r) => r.lastUsedDate != null)
              .toList()
            ..sort((a, b) => (b.lastUsedDate ?? DateTime(0))
                .compareTo(a.lastUsedDate ?? DateTime(0)));

          return Column(
            children: [
              if (startedRoutines.isNotEmpty) ...[
                _buildRoutineList('Devam Eden Rutinler', startedRoutines),
              ],
              _buildRoutineList('Önerilen Rutinler', _getRandomRoutines(routines)),
            ],
          );
        }

        if (state is RoutineExercisesLoaded) {
          // Rutin detayları yüklendiğinde yapılacak işlemler
          return const SizedBox.shrink();
        }

        return const Center(
          child: Text('Rutinler yüklenirken bir hata oluştu'),
        );
      },
    );
  }

  Widget _buildRoutineList(String title, List<Routines> routines) {
    if (routines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 270,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: routines.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final routine = routines[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 300,
                  child: RoutineCard(
                    key: ValueKey(routine.id),
                    routine: routine,
                    userId: widget.userId,
                    onTap: () => _showRoutineDetailBottomSheet(routine.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Routines> _getRandomRoutines(List<Routines> routines) {
    if (routines.isEmpty) return [];
    final randomRoutines = List<Routines>.from(routines);
    randomRoutines.shuffle();
    return randomRoutines.take(5).toList();
  }

  Future<void> _showRoutineDetailBottomSheet(int routineId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoutineDetailBottomSheet(
        routineId: routineId,
        userId: widget.userId,
      ),
    );
  }



}