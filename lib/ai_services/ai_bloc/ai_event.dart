// lib/ai_module/bloc/ai_event.dart

import 'package:equatable/equatable.dart';
import '../../models/Parts.dart';
import '../../models/routines.dart';

abstract class AIEvent extends Equatable {
  const AIEvent();

  @override
  List<Object?> get props => [];
}

class OptimizeRoutineRecommendations extends AIEvent {
  final List<Routines> routines;
  final String userId;

  const OptimizeRoutineRecommendations({
    required this.routines,
    required this.userId,
  });

  @override
  List<Object?> get props => [routines, userId];
}

class OptimizePartRecommendations extends AIEvent {
  final List<Parts> parts;
  final String userId;

  const OptimizePartRecommendations({
    required this.parts,
    required this.userId,
  });

  @override
  List<Object?> get props => [parts, userId];
}
