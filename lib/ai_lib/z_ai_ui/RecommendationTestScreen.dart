import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../ai_data_bloc/ai_repository.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../core/trainingConfig.dart';
import '../testing/model_tester.dart';

class ModelTestResult {
  final Map<String, double> metrics;
  final Map<String, dynamic> prediction;
  final Map<String, dynamic> expected;
  final double accuracy;
  final String modelName;
  final DateTime testTime;
  final bool passed;

  ModelTestResult({
    required this.metrics,
    required this.prediction,
    required this.expected,
    required this.accuracy,
    required this.modelName,
    DateTime? testTime,
    bool? passed,
  }) :
        testTime = testTime ?? DateTime.now(),
        passed = passed ?? _checkIfPassed(metrics);

  static bool _checkIfPassed(Map<String, double> metrics) {
    return metrics.entries.every((entry) =>
    entry.value >= (AIConstants.MINIMUM_METRICS[entry.key] ?? 0.0)
    );
  }

  factory ModelTestResult.fromMap(Map<String, dynamic> map) {
    return ModelTestResult(
      metrics: Map<String, double>.from(map['metrics'] ?? {}),
      prediction: map['prediction'] ?? {},
      expected: map['expected'] ?? {},
      accuracy: map['accuracy']?.toDouble() ?? 0.0,
      modelName: map['model_name'] ?? 'unknown',
      testTime: DateTime.tryParse(map['test_time'] ?? ''),
      passed: map['passed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'metrics': metrics,
    'prediction': prediction,
    'expected': expected,
    'accuracy': accuracy,
    'model_name': modelName,
    'test_time': testTime.toIso8601String(),
    'passed': passed,
  };
}




class RecommendationTestScreen extends StatefulWidget {
  const RecommendationTestScreen({super.key});

  @override
  _RecommendationTestScreenState createState() => _RecommendationTestScreenState();
}

class _RecommendationTestScreenState extends State<RecommendationTestScreen> {
  final Logger _logger = Logger('RecommendationTestScreen');
  final ModelTester _modelTester = ModelTester();
  final AIRepository _aiRepository = AIRepository();

  bool _isTesting = false;
  final List<ModelTestResult> _testResults = [];
  String _selectedTestType = 'exercise'; // Default test type
  Map<String, dynamic> _currentTestCase = {};

  // Test türleri
  final Map<String, String> _testTypes = {
    'exercise': 'Egzersiz Önerileri',
    'intensity': 'Yoğunluk Önerileri',
    'program': 'Program Önerileri',
  };



  @override
  void initState() {
    super.initState();
    _initializeTestCase();
  }

  void _initializeTestCase() {
    _currentTestCase = {
      'user_age': 25,
      'user_weight': 70,
      'user_height': 175,
      'fitness_level': 'intermediate',
      'training_goal': 'strength',
      'health_conditions': [],
      'preferred_equipment': ['dumbbell', 'bodyweight'],
    };
  }

  Future<void> _runTest() async {
    if (_isTesting) return;
    setState(() => _isTesting = true);

    try {
      final testData = await _prepareTestData();
      final results = await _runModelPredictions(testData);

      // Map'i ModelTestResult'a dönüştür
      final testResult = ModelTestResult(
          metrics: {
            'accuracy': results['accuracy'] ?? 0.0,
            'precision': results['precision'] ?? 0.0,
            'recall': results['recall'] ?? 0.0,
            'f1_score': results['f1_score'] ?? 0.0,
          },
          prediction: results['prediction'] ?? {},
          expected: results['expected'] ?? {},
          accuracy: results['accuracy']?.toDouble() ?? 0.0,
          modelName: _selectedTestType,
          testTime: DateTime.now()
      );

      setState(() {
        _testResults.insert(0, testResult);
        if (_testResults.length > 10) {
          _testResults.removeLast();
        }
      });

      _showTestResultDialog(testResult);

    } catch (e) {
      _logger.severe('Test failed: $e');
      _showErrorDialog('Test başarısız: ${e.toString()}');
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<Map<String, dynamic>> _runModelPredictions(
      List<Map<String, dynamic>> testData
      ) async {
    final results = <String, dynamic>{};

    for (var testCase in testData) {
      final userProfile = UserProfile.fromMap(testCase);

      // Program önerisi al
      final recommendation = await _aiRepository.getProgramRecommendation(
          userProfile: userProfile
      );

      // Sonuçları kaydet
      results['prediction'] = {
        'plan_id': recommendation.planId,
        'bmi_case': recommendation.bmiCase,
        'bfp_case': recommendation.bfpCase,
        'confidence': recommendation.confidenceScore
      };

      // Beklenen sonuçla karşılaştır
      results['expected'] = testCase['expected_output'];

    }

    return results;
  }



  Future<List<Map<String, dynamic>>> _prepareTestData() async {
    try {
      // Test case'ini UserProfile'a dönüştür
      final userProfile = UserProfile.fromMap(_currentTestCase);

      // Beklenen öneriyi al
      final expectedRecommendation = await _aiRepository.getProgramRecommendation(
          userProfile: userProfile
      );

      return [{
        ..._currentTestCase,
        'expected_output': {
          'plan_id': expectedRecommendation.planId,
          'bmi_case': expectedRecommendation.bmiCase,
          'bfp_case': expectedRecommendation.bfpCase,
          'confidence': expectedRecommendation.confidenceScore
        }
      }];
    } catch (e) {
      throw AITestingException('Test verisi hazırlama hatası: $e');
    }
  }


  Widget _buildTestConfigurationCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Konfigürasyonu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTestType,
              decoration: InputDecoration(
                labelText: 'Test Türü',
                border: OutlineInputBorder(),
              ),
              items: _testTypes.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedTestType = value!);
              },
            ),
            SizedBox(height: 16),
            _buildTestParametersForm(),
          ],
        ),
      ),
    );
  }


  Widget _buildTestParametersForm() {
    return Column(
      children: [
        TextFormField(
          initialValue: _currentTestCase['user_age'].toString(),
          decoration: InputDecoration(
            labelText: 'Yaş',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _currentTestCase['user_age'] = int.tryParse(value) ?? 25;
          },
        ),
        SizedBox(height: 12),
        TextFormField(
          initialValue: _currentTestCase['user_weight'].toString(),
          decoration: InputDecoration(
            labelText: 'Kilo (kg)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _currentTestCase['user_weight'] = double.tryParse(value) ?? 70;
          },
        ),
        SizedBox(height: 12),
        TextFormField(
          initialValue: _currentTestCase['user_height'].toString(),
          decoration: InputDecoration(
            labelText: 'Boy (cm)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _currentTestCase['user_height'] = double.tryParse(value) ?? 175;
          },
        ),
        SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _currentTestCase['fitness_level'],
          decoration: InputDecoration(
            labelText: 'Fitness Seviyesi',
            border: OutlineInputBorder(),
          ),
          items: ['beginner', 'intermediate', 'advanced'].map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _currentTestCase['fitness_level'] = value;
            });
          },
        ),
        SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _currentTestCase['training_goal'],
          decoration: InputDecoration(
            labelText: 'Antrenman Hedefi',
            border: OutlineInputBorder(),
          ),
          items: ['strength', 'endurance', 'weight_loss', 'muscle_gain'].map((goal) {
            return DropdownMenuItem(
              value: goal,
              child: Text(_formatGoal(goal)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _currentTestCase['training_goal'] = value;
            });
          },
        ),
        SizedBox(height: 16),
        _buildEquipmentSelectionChips(),
      ],
    );
  }

  String _formatGoal(String goal) {
    return goal.split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildEquipmentSelectionChips() {
    final availableEquipment = [
      'dumbbell',
      'barbell',
      'kettlebell',
      'bodyweight',
      'resistance_band',
      'machine',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tercih Edilen Ekipmanlar',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: availableEquipment.map((equipment) {
            final isSelected = (_currentTestCase['preferred_equipment'] as List)
                .contains(equipment);
            return FilterChip(
              label: Text(_formatGoal(equipment)),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    (_currentTestCase['preferred_equipment'] as List).add(equipment);
                  } else {
                    (_currentTestCase['preferred_equipment'] as List)
                        .remove(equipment);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTestResultsList() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Sonuçları',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            if (_testResults.isEmpty)
              Center(
                child: Text('Henüz test sonucu bulunmuyor'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _testResults.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  final result = _testResults[index];
                  return ListTile(
                    title: Text('Test #${_testResults.length - index}'),
                    subtitle: Text(
                      'Doğruluk: ${(result.metrics['accuracy'] ?? 0).toStringAsFixed(2)}\n'
                          'F1 Skor: ${(result.metrics['f1_score'] ?? 0).toStringAsFixed(2)}',
                    ),
                    trailing: Icon(
                      result.passed ? Icons.check_circle : Icons.error,
                      color: result.passed ? Colors.green : Colors.red,
                    ),
                    onTap: () => _showTestResultDialog(result),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showTestResultDialog(ModelTestResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test Sonuçları'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Model: ${result.modelName}'),
              Text('Tarih: ${result.testTime.toString()}'),
              Divider(),
              ...result.metrics.entries.map((entry) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(entry.value.toStringAsFixed(4)),
                  ],
                ),
              )),
              Divider(),
              Text(
                'Sonuç: ${result.passed ? 'Başarılı' : 'Başarısız'}',
                style: TextStyle(
                  color: result.passed ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Öneri Sistemi Testi'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTestConfigurationCard(),
            SizedBox(height: 16),
            _buildTestResultsList(),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isTesting ? null : _runTest,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isTesting ? 'Test Çalışıyor...' : 'Testi Başlat'),
            ),
          ],
        ),
      ),
    );
  }
}