import 'package:flutter/material.dart';
import 'package:workout/models/PartFocusRoutine.dart';
import 'package:workout/data_bloc/RoutineRepository.dart';
import 'package:workout/models/BodyPart.dart';

class PartFocusRoutineCard extends StatefulWidget {
  final Parts part;
  final RoutineRepository repository;
  final String userId;
  final VoidCallback onTap;

  const PartFocusRoutineCard({
    Key? key,
    required this.part,
    required this.repository,
    required this.userId,
    required this.onTap,
  }) : super(key: key);

  @override
  _PartFocusRoutineCardState createState() => _PartFocusRoutineCardState();
}

class _PartFocusRoutineCardState extends State<PartFocusRoutineCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    _isFavorite = await widget.repository.isPartFavorite(widget.userId, widget.part.id.toString());
    setState(() {});
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    try {
      await widget.repository.togglePartFavorite(widget.userId, widget.part.id.toString(), _isFavorite);
    } catch (e) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favori durumu güncellenirken bir hata oluştu')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.part.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : null,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
              SizedBox(height: 8),
              FutureBuilder<BodyParts?>(
                future: widget.repository.getBodyPartById(widget.part.bodyPartId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Yükleniyor...');
                  }
                  final bodyPart = snapshot.data;
                  return Text(
                    'Hedef Bölge: ${bodyPart?.name ?? 'Bilinmiyor'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  );
                },
              ),
              SizedBox(height: 8),
              Text('Set Tipi: ${widget.part.setTypeString}'),
              SizedBox(height: 8),
              Text('Egzersiz Sayısı: ${widget.part.exerciseCount}'),
              if (widget.part.additionalNotes.isNotEmpty) ...[
                SizedBox(height: 8),
                Text('Notlar: ${widget.part.additionalNotes}'),
              ],
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.part.setTypeColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}