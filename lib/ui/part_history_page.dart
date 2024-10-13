import 'package:flutter/material.dart';
import '../models/part.dart';

class PartHistoryPage extends StatelessWidget {
  final Part part;

  PartHistoryPage({required this.part});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: part.exerciseIds.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(part.name),
          bottom: TabBar(
            isScrollable: true,
            tabs: _getTabs(),
          ),
        ),
        body: TabBarView(
          children: _getTabChildren(),
        ),
      ),
    );
  }

  List<Widget> _getTabs() {
    return part.exerciseIds.map((id) {
      return Tab(text: 'Exercise $id'); // You might want to fetch exercise names from somewhere
    }).toList();
  }

  List<Widget> _getTabChildren() {
    return part.exerciseIds.map((id) {
      return TabChild(exerciseId: id, setType: part.setType);
    }).toList();
  }
}

class TabChild extends StatelessWidget {
  final int exerciseId;
  final SetType setType;

  TabChild({required this.exerciseId, required this.setType});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Exercise History for ID: $exerciseId'),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Set Type: ${setType.toString()}'),
          ),
          // Here you would add your chart or other widgets to display exercise history
        ],
      ),
    );
  }
}
