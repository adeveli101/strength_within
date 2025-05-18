import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';


import '../blocs/data_bloc_part/PartRepository.dart';
import '../blocs/data_bloc_part/part_bloc.dart';
import '../blocs/data_bloc_routine/RoutineRepository.dart';
import '../blocs/data_provider/firebase_provider.dart';
import '../blocs/data_provider/sql_provider.dart';
import '../blocs/data_schedule_bloc/schedule_repository.dart';
import '../models/sql_models/Parts.dart';
import '../models/sql_models/routines.dart';
import '../sw_app_theme/app_theme.dart';
import '../ui/part_ui/part_card.dart';
import '../ui/part_ui/part_detail.dart';
import '../ui/routine_ui/routine_card.dart';
import '../ui/routine_ui/routine_detail.dart';
import '../blocs/for_you_bloc.dart';
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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _workoutsByDay = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  Future<void> _fetchWorkouts() async {
    setState(() => _loading = true);
    final userId = widget.userId;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('exerciseProgress')
        .where('isCompleted', isEqualTo: true)
        .get();
    final Map<DateTime, List<Map<String, dynamic>>> byDay = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['completionDate'] != null) {
        final date = (data['completionDate'] as Timestamp).toDate();
        final day = DateTime(date.year, date.month, date.day);
        byDay.putIfAbsent(day, () => []).add({...data, 'id': doc.id});
      }
    }
    setState(() {
      _workoutsByDay = byDay;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _getWorkoutsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _workoutsByDay[key] ?? [];
  }

  int _getActiveDaysInMonth(DateTime month) {
    return _workoutsByDay.keys.where((d) => d.year == month.year && d.month == month.month).length;
  }

  int _getInactiveDaysInMonth(DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    return daysInMonth - _getActiveDaysInMonth(month);
  }

  void _showDayDetails(BuildContext context, DateTime day) {
    final workouts = _getWorkoutsForDay(day);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Antrenmanlar - ${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            if (workouts.isEmpty)
              Center(child: Text('Bu gün için kayıtlı antrenman yok.', style: TextStyle(color: Colors.white70))),
            ...workouts.map((workout) => Card(
                  color: AppTheme.surfaceColor,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                    title: Text(
                      workout['exerciseName'] ?? 'Antrenman',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Tamamlandı',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: workout['completionDate'] != null
                        ? Text(
                            '${(workout['completionDate'] as Timestamp).toDate().hour.toString().padLeft(2, '0')}:${(workout['completionDate'] as Timestamp).toDate().minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white54),
                          )
                        : null,
                  ),
                )),
            const SizedBox(height: 12),
            if (workouts.isNotEmpty)
              Center(
                child: Text(
                  'Harika! Bugün aktif kaldın 🎉',
                  style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            if (workouts.isEmpty)
              Center(
                child: Text(
                  'Bugün dinlenme günü. Yarın tekrar dene! 💪',
                  style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = _selectedDay ?? _focusedDay;
    final month = DateTime(_focusedDay.year, _focusedDay.month);
    final activeDays = _getActiveDaysInMonth(month);
    final inactiveDays = _getInactiveDaysInMonth(month);
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Aktivite Takvimi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWorkouts,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Gradientli başlık ve özet
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryRed, AppTheme.primaryGreen.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_focusedDay.year} - ${_focusedDay.month.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('Aktif gün: ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('$activeDays', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          Icon(Icons.hotel, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('İnaktif gün: ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('$inactiveDays', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.emoji_events, color: Colors.amberAccent, size: 20),
                          const SizedBox(width: 8),
                          Text('En uzun seri: ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(_getLongestStreak().toString(), style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Takvim
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2022, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    eventLoader: (day) => _getWorkoutsForDay(day),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: AppTheme.primaryRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isNotEmpty) {
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Icon(Icons.fitness_center, color: AppTheme.primaryGreen, size: 18),
                          );
                        }
                        return null;
                      },
                      defaultBuilder: (context, day, focusedDay) {
                        final isToday = isSameDay(day, DateTime.now());
                        final isSelected = isSameDay(day, _selectedDay);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryGreen.withOpacity(0.2)
                                : isToday
                                    ? AppTheme.primaryRed.withOpacity(0.1)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : isToday
                                        ? AppTheme.primaryRed
                                        : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                      _showDayDetails(context, selected);
                    },
                    onPageChanged: (focused) {
                      setState(() => _focusedDay = focused);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Motivasyon mesajı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.mood, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getMotivationMessage(selectedDay),
                          style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  int _getLongestStreak() {
    // En uzun üst üste aktif gün serisini hesapla
    final days = _workoutsByDay.keys.toList()..sort();
    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? prev;
    for (final day in days) {
      if (prev != null && day.difference(prev).inDays == 1) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
      if (currentStreak > maxStreak) maxStreak = currentStreak;
      prev = day;
    }
    return maxStreak;
  }

  String _getMotivationMessage(DateTime day) {
    final workouts = _getWorkoutsForDay(day);
    if (isSameDay(day, DateTime.now()) && workouts.isNotEmpty) {
      return 'Bugün de aktif kaldın, harikasın!';
    } else if (workouts.isNotEmpty) {
      return 'Bu gün antrenman yaptın, devam et!';
    } else if (isSameDay(day, DateTime.now())) {
      return 'Bugün henüz antrenman yapmadın. Hadi başlayalım!';
    } else {
      return 'Dinlenmek de önemli. Yarın tekrar dene!';
    }
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
