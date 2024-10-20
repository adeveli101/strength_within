import 'package:flutter/material.dart';
import 'package:workout/models/BodyPart.dart';
import 'package:workout/models/PartFocusRoutine.dart';


///initState(): Widget'ın başlangıç durumunu ayarlar ve animasyon kontrolcüsünü başlatır.
/// dispose(): Widget'ın hafızadan silinmesi sırasında animasyon kontrolcüsünü temizler.
/// _toggleExpand(): Kartın genişletilip daraltılmasını kontrol eder.
/// build(): Widget'ın ana yapısını oluşturur.
/// _buildCollapsedPart(): Kartın daraltılmış halini oluşturur.
/// _buildExpandedPart(): Kartın genişletilmiş halini oluşturur.




class PartCard extends StatefulWidget {
  final Parts part;
  final VoidCallback onTap;
  final bool isFavorite;
  final Function(bool) onFavoriteToggle;

  const PartCard({
    Key? key,
    required this.part,
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  _PartCardState createState() => _PartCardState();
}

class _PartCardState extends State<PartCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey[900],
      child: InkWell(
        onTap: _toggleExpand,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _controller.view,
          builder: (BuildContext context, Widget? child) {
            return Column(
              children: [
                _buildCollapsedPart(),
                ClipRect(
                  child: Align(
                    heightFactor: _heightFactor.value,
                    child: _buildExpandedPart(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCollapsedPart() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.part.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Hedef Bölge: ${MainTargetedBodyPart.values[widget.part.bodyPartId].toString().split('.').last}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.isFavorite ? Colors.red : Colors.grey[400],
            ),
            onPressed: () => widget.onFavoriteToggle(!widget.isFavorite),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedPart() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[850],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Tipi: ${widget.part.setType.toString().split('.').last}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ek Notlar:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            widget.part.additionalNotes,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onTap,
            child: Text('Detayları Göster'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }
}
