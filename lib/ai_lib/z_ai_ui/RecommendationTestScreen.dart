import 'package:flutter/material.dart';
import '../../z.app_theme/app_theme.dart';
import '../ai_data_bloc/ai_repository.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';

class RecommendationTestScreen extends StatefulWidget {
  const RecommendationTestScreen({super.key});

  @override
  _RecommendationTestScreenState createState() => _RecommendationTestScreenState();
}

class _RecommendationTestScreenState extends State<RecommendationTestScreen> {
  final AIRepository _repository = AIRepository();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  Map<String, dynamic> _recommendations = {};

  // Form değerleri
  final Map<String, dynamic> _userData = {
    'weight': 0.0,
    'height': 0.0,
    'age': 0,
    'gender': 'male',
    'experience_level': 1,
    'userId': 0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Program Önerisi', style: AppTheme.headingMedium),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserDataForm(),
            SizedBox(height: AppTheme.paddingLarge),
            _buildRecommendationButton(),
            SizedBox(height: AppTheme.paddingLarge),
            if (_recommendations.isNotEmpty) _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDataForm() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Kilo (kg)'),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Kilo gerekli' : null,
              onSaved: (value) => _userData['weight'] = double.parse(value!),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            TextFormField(
              decoration: InputDecoration(labelText: 'Boy (m)'),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Boy gerekli' : null,
              onSaved: (value) => _userData['height'] = double.parse(value!),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            TextFormField(
              decoration: InputDecoration(labelText: 'Yaş'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'Yaş gerekli';
                final age = int.parse(value);
                if (age < AIConstants.MIN_AGE || age > AIConstants.MAX_AGE) {
                  return 'Yaş ${AIConstants.MIN_AGE}-${AIConstants.MAX_AGE} arasında olmalı';
                }
                return null;
              },
              onSaved: (value) => _userData['age'] = int.parse(value!),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Cinsiyet'),
              items: ['male', 'female'].map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender == 'male' ? 'Erkek' : 'Kadın'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _userData['gender'] = value),
              value: _userData['gender'],
            ),
            SizedBox(height: AppTheme.paddingMedium),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'Deneyim Seviyesi'),
              items: [1, 2, 3].map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(_getExperienceLevelText(level)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _userData['experience_level'] = value),
              value: _userData['experience_level'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          padding: EdgeInsets.symmetric(vertical: AppTheme.paddingMedium),
        ),
        onPressed: _isLoading ? null : _getRecommendations,
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text('Öneri Al', style: AppTheme.bodyMedium),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Önerilen Programlar', style: AppTheme.headingSmall),
          SizedBox(height: AppTheme.paddingMedium),
          ..._recommendations['recommendations'].map<Widget>((programId) {
            return ListTile(
              title: Text(
                AIConstants.EXERCISE_PLAN_DESCRIPTIONS[programId]!,
                style: AppTheme.bodyMedium,
              ),
              leading: Icon(Icons.fitness_center, color: AppTheme.primaryRed),
            );
          }).toList(),
          if (_recommendations['metrics'] != null) ...[
            Divider(color: AppTheme.surfaceColor),
            Text('Model Güven Skorları', style: AppTheme.bodyMedium),
            SizedBox(height: AppTheme.paddingSmall),
            _buildMetricsTable(_recommendations['metrics']),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsTable(Map<String, Map<String, double>> metrics) {
    return Table(
      children: metrics.entries.map((entry) {
        return TableRow(
          children: [
            Padding(
              padding: EdgeInsets.all(AppTheme.paddingSmall),
              child: Text(entry.key, style: AppTheme.bodySmall),
            ),
            Padding(
              padding: EdgeInsets.all(AppTheme.paddingSmall),
              child: Text(
                '${(entry.value['accuracy']! * 100).toStringAsFixed(1)}%',
                style: AppTheme.bodySmall.copyWith(
                  color: entry.value['accuracy']! >= AIConstants.MIN_ACCURACY
                      ? AppTheme.successGreen
                      : AppTheme.warningColor,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getExperienceLevelText(int level) {
    switch (level) {
      case 1: return 'Başlangıç';
      case 2: return 'Orta Seviye';
      case 3: return 'İleri Seviye';
      default: return 'Bilinmiyor';
    }
  }

  Future<void> _getRecommendations() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final recommendations = await _repository.recommendProgram(_userData);
      setState(() => _recommendations = recommendations);
    } on AIException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Öneri alınamadı: ${e.message}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
