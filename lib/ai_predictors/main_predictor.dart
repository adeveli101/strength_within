import 'package:flutter/material.dart';
import '../sw_app_theme/app_theme.dart';
import 'exercise_plan_predictor.dart';
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
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
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
  final fitnessPredictor = FitnessPredictor();
  final exercisePredictor = ExercisePlanPredictor();
  final _formKey = GlobalKey<FormState>();

  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  int _selectedGender = 0;
  Map<String, double>? _fitnessResults;
  Map<String, dynamic>? _exercisePlan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeModels();
  }

  Future<void> _initializeModels() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        fitnessPredictor.initialize(),
        exercisePredictor.initialize(),
      ]);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // İlk model ile BMI ve BFP hesapla
      final fitnessResults = await fitnessPredictor.predict(
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text) / 100,
        gender: _selectedGender,
        age: int.parse(_ageController.text),
      );

      // İkinci model ile egzersiz planı tahmin et
      final planResults = await exercisePredictor.predict(
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text) / 100,
        gender: _selectedGender,
        age: int.parse(_ageController.text),
        bmi: fitnessResults['bmi']!,
        bodyFat: fitnessResults['body_fat']!,
        bmiCase: _getBMICase(fitnessResults['bmi']!),
        bfpCase: _getBFPCase(fitnessResults['body_fat']!, _selectedGender),
      );

      setState(() {
        _fitnessResults = fitnessResults;
        _exercisePlan = planResults;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _getBMICase(double bmi) {
    if (bmi < 16.0) return 1;      // Çok Zayıf
    if (bmi < 18.5) return 2;      // Zayıf
    if (bmi < 25.0) return 3;      // Normal
    if (bmi < 30.0) return 4;      // Kilolu
    if (bmi < 35.0) return 5;      // Obez
    return 6;                       // Aşırı Obez
  }

  int _getBFPCase(double bodyFat, int gender) {
    if (gender == 0) { // Erkek
      if (bodyFat < 6) return 1;   // Çok Düşük
      if (bodyFat < 14) return 2;  // Atletik
      if (bodyFat < 18) return 3;  // Normal
      return 4;                    // Yüksek
    } else { // Kadın
      if (bodyFat < 14) return 1;  // Çok Düşük
      if (bodyFat < 21) return 2;  // Atletik
      if (bodyFat < 25) return 3;  // Normal
      return 4;                    // Yüksek
    }
  }

  @override
  void dispose() {
    fitnessPredictor.dispose();
    exercisePredictor.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
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
              if (_fitnessResults != null) ...[
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
                'BMI: ${_fitnessResults!['bmi']!.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text('Vücut Kitle İndeksi'),
            ),
            ListTile(
              leading: const Icon(Icons.percent),
              title: Text(
                'Vücut Yağ Oranı: ${_fitnessResults!['body_fat']!.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (_exercisePlan != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(
                  'Önerilen Egzersiz Planı: ${_exercisePlan!['exercise_plan']}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                    'Güven Oranı: ${(_exercisePlan!['confidence'] * 100).toStringAsFixed(1)}%'
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
