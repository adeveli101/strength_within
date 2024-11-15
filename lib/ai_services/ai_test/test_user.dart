import 'dart:math';

class TestUser {
  final String id;
  final String name;
  final List<String> favoriteRoutineIds;
  final List<String> favoritePartIds;
  final Map<String, int> routineProgress;

  TestUser({
    required this.id,
    required this.name,
    this.favoriteRoutineIds = const [],
    this.favoritePartIds = const [],
    this.routineProgress = const {},
  });
}

List<TestUser> generateTestUsers(int count) {
  return List.generate(count, (index) {
    return TestUser(
      id: 'test_user_$index',
      name: 'Test User $index',
      favoriteRoutineIds: List.generate(Random().nextInt(5), (_) => 'routine_${Random().nextInt(20)}'),
      favoritePartIds: List.generate(Random().nextInt(5), (_) => 'part_${Random().nextInt(20)}'),
      routineProgress: Map.fromEntries(
          List.generate(Random().nextInt(10), (_) => MapEntry('routine_${Random().nextInt(20)}', Random().nextInt(100)))
      ),
    );
  });
}
