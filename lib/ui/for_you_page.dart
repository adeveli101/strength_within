import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/data_schedule_bloc/schedule_repository.dart';
import 'package:workout/ui/part_ui/part_card.dart';
import 'package:workout/ui/part_ui/part_detail.dart';
import 'package:workout/ui/routine_ui/routine_card.dart';
import 'package:workout/ui/routine_ui/routine_detail.dart';
import '../ai_services/ai_bloc/ai_bloc.dart';
import '../ai_services/ai_bloc/ai_state.dart';
import '../blocs/for_you_bloc.dart';
import '../data_bloc_part/PartRepository.dart';
import '../data_bloc_part/part_bloc.dart';
import '../data_bloc_routine/RoutineRepository.dart';
import '../data_provider/firebase_provider.dart';
import '../data_provider/sql_provider.dart';
import '../models/Parts.dart';
import '../models/routines.dart';
import '../z.app_theme/app_theme.dart';
import 'list_pages/parts_page.dart';
import 'list_pages/routines_page.dart';

class ForYouPage extends StatefulWidget {
  final String userId;

  const ForYouPage({super.key, required this.userId});

  @override
  _ForYouPageState createState() => _ForYouPageState();
}

class _ForYouPageState extends State<ForYouPage> {
  final sqlProvider = SQLProvider();
  final firebaseProvider = FirebaseProvider();
  bool isTestMode = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ForYouBloc(
            userId: widget.userId,
            partRepository: PartRepository(sqlProvider, firebaseProvider),
            routineRepository: RoutineRepository(sqlProvider, firebaseProvider),
            isTestMode: isTestMode, scheduleRepository: ScheduleRepository(firebaseProvider, sqlProvider),
          )..add(FetchForYouData(userId: widget.userId)),
        ),
        BlocProvider(
          create: (context) => AIBloc(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Senin İçin'),
          actions: [
            IconButton(
              icon: Icon(isTestMode ? Icons.bug_report : Icons.bug_report_outlined),
              onPressed: () {
                setState(() {
                  isTestMode = !isTestMode;
                });
                context.read<ForYouBloc>().add(FetchForYouData(userId: widget.userId));
              },
              tooltip: 'Test Modu',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<ForYouBloc>().add(FetchForYouData(userId: widget.userId));
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (isTestMode)
              Container(
                color: Colors.yellow,
                padding: EdgeInsets.all(8),
                child: Text('TEST MODU', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            Expanded(
              child: BlocListener<AIBloc, AIState>(
                listener: (context, aiState) {
                  if (aiState is AIError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(aiState.message)),
                    );
                  }
                },
                child: BlocConsumer<ForYouBloc, ForYouState>(
                  listener: (context, state) {
                    if (state is ForYouError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is ForYouLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ForYouLoaded) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<ForYouBloc>().add(
                            FetchForYouData(userId: widget.userId),
                          );
                        },
                        child: ListView(
                          children: [
                            if (state.weeklyChallenge != null)
                              _buildWeeklyChallenge(
                                state.weeklyChallenge!,
                                state.hasAcceptedChallenge,
                                context,
                              ),
                            _buildRecommendations(context, state),
                          ],
                        ),
                      );
                    } else {
                      return const Center(
                        child: Text('Veriler yüklenirken bir hata oluştu'),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChallenge(
      Routines challenge,
      bool hasAccepted,
      BuildContext context,
      ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _navigateToRoutineDetail(context, challenge),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.purple.shade700],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.white, size: 32),
                  SizedBox(width: 8),
                  Text(
                    'Haftalık Meydan Okuma',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                challenge.name,
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                challenge.description,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              if (!hasAccepted)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                  ),
                  onPressed: () {
                    context.read<ForYouBloc>().add(
                      AcceptWeeklyChallenge(
                        userId: widget.userId,
                        routineId: challenge.id,
                      ),
                    );
                  },
                  icon: const Icon(Icons.flag),
                  label: const Text('Meydan Okumayı Kabul Et'),
                )
              else
                const Chip(
                  backgroundColor: Colors.white,
                  label: Text(
                    'Meydan Okuma Kabul Edildi',
                    style: TextStyle(color: Colors.purple),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, ForYouLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Ai ile Kişiselleştirilmiş',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'Komple Rutinler'),
                  Tab(text: 'Bölgesel Rutinler'),
                ],
              ),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    _buildRoutineRecommendations(context, state.recommendedRoutines),
                    _buildPartRecommendations(context, state.recommendedParts),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineRecommendations(BuildContext context, List<Routines> recommendedRoutines) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedRoutines.length,
            itemBuilder: (context, index) {
              final routine = recommendedRoutines[index];
              return GestureDetector(
                onTap: () => _navigateToRoutineDetail(context, routine),
                onLongPress: () => _showRoutineDetails(context, routine),
                child: Container(
                  width: 280,
                  margin: EdgeInsets.all(8),
                  child: RoutineCard(
                    routine: routine,
                    userId: widget.userId,
                  ),
                ),
              );
            },
          ),
        ),
        TextButton(
          onPressed: () => _navigateToAllRoutines(context),
          child: Text('Daha fazla gör'),
        ),
      ],
    );
  }

  Widget _buildPartRecommendations(BuildContext context, List<Parts> recommendedParts) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedParts.length,
            itemBuilder: (context, index) {
              final part = recommendedParts[index];
              return GestureDetector(
                onTap: () => _navigateToPartDetail(context, part),
                onLongPress: () => _showPartDetails(context, part),
                child: Container(
                  width: 240,
                  margin: EdgeInsets.all(8),
                  child: PartCard(
                    part: part,
                    userId: widget.userId,
                    repository: context.read<PartRepository>(),
                    onTap: () => _showPartDetailBottomSheet(part.id),
                    onFavoriteChanged: (isFavorite) {
                      context.read<PartsBloc>().add(
                        TogglePartFavorite(
                          userId: widget.userId,
                          partId: part.id.toString(),
                          isFavorite: isFavorite,
                        ),
                      );
                    },
                  ),

                ),
              );
            },
          ),
        ),
        TextButton(
          onPressed: () => _navigateToAllParts(context),
          child: Text('Daha fazla gör'),
        ),
      ],
    );
  }

  void _showPartDetailBottomSheet(int partId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius:  BorderRadius.vertical(
              top: Radius.circular(AppTheme.borderRadiusLarge),
            ),
          ),
          child: PartDetailBottomSheet(
            partId: partId, userId: widget.userId,
          ),
        ),
      ),
    );
  }


  void _showRoutineDetails(BuildContext context, Routines routine) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(routine.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(routine.description),
              SizedBox(height: 8),
              Text('Zorluk: ${routine.difficulty}'),
              Text('İlerleme: ${routine.userProgress ?? 0}%'),
            ],
          ),
        );
      },
    );
  }

  void _showPartDetails(BuildContext context, Parts part) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(part.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(part.additionalNotes),
              SizedBox(height: 8),
              Text('Egzersiz Sayısı: ${part.exerciseIds.length}'),
              Text('İlerleme: ${part.userProgress ?? 0}%'),
            ],
          ),
        );
      },
    );
  }

  void _navigateToAllRoutines(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutinesPage(userId: widget.userId),
      ),
    ).then((_) => context.read<ForYouBloc>().add(FetchForYouData(userId: widget.userId)));
  }

  void _navigateToAllParts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartsPage(userId: widget.userId),
      ),
    ).then((_) => context.read<ForYouBloc>().add(FetchForYouData(userId: widget.userId)));
  }

  void _navigateToRoutineDetail(BuildContext context, Routines routine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineDetailBottomSheet(
          routineId: routine.id,
          userId: widget.userId,
        ),
      ),
    ).then((_) => context.read<ForYouBloc>().add(FetchForYouData(userId: widget.userId)));
  }

  void _navigateToPartDetail(BuildContext context, Parts part) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PartDetailBottomSheet(
        partId: part.id,
        userId: widget.userId,
      ),
    ).then((_) => context.read<ForYouBloc>().add(FetchForYouData(userId: widget.userId)));
  }
}
