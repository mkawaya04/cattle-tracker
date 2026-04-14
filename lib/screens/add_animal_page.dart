import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAnimalPage extends StatefulWidget {
  const AddAnimalPage({super.key});

  @override
  State<AddAnimalPage> createState() => _AddAnimalPageState();
}

class _AddAnimalPageState extends State<AddAnimalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _tagIdController = TextEditingController();

  DateTime? _selectedBirthDate;
  String _status = 'Healthy';
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'Healthy',
    'Sick',
    'Under Observation',
    'Pregnant',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _tagIdController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now()
          .subtract(const Duration(days: 365)), // Default to 1 year ago
      firstDate: DateTime(2000), // Animals born from year 2000
      lastDate: DateTime.now(), // Can't be born in the future
      helpText: 'Select Birth Date',
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  String _calculateAge() {
    if (_selectedBirthDate == null) return 'Not set';

    final now = DateTime.now();
    int years = now.year - _selectedBirthDate!.year;

    if (now.month < _selectedBirthDate!.month ||
        (now.month == _selectedBirthDate!.month &&
            now.day < _selectedBirthDate!.day)) {
      years--;
    }

    if (years == 0) {
      final months = now.month -
          _selectedBirthDate!.month +
          (12 * (now.year - _selectedBirthDate!.year));
      return '$months months';
    }

    return '$years years';
  }

  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a birth date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Create a unique animal ID
      final animalDoc = FirebaseFirestore.instance.collection('animals').doc();
      final animalId = animalDoc.id;

      await animalDoc.set({
        'animalId': animalId,
        'ownerId': userId,
        'name': _nameController.text.trim(),
        'breed': _breedController.text.trim(),
        'tagId': _tagIdController.text.trim(),
        'dateOfBirth': Timestamp.fromDate(_selectedBirthDate!),
        'status': _status,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animal added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkGreen = const Color(0xFF1B4332);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Add New Animal', style: TextStyle(color: Colors.white)),
        backgroundColor: darkGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: darkGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Animal Name',
                        prefixIcon: Icon(Icons.pets),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter animal name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tag ID
                    TextFormField(
                      controller: _tagIdController,
                      decoration: const InputDecoration(
                        labelText: 'Tag ID',
                        prefixIcon: Icon(Icons.qr_code),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter tag ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Breed
                    TextFormField(
                      controller: _breedController,
                      decoration: const InputDecoration(
                        labelText: 'Breed',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter breed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Birth Date Picker
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.cake, color: Colors.orange),
                        title: const Text('Birth Date'),
                        subtitle: Text(
                          _selectedBirthDate == null
                              ? 'Not selected'
                              : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year} (${_calculateAge()})',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectBirthDate(context),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.health_and_safety),
                        border: OutlineInputBorder(),
                      ),
                      items: _statusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _status = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveAnimal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add Animal',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
