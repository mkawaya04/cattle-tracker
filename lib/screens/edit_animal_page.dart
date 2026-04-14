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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _tagIdController;
  
  DateTime? _selectedBirthDate;
  late String _status;
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'Healthy',
    'Sick',
    'Under Observation',
    'Pregnant',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.animalData['name'] ?? '');
    _breedController = TextEditingController(text: widget.animalData['breed'] ?? '');
    _tagIdController = TextEditingController(text: widget.animalData['tagId'] ?? '');
    _status = widget.animalData['status'] ?? 'Healthy';
    
    // Load existing birth date if available
    if (widget.animalData['dateOfBirth'] != null) {
      _selectedBirthDate = (widget.animalData['dateOfBirth'] as Timestamp).toDate();
    }
  }

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
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
        (now.month == _selectedBirthDate!.month && now.day < _selectedBirthDate!.day)) {
      years--;
    }
    
    if (years == 0) {
      final months = now.month - _selectedBirthDate!.month + 
                     (12 * (now.year - _selectedBirthDate!.year));
      return '$months months';
    }
    
    return '$years years';
  }

  Future<void> _updateAnimal() async {
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
      await FirebaseFirestore.instance
          .collection('animals')
          .doc(widget.animalDocId)
          .update({
        'name': _nameController.text.trim(),
        'breed': _breedController.text.trim(),
        'tagId': _tagIdController.text.trim(),
        'dateOfBirth': Timestamp.fromDate(_selectedBirthDate!),
        'status': _status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animal updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
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
        title: const Text('Edit Animal', style: TextStyle(color: Colors.white)),
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

                    // Update Button
                    ElevatedButton(
                      onPressed: _updateAnimal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Update Animal',
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