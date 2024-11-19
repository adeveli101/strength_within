
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/Parts.dart';
import '../../data_bloc_part/PartRepository.dart';
import '../../data_schedule_bloc/schedule_repository.dart';
import '../../z.app_theme/app_theme.dart';
import '../components/program_merger.dart';

enum TrainingFrequency {
  beginner(2, 3, 'Başlangıç', 'Haftada 2-3 gün antrenman'),
  intermediate(3, 4, 'Orta Seviye', 'Haftada 3-4 gün antrenman'),
  advanced(4, 5, 'İleri Seviye', 'Haftada 4-5 gün antrenman'),
  athlete(5, 6, 'Atlet', 'Haftada 5-6 gün antrenman');

  final int minDays;
  final int maxDays;
  final String title;
  final String description;

  const TrainingFrequency(
      this.minDays,
      this.maxDays,
      this.title,
      this.description,
      );
}

class ProgramMergerPage extends StatefulWidget {
  const ProgramMergerPage({super.key, required this.userId});
  final String userId;

  @override
  _ProgramMergerPageState createState() => _ProgramMergerPageState();
}

class _ProgramMergerPageState extends State<ProgramMergerPage> {
  final List<int> selectedPartIds = [];
  final List<int> selectedDays = [];
  MergeType selectedMergeType = MergeType.sequential;
  TrainingFrequency? selectedFrequency;
  int? selectedDaysCount;
  bool isLoading = false;
  int currentStep = 0;

  late final ProgramMergerService _mergerService;
  late final PartRepository _partRepository;

  // Kas grupları sınıflandırması
  final majorMuscleParts = [1, 2, 3]; // Göğüs, Sırt, Bacak (Büyük kas grupları)
  final minorMuscleParts = [4, 5, 6]; // Omuz, Kol, Karın (Küçük kas grupları)

  // Kas grubu açıklamaları
  final muscleGroupDescriptions = {
    1: 'Göğüs kasları (Büyük ve küçük göğüs, ön göğüs yanı)',
    2: 'Sırt kasları (Kanat kası, boyun altı, kürek kemiği arası)',
    3: 'Bacak kasları (Ön bacak, arka bacak, baldır)',
    4: 'Omuz kasları (Ön, yan ve arka deltoid)',
    5: 'Kol kasları (Pazı ve arka kol)',
    6: 'Karın kasları (Düz karın ve yan karın)',
  };


