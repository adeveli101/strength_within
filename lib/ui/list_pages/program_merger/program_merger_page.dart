// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strength_within/ui/list_pages/program_merger/program_details.dart';
import '../../../blocs/data_bloc_part/PartRepository.dart';
import '../../../blocs/data_bloc_part/part_bloc.dart';
import '../../../blocs/data_schedule_bloc/schedule_repository.dart';
import '../../../models/sql_models/PartExercises.dart';
import '../../../models/sql_models/PartTargetedBodyParts.dart';
import '../../../models/sql_models/Parts.dart';
import '../../../models/sql_models/exercises.dart';
import '../../components/program_merger.dart';
import '../../part_ui/part_card.dart';
import 'package:strength_within/blocs/data_exercise_bloc/exercise_bloc.dart';
import 'package:strength_within/models/sql_models/BodyPart.dart';
import 'package:strength_within/models/sql_models/workoutGoals.dart';

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
  const ProgramMergerPage({required this.userId, super.key});

  @override
  State<ProgramMergerPage> createState() => _ProgramMergerPageState();
}

class _ProgramMergerPageState extends State<ProgramMergerPage> {
  int _currentStep = 0;

  // Kullanıcı seçimleri burada tutulacak
  String? selectedGoal;
  List<int> selectedBodyParts = [];
  Map<int, List<int>> selectedExercises = {}; // bodyPartId -> egzersizId listesi
  Map<int, Map<String, dynamic>> exerciseDetails = {}; // egzersizId -> detaylar
  Map<int, List<int>> dayToExercises = {}; // gün -> egzersizId listesi

