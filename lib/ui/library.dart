import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strength_within/blocs/data_bloc_part/PartRepository.dart';
import 'package:strength_within/blocs/data_bloc_routine/RoutineRepository.dart';
import '../blocs/data_bloc_part/part_bloc.dart';
import '../blocs/data_bloc_routine/routines_bloc.dart';
import '../blocs/data_schedule_bloc/schedule_repository.dart';
import '../models/sql_models/Parts.dart';
import '../models/sql_models/routines.dart';
import '../sw_app_theme/app_theme.dart';

class LibraryPage extends StatelessWidget {
  final String userId;
  final RoutineRepository routineRepository;
  final PartRepository partRepository;
  final ScheduleRepository scheduleRepository;

  const LibraryPage({
    super.key,
    required this.userId,
    required this.routineRepository,
    required this.partRepository,
    required this.scheduleRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => RoutinesBloc(
            repository: routineRepository,
            userId: userId,
            scheduleRepository: scheduleRepository,
          )..add(FetchRoutines()),
        ),
        BlocProvider(
          create: (_) => PartsBloc(
            repository: partRepository,
            userId: userId,
            scheduleRepository: scheduleRepository,
          )..add(FetchParts()),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          title: const Text('Kütüphane'),
          backgroundColor: AppTheme.primaryRed,
        ),
        body: RefreshIndicator(
          color: AppTheme.primaryRed,
          backgroundColor: AppTheme.darkBackground,
          strokeWidth: 3,
          onRefresh: () async {
            context.read<RoutinesBloc>().add(FetchRoutines());
            context.read<PartsBloc>().add(FetchParts());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Favori Rutinler'),
                const SizedBox(height: 10),
                _buildFavoriteRoutinesSection(),
                const SizedBox(height: 20),
                _buildSectionTitle('Başlanmış Rutinler'),
                const SizedBox(height: 10),
                _buildStartedRoutinesSection(),
                const SizedBox(height: 20),
                _buildSectionTitle('Favori Part\'lar'),
                const SizedBox(height: 10),
                _buildFavoritePartsSection(),
                const SizedBox(height: 20),
                _buildSectionTitle('Başlanmış Part\'lar'),
                const SizedBox(height: 10),
                _buildStartedPartsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildFavoriteRoutinesSection() {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        if (state is RoutinesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RoutinesLoaded) {
          final favoriteRoutines = state.routines.where((routine) => routine.isFavorite).toList();
          if (favoriteRoutines.isEmpty) {
            return const Text('Favori rutininiz yok.', style: TextStyle(color: Colors.white70));
          }
          return _buildRoutineList(favoriteRoutines);
        } else if (state is RoutinesError) {
          return Text('Hata oluştu: ${state.message}', style: const TextStyle(color: Colors.red));
        }
        return Container();
      },
    );
  }

  Widget _buildStartedRoutinesSection() {
    return BlocBuilder<RoutinesBloc, RoutinesState>(
      builder: (context, state) {
        if (state is RoutinesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RoutinesLoaded) {
          final startedRoutines = state.routines.where((routine) =>
          routine.userProgress != null && routine.userProgress! > 0).toList();
          if (startedRoutines.isEmpty) {
            return const Text('Henüz başlanmış bir rutininiz yok.', style: TextStyle(color: Colors.white70));
          }
          return _buildRoutineList(startedRoutines);
        } else if (state is RoutinesError) {
          return Text('Hata oluştu: ${state.message}', style: const TextStyle(color: Colors.red));
        }
        return Container();
      },
    );
  }

  Widget _buildFavoritePartsSection() {
    return BlocBuilder<PartsBloc, PartsState>(
      builder: (context, state) {
        if (state is PartsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PartsLoaded) {
          final favoriteParts = state.parts.where((part) => part.isFavorite).toList();
          if (favoriteParts.isEmpty) {
            return const Text('Favori part\'ınız yok.', style: TextStyle(color: Colors.white70));
          }
          return _buildPartList(favoriteParts);
        } else if (state is PartsError) {
          return Text('Hata oluştu: ${state.message}', style: const TextStyle(color: Colors.red));
        }
        return Container();
      },
    );
  }

  Widget _buildStartedPartsSection() {
    return BlocBuilder<PartsBloc, PartsState>(
      builder: (context, state) {
        if (state is PartsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PartsLoaded) {
          final startedParts = state.parts.where((part) =>
          part.userProgress != null && part.userProgress! > 0).toList();
          if (startedParts.isEmpty) {
            return const Text('Henüz başlanmış bir part\'ınız yok.', style: TextStyle(color: Colors.white70));
          }
          return _buildPartList(startedParts);
        } else if (state is PartsError) {
          return Text('Hata oluştu: ${state.message}', style: const TextStyle(color: Colors.red));
        }
        return Container();
      },
    );
  }

  Widget _buildRoutineList(List<Routines> routines) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final routine = routines[index];
          return Card(
            color: AppTheme.cardBackground,
            margin: EdgeInsets.all(AppTheme.paddingSmall),
            shape:
            RoundedRectangleBorder(borderRadius:
            BorderRadius.circular(AppTheme.borderRadiusMedium)),
            child:
            Padding(padding:
            EdgeInsets.symmetric(horizontal:
            AppTheme.paddingMedium, vertical:
            AppTheme.paddingSmall), child:
            Column(crossAxisAlignment:
            CrossAxisAlignment.start, children:
            [
              Text(routine.name, style:
              const TextStyle(fontWeight:
              FontWeight.bold, color:
              Colors.white)),
              SizedBox(height:
              AppTheme.paddingSmall),
              Text('İlerleme %${routine.userProgress ?? 0}',
                  style:
                  const TextStyle(color:
                  Colors.white70)),
            ])),
          );
        },
      ),
    );
  }

  Widget _buildPartList(List<Parts> parts) {
    return SizedBox(
      height :150,
      child :ListView.builder(
        scrollDirection :Axis.horizontal,
        itemCount :parts.length,
        itemBuilder :(context , index){
          final part = parts[index];

          return Card(
            color :AppTheme.cardBackground,
            margin :EdgeInsets.all(AppTheme.paddingSmall),
            shape :RoundedRectangleBorder(
              borderRadius :BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child :Padding(
              padding :EdgeInsets.symmetric(horizontal :AppTheme.paddingMedium, vertical :AppTheme.paddingSmall),
              child :Column(
                crossAxisAlignment :CrossAxisAlignment.start,
                children :[
                  Text(part.name, style :const TextStyle(fontWeight :FontWeight.bold,color :Colors.white)),
                  SizedBox(height :AppTheme.paddingSmall),
                  Text('İlerleme %${part.userProgress ?? 0}', style :const TextStyle(color :Colors.white70)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