  @override
  void initState() {
    super.initState();
    _partRepository = context.read<PartRepository>();
    _mergerService = ProgramMergerService(
      _partRepository,
      context.read<ScheduleRepository>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Program Oluştur'),
        actions: [
          if (isLoading)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Theme.of(context).primaryColor,
          ),
        ),
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: currentStep,
          onStepContinue: _handleStepContinue,
          onStepCancel: _handleStepCancel,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canContinue() ? details.onStepContinue : null,
                      child: Text(
                        currentStep == 3 ? 'Programı Oluştur' : 'Devam Et',
                      ),
                    ),
                  ),
                  if (currentStep > 0) ...[
                    SizedBox(width: 8),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text('Geri'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: Text('Sıklık'),
              content: _buildFrequencyStep(),
              isActive: currentStep >= 0,
            ),
            Step(
              title: Text('Tür'),
              content: _buildMergeTypeStep(),
              isActive: currentStep >= 1,
            ),
            Step(
              title: Text('Program'),
              content: _buildProgramSteps(),
              isActive: currentStep >= 2,
            ),
            Step(
              title: Text('Özet'),
              content: _buildSummaryStep(),
              isActive: currentStep >= 3,
            ),
          ],
        ),
      ),
      bottomSheet: _buildProgressSheet(),
    );
  }

  bool _canContinue() {
    switch (currentStep) {
      case 0:
        return selectedFrequency != null;
      case 1:
        return selectedMergeType != null;
      case 2:
        return selectedPartIds.isNotEmpty;
      case 3:
        return selectedDays.isNotEmpty;
      default:
        return false;
    }
  }


  Widget _buildFrequencyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haftalık Antrenman Sıklığınız',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Text(
          'Haftada kaç gün antrenman yapmak istiyorsunuz?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 16),
        _buildFrequencySlider(),
        SizedBox(height: 24),
        _buildFrequencyInfo(),
      ],
    );
  }

  Future<void> _handleStepContinue() async {
    bool canContinue = false;

    switch (currentStep) {
      case 0:
        canContinue = selectedFrequency != null;
        break;
      case 1:
        canContinue = selectedMergeType != null;
        break;
      case 2:
        canContinue = selectedPartIds.isNotEmpty;
        break;
      case 3:
        canContinue = selectedDays.isNotEmpty;
        if (canContinue) {
          await _createProgram();
          return;
        }
        break;
    }

    if (canContinue) {
      setState(() => currentStep++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen gerekli seçimleri yapın')),
      );
    }
  }

  void _handleStepCancel() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }


  Widget _buildFrequencySlider() {
    // Başlangıç değeri kontrolü
    if (selectedDays.isEmpty) {
      selectedDays.addAll([1, 2]); // Minimum 2 gün ile başla
    }

    return Column(
      children: [
        Slider(
          value: selectedDays.length.toDouble().clamp(2, 6),
          min: 2,
          max: 6,
          divisions: 4,
          label: '${selectedDays.length} gün',
          onChanged: (value) {
            setState(() {
              final newDayCount = value.toInt();
              // Günleri güncelle
              if (newDayCount > selectedDays.length) {
                for (var i = selectedDays.length + 1; i <= newDayCount; i++) {
                  selectedDays.add(i);
                }
              } else if (newDayCount < selectedDays.length) {
                selectedDays.removeRange(newDayCount, selectedDays.length);
              }

              // TrainingFrequency'yi güncelle
              selectedFrequency = _getFrequencyFromDays(newDayCount);
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFrequencyLabel('2', 'Az'),
            _buildFrequencyLabel('3', 'Orta'),
            _buildFrequencyLabel('4', 'Normal'),
            _buildFrequencyLabel('5', 'Yüksek'),
            _buildFrequencyLabel('6', 'Çok Yüksek'),
          ],
        ),
      ],
    );
  }


  TrainingFrequency _getFrequencyFromDays(int days) {
    switch (days) {
      case 2:
      case 3:
        return TrainingFrequency.beginner;
      case 4:
        return TrainingFrequency.intermediate;
      case 5:
        return TrainingFrequency.advanced;
      case 6:
        return TrainingFrequency.athlete;
      default:
        return TrainingFrequency.intermediate;
    }}

  Widget _buildFrequencyLabel(String number, String text) {
    return SizedBox(
      width: 50,
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildFrequencyInfo() {
    String recommendationText = '';
    Color recommendationColor = Colors.black;

    switch (selectedDays.length) {
      case 2:
      case 3:
        recommendationText = 'Başlangıç seviyesi için ideal';
        recommendationColor = Colors.green;
        break;
      case 4:
        recommendationText = 'Orta seviye için ideal';
        recommendationColor = Colors.blue;
        break;
      case 5:
        recommendationText = 'İleri seviye için uygun';
        recommendationColor = Colors.orange;
        break;
      case 6:
        recommendationText = 'Profesyonel seviye - Dikkatli planlama gerektirir';
        recommendationColor = Colors.red;
        break;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Program Önerisi',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: 8),
            Text(
              recommendationText,
              style: TextStyle(color: recommendationColor),
            ),
            SizedBox(height: 8),
            Text(
              '• ${selectedDays.length} gün antrenman\n'
                  '• ${7 - selectedDays.length} gün dinlenme\n'
                  '• ${_getRecommendedSplitType()} bölünmesi önerilir',
            ),
          ],
        ),
      ),
    );
  }

  String _getRecommendedSplitType() {
    switch (selectedDays.length) {
      case 2:
        return 'Üst Vücut / Alt Vücut';
      case 3:
        return 'Push / Pull / Legs';
      case 4:
        return 'Üst / Alt / Üst / Alt';
      case 5:
        return 'Push / Pull / Legs / Üst / Alt';
      case 6:
        return 'Push / Pull / Legs / Push / Pull / Legs';
      default:
        return 'Full Body';
    }
  }

  Widget _buildProgressSheet() {
    if (currentStep == 0 || selectedDays.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Program Özeti',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressItem(
                  'Antrenman',
                  '${selectedDays.length} gün',
                  Icons.calendar_today,
                ),
                _buildProgressItem(
                  'Dinlenme',
                  '${7 - selectedDays.length} gün',
                  Icons.bedtime,
                ),
                if (selectedPartIds.isNotEmpty)
                  _buildProgressItem(
                    'Program',
                    '${selectedPartIds.length}',
                    Icons.fitness_center,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildMergeTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Program Türünü Seçin',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Text(
          'Antrenman programınızın nasıl düzenleneceğini seçin:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 16),
        _buildMergeTypeCard(
          type: MergeType.sequential,
          title: 'Sıralı Program',
          description: 'Her kas grubu ayrı günlerde çalışılır',
          icon: Icons.linear_scale,
          recommendedFor: 'Başlangıç seviyesi için ideal',
        ),
        SizedBox(height: 8),
        _buildMergeTypeCard(
          type: MergeType.alternating,
          title: 'Dönüşümlü Program',
          description: 'Büyük ve küçük kas grupları dönüşümlü çalışılır',
          icon: Icons.swap_vert,
          recommendedFor: 'Orta seviye için ideal',
        ),
        SizedBox(height: 8),
        _buildMergeTypeCard(
          type: MergeType.superset,
          title: 'Süperset Program',
          description: 'Zıt kas grupları birlikte çalışılır',
          icon: Icons.compare_arrows,
          recommendedFor: 'İleri seviye için ideal',
        ),
      ],
    );
  }

  Widget _buildMergeTypeCard({
    required MergeType type,
    required String title,
    required String description,
    required IconData icon,
    required String recommendedFor,
  }) {
    final isSelected = selectedMergeType == type;

    return Card(
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () => setState(() => selectedMergeType = type),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
              if (isSelected) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        recommendedFor,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(),
        const SizedBox(height: AppTheme.paddingMedium),
        _buildMuscleGroupFilters(),
        const SizedBox(height: AppTheme.paddingMedium),
        _buildSelectedPartsWithRecommendations(),
      ],
    );
  }

  Widget _buildStepHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
            child: Text(
              '3',
              style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryRed),
            ),
          ),
          const SizedBox(width: AppTheme.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Program Oluşturma',
                  style: AppTheme.headingSmall,
                ),
                const SizedBox(height: AppTheme.paddingSmall / 2),
                Text(
                  'Çalışmak istediğiniz kas gruplarını seçin',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGroupFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMuscleGroupFilter(1, "Göğüs"),
          _buildMuscleGroupFilter(2, "Sırt"),
          _buildMuscleGroupFilter(3, "Bacak"),
          _buildMuscleGroupFilter(4, "Omuz"),
          _buildMuscleGroupFilter(5, "Kol"),
          _buildMuscleGroupFilter(6, "Karın"),
        ],
      ),
    );
  }

  Widget _buildSelectedPartsWithRecommendations() {
    return FutureBuilder<List<Parts>>(
      future: _partRepository.getAllParts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryRed,
            ),
          );
        }

        final selectedParts = snapshot.data!
            .where((part) => selectedPartIds.contains(part.bodyPartId))
            .toList();

        if (selectedParts.isEmpty) {
          return Center(
            child: Text(
              'Lütfen çalışmak istediğiniz kas gruplarını seçin',
              style: AppTheme.bodyMedium,
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: selectedParts.length,
          itemBuilder: (context, index) {
            final part = selectedParts[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                vertical: AppTheme.paddingSmall / 2,
                horizontal: AppTheme.paddingSmall,
              ),
              color: AppTheme.cardBackground,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getColorForBodyPart(part.bodyPartId).withOpacity(0.2),
                  child: Text(
                    '${part.exerciseCount}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: _getColorForBodyPart(part.bodyPartId),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(part.name, style: AppTheme.headingSmall),
                subtitle: Row(
                  children: [
                    Text(
                      'Zorluk: ${part.difficulty}/5',
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(width: AppTheme.paddingMedium),
                    _buildRecommendationBadge(part.bodyPartId),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          muscleGroupDescriptions[part.bodyPartId] ?? '',
                          style: AppTheme.bodyMedium,
                        ),
                        if (part.additionalNotes.isNotEmpty == true) ...[
                          const SizedBox(height: AppTheme.paddingSmall),
                          Text(
                            'Öneriler: ${part.additionalNotes}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textColorSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppTheme.paddingMedium),
                        _buildRecommendationDetails(part.bodyPartId),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecommendationBadge(int bodyPartId) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingSmall,
        vertical: AppTheme.paddingSmall / 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Text(
        'Önerilen',
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.primaryRed,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecommendationDetails(int bodyPartId) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Size Özel Öneriler',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            _getRecommendationText(bodyPartId),
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _getRecommendationText(int bodyPartId) {
    // Bu kısımda kas grubuna özel öneriler dönebilirsiniz
    switch (bodyPartId) {
      case 1:
        return 'Göğüs kaslarınız için haftada 2 antrenman önerilir.';
      case 2:
        return 'Sırt kaslarınızı güçlendirmek için çekiş hareketlerine odaklanın.';
    // Diğer kas grupları için öneriler...
      default:
        return 'Bu kas grubu için özel öneriler bulunmamaktadır.';
    }
  }

  Widget _buildMuscleGroupFilter(int id, String title) {
    final isSelected = selectedPartIds.contains(id);

    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.paddingSmall),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          title,
          style: AppTheme.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppTheme.textColorSecondary,
          ),
        ),
        onSelected: (selected) {
          setState(() {
            if (selected) {
              selectedPartIds.add(id);
            } else {
              selectedPartIds.remove(id);
            }
          });
        },
        avatar: Icon(
          isSelected ? Icons.check_circle : Icons.fitness_center,
          size: 18,
          color: isSelected ? Colors.white : AppTheme.textColorSecondary,
        ),
        backgroundColor: AppTheme.surfaceColor,
        selectedColor: AppTheme.primaryRed.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
      ),
    );
  }

  Widget _buildSelectedPartsDetails() {
    return FutureBuilder<List<Parts>>(
      future: _partRepository.getAllParts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryRed,
            ),
          );
        }

        final selectedParts = snapshot.data!
            .where((part) => selectedPartIds.contains(part.bodyPartId))
            .toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: selectedParts.length,
          itemBuilder: (context, index) {
            final part = selectedParts[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                vertical: AppTheme.paddingSmall / 2,
                horizontal: AppTheme.paddingSmall,
              ),
              color: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getColorForBodyPart(part.bodyPartId).withOpacity(0.2),
                  child: Text(
                    '${part.exerciseCount}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: _getColorForBodyPart(part.bodyPartId),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  part.name,
                  style: AppTheme.headingSmall,
                ),
                subtitle: Text(
                  'Zorluk: ${part.difficulty}/5',
                  style: AppTheme.bodySmall,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          muscleGroupDescriptions[part.bodyPartId] ?? '',
                          style: AppTheme.bodyMedium,
                        ),
                        if (part.additionalNotes.isNotEmpty == true) ...[
                          const SizedBox(height: AppTheme.paddingSmall),
                          Text(
                            'Açıklama: ${part.additionalNotes}',
                            style: AppTheme.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppTheme.textColorSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getColorForBodyPart(int bodyPartId) {
    switch (bodyPartId) {
      case 1: return AppTheme.primaryRed;      // Göğüs
      case 2: return AppTheme.accentBlue;      // Sırt
      case 3: return AppTheme.primaryGreen;    // Bacak
      case 4: return AppTheme.secondaryRed;    // Omuz
      case 5: return AppTheme.accentPurple;    // Kol
      case 6: return AppTheme.accentGreen;     // Karın
      default: return AppTheme.textColorSecondary;
    }
  }



  Widget _buildProgramGroups(List<Parts> allParts) {
    return Column(
      children: [
        _buildFrequencyInfo(),
        SizedBox(height: 16),
        _buildMuscleGroups(allParts),
      ],
    );
  }

  Widget _buildFrequencyInfoCard() {  // İsmi değiştirildi
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Haftada ${selectedDays.length} Gün Antrenman',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: 8),
            Text(
              _getFrequencyRecommendation(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }


  String _getFrequencyRecommendation() {
    switch (selectedDays.length) {
      case 2:
      case 3:
        return '• Büyük kas gruplarına öncelik verin\n• Her kas grubu için 1 program seçin';
      case 4:
      case 5:
        return '• Kas gruplarını bölerek çalışın\n• Büyük kas grupları için 1-2 program seçebilirsiniz';
      case 6:
        return '• İleri seviye bölünmüş program\n• Her kas grubu için detaylı program seçebilirsiniz';
      default:
        return '• Lütfen antrenman günü seçin';
    }
  }

  Widget _buildMuscleGroups(List<Parts> allParts) {
    // Kas gruplarını kategorize et
    final mainMuscles = allParts.where((p) => [1, 2, 3].contains(p.bodyPartId)).toList();
    final supportMuscles = allParts.where((p) => [4, 5].contains(p.bodyPartId)).toList();
    final coreMuscles = allParts.where((p) => p.bodyPartId == 6).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMuscleGroupSection(
            title: 'Ana Kas Grupları',
            subtitle: 'Göğüs, Sırt, Bacak',
            parts: mainMuscles,
            icon: Icons.fitness_center,
            color: Colors.red.shade700,
          ),
          SizedBox(height: 16),
          _buildMuscleGroupSection(
            title: 'Yardımcı Kas Grupları',
            subtitle: 'Omuz, Kol',
            parts: supportMuscles,
            icon: Icons.sports_martial_arts,
            color: Colors.blue.shade700,
          ),
          SizedBox(height: 16),
          _buildMuscleGroupSection(
            title: 'Core Bölgesi',
            subtitle: 'Karın, Alt Sırt',
            parts: coreMuscles,
            icon: Icons.circle_outlined,
            color: Colors.green.shade700,
          ),
        ],
      ),
    );
  }


  Widget _buildMuscleGroupSection({
    required String title,
    required String subtitle,
    required List<Parts> parts,
    required IconData icon,
    required Color color,
  }) {
    final selectedCount = parts.where((p) => selectedPartIds.contains(p.id)).length;

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: selectedCount > 0
            ? Chip(
          label: Text(
            '$selectedCount seçili',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: color,
        )
            : null,
        children: parts.map((part) => _buildProgramTile(
          part: part,
          color: color,
        )).toList(),
      ),
    );
  }


  Widget _buildProgramTile({
    required Parts part,
    required Color color,
  }) {
    final isSelected = selectedPartIds.contains(part.id);

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${part.exerciseCount}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(part.name),
      subtitle: Text(
        'Zorluk: ${part.difficulty}/5 • ${muscleGroupDescriptions[part.bodyPartId]}',
      ),
      trailing: Switch(
        value: isSelected,
        activeColor: color,
        onChanged: (value) => _handlePartSelection(part),
      ),
      onTap: () => _handlePartSelection(part),
    );
  }


  Widget _buildMuscleGroupCard({
    required Parts part,
    required Color color,
  }) {
    final isSelected = selectedPartIds.contains(part.id);

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(
        vertical: AppTheme.paddingSmall / 2,
        horizontal: AppTheme.paddingSmall,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.paddingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          side: isSelected
              ? BorderSide(color: AppTheme.primaryRed, width: 2)
              : BorderSide.none,
        ),
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.paddingSmall),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryRed.withOpacity(0.1)
                : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '${part.exerciseCount}',
            style: AppTheme.bodyLarge.copyWith(
              color: isSelected ? AppTheme.primaryRed : AppTheme.textColorSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          part.name,
          style: AppTheme.headingSmall.copyWith(
            color: isSelected ? AppTheme.primaryRed : Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zorluk: ${part.difficulty}/5 • ${muscleGroupDescriptions[part.bodyPartId]}',
              style: AppTheme.bodyMedium,
            ),
            if (isSelected) ...[
              SizedBox(height: AppTheme.paddingSmall),
              _buildRecommendationChip(part.bodyPartId),
            ],
          ],
        ),
        trailing: Switch(
          value: isSelected,
          onChanged: (bool value) => _handlePartSelection(part),
          activeColor: AppTheme.primaryRed,
          inactiveTrackColor: AppTheme.surfaceColor,
          inactiveThumbColor: AppTheme.textColorSecondary,
        ),
        onTap: () => _handlePartSelection(part),
      ),
    );
  }


  Widget _buildRecommendationChip(int bodyPartId) {
    return FutureBuilder<List<String>>(
        future: _getRecommendations(bodyPartId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }

          final recommendations = snapshot.data ?? [];

          if (recommendations.isEmpty) {
            return const SizedBox.shrink();
          }

          return Wrap(
            spacing: 4,
            children: recommendations.map((rec) => Chip(
              label: Text(
                rec,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white
                ),
              ),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            )).toList(),
          );
        }
    );
  }


  Future<List<String>> _getRecommendations(int bodyPartId) async {
    final recommendations = <String>[];

    // Seçili programlara göre öneriler
    final selectedBodyParts = await Future.wait(
        selectedPartIds.map((id) async {
          final part = await _partRepository.getPartById(id);
          return part?.bodyPartId;
        })
    ).then((bodyPartIds) => bodyPartIds.whereType<int>().toList());

    switch (bodyPartId) {
      case 1: // Göğüs
        if (!selectedBodyParts.contains(2)) {
          recommendations.add('Sırt ile kombinle');
        }
        if (!selectedBodyParts.contains(4)) {
          recommendations.add('Omuz ekle');
        }
        break;
      case 2: // Sırt
        if (!selectedBodyParts.contains(1)) {
          recommendations.add('Göğüs ile kombinle');
        }
        if (!selectedBodyParts.contains(5)) {
          recommendations.add('Biceps ekle');
        }
        break;
      case 3: // Bacak
        if (!selectedBodyParts.contains(6)) {
          recommendations.add('Core ekle');
        }
        recommendations.add('Tek başına çalış');
        break;
      case 4: // Omuz
        if (!selectedBodyParts.contains(5)) {
          recommendations.add('Kol ile kombinle');
        }
        break;
      case 5: // Kol
        if (!selectedBodyParts.contains(4)) {
          recommendations.add('Omuz ile kombinle');
        }
        break;
      case 6: // Core
        recommendations.add('Her programla kombinlenebilir');
        break;
    }

    return recommendations;
  }

  Future<void> _handlePartSelection(Parts part) async {
    try {
      final isSelected = selectedPartIds.contains(part.id);

      if (isSelected) {
        setState(() {
          selectedPartIds.remove(part.id);
        });
      } else {
        // Seçim öncesi validasyon
        final canAdd = await _validateNewSelection(part);
        if (canAdd) {
          setState(() {
            selectedPartIds.add(part.id);
          });

          // Seçim sonrası önerileri göster
          _showRecommendations(part);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<bool> _validateNewSelection(Parts part) async {
    try {
      // Seçili programları getir
      final selectedParts = <Parts>[];
      for (var id in selectedPartIds) {
        final selectedPart = await _partRepository.getPartById(id);
        if (selectedPart != null) {
          selectedParts.add(selectedPart);
        }
      }

      // Toplam zorluk kontrolü
      final totalDifficulty = selectedParts.fold<int>(
        0,
            (sum, p) => sum + p.difficulty,
      ) + part.difficulty;

      if (totalDifficulty > Constants.maxTotalDifficulty) {
        throw 'Toplam program zorluğu çok yüksek olacak (Max: ${Constants.maxTotalDifficulty})';
      }

      // Kas grubu çakışma kontrolü
      for (var selectedPart in selectedParts) {
        if (!_canCombineMuscleGroups(selectedPart.bodyPartId, part.bodyPartId)) {
          throw '${_getBodyPartName(selectedPart.bodyPartId)} ve ${_getBodyPartName(part.bodyPartId)} aynı programda olamaz';
        }
      }

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return false;
    }
  }

  String _getBodyPartName(int bodyPartId) {
    switch (bodyPartId) {
      case 1:
        return 'Göğüs';
      case 2:
        return 'Sırt';
      case 3:
        return 'Bacak';
      case 4:
        return 'Omuz';
      case 5:
        return 'Kol';
      case 6:
        return 'Karın';
      default:
        return 'Bilinmeyen';
    }
  }

  bool _canCombineMuscleGroups(int group1, int group2) {
    // Kas grubu kombinasyon kuralları
    final combinations = {
      1: [2, 4, 5], // Göğüs: Sırt, Omuz, Triceps ile kombinlenebilir
      2: [1, 4, 5], // Sırt: Göğüs, Omuz, Biceps ile kombinlenebilir
      3: [6],       // Bacak: Core ile kombinlenebilir
      4: [1, 2, 5], // Omuz: Göğüs, Sırt, Kol ile kombinlenebilir
      5: [1, 2, 4], // Kol: Göğüs, Sırt, Omuz ile kombinlenebilir
      6: [3],       // Core: Bacak ile kombinlenebilir
    };

    return combinations[group1]?.contains(group2) ?? false ||
        combinations[group2]!.contains(group1);
  }


  Future<void> _showRecommendations(Parts selectedPart) async {
    final recommendations = await _getRecommendations(selectedPart.bodyPartId);
    if (recommendations.isEmpty) return;

    if (!mounted) return; // Context kontrolü için güvenlik kontrolü

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Öneriler:'),
            const SizedBox(height: 4),
            ...recommendations.map((rec) => Text(
              '• $rec',
              style: const TextStyle(fontSize: 12),
            )),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSummaryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Program Özeti',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        _buildSummaryCard(
          'Seçilen Programlar',
          selectedPartIds.length.toString(),
          Icons.fitness_center,
        ),
        SizedBox(height: 8),
        _buildSummaryCard(
          'Antrenman Günleri',
          selectedDays.length.toString(),
          Icons.calendar_today,
        ),
        SizedBox(height: 8),
        _buildSummaryCard(
          'Program Türü',
          _getMergeTypeDescription(),
          Icons.sync,
        ),
        SizedBox(height: 16),
        _buildWorkoutSchedulePreview(),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: !isLoading ? _createProgram : null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
          ),
          child: Text(isLoading ? 'Oluşturuluyor...' : 'Programı Oluştur'),
        ),
      ],
    );
  }

  String _getMergeTypeDescription() {
    switch (selectedMergeType) {
      case MergeType.sequential:
        return 'Sıralı Program';
      case MergeType.alternating:
        return 'Dönüşümlü Program';
      case MergeType.superset:
        return 'Süperset Program';
    }
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutSchedulePreview() {
    if (selectedPartIds.isEmpty || selectedDays.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Haftalık Program Önizlemesi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12),
            ...selectedDays.map((day) => _buildDayPreview(day)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPreview(int day) {
    final dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final dayName = dayNames[day - 1];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Text(
            dayName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _createProgram() async {
    if (!_validateProgram()) return;

    setState(() => isLoading = true);

    try {
      final program = await _mergerService.createMergedProgram(
        userId: widget.userId,
        selectedPartIds: selectedPartIds,
        selectedDays: selectedDays,
        mergeType: selectedMergeType,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Program başarıyla oluşturuldu'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, program);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool _validateProgram() {
    if (selectedPartIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen en az bir program seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen antrenman günlerini seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    return true;
  }
}
