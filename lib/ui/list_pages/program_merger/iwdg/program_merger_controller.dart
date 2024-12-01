// program_merger_controller.dart

// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import '../../../../data_bloc_part/PartRepository.dart';
import '../../../../data_schedule_bloc/schedule_repository.dart';
import '../../../../models/Parts.dart';

class ProgramMergerController extends ChangeNotifier {
  final PartRepository _partRepository;
  final ScheduleRepository _scheduleRepository;

  // State değişkenleri
  final ValueNotifier<List<int>> selectedPartsNotifier = ValueNotifier<List<int>>([]);
  final ValueNotifier<List<int>> selectedDaysNotifier = ValueNotifier<List<int>>([]);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  // Cache
  final Map<int, Parts> _partsCache = {};
  final Map<int, List<String>> _recommendationsCache = {};

  ProgramMergerController({
    required PartRepository partRepository,
    required ScheduleRepository scheduleRepository,
  }) : _partRepository = partRepository,
        _scheduleRepository = scheduleRepository;

  Future<void> initialize() async {
    try {
      isLoadingNotifier.value = true;
      await _preloadData();
    } catch (e) {
      errorNotifier.value = e.toString();
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> _preloadData() async {
    final parts = await _partRepository.getAllParts();
    for (var part in parts) {
      _partsCache[part.id] = part;
    }
  }

  Future<void> togglePartSelection(int partId) async {
    try {
      final currentSelected = List<int>.from(selectedPartsNotifier.value);

      if (currentSelected.contains(partId)) {
        currentSelected.remove(partId);
      } else {
        await _validateSelection(partId);
        currentSelected.add(partId);
      }

      selectedPartsNotifier.value = currentSelected;
      notifyListeners();
    } catch (e) {
      errorNotifier.value = e.toString();
    }
  }

  Future<void> _validateSelection(int partId) async {
    final part = _partsCache[partId];
    if (part == null) throw 'Program bulunamadı';
    // Validasyon kuralları burada uygulanır
  }

  Future<List<String>> getRecommendations(int partId) async {
    if (_recommendationsCache.containsKey(partId)) {
      return _recommendationsCache[partId]!;
    }

    final recommendations = await _generateRecommendations(partId);
    _recommendationsCache[partId] = recommendations;
    return recommendations;
  }

  Future<List<String>> _generateRecommendations(int partId) async {
    // Öneri mantığı burada uygulanır
    return [];
  }

  @override
  void dispose() {
    selectedPartsNotifier.dispose();
    selectedDaysNotifier.dispose();
    isLoadingNotifier.dispose();
    errorNotifier.dispose();
    super.dispose();
  }
}
