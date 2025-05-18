// ignore_for_file: collection_methods_unrelated_type

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strength_within/blocs/data_bloc_part/PartRepository.dart';
import 'package:strength_within/blocs/data_bloc_routine/RoutineRepository.dart';
import 'package:strength_within/ui/profile_result_screen.dart';
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
        final history = (snapshot.data ?? []);
        if (history.isEmpty) {
          return const Text('Henüz profil geçmişiniz yok.', style: TextStyle(color: Colors.white70));
        }
        // En güncel profil
        final filtered = _filteredHistory(history);
        final latestData = filtered.isNotEmpty ? filtered.last as Map<String, dynamic> : null;
        return FutureBuilder<List<Routines>>(
          future: routineRepository.getAllRoutines(),
          builder: (context, routinesSnapshot) {
            final allRoutines = routinesSnapshot.data ?? [];
            if (latestData == null) return const SizedBox.shrink();
            final latestProfile = UserAIProfile.fromFirestore(_FakeDoc(latestData, id: 'profile_latest'));
            final routineIds = latestProfile.recommendedRoutineIds ?? [];
            final routineNames = allRoutines
                .where((r) => routineIds.contains(r.id.toString()) || routineIds.contains(r.id))
                .map((r) => r.name)
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 500,
                      minWidth: 0,
                    ),
                    child: ProfileHistoryCard(
                      profile: latestProfile,
                      recommendedRoutineNames: routineNames,
                      onTap: () => _showProfileDetailDialog(context, latestProfile),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _showAllProfileHistoryModal(context, filtered, allRoutines),
                    child: const Text('Hepsini gör', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAllProfileHistoryModal(BuildContext context, List<dynamic> filtered, List<Routines> allRoutines) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Tarihe göre yeni > eski sırala
        final sorted = List<Map<String, dynamic>>.from(filtered.reversed);
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Tüm Profil Geçmişi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        return GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isWide ? 2 : 1,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: sorted.length,
                          itemBuilder: (context, index) {
                            final data = sorted[index];
                            final profile = UserAIProfile.fromFirestore(_FakeDoc(data, id: 'profile_$index'));
                            final routineIds = profile.recommendedRoutineIds ?? [];
                            final routineNames = allRoutines
                                .where((r) => routineIds.contains(r.id.toString()) || routineIds.contains(r.id))
                                .map((r) => r.name)
                                .toList();
                            return ProfileHistoryCard(
                              profile: profile,
                              recommendedRoutineNames: routineNames,
                              onTap: () {
                                Navigator.of(context).pop();
                                _showProfileDetailDialog(context, profile);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
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
    final routineIds = profile.recommendedRoutineIds ?? [];
    // Rutin repository ve schedule repository üst widget'tan alınmalı
    final allRoutines = await routineRepository.getAllRoutines();
    final recommendedRoutines = allRoutines
        .where((r) => routineIds.contains(r.id.toString()) || routineIds.contains(r.id))
        .toList();

    await ProfileResultBottomSheet.show(
      context,
      userId: userId,
      userProfile: profile,
      recommendedRoutines: recommendedRoutines,
      routineRepository: routineRepository,
      scheduleRepository: scheduleRepository,
      selectedDays: [], // Profilde selectedDays yoksa boş bırak
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
// ignore: subtype_of_sealed_class
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

// Profil geçmişi kartı (RoutineCard tarzında)
class ProfileHistoryCard extends StatelessWidget {
  final UserAIProfile profile;
  final List<String> recommendedRoutineNames;
  final VoidCallback onTap;
  const ProfileHistoryCard({
    super.key,
    required this.profile,
    required this.recommendedRoutineNames,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: 180,
          maxWidth: 400,
        ),
        margin: EdgeInsets.all(AppTheme.paddingSmall),
        decoration: AppTheme.decoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryRed.withOpacity(0.7), AppTheme.cardBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppTheme.getBorderRadius(all: AppTheme.borderRadiusMedium),
          shadows: [
            BoxShadow(
              color: AppTheme.primaryRed.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_circle, color: AppTheme.primaryRed, size: 32),
                  SizedBox(width: AppTheme.paddingSmall),
                  Flexible(
                    child: Text(
                      _formatDate(profile.lastUpdateTime),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Seviye ${profile.fitnessLevel}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.paddingSmall),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Icon(Icons.monitor_weight, color: Colors.white70, size: 20),
                    SizedBox(width: 4),
                    Text('BMI: ${profile.bmi?.toStringAsFixed(1) ?? '-'}', style: TextStyle(color: Colors.white70)),
                    SizedBox(width: 12),
                    Icon(Icons.fitness_center, color: Colors.white70, size: 20),
                    SizedBox(width: 4),
                    Text('${profile.weight.round()} kg', style: TextStyle(color: Colors.white70)),
                    SizedBox(width: 12),
                    Icon(Icons.height, color: Colors.white70, size: 20),
                    SizedBox(width: 4),
                    Text('${profile.height.round()} cm', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.paddingSmall),
              Text('Önerilen Rutinler:', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 4),
              recommendedRoutineNames.isNotEmpty
                  ? Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: recommendedRoutineNames
                          .map((name) => Chip(
                                label: Text(name, style: TextStyle(color: Colors.white)),
                                backgroundColor: AppTheme.primaryRed.withOpacity(0.7),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    )
                  : Text('Yok', style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
