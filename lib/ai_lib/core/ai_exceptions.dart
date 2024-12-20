import 'ai_constants.dart';

/// AI sistemi için özel hata sınıfları
class AIException implements Exception {
  final String message;
  final String? code;

  AIException(this.message, {this.code});

  @override
  String toString() => code != null
      ? 'AIException: $code - $message'
      : 'AIException: $message';
}

/// Veri işleme hatalarını yöneten sınıf
class AIDataProcessingException extends AIException {
  AIDataProcessingException(super.message, {super.code});
}

class AIModelException extends AIException {
  AIModelException(super.message, {super.code});
}

// Eklenebilecek yeni exception sınıfı
class CollaborativeFilteringException extends AIModelException {
  CollaborativeFilteringException(super.message, {String? code})
      : super(code: code ?? AIConstants.ERROR_PREDICTION_FAILED);
}

/// Model eğitimi hatalarını yöneten sınıf
class AITrainingException extends AIException {
  AITrainingException(super.message, {super.code});
}

/// Model tahmin hatalarını yöneten sınıf
class AIPredictionException extends AIException {
  AIPredictionException(super.message, {super.code});
}

/// Model validasyon hatalarını yöneten sınıf
class AIValidationException extends AIException {
  AIValidationException(super.message, {super.code});
}

class AIInitializationException implements Exception {
  final String message;
  AIInitializationException(this.message);
  @override
  String toString() => 'AIInitializationException: $message';
}
