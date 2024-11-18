// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data_bloc_part/PartRepository.dart';
import '../../data_bloc_part/part_bloc.dart';
import '../../models/Parts.dart';
import '../../z.app_theme/app_theme.dart';
import '../components/custom_program_builder.dart';

class CustomProgramPage extends StatefulWidget {
  const CustomProgramPage({super.key});

  @override
  State<CustomProgramPage> createState() => _CustomProgramPageState();
}

class _CustomProgramPageState extends State<CustomProgramPage> {
  final List<Parts> selectedParts = [];
  final Map<int, Parts> selectedBodyParts = {};
  late final CustomProgramBuilder _programBuilder;

  // Zorunlu ve opsiyonel kas grupları
  final List<int> mandatoryMuscleGroups = [1, 2, 3]; // Göğüs, Sırt, Bacak
  final List<int> optionalMuscleGroups = [4, 5, 6]; // Omuz, Kol, Karın

  // Toplam zorluk kontrolü
  int totalDifficulty = 0;
  static const int maxDifficulty = 15;
  int currentBodyPartIndex = 1;
  final PageController _pageController = PageController();
  int currentPage = 0;
  final List<int> bodyPartOrder = [1, 2, 3, 4, 5, 6];

  final Map<int, bool> bodyPartUsed = {
    1: false, // Göğüs
    2: false, // Sırt
    3: false, // Bacak
    4: false, // Omuz
    5: false, // Kol
    6: false, // Karın
  };

  @override
  void initState() {
    super.initState();
    _initializeProgramBuilder();
  }

  void _initializeProgramBuilder() {
    final repository = context.read<PartRepository>();
    _programBuilder = CustomProgramBuilder(repository);
    context.read<PartsBloc>().add(FetchParts());
  }

  void _clearSelections() {
    setState(() {
      selectedParts.clear();
      selectedBodyParts.clear();
      bodyPartUsed.clear();
      totalDifficulty = 0;
      currentBodyPartIndex = 1;
    });
  }

