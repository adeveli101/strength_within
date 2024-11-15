import 'package:flutter_test/flutter_test.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/models/Parts.dart';
import '../../data_bloc_part/part_bloc.dart';
import '../../data_bloc_routine/routines_bloc.dart';
import '../ai_bloc/ai_bloc.dart';
import '../ai_bloc/ai_event.dart';
import '../ai_bloc/ai_state.dart';
import 'TestUserBehavior.dart';

class AIModuleTest {
  final AIBloc aiBloc;
  final RoutinesBloc routinesBloc;
  final PartsBloc partsBloc;

  AIModuleTest(this.aiBloc, this.routinesBloc, this.partsBloc);

  void runTests() {
    group('AI Module Tests', () {
      test('Optimize Routine Recommendations', () async {
        await _testOptimizeRoutineRecommendations();
      });

      test('Optimize Part Recommendations', () async {
        await _testOptimizePartRecommendations();
      });
    });
  }

  Future<void> _testOptimizeRoutineRecommendations() async {
    try {
      // RoutinesBloc'tan rutinleri al
      routinesBloc.add(FetchRoutines());
      await expectLater(
        routinesBloc.stream,
        emitsThrough(isA<RoutinesLoaded>()),
      );

      final routinesState = routinesBloc.state;
      if (routinesState is RoutinesLoaded) {
        final viewedRoutines = routinesState.routines
            .where((routine) => routine.id.toString().startsWith('routine_'))
            .toList();

        final event = OptimizeRoutineRecommendations(
          routines: viewedRoutines,
          userId: 'test_user',
        );

        aiBloc.add(event);

        await expectLater(
          aiBloc.stream,
          emitsInOrder([
            isA<AILoading>(),
            isA<AIRoutineRecommendationsOptimized>(),
          ]),
        );

        final currentState = aiBloc.state;
        if (currentState is AIRoutineRecommendationsOptimized) {
          expect(currentState.recommendations, isNotEmpty);
          expect(currentState.recommendations.length, lessThanOrEqualTo(5));
        } else {
          fail('Expected AIRoutineRecommendationsOptimized state');
        }
      } else {
        fail('Failed to load routines');
      }
    } catch (e) {
      print('Error in testOptimizeRoutineRecommendations: $e');
      fail('Test failed due to error: $e');
    }
  }

  Future<void> _testOptimizePartRecommendations() async {
    try {
      // PartsBloc'tan parçaları al
      partsBloc.add(FetchParts());
      await expectLater(
        partsBloc.stream,
        emitsThrough(isA<PartsLoaded>()),
      );

      final partsState = partsBloc.state;
      if (partsState is PartsLoaded) {
        final viewedParts = partsState.parts
            .where((part) => part.id.toString().startsWith('part_'))
            .toList();

        final event = OptimizePartRecommendations(
          parts: viewedParts,
          userId: 'test_user',
        );

        aiBloc.add(event);

        await expectLater(
          aiBloc.stream,
          emitsInOrder([
            isA<AILoading>(),
            isA<AIPartRecommendationsOptimized>(),
          ]),
        );

        final currentState = aiBloc.state;
        if (currentState is AIPartRecommendationsOptimized) {
          expect(currentState.recommendations, isNotEmpty);
          expect(currentState.recommendations.length, lessThanOrEqualTo(5));
        } else {
          fail('Expected AIPartRecommendationsOptimized state');
        }
      } else {
        fail('Failed to load parts');
      }
    } catch (e) {
      print('Error in testOptimizePartRecommendations: $e');
      fail('Test failed due to error: $e');
    }
  }
}
