import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/ui/routine_ui/routine_card.dart';
import '../../resource/routines_bloc.dart';
import '../models/exercises.dart';
import '../models/routines.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key, required RoutinesBloc routinesBloc}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late RoutinesBloc _routinesBloc;

  @override
  void initState() {
    super.initState();
    _routinesBloc = BlocProvider.of<RoutinesBloc>(context);
    _routinesBloc.add(FetchRoutines());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildUserRoutines(),
          _buildRecommendedRoutines(),
          _buildPopularExercises(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Color(0xFF121212),
      title: Text('Home', style: TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.white),
          onPressed: () {
            // Implement search functionality
          },
        ),
        IconButton(
          icon: Icon(Icons.account_circle, color: Colors.white),
          onPressed: () {
            // Navigate to user profile
          },
        ),
      ],
    );
  }

  Widget _buildUserRoutines() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Your Routines',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: BlocBuilder<RoutinesBloc, RoutinesState>(
              builder: (context, state) {
                if (state is RoutinesLoaded) {
                  return FutureBuilder<String?>(
                    future: _routinesBloc.getDeviceId().then((deviceId) =>
                    deviceId != null ? _routinesBloc.getUserId(deviceId) : null
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasData && snapshot.data != null) {
                        String userId = snapshot.data!;
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.routines.length,
                          itemBuilder: (context, index) {
                            return RoutineCard(
                              firebaseRoutine: (state.routines[index]).toFirebaseRoutine(userId),
                              routinesBloc: _routinesBloc,
                            );
                          },
                        );
                      } else {
                        return Center(child: Text('User ID not found', style: TextStyle(color: Colors.white)));
                      }
                    },
                  );
                } else if (state is RoutinesLoading) {
                  return Center(child: CircularProgressIndicator());
                } else {
                  return Center(child: Text('No routines found', style: TextStyle(color: Colors.white)));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedRoutines() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recommended for You',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<Routines>>(
              future: _routinesBloc.getRecommendedRoutines(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return _buildRecommendedRoutineCard(snapshot.data![index]);
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularExercises() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Popular Exercises',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<Exercises>>(
              future: _routinesBloc.getAllExercises(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return _buildExerciseCard(snapshot.data![index]);
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedRoutineCard(Routines routine) {
    return Card(
      color: Color(0xFF282828),
      child: Container(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/${routine.id}.jpg',
                height: 120,
                width: 160,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                routine.name,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercises exercise) {
    return Card(
      color: Color(0xFF282828),
      child: Container(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/${exercise.id}.jpg',
                height: 120,
                width: 160,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                exercise.name,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Color(0xFF282828),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
        BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
      ],
    );
  }
}
