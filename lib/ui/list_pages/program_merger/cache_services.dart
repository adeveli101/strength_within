// cache_service.dart

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../../../models/sql_models/Parts.dart';
import '../../../models/sql_models/exercises.dart';




class CacheService {
  // Singleton pattern
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();


  // Cache storage
  final Map<String, dynamic> _memoryCache = {};
  final Map<int, Parts> _partsCache = {};
  final Map<int, List<Exercises>> _exerciseCache = {};
  final Map<int, List<String>> _recommendationCache = {};

  // Cache TTL (Time To Live) in milliseconds
  static const int _cacheTTL = 30 * 60 * 1000; // 30 minutes
  final Map<String, DateTime> _cacheTimestamps = {};

  // Parts caching
  Future<Parts?> getPart(int id) async {
    if (_isExpired('part_$id')) {
      _partsCache.remove(id);
      return null;
    }
    return _partsCache[id];
  }

  Future<void> cachePart(Parts part) async {
    _partsCache[part.id] = part;
    _setCacheTimestamp('part_${part.id}');
  }

  // Exercise caching
  Future<List<Exercises>?> getExercises(int partId) async {
    if (_isExpired('exercises_$partId')) {
      _exerciseCache.remove(partId);
      return null;
    }
    return _exerciseCache[partId];
  }

  Future<void> cacheExercises(int partId, List<Exercises> exercises) async {
    _exerciseCache[partId] = exercises;
    _setCacheTimestamp('exercises_$partId');
  }

  // Recommendation caching
  Future<List<String>?> getRecommendations(int bodyPartId) async {
    if (_isExpired('recommendations_$bodyPartId')) {
      _recommendationCache.remove(bodyPartId);
      return null;
    }
    return _recommendationCache[bodyPartId];
  }

  Future<void> cacheRecommendations(int bodyPartId, List<String> recommendations) async {
    _recommendationCache[bodyPartId] = recommendations;
    _setCacheTimestamp('recommendations_$bodyPartId');
  }

  // Generic cache methods
  T? get<T>(String key) {
    if (_isExpired(key)) {
      _memoryCache.remove(key);
      return null;
    }
    return _memoryCache[key] as T?;
  }

  void set<T>(String key, T value) {
    _memoryCache[key] = value;
    _setCacheTimestamp(key);
  }

  // Cache management
  void clearCache() {
    _memoryCache.clear();
    _partsCache.clear();
    _exerciseCache.clear();
    _recommendationCache.clear();
    _cacheTimestamps.clear();
  }

  bool _isExpired(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return true;
    return DateTime.now().difference(timestamp).inMilliseconds > _cacheTTL;
  }

  void _setCacheTimestamp(String key) {
    _cacheTimestamps[key] = DateTime.now();
  }

  // Cache size management
  void trimCache() {
    if (_memoryCache.length > 100) {
      final oldestKeys = _cacheTimestamps.entries
          .sorted((a, b) => a.value.compareTo(b.value))
          .take(20)
          .map((e) => e.key)
          .toList();

      for (var key in oldestKeys) {
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
  }
}