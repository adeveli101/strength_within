import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:workout/ui/components/chart.dart';
import 'package:workout/ui/routine_edit_page.dart';
import 'package:workout/ui/routine_step_page.dart';
import '../controllers/routines_bloc.dart';
import '../models/routine.dart';
import '../utils/routine_helpers.dart';
import 'calender_page.dart';


class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoading = false;
  List<Routine> _loadedRoutines = [];

  @override
  void initState() {
    super.initState();
    _loadMoreRoutines();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreRoutines();
    }
  }

  Future<void> _loadMoreRoutines() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    final newRoutines = await RoutinesBloc().fetchRoutinesPaginated(_currentPage, _pageSize);
    setState(() {
      _loadedRoutines.addAll(newRoutines);
      _currentPage++;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                delegate: SliverChildListDelegate([
                  _buildUsageCard(),
                  _buildTotalCompletionCard(_getTotalWorkoutCount(_loadedRoutines)),
                  _buildDonutChartCard(_loadedRoutines, _getTotalWorkoutCount(_loadedRoutines)),
                  _buildGoalCard(_getRatio(_loadedRoutines)),
                ]),
              ),
            ),
            SliverFillRemaining(
              child: Container(
                child: CalendarPage(routines: _loadedRoutines),
              ),
            ),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }




  Widget buildMainLayout() {
    var totalCount = _getTotalWorkoutCount(_loadedRoutines);
    var ratio = _getRatio(_loadedRoutines);
    return SliverGrid.count(
      crossAxisCount: 2,
      children: [
        _buildUsageCard(),
        _buildTotalCompletionCard(totalCount),
        _buildDonutChartCard(_loadedRoutines, totalCount),
        _buildGoalCard(ratio),
      ],
    );
  }

  Widget _buildUsageCard() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Card(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        elevation: 12,
        color: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: FutureBuilder<String?>(
            future: _getFirstRunDate(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              String firstRunDateText = snapshot.data ?? "N/A";
              String daysSinceFirstRun = "N/A";

              if (snapshot.hasData && snapshot.data != null) {
                try {
                  DateTime firstRunDate = DateTime.parse(snapshot.data!);
                  daysSinceFirstRun = DateTime.now().difference(firstRunDate).inDays.toString();
                } catch (e) {
                  print('Tarih ayrıştırma hatası: $e');
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        children: [
                          TextSpan(
                            text: 'Bu uygulamayı kullanmaya başladığınız tarih:\n$firstRunDateText',
                            style: const TextStyle(fontFamily: 'Staa'),
                          ),
                          const TextSpan(text: '\n\nKullanım süreniz:\n', style: TextStyle(fontFamily: 'Staa')),
                          TextSpan(
                            text: daysSinceFirstRun,
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Staa'),
                          ),
                          const TextSpan(text: ' gün', style: TextStyle(fontFamily: 'Staa')),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }





  Widget _buildTotalCompletionCard(int totalCount) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Card(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        elevation: 12,
        color: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4, left: 8, right: 8),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                const TextSpan(text: 'Total Completion\n', style: TextStyle(fontFamily: 'Staa')),
                TextSpan(
                  text: totalCount.toString(),
                  style: TextStyle(fontSize: _getFontSize(totalCount.toString()), fontFamily: 'Staa'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonutChartCard(List<Routine> routines, int totalCount) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Card(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        elevation: 12,
        color: Theme.of(context).primaryColor,
        child: Center(
          child: totalCount == 0
              ? const Text(
            'No data available',
            style: TextStyle(color: Colors.white, fontSize: 16),
          )
              : SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.width * 0.4,
            child: DonutAutoLabelChart(
              routines,
              animate: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(double ratio) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Card(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        elevation: 12,
        color: Theme.of(context).primaryColor,
        child: InkWell(
          onTap: _handleCardTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double radius = constraints.maxWidth * 0.4;
              return Center(
                child: CircularPercentIndicator(
                  radius: radius,
                  lineWidth: radius * 0.1,
                  animation: true,
                  animateFromLastPercent: true,
                  percent: ratio,
                  center: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${(ratio * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0, color: Colors.white),
                    ),
                  ),
                  header: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Goal of this week",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0, color: Colors.white),
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: Colors.grey,
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  void _handleCardTap() {
    if (_loadedRoutines.isEmpty) {
      _navigateToRoutineEditPage();
    } else {
      _navigateToRoutineStepPage(_loadedRoutines as Routine);
    }
  }

  void _navigateToRoutineEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineEditPage(
          addOrEdit: AddOrEdit.add,
          mainTargetedBodyPart: MainTargetedBodyPart.fullBody,
        ),
      ),
    );
  }

  void _navigateToRoutineStepPage(Routine selectedRoutine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineStepPage(
          routine: selectedRoutine,
          celebrateCallback: () {
            // Celebration logic can be implemented here
            // For example, you might want to show a congratulatory message or update some stats
          },
          onBackPressed: () async {
            // This function will be called when the back button is pressed
            bool shouldPop = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.white,
                elevation: 4,
                title: Container(
                  width: double.infinity,
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: const [
                      Text(
                        'Too soon to quit. 😑',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your progress will not be saved.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Stay',
                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Quit',
                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ) ?? false;

            if (shouldPop) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}


Future<String?> _getFirstRunDate() async {
  return  _getFirstRunDate();
}


  int _getTotalWorkoutCount(List<Routine> routines) {
    return routines.fold(0, (total, routine) => total + routine.completionCount);
  }

  double _getRatio(List<Routine> routines) {
    int totalShare = 0;
    int share = 0;
    DateTime mondayDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    mondayDate = DateTime(mondayDate.year, mondayDate.month, mondayDate.day);
    for (var routine in routines) {
      totalShare += routine.weekdays.length;
      for (var weekday in routine.weekdays) {
        if (routine.routineHistory.any((ts) {
          var date = DateTime.fromMillisecondsSinceEpoch(ts).toLocal();
          return date.weekday == weekday && date.isAfter(mondayDate);
        })) {
          share++;
        }
      }
    }
    return totalShare == 0 ? 0 : share / totalShare;
  }

  double _getFontSize(String displayText) {
    return displayText.length <= 2 ? 120 : 72;
  }

