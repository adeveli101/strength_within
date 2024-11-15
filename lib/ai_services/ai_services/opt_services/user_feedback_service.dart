// lib/services/user_feedback_service.dart

import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore kullanarak geri bildirimi kaydetmek için
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication kullanarak kullanıcı kimliğini almak için

class UserFeedbackService {
  final Logger _logger = Logger('UserFeedbackService');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore örneği
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Authentication örneği

  Future<void> processFeedback(String userId, dynamic feedback) async {
    try {
      // Geri bildirimi işle ve kaydet
      _logger.info('Processing feedback from user $userId: $feedback');

      // Geri bildirimi veritabanına kaydet
      await _saveFeedbackToDatabase(userId, feedback);

      // Geri bildirimi AI modeline dahil et
      await _updateAIModel(userId, feedback);
    } catch (e, stackTrace) {
      _logger.severe('Error processing user feedback: $e', stackTrace);
      rethrow;
    }
  }

  Future<void> _saveFeedbackToDatabase(String userId, dynamic feedback) async {
    try {
      // Firestore'da "feedback" koleksiyonuna kullanıcı geri bildirimini kaydet
      await _firestore.collection('feedback').add({
        'userId': userId,
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(), // Geri bildirim zamanı
      });

      _logger.info('Feedback from user $userId saved to database.');
    } catch (e, stackTrace) {
      _logger.severe('Error saving feedback to database: $e', stackTrace);
    }
  }

  Future<void> _updateAIModel(String userId, dynamic feedback) async {
    try {
      // AI modelini güncelleme mantığı
      // Bu kısım, geri bildirimi kullanarak AI modelini nasıl güncelleyeceğinize bağlı olarak değişecektir.

      _logger.info('Updating AI model with feedback from user $userId');

      // Burada AI model güncellemesi yapılabilir.
    } catch (e, stackTrace) {
      _logger.severe('Error updating AI model: $e', stackTrace);
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        return currentUser.uid;
      } else {
        _logger.warning('No user is currently signed in.');
        return null;
      }
    } catch (e, stackTrace) {
      _logger.severe('Error retrieving current user ID: $e', stackTrace);
      return null;
    }
  }
}