  void _validateAndCreateProgram() async {
    if (!_isMandatorySelectionComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen zorunlu bölgeleri seçin'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    try {
      final program = await _programBuilder.createProgram(
        selectedParts.map((p) => p.id).toList(),
      );

      if (!mounted) return;
      _showProgramDialog(program);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Program oluşturulurken hata: $e')),
      );
    }
  }
  Widget _buildSelectedPartForBody(int bodyPartId) {
    final selectedPart = selectedBodyParts[bodyPartId];

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(
          color: _getBodyPartColor(bodyPartId).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getBodyPartIcon(bodyPartId),
            size: 16,
            color: _getBodyPartColor(bodyPartId),
          ),
          const SizedBox(width: 8),
          Text(
            _getBodyPartName(bodyPartId),
            style: AppTheme.bodySmall.copyWith(
              color: _getBodyPartColor(bodyPartId),
            ),
          ),
          const SizedBox(width: 4),
          if (selectedPart != null)
            Icon(
              Icons.check_circle,
              size: 14,
              color: AppTheme.primaryRed,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Program sonuçlarını gösteren dialog todo
  void _showProgramDialog(List<WorkoutDay> program) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.primaryRed),
                    const SizedBox(width: 8),
                    Text(
                      'Program Oluşturuldu',
                      style: AppTheme.headingMedium,
                    ),
                  ],
                ),
              ),
              // Program içeriği
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.paddingMedium),
                  child: Column(
                    children: program.map((day) {
                      final part = selectedParts.firstWhere((p) => p.id == day.partId);
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                          border: Border.all(
                            color: _getBodyPartColor(part.bodyPartId).withOpacity(0.3),
                          ),
                        ),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getBodyPartColor(part.bodyPartId).withOpacity(0.2),
                                child: Text(
                                  '${day.dayIndex}',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: _getBodyPartColor(part.bodyPartId),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      part.name,
                                      style: AppTheme.bodyLarge,
                                    ),
                                    Text(
                                      _getBodyPartName(part.bodyPartId),
                                      style: AppTheme.bodySmall.copyWith(
                                        color: _getBodyPartColor(part.bodyPartId),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(AppTheme.paddingMedium),
                              child: Column(
                                children: [
                                  _buildProgramInfoRow(
                                    icon: Icons.timer,
                                    label: 'Dinlenme',
                                    value: '${day.restTimeMinutes} ',
                                  ),
                                  _buildProgramInfoRow(
                                    icon: Icons.fitness_center,
                                    label: 'Egzersiz',
                                    value: '${day.exercises.length} hareket',
                                  ),
                                  _buildProgramInfoRow(
                                    icon: Icons.category,
                                    label: 'Program Tipi',
                                    value: day.workoutType.name,
                                  ),
                                  const Divider(),
                                  // Egzersiz listesi
                                  ...day.exercises.map((exercise) => ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.fitness_center,
                          size: 16,
                          color: AppTheme.primaryRed,
                        ),
                        title: Text(
                          exercise.exerciseId.toString(),  // exerciseName kullan
                          style: AppTheme.bodySmall,
                        ),
                        trailing: Text(
                          '${part.setTypeString} ',
                          style: AppTheme.bodySmall,
                        ),
                      ),
                                  )],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Butonlar
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Kapat',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textColorSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _saveProgram(program);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Programı Kaydet'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryRed),
          const SizedBox(width: 8),
          Text('$label:', style: AppTheme.bodySmall),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  Future<void> _saveProgram(List<WorkoutDay> program) async {
    try {
      // TODO: Schedule repository ile kaydetme işlemi yapılacak
      // Örnek: await _scheduleRepository.saveCustomProgram(program);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program başarıyla kaydedildi'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );

      // Başarılı kayıttan sonra ana sayfaya dön
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Program kaydedilirken hata: $e'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
    }
  }
  // Vücut bölgesi rengi
  Color _getBodyPartColor(int bodyPartId) {
    switch (bodyPartId) {
      case 1:
        return Colors.red; // Göğüs
      case 2:
        return Colors.blue; // Sırt
      case 3:
        return Colors.green; // Bacak
      case 4:
        return Colors.orange; // Omuz
      case 5:
        return Colors.purple; // Kol
      case 6:
        return Colors.brown; // Karın
      default:
        return Colors.grey;
    }
  }

  // Vücut bölgesi ikonu
  IconData _getBodyPartIcon(int bodyPartId) {
    switch (bodyPartId) {
      case 1:
        return Icons.fitness_center; // Göğüs
      case 2:
        return Icons.accessibility_new; // Sırt
      case 3:
        return Icons.directions_walk; // Bacak
      case 4:
        return Icons.sports_martial_arts; // Omuz
      case 5:
        return Icons.sports_handball; // Kol
      case 6:
        return Icons.circle; // Karın
      default:
        return Icons.help_outline;
    }
  }

  // Vücut bölgesi adı
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
        return 'Diğer';
    }
  }

  // Zorunlu seçimlerin kontrolü
  bool _isMandatorySelectionComplete() {
    return mandatoryMuscleGroups.every(
            (bodyPartId) => selectedBodyParts.containsKey(bodyPartId)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildAppBar(),
      body: _buildBody(),


    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Özel Program Oluştur',
        style: AppTheme.headingMedium,
      ),
      backgroundColor: AppTheme.surfaceColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppTheme.accentBlue),
          tooltip: 'Seçimleri Temizle',
          onPressed: _clearSelections,
        ),
        if (_isMandatorySelectionComplete())
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primaryRed),
            onPressed: _validateAndCreateProgram,
          ),
      ],
    );
  }

  Widget _buildBody() {
    return BlocBuilder<PartsBloc, PartsState>(
      builder: (context, state) {
        if (state is PartsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          );
        }

        if (state is PartsLoaded) {
          return SafeArea(
            child: Column(
              children: [
                _buildPartsIndicator(), //
                _buildSelectionProgress(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: bodyPartOrder.length,
                    onPageChanged: (index) {
                      setState(() => currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      final bodyPartId = bodyPartOrder[index];
                      final parts = state.parts
                          .where((p) => p.bodyPartId == bodyPartId)
                          .toList()
                        ..sort((a, b) => a.difficulty.compareTo(b.difficulty));

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppTheme.paddingMedium),
                              itemCount: parts.length,
                              itemBuilder: (context, index) => _buildPartCard(parts[index]),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return const Center(
          child: Text('Bir hata oluştu'),
        );
      },
    );
  }

  Widget _buildPartsIndicator() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppTheme.surfaceColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: bodyPartOrder.length,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
        itemBuilder: (context, index) {
          final bodyPartId = bodyPartOrder[index];
          final isMandatory = mandatoryMuscleGroups.contains(bodyPartId);
          final isSelected = currentPage == index;
          final isCompleted = selectedBodyParts.containsKey(bodyPartId);

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(
                horizontal: 4,
                vertical: isSelected ? 0 : 8,
              ),
              width: isSelected ? 80 : 64,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.primaryRed.withOpacity(0.1)
                    : isMandatory
                    ? AppTheme.primaryRed.withOpacity(0.05)
                    : AppTheme.accentBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted
                      ? AppTheme.primaryGreen
                      : isMandatory
                      ? AppTheme.primaryRed
                      : AppTheme.accentBlue,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getBodyPartIcon(bodyPartId),
                    color: isCompleted
                        ? AppTheme.primaryGreen
                        : isMandatory
                        ? AppTheme.primaryRed
                        : AppTheme.accentBlue,
                    size: isSelected ? 28 : 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getBodyPartName(bodyPartId),
                    style: AppTheme.bodySmall.copyWith(
                      color: isCompleted
                          ? AppTheme.primaryGreen
                          : isMandatory
                          ? AppTheme.primaryRed
                          : AppTheme.accentBlue,
                      fontSize: isSelected ? 12 : 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isCompleted)
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryGreen,
                      size: 12,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionProgress() {
    int mandatorySelected = selectedParts
        .where((p) => mandatoryMuscleGroups.contains(p.bodyPartId))
        .length;

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      color: AppTheme.surfaceColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Zorunlu Seçimler: $mandatorySelected/3',
                style: AppTheme.bodyMedium,
              ),
              Text(
                'Toplam Zorluk: $totalDifficulty/$maxDifficulty',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.getDifficultyColor(
                    (totalDifficulty / maxDifficulty * 5).round(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: mandatorySelected / 3,
            backgroundColor: AppTheme.progressBarBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryRed),
          ),
        ],
      ),
    );
  }


  Widget _buildPartCard(Parts part) {
    final isSelected = selectedBodyParts[part.bodyPartId]?.id == part.id;
    final wouldExceedLimit = (totalDifficulty + part.difficulty -
        (selectedBodyParts[part.bodyPartId]?.difficulty ?? 0)) >
        maxDifficulty;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      color: isSelected ? AppTheme.primaryRed.withOpacity(0.1) : AppTheme.cardBackground,
      child: ExpansionTile(
        title: Text(part.name, style: AppTheme.bodyLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Zorluk: ${AppTheme.getDifficultyText(part.difficulty)}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.getDifficultyColor(part.difficulty),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(5, (index) {
                    if (index < part.difficulty) {
                      return Icon(
                        Icons.star,
                        size: 14,
                        color: AppTheme.getDifficultyColor(part.difficulty),
                      );
                    }
                    return Icon(
                      Icons.star_border,
                      size: 14,
                      color: AppTheme.getDifficultyColor(part.difficulty)
                          .withOpacity(0.5),
                    );
                  }),
                ),
              ],
            ),
            if (part.additionalNotes.isNotEmpty)
              Text(
                part.additionalNotes,
                style: AppTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            isSelected ? Icons.check_circle : Icons.add_circle_outline,
            color: wouldExceedLimit
                ? Colors.grey
                : isSelected
                ? AppTheme.primaryRed
                : AppTheme.accentBlue,
          ),
          onPressed: wouldExceedLimit && !isSelected ? null : () => _selectPart(part),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Program detayları
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        icon: Icons.fitness_center,
                        label: 'Program Tipi',
                        value: part.setTypeString,
                      ),

                      _buildDetailRow(
                        icon: Icons.repeat,
                        label: 'Önerilen Frekans',
                        value: _getFrequencyText(part),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                // Tam açıklama
                if (part.additionalNotes.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.paddingSmall),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      border: Border.all(
                        color: AppTheme.getDifficultyColor(part.difficulty).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      part.additionalNotes,
                      style: AppTheme.bodySmall,
                    ),
                  ),
                // Uyarı mesajı
                if (wouldExceedLimit)
                  Container(
                    margin: const EdgeInsets.only(top: AppTheme.paddingSmall),
                    padding: const EdgeInsets.all(AppTheme.paddingSmall),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.warningColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bu programı eklemek toplam zorluk limitini aşacak',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryRed),
          const SizedBox(width: 8),
          Text('$label:', style: AppTheme.bodySmall),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }




  String _getFrequencyText(Parts part) {
    // Zorluk seviyesine göre önerilen frekans
    switch (part.difficulty) {
      case 1:
      case 2:
        return 'Haftada 3 kez';
      case 3:
        return 'Haftada 2-3 kez';
      case 4:
        return 'Haftada 2 kez';
      case 5:
        return 'Haftada 1-2 kez';
      default:
        return 'Haftada 2-3 kez';
    }
  }


  Widget _buildPartOption(Parts part) {
    final isSelected = selectedBodyParts[part.bodyPartId]?.id == part.id;
    final wouldExceedLimit = (totalDifficulty + part.difficulty -
        (selectedBodyParts[part.bodyPartId]?.difficulty ?? 0)) >
        maxDifficulty;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      title: Text(part.name, style: AppTheme.bodyMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Zorluk: ${AppTheme.getDifficultyText(part.difficulty)}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.getDifficultyColor(part.difficulty),
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(5, (index) {
                if (index < part.difficulty) {
                  return Icon(
                    Icons.star,
                    size: 14,
                    color: AppTheme.getDifficultyColor(part.difficulty),
                  );
                }
                return Icon(
                  Icons.star_border,
                  size: 14,
                  color:
                  AppTheme.getDifficultyColor(part.difficulty).withOpacity(0.5),
                );
              }),
            ],
          ),
          if (part.additionalNotes.isNotEmpty)
            Text(
              part.additionalNotes,
              style: AppTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          isSelected ? Icons.check_circle : Icons.add_circle_outline,
          color: wouldExceedLimit
              ? Colors.grey
              : isSelected
              ? AppTheme.primaryRed
              : AppTheme.accentBlue,
        ),
        onPressed: wouldExceedLimit && !isSelected ? null : () =>
            _selectPart(part),
      ),
    );
  }




  // Zorunlu seçimlerin ilerlemesi
  Widget _buildMandatoryProgress() {
    int mandatorySelected = selectedParts
        .where((p) => mandatoryMuscleGroups.contains(p.bodyPartId))
        .length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Zorunlu Bölgeler',
              style: AppTheme.bodyMedium,
            ),
            Text(
              '$mandatorySelected/3',
              style: AppTheme.bodyMedium.copyWith(
                color: mandatorySelected == 3
                    ? AppTheme.primaryRed
                    : AppTheme.textColorSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          child: LinearProgressIndicator(
            value: mandatorySelected / 3,
            backgroundColor: AppTheme.progressBarBackground,
            valueColor: AlwaysStoppedAnimation<Color>(
              mandatorySelected == 3
                  ? AppTheme.primaryRed
                  : AppTheme.accentBlue,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // Toplam zorluk göstergesi
  Widget _buildTotalDifficulty() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Toplam Zorluk',
          style: AppTheme.bodyMedium,
        ),
        Row(
          children: List.generate(5, (index) {
            double fillRate = (totalDifficulty / maxDifficulty * 5);

            if (index < fillRate.floor()) {
              return Icon(
                Icons.star,
                size: 20,
                color: AppTheme.getDifficultyColor(fillRate.round()),
              );
            } else if (index == fillRate.floor() && fillRate % 1 > 0) {
              return Icon(
                Icons.star_half,
                size: 20,
                color: AppTheme.getDifficultyColor(fillRate.round()),
              );
            } else {
              return Icon(
                Icons.star_border,
                size: 20,
                color: AppTheme.progressBarBackground,
              );
            }
          }),
        ),
      ],
    );
  }

  // Program oluşturma butonu
  Widget _buildCreateButton() {
    bool canCreate = _isMandatorySelectionComplete();

    return ElevatedButton(
      onPressed: canCreate ? _validateAndCreateProgram : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canCreate ? AppTheme.primaryRed : AppTheme
            .disabledColor,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
      ),
      child: Text(
        canCreate ? 'Programı Oluştur' : 'Zorunlu Bölgeleri Seçin',
        style: AppTheme.bodyMedium.copyWith(color: Colors.white),
      ),
    );
  }


  // Part seçme işlemini güncelle
  void _selectPart(Parts part) {
    setState(() {
      // Eğer bu part zaten seçiliyse, kaldır
      if (selectedBodyParts.containsKey(part.bodyPartId)) {
        _removePart(selectedBodyParts[part.bodyPartId]!);
        return;
      }

      // Toplam zorluk limitini kontrol et
      int newDifficulty = totalDifficulty + part.difficulty;
      if (newDifficulty > maxDifficulty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toplam zorluk limiti aşılıyor!'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }

      // Yeni seçimi ekle
      selectedParts.add(part);
      selectedBodyParts[part.bodyPartId] = part;
      totalDifficulty = newDifficulty;
    });
  }

  // Part silme işlemini güncelle
  void _removePart(Parts part) {
    setState(() {

      selectedParts.remove(part);
      selectedBodyParts.remove(part.bodyPartId);
      totalDifficulty -= part.difficulty;
    });
  }


}