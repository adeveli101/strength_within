import 'package:flutter/material.dart';

import '../../data_bloc/RoutineRepository.dart';
import '../../models/exercises.dart';
import '../../models/PartFocusRoutine.dart';



///initState(): Widget'ın başlangıç durumunu ayarlar ve egzersizleri yükler.
/// build(): Widget'ın ana yapısını oluşturur.
/// _buildExerciseItem(): Her bir egzersiz için liste öğesi oluşturur.
/// Bu iki kart, aşağıdaki özellikleri ve metodları kullanıyor:
/// DraggableScrollableSheet: PartDescription'da kullanılıyor, aşağıdan yukarı kaydırılabilen bir sayfa oluşturuyor.
/// AnimatedBuilder: PartCard'da kullanılıyor, genişleme/daralma animasyonunu yönetiyor.
/// FutureBuilder: PartDescription'da kullanılıyor, egzersizleri asenkron olarak yüklüyor.
/// ScrollController: PartDescription'da kullanılıyor, sayfanın kaydırılmasını kontrol ediyor.
/// IconButton: PartCard'da kullanılıyor, favori işlemini gerçekleştiriyor.
/// ElevatedButton: PartCard'da kullanılıyor, detayları gösterme işlemini gerçekleştiriyor.


class PartDescription extends StatefulWidget {
  final Parts part;
  final RoutineRepository repository;

  const PartDescription({
    Key? key,
    required this.part,
    required this.repository,
  }) : super(key: key);

  @override
  _PartDescriptionState createState() => _PartDescriptionState();
}

class _PartDescriptionState extends State<PartDescription> {
  late Future<List<Exercises>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = widget.repository.getExercisesForPart(widget.part.id);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                widget.part.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hedef Bölge: ${widget.part.bodyPartId.toString().split('.').last}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Set Tipi: ${widget.part.setType.toString().split('.').last}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Ek Notlar:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                widget.part.additionalNotes,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Egzersizler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              FutureBuilder<List<Exercises>>(
                future: _exercisesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Hata: ${snapshot.error}', style: TextStyle(color: Colors.red));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('Bu part için egzersiz bulunamadı.', style: TextStyle(color: Colors.grey[400]));
                  } else {
                    return Column(
                      children: snapshot.data!.map((exercise) => _buildExerciseItem(exercise)).toList(),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseItem(Exercises exercise) {
    return Card(
      color: Colors.grey[850],
      child: ListTile(
        title: Text(
          exercise.name,
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Set: ${exercise.defaultSets}, Tekrar: ${exercise.defaultReps}',
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: Icon(Icons.fitness_center, color: Colors.blue),
      ),
    );
  }
}
