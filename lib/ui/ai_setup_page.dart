import 'package:flutter/material.dart';

import '../ai_predictors/ai_bloc/ai_repository.dart';
import '../blocs/data_provider/firebase_provider.dart';
import '../blocs/data_provider/sql_provider.dart';
import '../models/firebase_models/user_ai_profile.dart';

class AIProfileSetupPage extends StatefulWidget {
  final String userId;

  const AIProfileSetupPage({
    super.key,
    required this.userId,
  });

  @override
  State<AIProfileSetupPage> createState() => _AIProfileSetupPageState();
}

class _AIProfileSetupPageState extends State<AIProfileSetupPage> {
  late final AIRepository _aiRepository;
  UserAIProfile? _userProfile;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _aiRepository = AIRepository(SQLProvider(), FirebaseProvider());
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _aiRepository.getLatestUserPrediction(widget.userId);
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileSetup() {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: () {
        if (_currentStep < 3) {
          setState(() => _currentStep++);
        }
      },
      onStepCancel: () {
        if (_currentStep > 0) {
          setState(() => _currentStep--);
        }
      },
      steps: [
        Step(
          title: const Text('Fiziksel Ölçümler'),
          content: _PhysicalMeasurementsForm(
            onSaved: (height, weight) {
              // BMI hesaplama ve kaydetme
            },
          ),
          isActive: _currentStep >= 0,
        ),
        Step(
          title: const Text('Fitness Seviyesi'),
          content: _FitnessLevelForm(
            onSaved: (level) {
              // Fitness seviyesi kaydetme
            },
          ),
          isActive: _currentStep >= 1,
        ),
        Step(
          title: const Text('Hedefler'),
          content: _GoalsSelectionForm(
            onSaved: (goals) {
              // Hedefleri kaydetme
            },
          ),
          isActive: _currentStep >= 2,
        ),
        Step(
          title: const Text('Program Tercihleri'),
          content: _WorkoutPreferencesForm(
            onSaved: (preferences) {
              // Tercihleri kaydetme
            },
          ),
          isActive: _currentStep >= 3,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Profil Oluşturma'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile != null
          ? _buildExistingProfile()
          : _buildProfileSetup(),
    );
  }

  Widget _buildExistingProfile() {
    return Column(
      children: [
        // Mevcut profil bilgileri
        Card(
          child: ListTile(
            title: const Text('Mevcut AI Profili'),
            subtitle: Text('Fitness Seviyesi: ${_userProfile?.fitnessLevel ?? "Belirsiz"}'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadExistingProfile,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => setState(() => _userProfile = null),
          child: const Text('Profili Güncelle'),
        ),
      ],
    );
  }
}

// Alt form widget'ları
class _PhysicalMeasurementsForm extends StatelessWidget {
  final Function(double height, double weight) onSaved;

  const _PhysicalMeasurementsForm({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: 'Boy (cm)'),
          keyboardType: TextInputType.number,
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Kilo (kg)'),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

// Form widget'ları
class _FitnessLevelForm extends StatelessWidget {
  final Function(int level) onSaved;

  const _FitnessLevelForm({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 1; i <= 5; i++)
          RadioListTile<int>(
            title: Text('Seviye $i'),
            value: i,
            groupValue: null, // Seçili değeri state'te tutmanız gerekir
            onChanged: (value) {
              if (value != null) onSaved(value);
            },
          ),
      ],
    );
  }
}

class _GoalsSelectionForm extends StatelessWidget {
  final Function(List<int> goals) onSaved;

  const _GoalsSelectionForm({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Kilo Vermek'),
          value: false, // State'te tutulmalı
          onChanged: (value) {
            // Seçili hedefleri güncelleyin
          },
        ),
        CheckboxListTile(
          title: const Text('Kas Kazanmak'),
          value: false,
          onChanged: (value) {
            // Seçili hedefleri güncelleyin
          },
        ),
        // Diğer hedefler...
      ],
    );
  }
}

class _WorkoutPreferencesForm extends StatelessWidget {
  final Function(Map<String, dynamic> preferences) onSaved;

  const _WorkoutPreferencesForm({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Haftalık Antrenman Günü'),
          trailing: DropdownButton<int>(
            value: 3, // Varsayılan değer
            items: List.generate(7, (index) => index + 1).map((day) {
              return DropdownMenuItem(
                value: day,
                child: Text('$day gün'),
              );
            }).toList(),
            onChanged: (value) {
              // Tercihleri güncelleyin
            },
          ),
        ),
        // Diğer tercihler...
      ],
    );
  }
}
