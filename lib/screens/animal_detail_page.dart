import 'package:flutter/material.dart';

class AnimalDetailPage extends StatelessWidget {
  final String animalId;
  final Map<String, dynamic> animalData;

  const AnimalDetailPage({
    super.key,
    required this.animalId,
    required this.animalData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(animalData['name'] ?? 'Animal Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${animalData['name'] ?? 'Unknown'}"),
            Text("Breed: ${animalData['breed'] ?? 'Unknown'}"),
            Text("Age: ${animalData['age']?.toString() ?? 'Unknown'}"),
            Text("Status: ${animalData['status'] ?? 'Unknown'}"),
          ],
        ),
      ),
    );
  }
}
