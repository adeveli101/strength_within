import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../ai_data_bloc/ai_repository.dart';
import '../ai_data_bloc/ai_state.dart';
import '../core/ai_constants.dart';
import '../core/trainingConfig.dart';


class ModelTrainingScreen extends StatefulWidget {
  const ModelTrainingScreen({super.key});

  @override
  _ModelTrainingScreenState createState() => _ModelTrainingScreenState();
}

class _ModelTrainingScreenState extends State<ModelTrainingScreen> {
  final Logger _logger = Logger('ModelTrainingScreen');
  final AIStateManager _stateManager = AIStateManager();
  late TrainingConfig _trainingConfig;

  bool _isTraining = false;
  Map<String, double> _currentMetrics = {};
  double _trainingProgress = 0.0;
  String _currentStatus = 'Hazır';

  @override
  void initState() {
    super.initState();
    _initializeTrainingConfig();
    _setupStateListeners();
  }

  void _initializeTrainingConfig() {
    _trainingConfig = TrainingConfig(
      epochs: AIConstants.EPOCHS,
      batchSize: AIConstants.BATCH_SIZE,
      learningRate: AIConstants.LEARNING_RATE,
      validationSplit: AIConstants.VALIDATION_SPLIT,
      useEarlyStopping: true,
    );
  }

  void _setupStateListeners() {
    _stateManager.modelState.listen((state) {
      setState(() {
        _currentStatus = state.toString().split('.').last;
        if (state == AIModelState.training) {
          _isTraining = true;
        } else if (state == AIModelState.error || state == AIModelState.initialized) {
          _isTraining = false;
        }
      });
    });

    _stateManager.metrics.listen((metrics) {
      setState(() => _currentMetrics = metrics);
    });

    _stateManager.progress.listen((progress) {
      setState(() => _trainingProgress = progress);
    });

    _stateManager.errors.listen((error) {
      _showErrorDialog(error.message);
    });
  }

  Future<void> _startTraining() async {
    try {
      setState(() => _isTraining = true);

      await AIRepository().trainModels(
        'AGDE Model',
      );

    } catch (e) {
      _logger.severe('Training failed: $e');
      _showErrorDialog('Eğitim başarısız: $e');
    } finally {
      setState(() => _isTraining = false);
    }
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

  Widget _buildMetricsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model Metrikleri',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ..._currentMetrics.entries.map((entry) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(entry.value.toStringAsFixed(4)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _trainingProgress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        SizedBox(height: 8),
        Text(
          'İlerleme: ${(_trainingProgress * 100).toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          'Durum: $_currentStatus',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildConfigurationSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eğitim Konfigürasyonu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('Epochs'),
              trailing: Text('${_trainingConfig.epochs}'),
            ),
            ListTile(
              title: Text('Batch Size'),
              trailing: Text('${_trainingConfig.batchSize}'),
            ),
            ListTile(
              title: Text('Learning Rate'),
              trailing: Text('${_trainingConfig.learningRate}'),
            ),
            ListTile(
              title: Text('Validation Split'),
              trailing: Text('${_trainingConfig.validationSplit}'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Model Eğitimi'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isTraining ? null : _initializeTrainingConfig,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConfigurationSection(),
            SizedBox(height: 16),
            _buildProgressSection(),
            SizedBox(height: 16),
            _buildMetricsCard(),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isTraining ? null : _startTraining,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isTraining ? 'Eğitim Devam Ediyor...' : 'Eğitimi Başlat'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Gerekli temizleme işlemleri
    super.dispose();
  }
}