import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fl_chart/fl_chart.dart';

class AnimalAnalyticsPage extends StatefulWidget {
  const AnimalAnalyticsPage({super.key});

  @override
  State<AnimalAnalyticsPage> createState() => _AnimalAnalyticsPageState();
}

class _AnimalAnalyticsPageState extends State<AnimalAnalyticsPage> {
  String? selectedAnimalId;
  final MapController mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final softBlue = Colors.lightBlue[50];
    final softBlueAccent = Colors.lightBlue[100];
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Animal Analytics'),
        centerTitle: true,
        backgroundColor: softBlueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('animals')
            .where('ownerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final animals = snapshot.data!.docs;

          // Calculate stats
          final totalAnimals = animals.length;
          final healthyAnimals = animals.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'Healthy';
          }).length;
          final sickAnimals = animals.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'Sick' ||
                data['status'] == 'Needs Attention';
          }).length;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🗺️ Map Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Animal Locations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildMap(userId),
                        ),
                      ),
                    ],
                  ),
                ),

                // 📊 Temperature Chart Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Temperature Monitoring',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Animal Selector Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: softBlue,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Select an animal'),
                            value: selectedAnimalId,
                            items: animals.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final animalId = data['animalId'] ?? doc.id;
                              final name = data['name'] ?? 'Unknown';
                              return DropdownMenuItem<String>(
                                value: animalId,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedAnimalId = value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Temperature Chart
                      if (selectedAnimalId != null)
                        _buildTemperatureChart(selectedAnimalId!)
                      else
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: softBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Select an animal to view temperature data',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 📈 Statistics Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.pets,
                              title: 'Total Animals',
                              value: totalAnimals.toString(),
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.check_circle,
                              title: 'Healthy',
                              value: healthyAnimals.toString(),
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.warning,
                              title: 'Sick',
                              value: sickAnimals.toString(),
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMap(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('locations')
          .where('ownerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, locationSnapshot) {
        if (!locationSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final locations = locationSnapshot.data!.docs;

        // Default center (Lusaka, Zambia coordinates)
        LatLng center = LatLng(-15.4167, 28.2833);

        // Group locations by animalId and get the most recent one
        Map<String, QueryDocumentSnapshot> latestLocations = {};
        for (var doc in locations) {
          final data = doc.data() as Map<String, dynamic>;
          final animalId = data['animalId'] as String?;

          if (animalId != null) {
            if (!latestLocations.containsKey(animalId)) {
              latestLocations[animalId] = doc;
            } else {
              final currentTimestamp =
                  (data['timestamp'] as Timestamp?)?.toDate();
              final existingData =
                  latestLocations[animalId]!.data() as Map<String, dynamic>;
              final existingTimestamp =
                  (existingData['timestamp'] as Timestamp?)?.toDate();

              if (currentTimestamp != null && existingTimestamp != null) {
                if (currentTimestamp.isAfter(existingTimestamp)) {
                  latestLocations[animalId] = doc;
                }
              }
            }
          }
        }

        if (latestLocations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No location data available',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('animals')
              .where('ownerId', isEqualTo: userId)
              .snapshots(),
          builder: (context, animalSnapshot) {
            if (!animalSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final animals = animalSnapshot.data!.docs;
            Map<String, Map<String, dynamic>> animalMap = {};
            for (var doc in animals) {
              final data = doc.data() as Map<String, dynamic>;
              final animalId = data['animalId'] ?? doc.id;
              animalMap[animalId] = data;
            }

            List<Marker> markers = [];
            bool firstMarker = true;

            latestLocations.forEach((animalId, locationDoc) {
              final locationData = locationDoc.data() as Map<String, dynamic>;
              final lat = locationData['lat'] as double?;
              final lng = locationData['lng'] as double?;

              if (lat != null && lng != null) {
                final animalData = animalMap[animalId];
                final name = animalData?['name'] ?? 'Unknown';
                final status = animalData?['status'] ?? 'Unknown';

                // Set first animal as center
                if (firstMarker) {
                  center = LatLng(lat, lng);
                  firstMarker = false;
                }

                markers.add(
                  Marker(
                    point: LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        _showAnimalInfo(context, name, status);
                      },
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: status == 'Healthy' ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              }
            });

            return FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(markers: markers),
              ],
            );
          },
        );
      },
    );
  }

  void _showAnimalInfo(BuildContext context, String name, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Text('Status: $status'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart(String animalId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('temperatures')
          .where('animalId', isEqualTo: animalId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final readings = snapshot.data!.docs;

        if (readings.isEmpty) {
          return Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.lightBlue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No temperature data available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        // Sort readings by timestamp manually
        final sortedReadings = readings.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTimestamp = aData['timestamp'] as Timestamp?;
            final bTimestamp = bData['timestamp'] as Timestamp?;

            if (aTimestamp == null || bTimestamp == null) return 0;
            return aTimestamp.compareTo(bTimestamp);
          });

        // Take only the last 24 readings
        final limitedReadings = sortedReadings.length > 24
            ? sortedReadings.sublist(sortedReadings.length - 24)
            : sortedReadings;

        List<FlSpot> spots = [];
        double minTemp = double.infinity;
        double maxTemp = double.negativeInfinity;

        for (int i = 0; i < limitedReadings.length; i++) {
          final data = limitedReadings[i].data() as Map<String, dynamic>;
          final temp = (data['temp'] ?? 0).toDouble();
          spots.add(FlSpot(i.toDouble(), temp));

          if (temp < minTemp) minTemp = temp;
          if (temp > maxTemp) maxTemp = temp;
        }

        // Add padding to min/max for better visualization
        final tempRange = maxTemp - minTemp;
        final paddedMin = minTemp - (tempRange * 0.1);
        final paddedMax = maxTemp + (tempRange * 0.1);

        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.lightBlue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}°C',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < limitedReadings.length) {
                        final data = limitedReadings[index].data()
                            as Map<String, dynamic>;
                        final timestamp = data['timestamp'] as Timestamp?;
                        if (timestamp != null) {
                          final hour = timestamp.toDate().hour;
                          return Text(
                            '${hour}h',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
              ],
              minY: paddedMin,
              maxY: paddedMax,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
