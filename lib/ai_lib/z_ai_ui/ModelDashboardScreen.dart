import 'package:flutter/material.dart';

import '../ai_data_bloc/ai_repository.dart';
import '../core/trainingConfig.dart';

class ModelDashboardScreen extends StatelessWidget {
  final AIRepository _repository = AIRepository();

  ModelDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Model Dashboard')),
      body: StreamBuilder<Map<String, Map<String, double>>>(
        stream: _repository.metricsStream,
        builder: (context, snapshot) {
          return Column(
            children: [
              // Model States Card
              _buildStateCard(),

              // Metrics Grid
              _buildMetricsGrid(snapshot.data ?? {}),

              // Action Buttons
              _buildActionButtons(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStateCard() {
    return Card(
      child: StreamBuilder<AIRepositoryState>(
        stream: _repository.stateStream,
        builder: (context, snapshot) {
          return ListTile(
            title: Text('Model Status'),
            subtitle: Text(snapshot.data?.toString() ?? 'Unknown'),
            trailing: _getStateIcon(snapshot.data),
          );
        },
      ),
    );
  }

  Widget _getStateIcon(AIRepositoryState? state) {
    switch (state) {
      case AIRepositoryState.ready:
        return Icon(Icons.check_circle, color: Colors.green);
      case AIRepositoryState.training:
        return CircularProgressIndicator();
      case AIRepositoryState.error:
        return Icon(Icons.error, color: Colors.red);
      default:
        return Icon(Icons.help_outline);
    }
  }

  Widget _buildMetricsGrid(Map<String, Map<String, double>> metrics) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final model = metrics.keys.elementAt(index);
        final modelMetrics = metrics[model]!;
        return _buildMetricCard(model, modelMetrics);
      },
    );
  }
  Widget _buildMetricCard(String model, Map<String, double> metrics) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(model, style: TextStyle(fontWeight: FontWeight.bold)),
            ...metrics.entries.map((entry) =>
                Text('${entry.key}: ${entry.value.toStringAsFixed(3)}')
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => _repository.trainModels(
              config: TrainingConfig(),
              useBatchProcessing: true,
            ),
            child: Text('Train Models'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/test'),
            child: Text('Test Models'),
          ),
        ],
      ),
    );
  }
}
