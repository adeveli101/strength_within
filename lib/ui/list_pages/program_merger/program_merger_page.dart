// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workout/ui/list_pages/program_merger/program_details.dart';

import '../../../data_bloc_part/PartRepository.dart';
import '../../../data_bloc_part/part_bloc.dart';
import '../../../data_schedule_bloc/schedule_repository.dart';
import '../../../models/BodyPart.dart';
import '../../../models/PartExercises.dart';
import '../../../models/PartTargetedBodyParts.dart';
import '../../../models/Parts.dart';
import '../../../models/exercises.dart';
import '../../../models/part_frequency.dart';
import '../../components/program_merger.dart';
import '../../part_ui/part_card.dart';

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
  final String userId;
  const ProgramMergerPage({super.key, required this.userId});

  @override
  State<ProgramMergerPage> createState() => _ProgramMergerPageState();
}

class _ProgramMergerPageState extends State<ProgramMergerPage> {
  static const int maxSelectedProgramCount = 4;
  final ScrollController _scrollController = ScrollController();

  // State değişkenleri
  int _currentStep = 0;
  final Set<int> _selectedPartIds = {};
  final Set<int> _selectedDays = {};
  TrainingFrequency? _selectedFrequency;
  final MergeType _selectedMergeType = MergeType.sequential;
  bool _isLoading = false;

  // Repository ve Service
  late final PartRepository _partRepository;
  late final PartsBloc _partsBloc;
  late final ProgramMergerService _mergerService;

  @override
  void initState() {
    super.initState();
    _partRepository = context.read<PartRepository>();
    _partsBloc = context.read<PartsBloc>();
    _mergerService = ProgramMergerService(
      _partRepository,
      context.read<ScheduleRepository>(),
    );
    _loadInitialData();
  }


  void _initializeServices() {
    _partRepository = context.read<PartRepository>();
    _partsBloc = context.read<PartsBloc>();
    _mergerService = ProgramMergerService(
      _partRepository,
      context.read<ScheduleRepository>(),
    );
  }

