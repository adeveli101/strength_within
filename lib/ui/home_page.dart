import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/ui/part_ui/part_card.dart';
import 'package:workout/ui/part_ui/part_detail.dart';
import 'package:workout/ui/routine_ui/routine_card.dart';
import 'package:logging/logging.dart';
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
  // ignore: unused_field
  final _logger = Logger('HomePage');

  @override
  void initState() {
    super.initState();
    _setupLogging();
    _routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    _partsBloc = BlocProvider.of<PartsBloc>(context);
    _loadAllData();
  }

  void _setupLogging() {
    hierarchicalLoggingEnabled = true;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.loggerName}: ${record.level.name}: ${record.message}');
    });
  }

  void _loadAllData() {
    debugPrint('Loading all data for user: ${widget.userId}');
    _partsBloc.add(FetchParts());  // Önce part'ları yükle
    _routinesBloc.add(FetchHomeData(userId: widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadAllData();
        },
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
        debugPrint('Building parts with state: ${state.runtimeType}');

        if (state is PartsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // PartExercisesLoaded state'ini de kontrol ediyoruz
        if (state is PartsLoaded || state is PartExercisesLoaded) {
          final parts = state is PartsLoaded
              ? state.parts
              : (state as PartExercisesLoaded).parts;

          if (parts.isEmpty) {
            return const Center(child: Text('Henüz hiç part eklenmemiş.'));
          }

          return Column(
            children: [
              if (parts.any((p) => p.isFavorite))
                _buildPartList('Favori Part\'larınız',
                    parts.where((p) => p.isFavorite).toList()
                ),

              if (parts.any((p) => p.lastUsedDate != null))
                _buildPartList('Son Kullanılan Part\'lar',
                    _getRecentParts(parts)
                ),

              _buildPartList('Keşfet',
                  _getRandomParts(parts)
              ),
            ],
          );
        }

        return const Center(child: Text('Veriler yüklenirken bir hata oluştu.'));
      },
    );
  }


  List<Parts> _getRecentParts(List<Parts> parts) {
    final recentParts = parts
        .where((p) => p.lastUsedDate != null)
        .toList()
      ..sort((a, b) => (b.lastUsedDate ?? DateTime(0))
          .compareTo(a.lastUsedDate ?? DateTime(0)));
    return recentParts.take(5).toList();
  }

  List<Parts> _getRandomParts(List<Parts> parts) {
    final randomParts = List<Parts>.from(parts);
    randomParts.shuffle();
    return randomParts.take(5).toList();
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
          return _buildRoutineSections(state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRoutineSections(RoutinesLoaded state) {
    return Column(
      children: [
        if (state.routines.any((r) => r.isFavorite))
          _buildRoutineList('Favori Rutinleriniz',
              state.routines.where((r) => r.isFavorite).toList()
          ),

        if (state.routines.any((r) => r.lastUsedDate != null))
          _buildRoutineList('Son Kullanılan Rutinler',
              state.routines
                  .where((r) => r.lastUsedDate != null)
                  .toList()
                ..sort((a, b) => (b.lastUsedDate ?? DateTime(0))
                    .compareTo(a.lastUsedDate ?? DateTime(0)))
          ),

        _buildRoutineList('Tüm Rutinler', state.routines),
      ],
    );
  }

  Widget _buildRoutineList(String title, List<Routines> routines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return SizedBox(
                width: 300,
                child: RoutineCard(
                  routine: routine,
                  userId: widget.userId,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPartList(String title, List<Parts> parts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: parts.length,
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

  Future<void> _showPartDetailBottomSheet(int partId) async {
    debugPrint('Showing part detail bottom sheet for partId: $partId');
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
}
