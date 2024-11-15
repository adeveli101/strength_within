// lib/ai_module/bloc/ai_state.dart

import 'package:equatable/equatable.dart';
import '../../models/Parts.dart';
import '../../models/routines.dart';

abstract class AIState extends Equatable {
  const AIState();

  @override
  List<Object?> get props => [];
}

class AIInitial extends AIState {}

class AILoading extends AIState {}

class AIRoutineRecommendationsOptimized extends AIState {
  final List<Routines> recommendations;
  final String userId;

  const AIRoutineRecommendationsOptimized({
    required this.recommendations,
    required this.userId,
  });

  @override
  List<Object?> get props => [recommendations, userId];
}

class AIPartRecommendationsOptimized extends AIState {
  final List<Parts> recommendations;
  final String userId;

  const AIPartRecommendationsOptimized({
    required this.recommendations,
    required this.userId,
  });

  @override
  List<Object?> get props => [recommendations, userId];
}

class AIError extends AIState {
  final String message;
  final String userId;

  const AIError({
    required this.message,
    required this.userId,
  });

  @override
  List<Object?> get props => [message, userId];
}
