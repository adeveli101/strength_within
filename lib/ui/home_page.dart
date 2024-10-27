import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/ui/part_ui/part_card.dart';
import 'package:workout/ui/part_ui/part_detail.dart';
import 'package:workout/ui/routine_ui/routine_card.dart';
import 'package:workout/ui/routine_ui/routine_detail.dart';
import '../data_bloc_part/part_bloc.dart';
import '../data_bloc_routine/routines_bloc.dart';
import 'package:logging/logging.dart';
import 'list_pages/parts_page.dart';

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
  List _randomRoutines = [];
  List _randomParts = [];

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
    _logger.info('Loading all data for user: ${widget.userId}');
    _partsBloc.add(FetchParts());
    _routinesBloc.add(FetchRoutines());
    setState(() {
      _randomRoutines = [];
      _randomParts = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fitness Uygulaması'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeText(constraints),
                _buildParts(constraints),
                _buildRoutines(constraints),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeText(BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Hoş Geldin!',
        style: TextStyle(
          fontSize: constraints.maxWidth > 600 ? 32 : 28,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildParts(BoxConstraints constraints) {
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
          return Center(
            child: LoadingAnimationWidget.threeArchedCircle(
              color: Colors.blue,
              size: 50,
            ),
          );
        }
        if (state is PartsLoaded || state is PartExercisesLoaded) {
          final parts = state is PartsLoaded
              ? state.parts
              : (state as PartExercisesLoaded).parts;
          final startedParts = parts.where((p) => p.lastUsedDate != null).toList()
            ..sort((a, b) => (b.lastUsedDate ?? DateTime(0))
                .compareTo(a.lastUsedDate ?? DateTime(0)));
          return Column(
            children: [
              if (startedParts.isNotEmpty) ...[
                _buildPartList('Devam Eden Antrenmanlar', startedParts, constraints),
              ],
              _buildPartList('Keşfet', _getRandomParts(parts), constraints, showAllButton: true),
            ],
          );
        }
        return Center(child: Text('Veriler yüklenirken bir hata oluştu'));
      },
    );
  }

  Widget _buildPartList(String title, List parts, BoxConstraints constraints, {bool showAllButton = false}) {
    final isWideScreen = constraints.maxWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: isWideScreen ? 24 : 20,
                    fontWeight: FontWeight.bold
                ),
              ),
              if (showAllButton)
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PartsPage(userId: widget.userId)));
                  },
                  child: Text('Hepsini Gör'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: isWideScreen ? 280 : 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: parts.length,
            itemBuilder: (context, index) {
              return _buildPartCard(parts[index],constraints);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPartCard(dynamic part, BoxConstraints constraints) {
    return LayoutBuilder(
      builder: (context, cardConstraints) {
        final isWideScreen = constraints.maxWidth > 500;
        final cardWidth = isWideScreen ? 200.0 : 240.0;
        final cardHeight = isWideScreen ? 320.0 : 230.0;

        return Container(
          width: cardWidth,
          height: cardHeight,
          child: Card(
            margin: EdgeInsets.all(4),
            child: PartCard(
              key: ValueKey(part.id),
              part: part,
              userId: widget.userId,
              onTap: () => _showPartDetailBottomSheet(part.id),
            ),
          ),
        );
      },
    );
  }



  List _getRandomParts(List parts) {
    if (_randomParts.isEmpty) {
      final randomParts = List.from(parts);
      randomParts.shuffle();
      _randomParts = randomParts.take(5).toList();
    }
    return _randomParts;
  }

  Future _showPartDetailBottomSheet(int partId) async {
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

  Widget _buildRoutines(BoxConstraints constraints) {
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
          return Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.blue,
              size: 50,
            ),
          );
        }
        if (state is RoutinesLoaded) {
          final List<Routines> routines = state.routines;
          if (routines.isEmpty) {
            return _buildEmptyRoutinesMessage(constraints);
          }
          final List<Routines> startedRoutines = routines
              .where((r) => r.lastUsedDate != null)
              .toList()
            ..sort((a, b) => (b.lastUsedDate ?? DateTime(0))
                .compareTo(a.lastUsedDate ?? DateTime(0)));
          return Column(
            children: [
              if (startedRoutines.isNotEmpty) ...[
                _buildRoutineList('Devam Eden Rutinler', startedRoutines, constraints),
              ],
              _buildRoutineList('Önerilen Rutinler', _getRandomRoutines(routines), constraints, showAllButton: true),
            ],
          );
        }
        return Center(child: Text('Rutinler yüklenirken bir hata oluştu'));
      },
    );
  }

  Widget _buildEmptyRoutinesMessage(BoxConstraints constraints) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: constraints.maxWidth > 600 ? 100 : 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Henüz rutin bulunmamaktadır.',
            style: TextStyle(fontSize: constraints.maxWidth > 600 ? 22 : 18, color: Colors.grey),
          ),
          ElevatedButton(
            child: Text('Rutin Ekle'),
            onPressed: () {
              // Rutin ekleme sayfasına yönlendir
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineList(String title, List<Routines> routines, BoxConstraints constraints, {bool showAllButton = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: constraints.maxWidth > 600 ? 24 : 20, fontWeight: FontWeight.bold),
              ),
              if (showAllButton)
                TextButton(
                  onPressed: () {
                    // Navigate to routines_list_page
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => RoutinesListPage()));
                  },
                  child: Text('Hepsini Gör'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: constraints.maxWidth > 600 ? 320 : 270,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: routines.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: constraints.maxWidth > 600 ? 300 : 250,
                child: _buildRoutineCard(routines[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineCard(Routines routine) {
    return Card(
      margin: EdgeInsets.all(8),
      child: RoutineCard(
        key: ValueKey(routine.id),
        routine: routine,
        userId: widget.userId,
        onTap: () => _showRoutineDetailBottomSheet(routine.id),
      ),
    );
  }

  List<Routines> _getRandomRoutines(List<Routines> routines) {
    if (_randomRoutines.isEmpty) {
      if (routines.isEmpty) return [];
      final randomRoutines = List<Routines>.from(routines);
      randomRoutines.shuffle();
      _randomRoutines = randomRoutines.take(5).toList();
    }
    return _randomRoutines.cast<Routines>();
  }

  Future _showRoutineDetailBottomSheet(int routineId) async {
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
