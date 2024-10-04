import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String id;
  final String? optionalParam;
  final DateTime createdAt;
  final List<Part> parts;

  const HomePage({super.key,
    required this.id,
    this.optionalParam,
    required this.createdAt,
    required this.parts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('ID: $id'),
        if (optionalParam != null) Text('Optional: $optionalParam'),
        Text('Created: ${createdAt.toIso8601String()}'),
        Expanded(
          child: FirestoreListView<Map<String, dynamic>>(
            query: FirebaseFirestore.instance.collection('routines').orderBy('createdAt', descending: true),
            itemBuilder: (context, snapshot) {
              Map<String, dynamic> data = snapshot.data();
              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text(data['createdAt'].toDate().toString()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class Part {
  final String name;
  Part(this.name);
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: HomePage(
        id: 'unique_id_1',
        createdAt: DateTime.now(),
        parts: [Part('Part 1'), Part('Part 2')],
      ),
    ),
  ));
}