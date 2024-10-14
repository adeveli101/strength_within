import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../resource/routines_bloc.dart';
import '../../models/routine.dart';
import '../routine_detail_page.dart';
import '../../resource/firebase_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final bool isRecRoutine;
  final bool isSmall;
  final VoidCallback onFavoriteToggle;

  const RoutineCard({
    Key? key,
    required this.routine,
    this.isRecRoutine = false,
    this.isSmall = false,
    required this.onFavoriteToggle,
  }) : super(key: key);

  Future<String?> _getAnonymousUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      return userCredential.user?.uid;
    }
    return user.uid;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        routinesBloc.setCurrentRoutine(routine);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoutineDetailPage(
              isRecRoutine: isRecRoutine,
              routine: routine,
            ),
          ),
        );
      },
      child: Container(
        width: isSmall ? 140 : double.infinity,
        height: isSmall ? 120 : 180,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: isSmall ? 4 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 8 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      routine.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildFavoriteButton(),
                ],
              ),
              SizedBox(height: isSmall ? 4 : 8),
              _buildDifficultyStars(),
              SizedBox(height: isSmall ? 4 : 8),
              Text(
                '${routine.estimatedTime ?? 30} min',
                style: TextStyle(fontSize: isSmall ? 10 : 12, color: Colors.grey),
              ),
              if (!isSmall) ...[
                Spacer(),
                _buildQuickStartButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return FutureBuilder<String?>(
      future: _getAnonymousUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(width: 20, height: 20);
        }
        if (snapshot.hasData && snapshot.data != null) {
          String userId = snapshot.data!;
          return StreamBuilder<DocumentSnapshot>(
            stream: firebaseProvider.firestore
                .collection("users")
                .doc(userId)
                .collection("routines")
                .doc(routine.id.toString())
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                bool isRecommended = snapshot.data!['isRecommended'] ?? false;
                return IconButton(
                  icon: Icon(
                    isRecommended ? Icons.favorite : Icons.favorite_border,
                    size: isSmall ? 16 : 20,
                    color: isRecommended ? Colors.red : Colors.white,
                  ),
                  onPressed: onFavoriteToggle,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                );
              }
              return SizedBox(width: 20, height: 20);
            },
          );
        }
        return SizedBox(width: 20, height: 20);
      },
    );
  }

  Widget _buildDifficultyStars() {
    return Row(
      children: List.generate(3, (index) {
        return Icon(
          index < (routine.difficulty ?? 1) ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: isSmall ? 12 : 15,
        );
      }),
    );
  }

  Widget _buildQuickStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        child: Text('Quick Start', style: TextStyle(fontSize: 12)),
        onPressed: () {
          // Implement quick start functionality
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          padding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}