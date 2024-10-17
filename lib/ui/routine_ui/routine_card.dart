import 'package:flutter/material.dart';
import '../../firebase_class/firebase_routines.dart';
import '../../resource/routines_bloc.dart';


class RoutineCard extends StatelessWidget {
  final FirebaseRoutine firebaseRoutine;
  final RoutinesBloc routinesBloc;

  const RoutineCard({
    Key? key,
    required this.firebaseRoutine,
    required this.routinesBloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/routine_detail', arguments: firebaseRoutine);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Routine Image
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/images/${firebaseRoutine.routineId}.jpg',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 16),
              // Routine Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      firebaseRoutine.routineId.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      firebaseRoutine.isCustom ? 'Custom Routine' : 'Predefined Routine',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Favorite Button
              IconButton(
                icon: Icon(
                  firebaseRoutine.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white70,
                ),
                onPressed: () => _toggleFavorite(context),
              ),
              // More Options Button
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.white70),
                onPressed: () => _showOptionsMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFavorite(BuildContext context) async {
    final updatedRoutine = FirebaseRoutine(
      id: firebaseRoutine.id,
      userId: firebaseRoutine.userId,
      routineId: firebaseRoutine.routineId,
      userProgress: firebaseRoutine.userProgress,
      lastUsedDate: firebaseRoutine.lastUsedDate,
      userRecommended: firebaseRoutine.userRecommended,
      isCustom: firebaseRoutine.isCustom,
      isFavorite: !firebaseRoutine.isFavorite,
    );
    String? deviceId = await routinesBloc.getDeviceId();
    if (deviceId != null) {
      String? userId = await routinesBloc.getUserId(deviceId);
      if (userId != null) {
        await routinesBloc.updateUserRoutine(userId, updatedRoutine);
      }
    }
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Color(0xFF282828),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.play_arrow, color: Colors.white),
                  title: Text('Start Routine', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    String? deviceId = await routinesBloc.getDeviceId();
                    if (deviceId != null) {
                      String? userId = await routinesBloc.getUserId(deviceId);
                      if (userId != null) {
                        await routinesBloc.updateUserRoutineLastUsedDate(userId, firebaseRoutine.id);
                        // Navigate to start routine page
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.white),
                  title: Text('Edit Routine', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to edit routine page
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.white),
                  title: Text('Delete Routine', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    String? deviceId = await routinesBloc.getDeviceId();
                    if (deviceId != null) {
                      String? userId = await routinesBloc.getUserId(deviceId);
                      if (userId != null) {
                        await routinesBloc.deleteUserRoutine(userId, firebaseRoutine.id);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
