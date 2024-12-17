import 'package:logging/logging.dart';
import 'dart:async';

class AppCache {
  // Singleton yapısı
  static final AppCache _instance = AppCache._internal();
  factory AppCache() => _instance;
  AppCache._internal() {
    _initializeStats();
  }

  // Cache süreleri
  static const Duration WORKOUT_TYPES_EXPIRY = Duration(days: 1);
  static const Duration BODY_PARTS_EXPIRY = Duration(days: 1);
  static const Duration EXERCISES_EXPIRY = Duration(hours: 6);
  static const Duration PARTS_EXPIRY = Duration(hours: 6);
  static const Duration ROUTINES_EXPIRY = Duration(hours: 6);
  static const Duration JOIN_QUERY_EXPIRY = Duration(minutes: 30);
  static const Duration DEFAULT_EXPIRY = Duration(minutes: 30);

  // Cache limitleri
  static const int MAX_ITEMS = 1000;
  static const int CLEANUP_THRESHOLD = 800;

  // Cache yapıları
  final Map<String, _CacheItem> _cache = {};
  final Logger _logger = Logger('AppCache');
  final _stats = _CacheStats();
  final _listeners = <Function(String key, dynamic value)>[];
  CacheState _state = CacheState.ready;

  // Ana cache operasyonları
  T? get<T>(String key) {
    final item = _cache[key];
    if (item == null || item.isExpired) {
      _stats.incrementMiss();
      if (item != null) {
        _cache.remove(key);
        _logger.fine('Cache expired for key: $key');
      }
      return null;
    }
    _stats.incrementHit();
    _logger.fine('Cache hit for key: $key');
    return item.data as T;
  }

  Future<T?> getOrFetch<T>(
      String key,
      Future<T?> Function() fetchData,
      Duration expiry,
      ) async {
    final cachedData = get<T>(key);
    if (cachedData != null) return cachedData;

    _state = CacheState.loading;
    try {
      final data = await fetchData();
      if (data != null) {
        set(key, data, expiry: expiry);
      }
      _state = CacheState.ready;
      return data;
    } catch (e) {
      _state = CacheState.error;
      _logger.severe('Cache fetch error for key: $key', e);
      rethrow;
    }
  }

  void set(
      String key,
      dynamic data, {
        Duration? expiry,
        CachePriority priority = CachePriority.normal,
      }) {
    if (_cache.length >= MAX_ITEMS) {
      _evictCache();
    }

    _cache[key] = _CacheItem(
      data: data,
      expiry: expiry ?? DEFAULT_EXPIRY,
      priority: priority,
      version: 1,
    );
    _notifyListeners(key, data);
    _logger.fine('Cache set for key: $key');
  }

  // Cache temizleme ve yönetim
  void _evictCache() {
    final itemsToRemove = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (var key in itemsToRemove) {
      _cache.remove(key);
    }

    if (_cache.length >= CLEANUP_THRESHOLD) {
      final sortedItems = _cache.entries.toList()
        ..sort((a, b) => a.value.priority.index.compareTo(b.value.priority.index));

      for (var entry in sortedItems) {
        _cache.remove(entry.key);
        if (_cache.length < CLEANUP_THRESHOLD) break;
      }
    }
  }

  // İstatistik ve monitoring
  void _initializeStats() {
    Timer.periodic(Duration(hours: 1), (_) {
      _logger.info('Cache Stats: ${getStats()}');
    });
  }

  Map<String, dynamic> getStats() {
    return {
      'totalItems': _cache.length,
      'expiredItems': _cache.values.where((item) => item.isExpired).length,
      'hitRate': _stats.hitRate,
      'memoryUsage': _estimateMemoryUsage(),
      'state': _state.toString(),
    };
  }

  // Listener yönetimi
  void addListener(Function(String key, dynamic value) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(String key, dynamic value) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(String key, dynamic value) {
    for (var listener in _listeners) {
      listener(key, value);
    }
  }

  // Yardımcı metodlar
  void invalidate(String key) {
    _cache.remove(key);
    _logger.fine('Cache invalidated for key: $key');
  }

  void invalidatePattern(String pattern) {
    final regex = RegExp(pattern);
    _cache.removeWhere((key, _) => regex.hasMatch(key));
    _logger.fine('Cache invalidated for pattern: $pattern');
  }

  void clear() {
    _cache.clear();
    _listeners.clear();
    _stats.reset();
    _logger.fine('Cache cleared');
  }

  int _estimateMemoryUsage() {
    return _cache.values.fold(0, (sum, item) => sum + item.estimateSize());
  }
}

class _CacheItem {
  final dynamic data;
  final DateTime expiryTime;
  final CachePriority priority;
  final int version;

  _CacheItem({
    required this.data,
    required Duration expiry,
    this.priority = CachePriority.normal,
    this.version = 1,
  }) : expiryTime = DateTime.now().add(expiry);

  bool get isExpired => DateTime.now().isAfter(expiryTime);

  int estimateSize() {
    if (data is String) return (data as String).length * 2;
    if (data is Map) return (data as Map).length * 16;
    if (data is List) return (data as List).length * 8;
    return 8;
  }
}

class _CacheStats {
  int hits = 0;
  int misses = 0;

  void incrementHit() => hits++;
  void incrementMiss() => misses++;
  void reset() {
    hits = 0;
    misses = 0;
  }

  double get hitRate => hits + misses > 0 ? hits / (hits + misses) : 0;
}

enum CachePriority { low, normal, high }
enum CacheState { ready, loading, error }

class CacheException implements Exception {
  final String message;
  final String? code;

  CacheException(this.message, {this.code});

  @override
  String toString() => 'CacheException: $message ${code != null ? '($code)' : ''}';
}