  @override
  void initState() {
    super.initState();
    // Event'leri sadece bir kez tetikle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<ExerciseBloc>();
      bloc.add(FetchWorkoutGoals());
      bloc.add(FetchBodyParts());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rutin Oluştur')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onContinue,
        onStepCancel: _onCancel,
        steps: [
          Step(
            title: Text('Hedefini Seç'),
            content: _buildGoalStep(),
            isActive: _currentStep == 0,
          ),
          Step(
            title: Text('Bölge Seç'),
            content: _buildBodyPartStep(),
            isActive: _currentStep == 1,
          ),
          Step(
            title: Text('Egzersiz Seç'),
            content: _buildExerciseStep(),
            isActive: _currentStep == 2,
          ),
          Step(
            title: Text('Detayları Gir'),
            content: _buildExerciseDetailStep(),
            isActive: _currentStep == 3,
          ),
          Step(
            title: Text('Günlere Dağıt'),
            content: _buildDayAssignmentStep(),
            isActive: _currentStep == 4,
          ),
          Step(
            title: Text('Özet'),
            content: _buildSummaryStep(),
            isActive: _currentStep == 5,
          ),
        ],
      ),
    );
  }

  void _onContinue() {
    if (_currentStep < 5) setState(() => _currentStep++);
    // Son adımda kaydetme işlemi yapılabilir
  }

  void _onCancel() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Widget _buildGoalStep() {
    // Hedef seçimi UI (gerçek veri)
    return BlocBuilder<ExerciseBloc, ExerciseState>(
      builder: (context, state) {
        if (state is ExerciseLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (state is WorkoutGoalsLoaded) {
          final goals = state.goals;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: goals.map((goal) {
              final isSelected = selectedGoal == goal.id.toString();
              return ChoiceChip(
                label: Text(goal.name),
                selected: isSelected,
                selectedColor: Colors.deepOrangeAccent,
                backgroundColor: Colors.grey[850],
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                onSelected: (selected) {
                  setState(() {
                    selectedGoal = selected ? goal.id.toString() : null;
                  });
                },
              );
            }).toList(),
          );
        } else if (state is ExerciseError) {
          return Text('Hedefler yüklenemedi: ${state.message}', style: TextStyle(color: Colors.red));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildBodyPartStep() {
    // Vücut bölgesi seçimi UI (gerçek veri)
    return BlocBuilder<ExerciseBloc, ExerciseState>(
      builder: (context, state) {
        if (state is ExerciseLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (state is BodyPartsLoaded) {
          final bodyParts = state.bodyParts;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: bodyParts.map((bp) {
              final isSelected = selectedBodyParts.contains(bp.id);
              return ChoiceChip(
                label: Text(bp.name),
                selected: isSelected,
                selectedColor: Colors.deepOrangeAccent,
                backgroundColor: Colors.grey[850],
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedBodyParts.add(bp.id);
                    } else {
                      selectedBodyParts.remove(bp.id);
                    }
                  });
                },
              );
            }).toList(),
          );
        } else if (state is ExerciseError) {
          return Text('Vücut bölgeleri yüklenemedi: ${state.message}', style: TextStyle(color: Colors.red));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildExerciseStep() {
    // Egzersiz seçimi UI
    // Örnek egzersiz ve hedef body part verisi
    final Map<int, List<Map<String, dynamic>>> exercisesByBodyPart = {
      1: [ // Göğüs
        {'id': 101, 'name': 'Bench Press', 'targets': [{'name': 'Göğüs', 'percentage': 80}, {'name': 'Triceps', 'percentage': 20}]},
        {'id': 102, 'name': 'Incline Dumbbell Press', 'targets': [{'name': 'Üst Göğüs', 'percentage': 70}, {'name': 'Ön Omuz', 'percentage': 30}]},
        {'id': 103, 'name': 'Chest Fly', 'targets': [{'name': 'Göğüs', 'percentage': 90}]},
      ],
      2: [ // Sırt
        {'id': 201, 'name': 'Barbell Row', 'targets': [{'name': 'Sırt', 'percentage': 70}, {'name': 'Arka Omuz', 'percentage': 30}]},
        {'id': 202, 'name': 'Lat Pulldown', 'targets': [{'name': 'Sırt', 'percentage': 80}, {'name': 'Biceps', 'percentage': 20}]},
        {'id': 203, 'name': 'Face Pull', 'targets': [{'name': 'Arka Omuz', 'percentage': 60}, {'name': 'Sırt', 'percentage': 40}]},
      ],
      3: [ // Bacak
        {'id': 301, 'name': 'Squat', 'targets': [{'name': 'Bacak', 'percentage': 80}, {'name': 'Kalça', 'percentage': 20}]},
        {'id': 302, 'name': 'Leg Press', 'targets': [{'name': 'Bacak', 'percentage': 90}]},
        {'id': 303, 'name': 'Lunge', 'targets': [{'name': 'Bacak', 'percentage': 70}, {'name': 'Kalça', 'percentage': 30}]},
      ],
      4: [ // Omuz
        {'id': 401, 'name': 'Shoulder Press', 'targets': [{'name': 'Omuz', 'percentage': 80}, {'name': 'Triceps', 'percentage': 20}]},
        {'id': 402, 'name': 'Lateral Raise', 'targets': [{'name': 'Yan Omuz', 'percentage': 90}]},
        {'id': 403, 'name': 'Front Raise', 'targets': [{'name': 'Ön Omuz', 'percentage': 90}]},
      ],
      5: [ // Kol
        {'id': 501, 'name': 'Biceps Curl', 'targets': [{'name': 'Biceps', 'percentage': 100}]},
        {'id': 502, 'name': 'Triceps Extension', 'targets': [{'name': 'Triceps', 'percentage': 100}]},
        {'id': 503, 'name': 'Hammer Curl', 'targets': [{'name': 'Biceps', 'percentage': 80}, {'name': 'Ön Kol', 'percentage': 20}]},
      ],
      6: [ // Karın
        {'id': 601, 'name': 'Crunch', 'targets': [{'name': 'Karın', 'percentage': 100}]},
        {'id': 602, 'name': 'Plank', 'targets': [{'name': 'Karın', 'percentage': 80}, {'name': 'Sırt', 'percentage': 20}]},
        {'id': 603, 'name': 'Leg Raise', 'targets': [{'name': 'Alt Karın', 'percentage': 100}]},
      ],
    };

    if (selectedBodyParts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Lütfen önce çalışmak istediğiniz vücut bölgelerini seçin.', style: TextStyle(color: Colors.orange)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...selectedBodyParts.map((bodyPartId) {
          final exercises = exercisesByBodyPart[bodyPartId] ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  _getBodyPartName(bodyPartId),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: exercises.map((ex) {
                  final selectedList = selectedExercises[bodyPartId] ?? [];
                  final isSelected = selectedList.contains(ex['id']);
                  return FilterChip(
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex['name'].toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                        if (ex['targets'] != null)
                          Wrap(
                            spacing: 4,
                            children: (ex['targets'] as List).map((t) => Text(
                              '${t['name']} (%${t['percentage']})',
                              style: TextStyle(fontSize: 11, color: Colors.white70),
                            )).toList(),
                          ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: Colors.deepOrangeAccent,
                    backgroundColor: Colors.grey[850],
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                    onSelected: (selected) {
                      setState(() {
                        final list = selectedExercises[bodyPartId] ?? [];
                        if (selected) {
                          if (!list.contains(ex['id'])) list.add(ex['id'] as int);
                        } else {
                          list.remove(ex['id'] as int);
                        }
                        selectedExercises[bodyPartId] = list;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  String _getBodyPartName(int id) {
    switch (id) {
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
        return '';
    }
  }

  Widget _buildExerciseDetailStep() {
    // Set/rep gibi detaylar (basit)
    // Günlere atanmış egzersizlerin benzersiz listesini çıkar
    final assignedExerciseIds = <int>{};
    dayToExercises.forEach((_, exList) => assignedExerciseIds.addAll(exList));
    if (assignedExerciseIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Lütfen önce egzersizleri günlere atayın.', style: TextStyle(color: Colors.orange)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: assignedExerciseIds.map((exId) {
        final details = exerciseDetails[exId] ?? {'sets': 3, 'reps': 10};
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(child: Text(_getExerciseNameById(exId), style: TextStyle(color: Colors.white))),
                SizedBox(width: 12),
                _NumberInputField(
                  label: 'Set',
                  initialValue: details['sets'],
                  onChanged: (val) {
                    setState(() {
                      exerciseDetails[exId] = {
                        ...details,
                        'sets': val,
                      };
                    });
                  },
                ),
                SizedBox(width: 12),
                _NumberInputField(
                  label: 'Tekrar',
                  initialValue: details['reps'],
                  onChanged: (val) {
                    setState(() {
                      exerciseDetails[exId] = {
                        ...details,
                        'reps': val,
                      };
                    });
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayAssignmentStep() {
    // Egzersizleri günlere dağıtma UI
    // Haftada kaç gün çalışmak istiyorsun?
    final weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    int totalDays = dayToExercises.keys.isNotEmpty ? dayToExercises.keys.length : 3;

    // Eğer hiç gün atanmadıysa, varsayılan olarak 3 gün göster
    if (dayToExercises.isEmpty) {
      for (int i = 0; i < totalDays; i++) {
        dayToExercises[i] = [];
      }
    }

    // Seçilen tüm egzersizlerin düz listesi
    final allSelectedExercises = <Map<String, dynamic>>[];
    selectedExercises.forEach((bodyPartId, exList) {
      for (var exId in exList) {
        allSelectedExercises.add({'id': exId, 'bodyPartId': bodyPartId});
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Haftada kaç gün çalışmak istiyorsun?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 10),
        Row(
          children: [
            for (int i = 2; i <= 6; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text('$i gün'),
                  selected: totalDays == i,
                  selectedColor: Colors.deepOrangeAccent,
                  backgroundColor: Colors.grey[850],
                  labelStyle: TextStyle(color: totalDays == i ? Colors.white : Colors.white70),
                  onSelected: (selected) {
                    setState(() {
                      totalDays = i;
                      // Gün sayısı değişince dayToExercises güncellenir
                      final newMap = <int, List<int>>{};
                      for (int d = 0; d < totalDays; d++) {
                        newMap[d] = dayToExercises[d] ?? [];
                      }
                      dayToExercises = newMap;
                    });
                  },
                ),
              ),
          ],
        ),
        SizedBox(height: 18),
        Text('Egzersizleri günlere ata:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 10),
        ...List.generate(totalDays, (dayIdx) {
          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gün ${dayIdx + 1} (${weekDays[dayIdx % 7]})', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allSelectedExercises.map((ex) {
                      final exId = ex['id'] as int;
                      final isSelected = dayToExercises[dayIdx]?.contains(exId) ?? false;
                      return FilterChip(
                        label: Text(_getExerciseNameById(exId)),
                        selected: isSelected,
                        selectedColor: Colors.deepOrangeAccent,
                        backgroundColor: Colors.grey[850],
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                        onSelected: (selected) {
                          setState(() {
                            final list = dayToExercises[dayIdx] ?? [];
                            if (selected) {
                              if (!list.contains(exId)) list.add(exId);
                            } else {
                              list.remove(exId);
                            }
                            dayToExercises[dayIdx] = list;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _getExerciseNameById(int exId) {
    // Egzersiz adını bulmak için örnek veriyle eşleştir
    final allExercises = <int, String>{
      101: 'Bench Press', 102: 'Incline Dumbbell Press', 103: 'Chest Fly',
      201: 'Barbell Row', 202: 'Lat Pulldown', 203: 'Face Pull',
      301: 'Squat', 302: 'Leg Press', 303: 'Lunge',
      401: 'Shoulder Press', 402: 'Lateral Raise', 403: 'Front Raise',
      501: 'Biceps Curl', 502: 'Triceps Extension', 503: 'Hammer Curl',
      601: 'Crunch', 602: 'Plank', 603: 'Leg Raise',
    };
    return allExercises[exId] ?? 'Egzersiz';
  }

  Widget _buildSummaryStep() {
    // Özet ve kaydet
    final weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    // Egzersiz hedef body part mock verisi (id->targets)
    final Map<int, List<Map<String, dynamic>>> exerciseTargets = {
      101: [{'name': 'Göğüs', 'percentage': 80}, {'name': 'Triceps', 'percentage': 20}],
      102: [{'name': 'Üst Göğüs', 'percentage': 70}, {'name': 'Ön Omuz', 'percentage': 30}],
      103: [{'name': 'Göğüs', 'percentage': 90}],
      201: [{'name': 'Sırt', 'percentage': 70}, {'name': 'Arka Omuz', 'percentage': 30}],
      202: [{'name': 'Sırt', 'percentage': 80}, {'name': 'Biceps', 'percentage': 20}],
      203: [{'name': 'Arka Omuz', 'percentage': 60}, {'name': 'Sırt', 'percentage': 40}],
      301: [{'name': 'Bacak', 'percentage': 80}, {'name': 'Kalça', 'percentage': 20}],
      302: [{'name': 'Bacak', 'percentage': 90}],
      303: [{'name': 'Bacak', 'percentage': 70}, {'name': 'Kalça', 'percentage': 30}],
      401: [{'name': 'Omuz', 'percentage': 80}, {'name': 'Triceps', 'percentage': 20}],
      402: [{'name': 'Yan Omuz', 'percentage': 90}],
      403: [{'name': 'Ön Omuz', 'percentage': 90}],
      501: [{'name': 'Biceps', 'percentage': 100}],
      502: [{'name': 'Triceps', 'percentage': 100}],
      503: [{'name': 'Biceps', 'percentage': 80}, {'name': 'Ön Kol', 'percentage': 20}],
      601: [{'name': 'Karın', 'percentage': 100}],
      602: [{'name': 'Karın', 'percentage': 80}, {'name': 'Sırt', 'percentage': 20}],
      603: [{'name': 'Alt Karın', 'percentage': 100}],
    };
    if (dayToExercises.isEmpty || exerciseDetails.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Lütfen önce egzersizleri günlere atayın ve detayları girin.', style: TextStyle(color: Colors.orange)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rutin Özeti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        SizedBox(height: 16),
        _buildTargetAnalysis(exerciseTargets),
        ...dayToExercises.entries.map((entry) {
          final dayIdx = entry.key;
          final exList = entry.value;
          if (exList.isEmpty) return SizedBox.shrink();
          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gün ${dayIdx + 1} (${weekDays[dayIdx % 7]})', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent)),
                  SizedBox(height: 8),
                  ...exList.map((exId) {
                    final details = exerciseDetails[exId] ?? {'sets': 3, 'reps': 10};
                    final targets = exerciseTargets[exId] ?? [];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(_getExerciseNameById(exId), style: TextStyle(color: Colors.white))),
                              Text('${details['sets']} x ${details['reps']}', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                          if (targets.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 2),
                              child: Wrap(
                                spacing: 6,
                                children: targets.map<Widget>((t) => Text(
                                  '${t['name']} (%${t['percentage']})',
                                  style: TextStyle(fontSize: 11, color: Colors.white54),
                                )).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            icon: Icon(Icons.save),
            label: Text('Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrangeAccent,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              // Şimdilik sadece snackbar ile onay
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Rutin kaydedildi!')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTargetAnalysis(Map<int, List<Map<String, dynamic>>> exerciseTargets) {
    // Tüm günlerdeki egzersizleri topla
    final Map<String, int> bodyPartTotals = {};
    dayToExercises.forEach((_, exList) {
      for (var exId in exList) {
        final targets = exerciseTargets[exId] ?? [];
        for (var t in targets) {
          bodyPartTotals[t['name']] = (bodyPartTotals[t['name']] ?? 0) + (t['percentage'] as int);
        }
      }
    });

    if (bodyPartTotals.isEmpty) {
      return SizedBox.shrink();
    }

    // Analiz ve uyarı
    final maxEntry = bodyPartTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    final minEntry = bodyPartTotals.entries.reduce((a, b) => a.value < b.value ? a : b);

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kas Grubu Analizi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent)),
            SizedBox(height: 8),
            ...bodyPartTotals.entries.map((e) => Row(
              children: [
                Expanded(child: Text(e.key.toString(), style: TextStyle(color: Colors.white))),
                Text('%${e.value}', style: TextStyle(color: Colors.white70)),
              ],
            )),
            SizedBox(height: 8),
            if (minEntry.value < 20)
              Text('Uyarı: ${minEntry.key} çok az çalıştırılıyor!', style: TextStyle(color: Colors.orange)),
            if (maxEntry.value > 180)
              Text('Uyarı: ${maxEntry.key} aşırı yükleniyor!', style: TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }
}

class _NumberInputField extends StatelessWidget {
  final String label;
  final int initialValue;
  final ValueChanged<int> onChanged;
  const _NumberInputField({required this.label, required this.initialValue, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialValue.toString());
    return SizedBox(
      width: 60,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
          isDense: true,
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepOrangeAccent)),
        ),
        onChanged: (val) {
          final parsed = int.tryParse(val);
          if (parsed != null) onChanged(parsed);
        },
      ),
    );
  }
}