import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../blocs/data_exercise_bloc/exercise_bloc.dart';
import '../../../exercises_ui/exercise_card.dart';
import '../program_merger_form_model.dart';
import '../../../../models/sql_models/BodyPart.dart';
import '../../../../models/sql_models/exercises.dart';
import '../../../../sw_app_theme/app_theme.dart';

class ExerciseStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const ExerciseStep({required this.onNext, this.onBack, super.key});

  @override
  State<ExerciseStep> createState() => _ExerciseStepState();
}

class _ExerciseStepState extends State<ExerciseStep> {
  int selectedDayIndex = 0;
  int? selectedBodyPartId;
  Map<int, bool> expansionState = {};
  final ScrollController _chipScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ExerciseBloc>().add(FetchBodyParts());
    context.read<ExerciseBloc>().add(FetchExercises());
  }

  @override
  void dispose() {
    _chipScrollController.dispose();
    super.dispose();
  }

  void _scrollToChip(int index) {
    // Her chip yaklaşık 80px genişlikte, başta 8px boşluk var
    final double offset = (index * 80.0) - 24.0;
    _chipScrollController.animateTo(
      offset < 0 ? 0 : offset,
      duration: Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ProgramMergerFormModel>(context);
    final selectedDays = model.selectedDays;
    return Container(
      color: AppTheme.darkBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 12),
          Icon(Icons.fitness_center_rounded, size: 48, color: AppTheme.accentPurple),
          SizedBox(height: 8),
          Text('Egzersizlerini Seç!', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 24)),
          SizedBox(height: 8),
          Text('Her güne uygun egzersizleri seç ve programını kişiselleştir!', style: AppTheme.bodyMedium.copyWith(color: Colors.white70), textAlign: TextAlign.center),
          SizedBox(height: 16),
          // Gün sekmeleri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(selectedDays.length, (i) {
                final isActive = i == selectedDayIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('Gün ${i + 1}', style: AppTheme.bodyMedium.copyWith(color: isActive ? Colors.white : AppTheme.textPrimary)),
                    selected: isActive,
                    selectedColor: AppTheme.accentPurple,
                    backgroundColor: AppTheme.cardBackground,
                    onSelected: (val) {
                      if (val) setState(() => selectedDayIndex = i);
                    },
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 12),
          // Filtre chip barı HER ZAMAN görünür
          BlocBuilder<ExerciseBloc, ExerciseState>(
            buildWhen: (prev, curr) => curr is BodyPartsLoaded,
            builder: (context, state) {
              if (state is BodyPartsLoaded) {
                final chips = <Widget>[
                  SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Tümü', style: AppTheme.bodyMedium.copyWith(color: selectedBodyPartId == null ? Colors.white : AppTheme.textPrimary)),
                    selected: selectedBodyPartId == null,
                    selectedColor: AppTheme.accentPurple,
                    backgroundColor: AppTheme.cardBackground,
                    onSelected: (val) {
                      if (val) {
                        setState(() => selectedBodyPartId = null);
                        context.read<ExerciseBloc>().add(FetchExercises());
                        _scrollToChip(0);
                      }
                    },
                  ),
                  ...state.bodyParts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final part = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(part.name, style: AppTheme.bodyMedium.copyWith(color: selectedBodyPartId == part.id ? Colors.white : AppTheme.textPrimary)),
                        selected: selectedBodyPartId == part.id,
                        selectedColor: AppTheme.accentPurple,
                        backgroundColor: AppTheme.cardBackground,
                        onSelected: (val) {
                          if (val) {
                            setState(() => selectedBodyPartId = part.id);
                            context.read<ExerciseBloc>().add(FetchExercisesByMainBodyPart(part.id));
                            _scrollToChip(i + 1); // +1 çünkü 'Tümü' chipi başta
                          }
                        },
                      ),
                    );
                  }),
                  SizedBox(width: 8),
                ];
                return SingleChildScrollView(
                  controller: _chipScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(children: chips),
                );
              }
              return SizedBox(height: 36); // Yüklenene kadar boşluk bırak
            },
          ),
          SizedBox(height: 12),
          // Egzersiz listesi
          Expanded(
            child: Builder(
              builder: (context) {
                if (selectedBodyPartId == null) {
                  // Tümü: Ana bölge > yan bölge > egzersiz
                  final bodyPartsState = context.watch<ExerciseBloc>().state;
                  if (bodyPartsState is! BodyPartsLoaded) {
                    context.read<ExerciseBloc>().add(FetchBodyParts());
                    return Center(child: CircularProgressIndicator());
                  }
                  final mainBodyParts = bodyPartsState.bodyParts.where((b) => b.parentBodyPartId == null).toList();
                  return FutureBuilder<List<Widget>>(
                    future: _buildBodyPartExerciseTree(context, mainBodyParts),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                      return ListView(children: snapshot.data!);
                    },
                  );
                } else {
                  // Seçili ana bölge: alt bölgeler başlık, altında egzersizler
                  return FutureBuilder<List<Widget>>(
                    future: _buildSubBodyPartExerciseTree(context, selectedBodyPartId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                      return ListView(children: snapshot.data!);
                    },
                  );
                }
              },
            ),
          ),
          Row(
            children: [
              if (widget.onBack != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onBack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: AppTheme.accentBlue,
                      minimumSize: Size(0, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 2,
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) => null),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    label: Text('Geri Dön', style: TextStyle(fontSize: 16)),
                  ),
                ),
              if (widget.onBack != null) SizedBox(width: 12),
              Expanded(
                child: AnimatedOpacity(
                  opacity: model.dayToExerciseIds.values.any((l) => l.isNotEmpty) ? 1 : 0.5,
                  duration: Duration(milliseconds: 200),
                  child: ElevatedButton.icon(
                    onPressed: model.dayToExerciseIds.values.any((l) => l.isNotEmpty) ? widget.onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: AppTheme.accentBlue,
                      minimumSize: Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) => null),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    icon: Icon(Icons.arrow_forward, color: Colors.white),
                    label: Text('Devam Et', style: TextStyle(fontSize: 19)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _themedExpansionTile({required String title, required List<Widget> children, bool initiallyExpanded = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.getPartGradient(difficulty: 5, secondaryColor: AppTheme.accentPurple),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPurple.withOpacity(0.10),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppTheme.accentPurple.withOpacity(0.08),
        ),
        child: ExpansionTile(
          title: Text(
            title,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          initiallyExpanded: initiallyExpanded,
          iconColor: AppTheme.accentPurple,
          collapsedIconColor: AppTheme.accentPurple,
          children: children,
        ),
      ),
    );
  }

  Future<List<Widget>> _buildBodyPartExerciseTree(BuildContext context, List<BodyParts> mainBodyParts) async {
    final repo = context.read<ExerciseBloc>().exerciseRepository;
    final model = Provider.of<ProgramMergerFormModel>(context, listen: false);
    final selectedDays = model.selectedDays;
    final day = selectedDays.isNotEmpty ? selectedDays[selectedDayIndex] : null;
    final selectedForDay = day != null ? model.dayToExerciseIds[day] ?? [] : [];
    List<Widget> widgets = [];
    for (final main in mainBodyParts) {
      final subParts = await repo.sqlProvider.getBodyPartsByParentId(main.id);
      widgets.add(
        _themedExpansionTile(
          title: main.name,
          children: [
            for (final sub in subParts)
              FutureBuilder<List<Exercises>>(
                future: repo.sqlProvider.getExercisesByBodyPart(sub.id, isPrimary: true),
                builder: (context, snap) {
                  if (!snap.hasData) return SizedBox.shrink();
                  final exercises = snap.data!;
                  if (exercises.isEmpty) return SizedBox.shrink();
                  return _themedExpansionTile(
                    title: sub.name,
                    children: exercises.map((e) {
                      final isSelected = selectedForDay.contains(e.id);
                      return ExerciseCard(
                        exercise: e,
                        userId: 'local',
                        isSelected: isSelected,
                        onSelectionChanged: (val) => model.toggleExerciseForDay(day!, e.id),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      );
    }
    return widgets;
  }

  Future<List<Widget>> _buildSubBodyPartExerciseTree(BuildContext context, int mainBodyPartId) async {
    final repo = context.read<ExerciseBloc>().exerciseRepository;
    final model = Provider.of<ProgramMergerFormModel>(context, listen: false);
    final selectedDays = model.selectedDays;
    final day = selectedDays.isNotEmpty ? selectedDays[selectedDayIndex] : null;
    final selectedForDay = day != null ? model.dayToExerciseIds[day] ?? [] : [];
    List<Widget> widgets = [];
    final subParts = await repo.sqlProvider.getBodyPartsByParentId(mainBodyPartId);
    for (final sub in subParts) {
      widgets.add(
        FutureBuilder<List<Exercises>>(
          future: repo.sqlProvider.getExercisesByBodyPart(sub.id, isPrimary: true),
          builder: (context, snap) {
            if (!snap.hasData) return SizedBox.shrink();
            final exercises = snap.data!;
            if (exercises.isEmpty) return SizedBox.shrink();
            return _themedExpansionTile(
              title: sub.name,
              children: exercises.map((e) {
                final isSelected = selectedForDay.contains(e.id);
                return ExerciseCard(
                  exercise: e,
                  userId: 'local',
                  isSelected: isSelected,
                  onSelectionChanged: (val) => model.toggleExerciseForDay(day!, e.id),
                );
              }).toList(),
            );
          },
        ),
      );
    }
    return widgets;
  }
} 