  void _loadInitialData() {
    _partsBloc.add(const FetchPartsGroupedByBodyPart());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Oluştur'),
        backgroundColor: Colors.grey[900],
      ),
      body: Stepper(
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
            title: const Text('Seviye Seçimi'),
            content: _buildLevelSelectionStep(),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Gün Seçimi'),
            content: _buildDaySelectionStep(),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Program Seçimi'),
            content: _buildProgramSelectionStep(),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Program Özeti'),
            content: _buildProgramSummaryStep(),
            isActive: _currentStep >= 3,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelectionStep() {
    return Column(
      children: TrainingFrequency.values.map((frequency) {
        final isSelected = _selectedFrequency == frequency;
        return Card(
          color: isSelected ? Colors.red.shade900 : Colors.grey[900],
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            onTap: () => setState(() => _selectedFrequency = frequency),
            leading: Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            title: Text(
              frequency.title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              frequency.description,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaySelectionStep() {
    if (_selectedFrequency == null) {
      return const Text(
        'Lütfen önce seviye seçimi yapın',
        style: TextStyle(color: Colors.red),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Antrenman Günlerinizi Seçin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final day = index + 1;
            final isSelected = _selectedDays.contains(day);
            final isEnabled = _selectedDays.length <
                _selectedFrequency!.maxDays || isSelected;

            return FilterChip(
              selected: isSelected,
              onSelected: isEnabled ? (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(day);
                  } else {
                    _selectedDays.remove(day);
                  }
                });
              } : null,
              backgroundColor: Colors.grey[900],
              selectedColor: Colors.red.shade900,
              checkmarkColor: Colors.white,
              label: Text(
                _getDayName(day),
                style: TextStyle(
                  color: isEnabled ? Colors.white : Colors.grey,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.red : Colors.grey[700]!,
                ),
              ),
            );
          }),
        ),
        if (_selectedDays.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Seçilen gün sayısı: ${_selectedDays.length}/${_selectedFrequency!
                .maxDays}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ],
    );
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Pzt';
      case 2:
        return 'Sal';
      case 3:
        return 'Çar';
      case 4:
        return 'Per';
      case 5:
        return 'Cum';
      case 6:
        return 'Cmt';
      case 7:
        return 'Paz';
      default:
        return '';
    }
  }

  Widget _buildProgramSelectionStep() {
    if (_selectedFrequency == null || _selectedDays.isEmpty) {
      return const Text(
        'Lütfen önce seviye ve gün seçimi yapın',
        style: TextStyle(color: Colors.red),
      );
    }

    return BlocConsumer<PartsBloc, PartsState>(
      listener: (context, state) {
        if (state is PartsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is PartsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PartsGroupedByBodyPart) {
          if (state.groupedParts.isEmpty) {
            return const Center(child: Text('Hiç program bulunamadı'));
          }

          return _buildProgramList(state.groupedParts);
        }

        return const Center(child: Text('Program listesi yüklenemedi'));
      },
    );
  }

  Widget _buildProgramList(Map<int, List<Parts>> groupedParts) {
    // Ana kas grupları için sabit sıralama
    final mainBodyParts = [1, 2, 3, 4, 5, 6]; // Göğüs, Sırt, Bacak, Omuz, Kol, Karın

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgramSelectionHeader(),
          ...mainBodyParts.map((bodyPartId) {
            final partsForBodyPart = groupedParts[bodyPartId] ?? [];
            if (partsForBodyPart.isEmpty) return const SizedBox.shrink();

            return FutureBuilder<List<PartTargetedBodyParts>>(
              future: _partRepository.getPrimaryTargetedPartsForBodyPart(bodyPartId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                // Zorluk seviyesine göre filtreleme
                final filteredParts = partsForBodyPart.where((part) {
                  final bool difficultyMatch = _selectedFrequency != null &&
                      part.difficulty >= _selectedFrequency!.minDays &&
                      part.difficulty <= _selectedFrequency!.maxDays;

                  final bool hasMatchingTarget = snapshot.data!.any((target) =>
                  target.partId == part.id &&
                      target.isPrimary &&
                      target.bodyPartId == bodyPartId);

                  return difficultyMatch && hasMatchingTarget;
                }).toList();

                if (filteredParts.isEmpty) return const SizedBox.shrink();

                // Zorluk seviyesine göre sıralama
                filteredParts.sort((a, b) => b.difficulty.compareTo(a.difficulty));

                return _buildBodyPartSection(
                    bodyPartId,
                    filteredParts,
                    snapshot.data!
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  List<Widget> _buildBodyPartGroups(Map<int, List<Parts>> groupedParts) {
    final Set<int> usedPartIds = {};

    return [1, 2, 3, 4, 5, 6].map((bodyPartId) {
      final parts = groupedParts[bodyPartId] ?? [];
      if (parts.isEmpty) return const SizedBox.shrink();

      return FutureBuilder<List<PartTargetedBodyParts>>(
        future: _partRepository.getPrimaryTargetedPartsForBodyPart(bodyPartId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final primaryTargets = snapshot.data!;

          // Filtreleme işlemi
          final filteredParts = parts.where((part) {
            // Daha önce kullanılmış part kontrolü
            if (usedPartIds.contains(part.id)) return false;

            // Zorluk seviyesi kontrolü
            final bool difficultyMatch = _selectedFrequency != null &&
                part.difficulty >= _selectedFrequency!.minDays &&
                part.difficulty <= _selectedFrequency!.maxDays;

            // Primary hedef kontrolü
            final bool isPrimaryTarget = primaryTargets.any((target) =>
            target.partId == part.id &&
                target.isPrimary &&
                target.bodyPartId == bodyPartId
            );

            // Koşullar sağlanıyorsa part'ı işaretle
            if (difficultyMatch && isPrimaryTarget) {
              usedPartIds.add(part.id);
              return true;
            }
            return false;
          }).toList();

          if (filteredParts.isEmpty) return const SizedBox.shrink();

          // Zorluk seviyesine göre sıralama
          filteredParts.sort((a, b) => b.difficulty.compareTo(a.difficulty));

          return _buildBodyPartSection(
              bodyPartId,
              filteredParts,
              primaryTargets
          );
        },
      );
    }).toList();
  }


  List<Parts> _filterPartsByFrequency(
      List<Parts> parts,
      List<PartTargetedBodyParts> targets
      ) {
    if (_selectedFrequency == null) return parts;

    return parts.where((part) {
      final bool difficultyMatch = part.difficulty >= _selectedFrequency!.minDays &&
          part.difficulty <= _selectedFrequency!.maxDays;

      final bool hasMatchingTarget = targets.any((target) =>
      target.partId == part.id && target.isPrimary
      );

      return difficultyMatch && hasMatchingTarget;
    }).toList();
  }


  Widget _buildProgramSelectionHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seçilen Programlar: ${_selectedPartIds
                .length}/$maxSelectedProgramCount',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seçilen Günler: ${_selectedDays.length} gün',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBodyPartSection(int bodyPartId, List<Parts> filteredParts,
      List<PartTargetedBodyParts> primaryTargets) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _selectedPartIds.any(
                (id) => filteredParts.any((part) => part.id == id)
        ),
        leading: Icon(
          _getBodyPartIcon(bodyPartId),
          color: Colors.red[300],
        ),
        title: FutureBuilder<String>(
          future: _partRepository.getBodyPartName(bodyPartId),
          builder: (context, snapshot) {
            return Text(
              snapshot.data ?? 'Yükleniyor...',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        children: filteredParts.map((part) {
          final target = primaryTargets.firstWhere(
                (t) => t.partId == part.id,
            orElse: () => primaryTargets.first,
          );
          return _buildPartCard(part, target);
        }).toList(),
      ),
    );
  }

  Widget _buildPartCard(Parts part, PartTargetedBodyParts target) {
    final isSelected = _selectedPartIds.contains(part.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.shade900.withOpacity(0.2) : Colors
            .transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.red : Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: () => _handlePartSelection(part.id, !isSelected),
        leading: Icon(
          isSelected ? Icons.check_circle : Icons.circle_outlined,
          color: isSelected ? Colors.red : Colors.grey,
        ),
        title: Text(
          part.name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDifficultyRow(part),
            if (target.targetPercentage < 100)
              _buildTargetRow(target),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyRow(Parts part) {
    return Row(
      children: [
        Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          'Zorluk: ${part.difficulty}/5',
          style: TextStyle(color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildTargetRow(PartTargetedBodyParts target) {
    return Row(
      children: [
        Icon(Icons.adjust, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          'Hedef: %${target.targetPercentage}',
          style: TextStyle(color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildProgramSummaryStep() {
    if (_selectedPartIds.isEmpty) {
      return const Center(
        child: Text(
          'Lütfen önce program seçimi yapın',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadProgramSummaryData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Program detayları yüklenemedi'));
        }

        final data = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryOverview(data),
              const SizedBox(height: 24),
              _buildDailyProgramList(data),
              const SizedBox(height: 32),
              _buildCreateProgramButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFrequencyInfo() {
    return Card(
      color: Colors.grey[900],
      child: ListTile(
        leading: Icon(Icons.fitness_center, color: Colors.red[300]),
        title: Text(
          _selectedFrequency?.title ?? '',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          _selectedFrequency?.description ?? '',
          style: TextStyle(color: Colors.grey[400]),
        ),
      ),
    );
  }

  Widget _buildSummaryOverview(Map<String, dynamic> data) {
    final parts = (data['parts'] as List).cast<Parts>();

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryHeader(parts),
            const Divider(color: Colors.grey),
            _buildTargetMuscleGroups(data),
            const Divider(color: Colors.grey),
            _buildFrequencyInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(List<Parts> parts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Program Özeti',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seçilen Program Sayısı: ${parts.length}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Ortalama Zorluk: ',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                _buildAverageDifficultyDisplay(parts),
              ],
            ),
          ],
        )

      ],
    );
  }

  Widget _buildCreateProgramButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCreateProgram,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white54,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'Programı Oluştur',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadProgramSummaryData() async {
    try {
      final selectedParts = await _loadSelectedParts();
      final Map<String, dynamic> summaryData = {
        'parts': selectedParts,
        'targetedBodyParts': await _loadTargetedBodyParts(selectedParts),
        'exerciseCounts': await _calculateExerciseCounts(selectedParts),
        'averageDifficulty': _calculateAverageDifficulty(selectedParts),
      };
      return summaryData;
    } catch (e) {
      throw Exception('Program özeti yüklenirken hata: $e');
    }
  }

  Widget _buildDailyProgramList(Map<String, dynamic> data) {
    final parts = data['parts'] as List<Parts>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Günlük Program Detayları',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_selectedDays.length, (index) {
          final dayNumber = _selectedDays.elementAt(index);
          return _buildDayCard(dayNumber, parts[index % parts.length]);
        }),
      ],
    );
  }

  Widget _buildDayCard(int day, Parts part) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          'Gün $day: ${part.name}',
          style: const TextStyle(color: Colors.white),
        ),
        children: [
          FutureBuilder<List<PartExercise>>(
            future: _partRepository.getPartExercisesByPartId(part.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: snapshot.data!.map((exercise) {
                  return _buildExerciseItem(exercise);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDaysInfo() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seçilen Günler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _selectedDays.map((day) {
                return Chip(
                  backgroundColor: Colors.red.shade900,
                  label: Text(
                    _getDayName(day),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Parts>> _loadSelectedParts() async {
    final parts = <Parts>[];
    for (var id in _selectedPartIds) {
      final part = await _partRepository.getPartById(id);
      if (part != null) {
        parts.add(part);
      }
    }
    return parts;
  }

  Widget _buildExerciseItem(PartExercise exercise) {
    return FutureBuilder<Exercises?>(
      future: _partRepository.getExerciseById(exercise.exerciseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final exerciseData = snapshot.data!;
        return ListTile(
          leading: Icon(Icons.fitness_center, color: Colors.grey[400]),
          title: Text(
            exerciseData.name,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            '${exerciseData.defaultSets} set x ${exerciseData
                .defaultReps} tekrar',
            style: TextStyle(color: Colors.grey[400]),
          ),
        );
      },
    );
  }

  double _calculateAverageDifficulty(List<Parts> parts) {
    if (parts.isEmpty) return 0;

    int totalDifficulty = parts.fold<int>(
      0,
          (sum, part) => sum + part.difficulty,
    );

    return totalDifficulty / parts.length;
  }

  Widget _buildAverageDifficultyDisplay(List<Parts> parts) {
    double averageDifficulty = _calculateAverageDifficulty(parts);

    // Tam sayı olarak gösterim için rounded kullanabiliriz
    int roundedDifficulty = averageDifficulty.round();

    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < roundedDifficulty ? Icons.star : Icons.star_border,
          color: Colors.redAccent,
        );
      }),
    );
  }

  Future<void> _handleCreateProgram() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final program = await _mergerService.createMergedProgram(
        userId: _partsBloc.userId,
        selectedPartIds: _selectedPartIds.toList(),
        selectedDays: _selectedDays.toList(),
        mergeType: _selectedMergeType,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program başarıyla oluşturuldu')),
      );
      Navigator.pop(context, program);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTargetMuscleGroups(Map<String, dynamic> data) {
    final parts = data['parts'] as List<Parts>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hedef Kas Grupları',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, int>>(
          future: calculateMainBodyPartPercentages(parts),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final groupedData = snapshot.data!;
            final overloadThreshold = 70; // Aşırı yüklenme eşiği
            final filteredData = groupedData.entries
                .where((entry) => entry.value >= 10) // %10'un altındaki grupları gösterme
                .toList();

            if (filteredData.isEmpty) {
              return const Text(
                'Yeterli hedef kas grubu bulunamadı.',
                style: TextStyle(color: Colors.grey),
              );
            }

            bool isOverloaded = filteredData.any((entry) => entry.value > overloadThreshold);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOverloaded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[300]),
                        const SizedBox(width: 8),
                        const Text(
                          'Bir bölgeye aşırı yüklenme var!',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3,
                  ),
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final entry = filteredData[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          entry.key,
                          style:
                          const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<Map<String, int>> calculateMainBodyPartPercentages(List<Parts> parts) async {
    final Map<String, int> percentages = {};

    for (var part in parts) {
      final targets = await _partRepository.getPartTargetedBodyParts(part.id);

      for (var target in targets) {
        // Sadece ana kas gruplarını hesapla
        if (target.isPrimary) {
          final bodyPartName = await _partRepository.getBodyPartName(target.bodyPartId);

          percentages[bodyPartName] =
              (percentages[bodyPartName] ?? 0) + target.targetPercentage;
        }
      }
    }

    return percentages;
  }


  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCreateProgram,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(color: Colors.red),
        )
            : const Text(
          'Programı Oluştur',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
              color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProgramDetails(List<Parts> selectedParts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Program Detayları',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...selectedParts.map((part) => _buildProgramDetailCard(part)).toList(),
      ],
    );
  }

  Widget _buildProgramDetailCard(Parts part) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          part.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: FutureBuilder<List<String>>(
          future: _partRepository.getPartTargetedBodyPartsName(part.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return Text(
              snapshot.data!.join(', '),
              style: TextStyle(color: Colors.grey[400]),
            );
          },
        ),
        children: [
          FutureBuilder<List<PartExercise>>(
            future: _partRepository.getPartExercisesByPartId(part.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: snapshot.data!.map((exercise) {
                  return _buildExerciseDetailItem(exercise);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetailItem(PartExercise exercise) {
    return FutureBuilder<Exercises?>(
      future: _partRepository.getExerciseById(exercise.exerciseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final exerciseData = snapshot.data!;
        return ListTile(
          leading: Icon(Icons.fitness_center, color: Colors.grey[400]),
          title: Text(
            exerciseData.name,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            '${exerciseData.defaultSets} set x ${exerciseData
                .defaultReps} tekrar',
            style: TextStyle(color: Colors.grey[400]),
          ),
          trailing: Text(
            '${exerciseData.defaultWeight} kg',
            style: TextStyle(color: Colors.grey[400]),
          ),
        );
      },
    );
  }

  Widget _buildDayDistribution(List<Parts> parts) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Günlük Program Dağılımı',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedDays.length,
              itemBuilder: (context, index) {
                final day = _selectedDays.elementAt(index);
                final part = parts[index % parts.length];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[900],
                    child: Text(
                      _getDayName(day)[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    part.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: FutureBuilder<List<String>>(
                    future: _partRepository.getPartTargetedBodyPartsName(
                        part.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      return Text(
                        snapshot.data!.join(', '),
                        style: TextStyle(color: Colors.grey[400]),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseStats(Map<int, int> exerciseCounts) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Egzersiz İstatistikleri',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exerciseCounts.length,
              itemBuilder: (context, index) {
                final bodyPartId = exerciseCounts.keys.elementAt(index);
                final count = exerciseCounts[bodyPartId]!;
                return FutureBuilder<String>(
                  future: _partRepository.getBodyPartName(bodyPartId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    return ListTile(
                      title: Text(
                        snapshot.data!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        '$count egzersiz',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Parts> _filterPartsByDifficulty(List<Parts> parts) {
    if (_selectedFrequency == null) return parts;

    final minDifficulty = _selectedFrequency!.minDays;
    final maxDifficulty = _selectedFrequency!.maxDays;

    return parts.where((part) {
      return part.difficulty >= minDifficulty &&
          part.difficulty <= maxDifficulty;
    }).toList();
  }

  void _handlePartSelection(int partId, bool isSelected) {
    if (!mounted) return;

    setState(() {
      if (isSelected) {
        if (_selectedPartIds.length < maxSelectedProgramCount) {
          _selectedPartIds.add(partId);
        }
      } else {
        _selectedPartIds.remove(partId);
      }
    });
  }

  Future<Map<String, dynamic>> _calculateExerciseCounts(
      List<Parts> parts) async {
    final Map<int, int> exerciseCounts = {};

    for (var part in parts) {
      final exercises = await _partRepository.getPartExercisesByPartId(part.id);
      for (var exercise in exercises) {
        final targets = await _partRepository.getPartTargetedBodyParts(
            exercise.partId);
        for (var target in targets) {
          exerciseCounts[target.bodyPartId] =
              (exerciseCounts[target.bodyPartId] ?? 0) + 1;
        }
      }
    }

    return {
      'exerciseCounts': exerciseCounts,
    };
  }

  Future<List<String>> _loadTargetedBodyParts(List<Parts> parts) async {
    final Set<String> bodyParts = {};

    for (var part in parts) {
      final targets = await _partRepository.getPartTargetedBodyPartsName(
          part.id);
      bodyParts.addAll(targets);
    }

    return bodyParts.toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData _getBodyPartIcon(int bodyPartId) {
    switch (bodyPartId) {
      case 1: return Icons.fitness_center; // Göğüs
      case 2: return Icons.accessibility_new; // Sırt
      case 3: return Icons.directions_walk; // Bacak
      case 4: return Icons.sports_martial_arts; // Omuz
      case 5: return Icons.sports_handball; // Kol
      case 6: return Icons.circle; // Karın
      default: return Icons.fitness_center;
    }
  }

}