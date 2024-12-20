import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../z.app_theme/app_theme.dart';
import '../ai_data_bloc/ai_repository.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../testing/ab_test_runner.dart';
import '../testing/model_tester.dart';

class ModelDashboardScreen extends StatefulWidget {
  const ModelDashboardScreen({super.key});

  @override
  _ModelDashboardScreenState createState() => _ModelDashboardScreenState();
}

class _ModelDashboardScreenState extends State<ModelDashboardScreen> {
  final AIRepository _repository = AIRepository();
  final ModelTester _modelTester = ModelTester();
  final ABTestRunner _abTestRunner = ABTestRunner();

  Map<String, Map<String, double>> _modelMetrics = {};
  Map<String, Map<String, double>> _testResults = {};
  bool _isLoading = false;

  Map<String, Map<String, double>> get modelMetrics => _modelMetrics;


  @override
  void initState() {
    super.initState();
    _subscribeToMetrics();
    _loadData();
  }

  void _subscribeToMetrics() {
    _repository.metricsStream.listen((metrics) {
      setState(() {
        _modelMetrics = {
          'agde': metrics,
          'knn': metrics,
          'collaborative': metrics,
        };
      });
    });
  }


  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _repository.initialize();
      final metrics = await _modelTester.testModels();
      final abResults = await _abTestRunner.runTest();

      setState(() {
        _modelMetrics = metrics;
        _testResults = abResults;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veri yükleme hatası: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Model Performans', style: AppTheme.headingMedium),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryRed),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModelComparison(),
            SizedBox(height: AppTheme.paddingLarge),
            _buildABTestResults(),
            SizedBox(height: AppTheme.paddingLarge),
            _buildDetailedMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildModelComparison() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Model Karşılaştırması', style: AppTheme.headingSmall),
          SizedBox(height: AppTheme.paddingMedium),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                barGroups: _createBarGroups(),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch(value.toInt()) {
                          case 0: return Text('AGDE', style: AppTheme.bodySmall);
                          case 1: return Text('KNN', style: AppTheme.bodySmall);
                          case 2: return Text('Collab', style: AppTheme.bodySmall);
                          default: return Text('');
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups() {
    final metrics = ['accuracy', 'precision', 'recall', 'f1_score'];
    final models = ['agde', 'knn', 'collaborative'];

    return List.generate(models.length, (index) {
      final modelMetrics = _modelMetrics[models[index]] ?? {};
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: modelMetrics['accuracy'] ?? 0,
            color: AppTheme.primaryRed,
            width: 15,
          ),
        ],
      );
    });
  }

  Widget _buildABTestResults() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A/B Test Sonuçları', style: AppTheme.headingSmall),
          SizedBox(height: AppTheme.paddingMedium),
          Row(
            children: [
              Expanded(
                child: _buildTestGroup('Kontrol Grubu', _testResults['control_group']),
              ),
              SizedBox(width: AppTheme.paddingMedium),
              Expanded(
                child: _buildTestGroup('Test Grubu', _testResults['test_group']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestGroup(String title, Map<String, double>? metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.bodyMedium),
        SizedBox(height: AppTheme.paddingSmall),
        ...AIConstants.MINIMUM_METRICS.entries.map((entry) {
          final value = metrics?[entry.key] ?? 0.0;
          final isGood = value >= entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: AppTheme.paddingSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key, style: AppTheme.bodySmall),
                Text(
                  '${(value * 100).toStringAsFixed(1)}%',
                  style: AppTheme.bodySmall.copyWith(
                    color: isGood ? AppTheme.successGreen : AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailedMetrics() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detaylı Metrikler', style: AppTheme.headingSmall),
          SizedBox(height: AppTheme.paddingMedium),
          DataTable(
            columns: [
              DataColumn(label: Text('Metrik', style: AppTheme.bodyMedium)),
              DataColumn(label: Text('AGDE', style: AppTheme.bodyMedium)),
              DataColumn(label: Text('KNN', style: AppTheme.bodyMedium)),
              DataColumn(label: Text('Collab', style: AppTheme.bodyMedium)),
            ],
            rows: _createMetricRows(),
          ),
        ],
      ),
    );
  }

  List<DataRow> _createMetricRows() {
    return AIConstants.MINIMUM_METRICS.keys.map((metric) {
      return DataRow(
        cells: [
          DataCell(Text(metric, style: AppTheme.bodySmall)),
          ...['agde', 'knn', 'collaborative'].map((model) {
            final value = _modelMetrics[model]?[metric] ?? 0.0;
            return DataCell(Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: AppTheme.bodySmall.copyWith(
                color: value >= AIConstants.MINIMUM_METRICS[metric]!
                    ? AppTheme.successGreen
                    : AppTheme.warningColor,
              ),
            ));
          }),
        ],
      );
    }).toList();
  }
}
