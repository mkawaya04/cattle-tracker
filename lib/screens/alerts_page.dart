import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('animals')
            .where('ownerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('ALERTS ERROR: ${snapshot.error}');
            return const Center(child: Text('Error loading alerts'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No animals found.'));
          }

          final animals = snapshot.data!.docs;

          // Filter animals with status "Sick" or "Needs Attention"
          final alertAnimals = animals.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            return status == 'Sick' || status == 'Needs Attention';
          }).toList();

          if (alertAnimals.isEmpty) {
            return const Center(child: Text('No alerts'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alertAnimals.length,
            itemBuilder: (context, index) {
              final data = alertAnimals[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(
                    data['status'] == 'Sick'
                        ? Icons.warning
                        : Icons.error_outline,
                    color:
                        data['status'] == 'Sick' ? Colors.red : Colors.orange,
                  ),
                  title: Text('${data['name']} requires attention!'),
                  subtitle: Text('Status: ${data['status']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
