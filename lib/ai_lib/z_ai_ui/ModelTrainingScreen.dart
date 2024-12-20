import 'package:flutter/material.dart';

import '../../z.app_theme/app_theme.dart';
import '../ai_data_bloc/ai_repository.dart';
import '../core/ai_constants.dart';

class ModelTrainingScreen extends StatefulWidget {
  const ModelTrainingScreen({super.key});

  @override
  _ModelTrainingScreenState createState() => _ModelTrainingScreenState();
}

class _ModelTrainingScreenState extends State<ModelTrainingScreen> {
  final AIRepository _repository = AIRepository();
  bool _isTraining = false;
  Map<String, Map<String, double>> _modelMetrics = {};

  @override
  void initState() {
    super.initState();
    _subscribeToMetrics();
  }

  void _subscribeToMetrics() {
    _repository.metricsStream.listen((metrics) {
      setState(() {
        _modelMetrics = {
          'agde': metrics,
        };
      });
    });
  }

  Future<void> _startTraining() async {
    setState(() => _isTraining = true);
    try {
      await _repository.trainModels();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eğitim hatası: $e')),
      );
    } finally {
      setState(() => _isTraining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Model Eğitimi', style: AppTheme.headingMedium),
        actions: [
          IconButton(
            icon: Icon(
              _isTraining ? Icons.stop : Icons.play_arrow,
              color: AppTheme.primaryRed,
            ),
            onPressed: _isTraining ? null : _startTraining,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          children: [
            _buildModelStatus('AGDE Model', _modelMetrics['agde']),
            SizedBox(height: AppTheme.paddingLarge),
            _buildModelStatus('KNN Model', _modelMetrics['knn']),
            SizedBox(height: AppTheme.paddingLarge),
            _buildModelStatus('Collaborative Model', _modelMetrics['collaborative']),
          ],
        ),
      ),
    );
  }

  Widget _buildModelStatus(String modelName, Map<String, double>? metrics) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(modelName, style: AppTheme.headingSmall),
          SizedBox(height: AppTheme.paddingMedium),
          if (metrics != null) ...[
            _buildMetricRow('Accuracy', metrics['accuracy'] ?? 0),
            _buildMetricRow('Precision', metrics['precision'] ?? 0),
            _buildMetricRow('Recall', metrics['recall'] ?? 0),
            _buildMetricRow('F1 Score', metrics['f1_score'] ?? 0),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow(String name, double value) {
    final isGood = value >= AIConstants.MINIMUM_METRICS[name]!;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: AppTheme.bodyMedium),
          Text(
            '${(value * 100).toStringAsFixed(1)}%',
            style: AppTheme.bodyMedium.copyWith(
              color: isGood ? AppTheme.successGreen : AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }
}
