import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_animal_page.dart';
import 'animal_detail_page.dart';

class AnimalProfilesPage extends StatefulWidget {
  const AnimalProfilesPage({super.key});

  @override
  State<AnimalProfilesPage> createState() => _AnimalProfilesPageState();
}

class _AnimalProfilesPageState extends State<AnimalProfilesPage> {
  String searchQuery = '';
  String selectedBreed = 'All';
  String selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final darkGreen = const Color(0xFF1B4332);
    final lightFill = Colors.grey[100];
    final statuses = ['All', 'Healthy', 'Needs Attention', 'Sick'];
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Animal Profiles',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: darkGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔹 Search + Filters
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: lightFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedBreed,
                        items: ['All', 'Boran', 'Friesian']
                            .map((b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(b),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedBreed = value!),
                        decoration: InputDecoration(
                          labelText: 'Breed',
                          filled: true,
                          fillColor: lightFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        items: statuses
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedStatus = value!),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          filled: true,
                          fillColor: lightFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🔹 Animal List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('animals')
                  .where('ownerId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(color: darkGreen));
                }

                final docs = snapshot.data!.docs;

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final breed = (data['breed'] ?? '').toString();
                  final status = (data['status'] ?? '').toString();

                  final matchesSearch =
                      name.contains(searchQuery.toLowerCase());
                  final matchesBreed =
                      selectedBreed == 'All' || breed == selectedBreed;
                  final matchesStatus =
                      selectedStatus == 'All' || status == selectedStatus;

                  return matchesSearch && matchesBreed && matchesStatus;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final breed = data['breed'] ?? 'Unknown';
                    final age = data['age']?.toString() ?? 'Unknown';
                    final status = data['status'] ?? 'Unknown';
                    final animalId = data['animalId'] ?? doc.id;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: darkGreen,
                          child: const Icon(Icons.pets, color: Colors.white),
                        ),
                        title: Text(name),
                        subtitle: Text('$breed • $age'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              status,
                              style: TextStyle(
                                color: status == 'Healthy'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // ✏ Edit button
                            IconButton(
                              icon: Icon(Icons.edit, color: darkGreen),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditAnimalPage(
                                      animalDocId: doc.id,
                                      animalData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        // 👁 Tap to view details
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnimalDetailPage(
                                animalId: animalId,
                                animalData: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/add_animal');
        },
      ),
    );
  }
}
