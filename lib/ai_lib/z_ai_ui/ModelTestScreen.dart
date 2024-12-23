import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../ai_data_bloc/ai_repository.dart';
import '../ai_data_bloc/ai_state.dart';
import '../core/ai_constants.dart';

class ModelTestScreen extends StatefulWidget {
  const ModelTestScreen({super.key});

  @override
  _ModelTestScreenState createState() => _ModelTestScreenState();
}

class _ModelTestScreenState extends State<ModelTestScreen> {
  final _logger = Logger('ModelTestScreen');
  late AIRepository _aiRepository;
  bool _isTraining = false;
  bool _isInitialized = false;
  String _currentModel = '';
  double _trainingProgress = 0.0;
  Map<String, Map<String, double>> _metrics = {};
  String _currentStatus = '';
  // ignore: unused_field
  AIRepositoryState _repositoryState = AIRepositoryState.uninitialized;

  @override
  void initState() {
    super.initState();
    _aiRepository = AIRepository();
    _setupListeners();
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    try {
      setState(() => _currentStatus = 'Repository başlatılıyor...');
      await _aiRepository.initialize();
      setState(() {
        _isInitialized = true;
        _currentStatus = 'Repository hazır';
      });
      _logger.info('AI Repository başarıyla başlatıldı');
    } catch (e) {
      _logger.severe('Repository başlatma hatası: $e');
      _showError('Sistem başlatılamadı: $e');
    }
  }

  void _setupListeners() {
    // Model durumu dinleyicisi
    AIStateManager().modelState.listen((state) {
      setState(() {
        switch (state) {
          case AIModelState.uninitialized:
            _currentStatus = 'Model başlatılmadı';
            break;
          case AIModelState.initializing:
            _currentStatus = 'Model başlatılıyor...';
            break;
          case AIModelState.initialized:
            _currentStatus = 'Model hazır';
            break;
          case AIModelState.training:
            _isTraining = true;
            _currentStatus = 'Eğitim devam ediyor...';
            break;
          case AIModelState.validating:
            _currentStatus = 'Model doğrulanıyor...';
            break;
          case AIModelState.inferencing:
            _currentStatus = 'Model tahmin yapıyor...';
            break;
          case AIModelState.error:
            _isTraining = false;
            _currentStatus = 'Hata oluştu!';
            _showError('Model eğitimi başarısız oldu');
            break;
          case AIModelState.disposed:
            _isTraining = false;
            _currentStatus = 'Eğitim tamamlandı';
            break;
        }
      });
    });

    // İlerleme durumu dinleyicisi
    AIStateManager().progress.listen((progress) {
      setState(() {
        _trainingProgress = progress;
        if (_isTraining) {
          _currentStatus = 'İlerleme: ${(progress * 100).toStringAsFixed(1)}%';
        }
      });
    });

    // Metrik dinleyicisi
    _aiRepository.metricsStream.listen((metrics) {
      setState(() => _metrics = metrics);
    });

    // Repository durum dinleyicisi
    _aiRepository.stateStream.listen((state) {
      setState(() => _repositoryState = state);
    });
  }

  Future<void> _startTraining() async {
    if (!_isInitialized) {
      _showError('Sistem henüz başlatılmadı');
      return;
    }

    if (_currentModel.isEmpty) {
      _showError('Lütfen bir model seçin');
      return;
    }

    try {
      setState(() {
        _isTraining = true;
        _metrics.clear();
        _trainingProgress = 0.0;
      });

      switch (_currentModel) {
        case 'AGDE Model':
          await _aiRepository.runAGDEModel();
          break;
        case 'KNN Model':
          await _aiRepository.runKNNModel();
          break;
        case 'ENN Model':
          await _aiRepository.runENModel();
          break;
        default:
          throw Exception('Geçersiz model seçimi');
      }

      _logger.info('$_currentModel eğitimi tamamlandı');
    } catch (e, stackTrace) {
      _logger.severe('Eğitim hatası: $e\nStack trace: $stackTrace');
      _showError('Eğitim başarısız: $e');
    } finally {
      if (mounted) {
        setState(() => _isTraining = false);
      }
    }
  }

  Widget _buildMetricsCard() {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Model Metrikleri',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: _metrics.isEmpty
                ? Center(
                child: Text('Henüz metrik yok',
                    style: Theme.of(context).textTheme.bodyLarge))
                : ListView.builder(
              itemCount: _metrics.length,
              itemBuilder: (context, index) {
                String modelKey = _metrics.keys.elementAt(index);
                Map<String, double> modelMetrics =
                    _metrics[modelKey] ?? {};

                return ExpansionTile(
                  title: Text(modelKey),
                  children: modelMetrics.entries.map((entry) {
                    bool isGood = entry.value >= AIConstants.MIN_ACCURACY;
                    return ListTile(
                      title: Text(entry.key),
                      trailing: Text(
                        '${(entry.value * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isGood ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(_currentStatus,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: _getStatusColor())),
          if (_isTraining)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(
                value: _trainingProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_currentStatus.contains('Hata')) return Colors.red;
    if (_currentStatus.contains('tamamlandı')) return Colors.green;
    if (_isTraining) return Theme.of(context).primaryColor;
    return Colors.grey;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Model Test'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isTraining ? null : _initializeRepository,
            tooltip: 'Repository\'yi yeniden başlat',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildModelSelection(),
            SizedBox(height: 16.0),
            _buildTrainingControls(),
            _buildStatusDisplay(),
            Expanded(child: _buildMetricsCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model Seçimi',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              value: _currentModel.isEmpty ? null : _currentModel,
              items: ['AGDE Model', 'KNN Model', 'ENN Model']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: _isTraining ? null : (String? newValue) {
                setState(() => _currentModel = newValue!);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Bir model seçin',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingControls() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isTraining ? null : _startTraining,
                icon: Icon(Icons.play_arrow),
                label: Text('Eğitimi Başlat'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isTraining
                    ? () => _showError('Eğitim durdurulamaz')
                    : null,
                icon: Icon(Icons.stop),
                label: Text('Eğitimi Durdur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _aiRepository.dispose();
    super.dispose();
  }
}
