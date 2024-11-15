// lib/services/caching_service.dart

import 'package:logging/logging.dart';
import 'dart:collection';

class CachingService {
  final Logger _logger = Logger('CachingService');
  final int _maxSize;
  final LinkedHashMap<String, dynamic> _cache;

  CachingService({int maxSize = 100})
      : _maxSize = maxSize,
        _cache = LinkedHashMap();

  T? get<T>(String key) {
    try {
      final value = _cache[key];
      if (value != null) {
        // LRU: Erişilen öğeyi listenin sonuna taşı
        _cache.remove(key);
        _cache[key] = value;
        return value as T;
      }
      return null;
    } catch (e, stackTrace) {
      _logger.warning('Error retrieving from cache: $e', stackTrace);
      return null;
    }
  }

  void set(String key, dynamic value) {
    try {
      if (_cache.length >= _maxSize) {
        // LRU: En az kullanılan öğeyi çıkar
        _cache.remove(_cache.keys.first);
      }
      _cache[key] = value;
    } catch (e, stackTrace) {
      _logger.severe('Error setting cache: $e', stackTrace);
    }
  }

  void clear() {
    try {
      _cache.clear();
    } catch (e, stackTrace) {
      _logger.severe('Error clearing cache: $e', stackTrace);
    }
  }
}
