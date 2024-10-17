import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../firebase_class/firebase_routines.dart';
import '../../resource/routines_bloc.dart';

class RoutineDetails extends StatelessWidget {
  final FirebaseRoutine firebaseRoutine;

  const RoutineDetails({Key? key, required this.firebaseRoutine})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RoutinesBloc routinesBloc = BlocProvider.of<RoutinesBloc>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: RoutineHeaderDelegate(
              minHeight: 60,
              maxHeight: 200,
              routinesBloc: routinesBloc,
              routine: firebaseRoutine,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Burada rutin detaylarının geri kalanını ekleyin
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firebaseRoutine.isCustom
                          ? 'Custom Routine'
                          : 'Predefined Routine',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Last Used: ${firebaseRoutine.lastUsedDate?.toString() ??
                          'Never'}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Progress: ${firebaseRoutine.userProgress}%',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _startRoutine(context, routinesBloc),
                      child: Text('Start Routine'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme
                            .of(context)
                            .primaryColor,
                        padding: EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _startRoutine(BuildContext context, RoutinesBloc routinesBloc) async {
    String? deviceId = await routinesBloc.getDeviceId();
    if (deviceId != null) {
      String? userId = await routinesBloc.getUserId(deviceId);
      if (userId != null) {
        await routinesBloc.updateUserRoutineLastUsedDate(
            userId, firebaseRoutine.id);
        // Burada rutini başlatmak için gerekli navigasyon veya işlemleri ekleyin
        // Örneğin:
        // Navigator.pushNamed(context, '/start_routine', arguments: firebaseRoutine);
      }
    }
  }
}


///Routine Header Routine Header  Routine Header  Routine Header
///Routine Header Routine Header  Routine Header  Routine Header




class RoutineHeaderDelegate extends SliverPersistentHeaderDelegate {
  RoutineHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.routinesBloc,
    required this.routine,
  });

  final double minHeight;
  final double maxHeight;
  final RoutinesBloc routinesBloc;
  final FirebaseRoutine routine;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = shrinkOffset / maxExtent;
    final fontSize = _lerp(28, 22, progress);

    return Container(
      color: Color(0xFF121212),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 1 - progress,
            child: Hero(
              tag: 'routine_image_${routine.id}',
              child: Image.asset(
                'assets/images/${routine.routineId}.jpg',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.5),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: _lerp(16, 8, progress),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  routine.routineId.toString(),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Opacity(
                  opacity: 1 - progress,
                  child: Text(
                    '${routine.isCustom ? "Custom" : "Predefined"} Routine',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: _lerp(16, 8, progress),
            child: Opacity(
              opacity: 1 - progress,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      routine.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                    ),
                    onPressed: () => _toggleFavorite(context, routinesBloc),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () => _showOptionsMenu(context, routinesBloc),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _lerp(double min, double max, double t) {
    return (1 - t) * min + t * max;
  }

  @override
  bool shouldRebuild(RoutineHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        routinesBloc != oldDelegate.routinesBloc ||
        routine != oldDelegate.routine;
  }

  void _toggleFavorite(BuildContext context, RoutinesBloc routinesBloc) async {
    // Implement favorite toggle logic here
  }

  void _showOptionsMenu(BuildContext context, RoutinesBloc routinesBloc) {
    // Implement options menu logic here
  }
}