import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/material.dart';
import 'fitness_predictor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Değerlendirme',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final fitnessPredictor = FitnessPredictorv2();
  final _formKey = GlobalKey<FormState>();

  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  int _selectedGender = 0;
  Map<String, dynamic>? _results;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    setState(() => _isLoading = true);
    try {
      await fitnessPredictor.initialize();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final results = await fitnessPredictor.predict(
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text) / 100,
        gender: _selectedGender,
        age: int.parse(_ageController.text),
      );

      setState(() => _results = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Değerlendirme'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Kilo (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Kilo giriniz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Boy (cm)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.height),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Boy giriniz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Yaş',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Yaş giriniz' : null,
              ),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Erkek'),
                    icon: Icon(Icons.male),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Kadın'),
                    icon: Icon(Icons.female),
                  ),
                ],
                selected: {_selectedGender},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() => _selectedGender = newSelection.first);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _predict,
                icon: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.calculate),
                label: Text(_isLoading ? 'Hesaplanıyor...' : 'Hesapla'),
              ),
              if (_results != null) ...[
                const SizedBox(height: 24),
                _buildResultsCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.monitor_weight),
              title: Text(
                'BMI: ${_results!['bmi'].toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: Text(
                'Önerilen Egzersiz Planı: ${_results!['exercise_plan']}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(
                  'Güven Oranı: ${(_results!['confidence'] * 100).toStringAsFixed(1)}%'
              ),
            ),
          ],
        ),
      ),
    );
  }



  @override
  void dispose() {
    fitnessPredictor.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}

class FitnessPredictorv2 {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  final FitnessPredictor _fitnessPredictor = FitnessPredictor();

  final Map<String, Map<String, double>> _normalization = {
    'bmi': {'mean': 25.0, 'std': 5.0},
    'gender': {'mean': 0.5, 'std': 0.5},
    'weight': {'mean': 80.5, 'std': 15.0},
    'height': {'mean': 1.75, 'std': 0.12},
    'age': {'mean': 35.0, 'std': 15.0}
  };

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Future.wait([
        _fitnessPredictor.initialize(),
        Interpreter.fromAsset('assets/ai_models/fitness_model.tflite').then((value) => _interpreter = value),
      ]);
      _isInitialized = true;
    } catch (e) {
      throw Exception('Model yüklenirken hata: $e');
    }
  }

  List<double> _normalizeInput({
    required double bmi,
    required int gender,
    required double weight,
    required double height,
    required int age,
  }) {
    return [
      (bmi - _normalization['bmi']!['mean']!) / _normalization['bmi']!['std']!,
      (gender.toDouble() - _normalization['gender']!['mean']!) / _normalization['gender']!['std']!,
      (weight - _normalization['weight']!['mean']!) / _normalization['weight']!['std']!,
      (height - _normalization['height']!['mean']!) / _normalization['height']!['std']!,
      (age.toDouble() - _normalization['age']!['mean']!) / _normalization['age']!['std']!,
    ];
  }

  Future<Map<String, dynamic>> predict({
    required double weight,
    required double height,
    required int gender,
    required int age,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // FitnessPredictor ile BMI ve BFP hesapla
      final bodyComposition = await _fitnessPredictor.predict(
        weight: weight,
        height: height,
        gender: gender,
        age: age,
      );

      if (bodyComposition == null) {
        throw Exception('Vücut kompozisyonu hesaplanamadı');
      }

      final double bmi = bodyComposition['bmi'] ?? 0.0;
      final double bodyFat = bodyComposition['body_fat'] ?? 0.0;

      // Egzersiz planı tahmini için girdiyi hazırla
      var normalizedInputs = _normalizeInput(
        bmi: bmi,
        gender: gender,
        weight: weight,
        height: height,
        age: age,
      );

      var inputArray = [normalizedInputs];
      var outputArray = List<double>.filled(1 * 7, 0.0).reshape([1, 7]);

      _interpreter!.run(inputArray, outputArray);

      int predictedPlan = 0;
      double maxProb = outputArray[0][0];

      for (int i = 1; i < 7; i++) {
        if (outputArray[0][i] > maxProb) {
          maxProb = outputArray[0][i];
          predictedPlan = i;
        }
      }

      return {
        'bmi': bmi,
        'body_fat': bodyFat,
        'exercise_plan': predictedPlan + 1,
        'confidence': maxProb,
      };
    } catch (e) {
      throw Exception('Tahmin hatası: $e');
    }
  }

  void dispose() {
    _interpreter?.close();
    _fitnessPredictor.dispose();
    _isInitialized = false;
  }
}


