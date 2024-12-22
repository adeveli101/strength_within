import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../ai_data_bloc/ai_repository.dart';
import '../ai_data_bloc/ai_state.dart';

class ModelTestScreen extends StatefulWidget {
  const ModelTestScreen({super.key});

  @override
  _ModelTestScreenState createState() => _ModelTestScreenState();
}

class _ModelTestScreenState extends State<ModelTestScreen> {
  final _logger = Logger('ModelTestScreen');
  late AIRepository _aiRepository;
  bool _isTraining = false;
  String _currentModel = '';
  Map<String, double> _metrics = {};

  @override
  void initState() {
    super.initState();
    _aiRepository = AIRepository();
    _setupModelListeners();
  }

  void _setupModelListeners() {
    AIStateManager().modelState.listen((state) {
      setState(() {
        switch (state) {
          case AIModelState.training:
            _isTraining = true;
            break;
          case AIModelState.error:
            _isTraining = false;
            _showError('Model eğitimi başarısız oldu');
            break;
          case AIModelState.disposed:
            _isTraining = false;
            break;
          default:
            break;
        }
      });
    });
  }

  void _startTraining() {
    if (_currentModel.isNotEmpty) {
      _logger.info('Eğitim başlatılıyor: $_currentModel');

      // Eğitim sürecini başlat
      _aiRepository.trainModels(_currentModel).then((_) {
        // Eğitim tamamlandığında yapılacak işlemler
        _logger.info('Eğitim tamamlandı.');
        // Metrikleri güncellemek için başka bir mekanizma kullanabilirsiniz.
      }).catchError((error) {
        _showError('Eğitim sırasında hata oluştu: $error');
      });
    } else {
      _showError('Lütfen bir model seçin.');
    }
  }



  void _stopTraining() {
    _logger.info('Eğitim durduruluyor');
    // Eğitim sürecini durdur
    // Eğer bir durdurma metodu varsa onu çağırın.
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsDisplay() {
    return Expanded(
      child: ListView.builder(
        itemCount: _metrics.length,
        itemBuilder: (context, index) {
          String key = _metrics.keys.elementAt(index);
          double value = _metrics[key] ?? 0.0;
          return ListTile(
            title: Text(key),
            trailing: Text(value.toStringAsFixed(2)),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Visibility(
      visible: _isTraining,
      child: LinearProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Model Test')),
      body: Column(
        children: [
          _buildModelSelection(),
          _buildTrainingControls(),
          Expanded(child: Column(
            children: [
              Expanded(child: _buildMetricsDisplay()),
              _buildProgressIndicator(),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildModelSelection() {
    return DropdownButton<String>(
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
      hint: Text('Bir model seçin'),
    );
  }

  Widget _buildTrainingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _isTraining ? null : _startTraining,
          child: Text('Eğitimi Başlat'),
        ),
        ElevatedButton(
          onPressed: !_isTraining ? null : _stopTraining,
          child: Text('Eğitimi Durdur'),
        ),
      ],
    );
  }
}
