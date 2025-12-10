import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAnimalPage extends StatefulWidget {
  final String animalDocId;
  final Map<String, dynamic> animalData;

  const EditAnimalPage({
    super.key,
    required this.animalDocId,
    required this.animalData,
  });

  @override
  State<EditAnimalPage> createState() => _EditAnimalPageState();
}

class _EditAnimalPageState extends State<EditAnimalPage> {
  late TextEditingController nameController;
  late TextEditingController breedController;
  late TextEditingController ageController;
  late String status;

  final statuses = ['Healthy', 'Needs Attention', 'Sick'];

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.animalData['name'] ?? '');
    breedController =
        TextEditingController(text: widget.animalData['breed'] ?? '');
    ageController =
        TextEditingController(text: widget.animalData['age']?.toString() ?? '');
    status = widget.animalData['status'] ?? 'Healthy';
  }

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    ageController.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    await FirebaseFirestore.instance
        .collection('animals')
        .doc(widget.animalDocId)
        .update({
      'name': nameController.text,
      'breed': breedController.text,
      'age': int.tryParse(ageController.text) ?? 0,
      'status': status,
    });

    Navigator.pop(context); // go back to profile page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Animal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: breedController,
              decoration: const InputDecoration(labelText: 'Breed'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              items: statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => status = val!),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: saveChanges,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
