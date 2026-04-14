import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final darkGreen = const Color(0xFF1B4332);
    final name = animalData['name'] ?? 'Unknown';
    final breed = animalData['breed'] ?? 'Unknown';

    // Calculate age from birth date (new system) or use old age field
    final age = _calculateAgeFromData(animalData);

    final status = animalData['status'] ?? 'Unknown';
    final tagId = animalData['tagId'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(color: Colors.white)),
        backgroundColor: darkGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit page if you have one
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Basic Info Card
            Card(
              elevation: 2,
              color: const Color(0xFFFEFEFE),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pets, color: darkGreen, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          'Animal Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Name', name, Icons.label),
                    _buildInfoRow('Tag ID', tagId, Icons.qr_code),
                    _buildInfoRow('Breed', breed, Icons.category),
                    _buildInfoRow('Age', age, Icons.calendar_today),
                    _buildInfoRow('Status', status, Icons.health_and_safety,
                        statusColor: _getStatusColor(status)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Temperature Summary Stats
            _buildTemperatureSummary(),

            const SizedBox(height: 16),

            // Temperature History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Temperature History (Last 7 Days)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showFullTemperatureHistory(context);
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTemperatureHistory(),

            const SizedBox(height: 24),

            // Location History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Locations (Last 24 Hours)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showFullLocationHistory(context);
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildLocationHistory(),
          ],
        ),
      ),
    );
  }

  // NEW METHOD: Calculate age from birth date or fall back to old age field
  String _calculateAgeFromData(Map<String, dynamic> data) {
    // Try to get dateOfBirth first (new system)
    if (data['dateOfBirth'] != null) {
      final birthDate = (data['dateOfBirth'] as Timestamp).toDate();
      final now = DateTime.now();
      int years = now.year - birthDate.year;

      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        years--;
      }

      // If less than 1 year old, show months instead
      if (years == 0) {
        final months =
            now.month - birthDate.month + (12 * (now.year - birthDate.year));
        if (months <= 0) {
          return 'Less than 1 month';
        }
        return '$months months';
      }

      return '$years years';
    }

    // Fall back to old age field if it exists
    if (data['age'] != null) {
      return '${data['age']} years (approx)';
    }

    return 'Unknown';
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: statusColor ?? Colors.black87,
              fontWeight:
                  statusColor != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'sick':
        return Colors.red;
      case 'under observation':
        return Colors.orange;
      case 'pregnant':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTemperatureSummary() {
    // Date 7 days ago
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('temperatures')
          .where('animalId', isEqualTo: animalData['animalId'] ?? animalId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final temps = snapshot.data!.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['temp'] as num?)
            .where((temp) => temp != null)
            .map((temp) => temp!.toDouble())
            .toList();

        if (temps.isEmpty) return const SizedBox.shrink();

        final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
        final minTemp = temps.reduce((a, b) => a < b ? a : b);
        final maxTemp = temps.reduce((a, b) => a > b ? a : b);

        return Card(
          elevation: 2,
          color: const Color(0xFFFEFEFE),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Temperature Summary (7 Days)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Average',
                      '${avgTemp.toStringAsFixed(1)}°C',
                      Icons.thermostat,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Minimum',
                      '${minTemp.toStringAsFixed(1)}°C',
                      Icons.arrow_downward,
                      Colors.cyan,
                    ),
                    _buildStatCard(
                      'Maximum',
                      '${maxTemp.toStringAsFixed(1)}°C',
                      Icons.arrow_upward,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureHistory() {
    // Date 7 days ago
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('temperatures')
          .where('animalId', isEqualTo: animalData['animalId'] ?? animalId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('timestamp', descending: true)
          .limit(5) // Show only last 5 for quick view
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            color: Color(0xFFFEFEFE),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            color: const Color(0xFFFEFEFE),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  Icon(Icons.thermostat_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No temperature data in the last 7 days',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final temps = snapshot.data!.docs;

        return Card(
          elevation: 2,
          color: const Color(0xFFFEFEFE),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: temps.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = temps[index].data() as Map<String, dynamic>;
              final temp = (data['temp'] ?? 0).toDouble();
              final timestamp = data['timestamp'] as Timestamp?;
              final isNormal = temp >= 38.0 && temp <= 39.5;
              final tempColor = isNormal ? Colors.green : Colors.red;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tempColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.thermostat,
                    color: tempColor,
                  ),
                ),
                title: Text(
                  '${temp.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: tempColor,
                  ),
                ),
                subtitle: timestamp != null
                    ? Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    : null,
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tempColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isNormal ? 'Normal' : 'Alert',
                    style: TextStyle(
                      color: tempColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLocationHistory() {
    // Date 24 hours ago
    final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('locations')
          .where('animalId', isEqualTo: animalData['animalId'] ?? animalId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .orderBy('timestamp', descending: true)
          .limit(5) // Show only last 5 for quick view
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            color: Color(0xFFFEFEFE),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            color: const Color(0xFFFEFEFE),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  Icon(Icons.location_off_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No location data in the last 24 hours',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final locations = snapshot.data!.docs;

        return Card(
          elevation: 2,
          color: const Color(0xFFFEFEFE),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: locations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = locations[index].data() as Map<String, dynamic>;
              final lat = (data['lat'] ?? 0).toDouble();
              final lng = (data['lng'] ?? 0).toDouble();
              final timestamp = data['timestamp'] as Timestamp?;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                  ),
                ),
                title: Text(
                  'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: timestamp != null
                    ? Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.map, color: Colors.blue),
                  tooltip: 'View on map',
                  onPressed: () {
                    // TODO: Open map view with this location
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showFullTemperatureHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullTemperatureHistoryPage(
          animalId: animalData['animalId'] ?? animalId,
          animalName: animalData['name'] ?? 'Unknown',
        ),
      ),
    );
  }

  void _showFullLocationHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullLocationHistoryPage(
          animalId: animalData['animalId'] ?? animalId,
          animalName: animalData['name'] ?? 'Unknown',
        ),
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
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Full Temperature History Page
class FullTemperatureHistoryPage extends StatelessWidget {
  final String animalId;
  final String animalName;

  const FullTemperatureHistoryPage({
    super.key,
    required this.animalId,
    required this.animalName,
  });

  @override
  Widget build(BuildContext context) {
    final darkGreen = const Color(0xFF1B4332);

    return Scaffold(
      appBar: AppBar(
        title: Text('$animalName - All Temperatures',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: darkGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('temperatures')
            .where('animalId', isEqualTo: animalId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No temperature data available'),
            );
          }

          final temps = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: temps.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final data = temps[index].data() as Map<String, dynamic>;
              final temp = (data['temp'] ?? 0).toDouble();
              final timestamp = data['timestamp'] as Timestamp?;
              final isNormal = temp >= 38.0 && temp <= 39.5;
              final tempColor = isNormal ? Colors.green : Colors.red;

              return ListTile(
                leading: Icon(Icons.thermostat, color: tempColor),
                title: Text(
                  '${temp.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: tempColor,
                  ),
                ),
                subtitle: timestamp != null
                    ? Text(_formatTimestamp(timestamp))
                    : null,
                trailing: Text(
                  isNormal ? 'Normal' : 'Alert',
                  style: TextStyle(
                    color: tempColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Full Location History Page
class FullLocationHistoryPage extends StatelessWidget {
  final String animalId;
  final String animalName;

  const FullLocationHistoryPage({
    super.key,
    required this.animalId,
    required this.animalName,
  });

  @override
  Widget build(BuildContext context) {
    final darkGreen = const Color(0xFF1B4332);

    return Scaffold(
      appBar: AppBar(
        title: Text('$animalName - All Locations',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: darkGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('locations')
            .where('animalId', isEqualTo: animalId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No location data available'),
            );
          }

          final locations = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final data = locations[index].data() as Map<String, dynamic>;
              final lat = (data['lat'] ?? 0).toDouble();
              final lng = (data['lng'] ?? 0).toDouble();
              final timestamp = data['timestamp'] as Timestamp?;

              return ListTile(
                leading: const Icon(Icons.location_on, color: Colors.blue),
                title: Text(
                  'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
                ),
                subtitle: timestamp != null
                    ? Text(_formatTimestamp(timestamp))
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
