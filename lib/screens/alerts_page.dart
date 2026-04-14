import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/monitoring_service.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final darkGreen = const Color(0xFF1B4332);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: darkGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .where('ownerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: darkGreen));
          }
          if (snapshot.hasError) {
            debugPrint('ALERTS ERROR: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading alerts'),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You may need to create a Firestore index.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'No active alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All your animals are within safe parameters',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Filter and sort in code instead of in query
          final allAlerts = snapshot.data!.docs;
          final unresolvedAlerts = allAlerts.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['resolved'] != true;
          }).toList();

          // Sort by timestamp
          unresolvedAlerts.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['timestamp'] as Timestamp?;
            final bTime = bData['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); // Descending
          });

          if (unresolvedAlerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'No active alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All your animals are within safe parameters',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: unresolvedAlerts.length,
            itemBuilder: (context, index) {
              final alertDoc = unresolvedAlerts[index];
              final data = alertDoc.data() as Map<String, dynamic>;
              final type = data['type'] ?? 'unknown';
              final severity = data['severity'] ?? 'medium';
              final message = data['message'] ?? 'Alert';
              final timestamp = data['timestamp'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.white,
                child: ListTile(
                  leading: Icon(
                    type == 'temperature'
                        ? Icons.thermostat
                        : Icons.location_off,
                    color: severity == 'high' ? Colors.red : Colors.orange,
                    size: 32,
                  ),
                  title: Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: timestamp != null
                      ? Text(
                          _formatTimestamp(timestamp),
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    tooltip: 'Mark as resolved',
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('alerts')
                          .doc(alertDoc.id)
                          .update({
                        'resolved': true,
                        'resolvedAt': FieldValue.serverTimestamp(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alert resolved')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          MonitoringService.checkAllAnimals();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checking all animals for alerts...')),
          );
        },
        backgroundColor: darkGreen,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
