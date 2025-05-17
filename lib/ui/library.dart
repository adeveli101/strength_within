import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strength_within/blocs/data_bloc_part/PartRepository.dart';
import 'package:strength_within/blocs/data_bloc_routine/RoutineRepository.dart';
import '../blocs/data_bloc_part/part_bloc.dart';
import '../blocs/data_bloc_routine/routines_bloc.dart';
import '../blocs/data_provider/firebase_provider.dart';
import '../blocs/data_provider/sql_provider.dart';
import '../blocs/data_schedule_bloc/schedule_repository.dart';
import '../models/sql_models/Parts.dart';
import '../models/sql_models/routines.dart';
import '../sw_app_theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ai_predictors/ai_bloc/ai_repository.dart';
import '../models/firebase_models/user_ai_profile.dart';

class LibraryPage extends StatelessWidget {
  final String userId;
  final RoutineRepository routineRepository;
  final ScheduleRepository scheduleRepository;
  final SQLProvider sqlProvider;
  final FirebaseProvider firebaseProvider;

  const LibraryPage({
    super.key,
    required this.userId,
    required this.routineRepository,
    required this.scheduleRepository,
    required this.sqlProvider,
    required this.firebaseProvider,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoutinesBloc(
        repository: routineRepository,
        userId: userId,
        scheduleRepository: scheduleRepository,
      )..add(FetchRoutines()),
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
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Profil Sonuçları'),
                const SizedBox(height: 10),
                _buildProfileHistorySection(),
                const SizedBox(height: 20),
                _buildSectionTitle('Favori Rutinler'),
                const SizedBox(height: 10),
                _buildFavoriteRoutinesSection(),
                const SizedBox(height: 20),
                _buildSectionTitle('Başlanmış Rutinler'),
                const SizedBox(height: 10),
                _buildStartedRoutinesSection(),
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

  // --- Profil geçmişi bölümü ---
  Widget _buildProfileHistorySection() {
    return FutureBuilder<List<dynamic>>(
      future: AIRepository(sqlProvider, firebaseProvider).getUserPredictionHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Profil geçmişi yüklenemedi: {snapshot.error}', style: const TextStyle(color: Colors.redAccent));
        }
        final history = (snapshot.data ?? []) as List<dynamic>;
        if (history.isEmpty) {
          return const Text('Henüz profil geçmişiniz yok.', style: TextStyle(color: Colors.white70));
        }
        return SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filteredHistory(history).length,
            itemBuilder: (context, index) {
              final filtered = _filteredHistory(history);
              final data = filtered[filtered.length - 1 - index] as Map<String, dynamic>; // En yeni başta
              final profile = UserAIProfile.fromFirestore(_FakeDoc(data, id: 'profile_$index'));
              return GestureDetector(
                onTap: () => _showProfileDetailDialog(context, profile),
                child: Card(
                  color: AppTheme.cardBackground,
                  margin: EdgeInsets.all(AppTheme.paddingSmall),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium, vertical: AppTheme.paddingSmall),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Tarih: ${_formatDate(profile.lastUpdateTime)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('BMI: ${profile.bmi?.toStringAsFixed(1) ?? '-'}', style: const TextStyle(color: Colors.white70)),
                        Text('Fitness Seviyesi: ${profile.fitnessLevel}', style: const TextStyle(color: Colors.white70)),
                        Text('Kilo: ${profile.weight.round()} kg', style: const TextStyle(color: Colors.white70)),
                        Text('Boy: ${profile.height.round()} cm', style: const TextStyle(color: Colors.white70)),
                        if (profile.recommendedRoutineIds != null && profile.recommendedRoutineIds!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Önerilen rutinler için tıklayın', style: TextStyle(color: AppTheme.primaryRed, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<dynamic> _filteredHistory(List<dynamic> history) {
    final now = DateTime.now();
    final oneMonthAgo = now.subtract(Duration(days: 31));
    final filtered = history.where((data) {
      final map = data as Map<String, dynamic>;
      final ts = map['lastUpdateTime'];
      DateTime? date;
      if (ts is Timestamp) {
        date = ts.toDate();
      } else if (ts is DateTime) {
        date = ts;
      }
      return date != null && date.isAfter(oneMonthAgo);
    }).toList();
    // En fazla 5 kayıt
    if (filtered.length > 5) {
      return filtered.sublist(filtered.length - 5);
    }
    return filtered;
  }

  Future<void> _showProfileDetailDialog(BuildContext context, UserAIProfile profile) async {
    final routineIds = profile.recommendedRoutineIds;
    List<String> routineNames = [];
    if (routineIds != null && routineIds.isNotEmpty) {
      // Rutin isimlerini bulmak için RoutineRepository kullanılabilir
      final routines = await routineRepository.getAllRoutines();
      // DEBUG: Log routine IDs and all routines
      print('DEBUG: recommendedRoutineIds: ' + routineIds.toString());
      print('DEBUG: allRoutines: ' + routines.map((r) => 'id:${r.id} name:${r.name}').join(', '));
      routineNames = routines
        .where((r) => routineIds.contains(r.id.toString()) || routineIds.contains(r.id))
        .map((r) => r.name)
        .toList();
      print('DEBUG: matched routineNames: ' + routineNames.toString());
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Profil Detayı', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tarih: ${_formatDate(profile.lastUpdateTime)}', style: TextStyle(color: Colors.white)),
            Text('BMI: ${profile.bmi?.toStringAsFixed(1) ?? '-'}', style: TextStyle(color: Colors.white70)),
            Text('Fitness Seviyesi: ${profile.fitnessLevel}', style: TextStyle(color: Colors.white70)),
            Text('Kilo: ${profile.weight.round()} kg', style: TextStyle(color: Colors.white70)),
            Text('Boy: ${profile.height.round()} cm', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            if (routineNames.isNotEmpty)
              Text('Önerilen Rutinler:', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
            if (routineNames.isNotEmpty)
              ...routineNames.map((name) => Text('- $name', style: TextStyle(color: Colors.white70))),
            if (routineNames.isEmpty)
              Text('Bu profil için önerilen rutin yok.', style: TextStyle(color: Colors.white38)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Kapat', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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
          return Text('Hata oluştu: {state.message}', style: const TextStyle(color: Colors.red));
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
          return Text('Hata oluştu: {state.message}', style: const TextStyle(color: Colors.red));
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
}

// Firestore DocumentSnapshot taklidi (sadece fromFirestore için)
class _FakeDoc implements DocumentSnapshot {
  final Map<String, dynamic> _data;
  @override
  final String id;
  _FakeDoc(this._data, {required this.id});
  @override
  dynamic data() => _data;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
