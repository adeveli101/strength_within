import 'dart:math';
import 'package:strength_within/models/routines.dart';
import 'package:strength_within/models/Parts.dart';
import 'package:strength_within/ai_services/ai_test/test_user.dart';

class TestUserBehavior {
  final TestUser user;
  final List<Routines> viewedRoutines;
  final List<Routines> completedRoutines;
  final List<Parts> viewedParts;

  TestUserBehavior({
    required this.user,
    List<Routines>? viewedRoutines,
    List<Routines>? completedRoutines,
    List<Parts>? viewedParts,
  })  : viewedRoutines = viewedRoutines ?? [],
        completedRoutines = completedRoutines ?? [],
        viewedParts = viewedParts ?? [];

  void simulateUserActivity(List<Routines> allRoutines, List<Parts> allParts) {
    final random = Random();

    // Rutin görüntüleme simülasyonu
    viewedRoutines.addAll(List.generate(
      random.nextInt(10),
          (_) => allRoutines[random.nextInt(allRoutines.length)],
    ));

    // Rutin tamamlama simülasyonu
    completedRoutines.addAll(List.generate(
      random.nextInt(5),
          (_) => allRoutines[random.nextInt(allRoutines.length)],
    ));

    // Parça görüntüleme simülasyonu
    viewedParts.addAll(List.generate(
      random.nextInt(10),
          (_) => allParts[random.nextInt(allParts.length)],
    ));
  }
}

List<TestUserBehavior> generateTestUserBehaviors(
    List<TestUser> users,
    List<Routines> allRoutines,
    List<Parts> allParts,
    ) {
  return users.map((user) {
    var behavior = TestUserBehavior(user: user);
    behavior.simulateUserActivity(allRoutines, allParts);
    return behavior;
  }).toList();
}
