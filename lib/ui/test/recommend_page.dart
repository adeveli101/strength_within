import 'package:flutter/material.dart';
import '../../ai_predictors/ai_bloc/ai_repository.dart';
import '../../ai_predictors/ai_bloc/reccomend_system.dart';
import '../../blocs/data_bloc_part/PartRepository.dart';
import '../../blocs/data_bloc_routine/RoutineRepository.dart';
import '../../blocs/data_provider/firebase_provider.dart';
import '../../blocs/data_provider/sql_provider.dart';
import '../../models/firebase_models/user_ai_profile.dart';
import '../../models/sql_models/routines.dart';

class RecommendPage extends StatefulWidget {
  final String userId;
  final RoutineRepository routineRepository;
  final PartRepository partRepository;

  const RecommendPage({
    super.key,
    required this.userId,
    required this.routineRepository,
    required this.partRepository,
  });

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  late final RecommendationService _recommendationService;
  late Future<List<Routines>> _recommendationsFuture;
  UserAIProfile? _userProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadInitialData();
  }

  void _initializeServices() {
    _recommendationService = RecommendationService(
      AIRepository(
        SQLProvider(),
        FirebaseProvider(),
      ),
      SQLProvider(),
    );
  }

  Future<void> _loadInitialData() async {
    await _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final aiRepository = AIRepository(SQLProvider(), FirebaseProvider());
      final userProfile = await aiRepository.getLatestUserPrediction(widget.userId);

      if (!mounted) return;

      setState(() {
        _userProfile = userProfile;
        _loadRecommendations();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil yüklenirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadRecommendations() {
    if (_userProfile == null) return;

    setState(() {
      _recommendationsFuture = _recommendationService.getRecommendedRoutines(
        userId: widget.userId,
        userProfile: _userProfile!,
      );
    });
  }

  Future<void> _refreshData() async {
    await _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Önerilen Programlar'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _refreshData,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_userProfile == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return FutureBuilder<List<Routines>>(
      future: _recommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Hata oluştu: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        final routines = snapshot.data ?? [];
        if (routines.isEmpty) {
          return const Center(
            child: Text('Henüz öneri bulunmuyor'),
          );
        }

        return _buildRoutinesList(routines);
      },
    );
  }

  Widget _buildRoutinesList(List<Routines> routines) {
    return ListView.builder(
      itemCount: routines.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildRoutineCard(routines[index]),
    );
  }

  Widget _buildRoutineCard(Routines routine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(routine.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(routine.description),
            const SizedBox(height: 8),
            _buildDifficultyRow(routine),
          ],
        ),
        trailing: _buildFavoriteButton(routine),
        onTap: () => _navigateToRoutineDetail(routine),
      ),
    );
  }

  Widget _buildDifficultyRow(Routines routine) {
    return Row(
      children: [
        Icon(
          Icons.fitness_center,
          size: 16,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 4),
        Text('Zorluk: ${routine.difficulty}/5'),
      ],
    );
  }

  Widget _buildFavoriteButton(Routines routine) {
    return IconButton(
      icon: Icon(
        routine.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: routine.isFavorite ? Colors.red : null,
      ),
      onPressed: () => _toggleFavorite(routine),
    );
  }

  void _toggleFavorite(Routines routine) {
    // TODO: Implement favorite toggle logic
  }

  void _navigateToRoutineDetail(Routines routine) {
    // TODO: Implement navigation to routine detail
  }
}
