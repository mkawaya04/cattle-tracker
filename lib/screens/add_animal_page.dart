import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAnimalPage extends StatefulWidget {
  const AddAnimalPage({super.key});

  @override
  State<AddAnimalPage> createState() => _AddAnimalPageState();
}

class _AddAnimalPageState extends State<AddAnimalPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tagIdController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  String selectedStatus = 'Healthy';

  Future<void> _saveAnimal() async {
    try {
      await FirebaseFirestore.instance.collection('animals').add({
        'name': nameController.text.trim(),
        'tagId': tagIdController.text.trim(),
        'breed': breedController.text.trim(),
        'age': int.tryParse(ageController.text.trim()) ?? 0,
        'status': selectedStatus,
        'createdAt': FieldValue
            .serverTimestamp(), // ✅ added so profile page ordering works
        // 🚫 No lat/lng here — GPS will update later
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animal saved successfully!')),
      );

      // Clear inputs
      nameController.clear();
      tagIdController.clear();
      breedController.clear();
      ageController.clear();
      setState(() => selectedStatus = 'Healthy');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving animal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final softBlue = Colors.lightBlue[50];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Animal'),
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildTextField(
                controller: nameController, label: 'Name', fill: softBlue),
            const SizedBox(height: 12),
            _buildTextField(
                controller: tagIdController, label: 'Tag ID', fill: softBlue),
            const SizedBox(height: 12),
            _buildTextField(
                controller: breedController, label: 'Breed', fill: softBlue),
            const SizedBox(height: 12),
            _buildTextField(
              controller: ageController,
              label: 'Age',
              fill: softBlue,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildStatusDropdown(fill: softBlue),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveAnimal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color? fill,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildStatusDropdown({required Color? fill}) {
    return DropdownButtonFormField<String>(
      value: selectedStatus,
      items: const [
        DropdownMenuItem(value: 'Healthy', child: Text('Healthy')),
        DropdownMenuItem(value: 'Sick', child: Text('Sick')),
        DropdownMenuItem(
            value: 'Needs Attention', child: Text('Needs Attention')),
      ],
      onChanged: (value) {
        if (value != null) setState(() => selectedStatus = value);
      },
      decoration: InputDecoration(
        labelText: 'Status',
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
