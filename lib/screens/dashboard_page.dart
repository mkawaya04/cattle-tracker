import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  void navigateTo(int index) {
    setState(() {
      selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/profiles');
        break;
      case 1:
        Navigator.pushNamed(context, '/analytics');
        break;
      case 2:
        Navigator.pushNamed(context, '/alerts');
        break;
      case 3:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkGreen = const Color(0xFF1B4332);
    final lightGreen = const Color(0xFF2D6A4F);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final cardColor =
        const Color(0xFFFEFEFE); // Almost pure white for all cards

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: darkGreen,
            child: Column(
              children: [
                const SizedBox(height: 120),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.pets, color: Colors.white),
                        title: const Text('Animal Profiles',
                            style: TextStyle(color: Colors.white)),
                        onTap: () => navigateTo(0),
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.analytics, color: Colors.white),
                        title: const Text('Animal Analytics',
                            style: TextStyle(color: Colors.white)),
                        onTap: () => navigateTo(1),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.notification_important,
                          color: Colors.white,
                        ),
                        title: const Text('Alerts',
                            style: TextStyle(color: Colors.white)),
                        onTap: () => navigateTo(2),
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.settings, color: Colors.white),
                        title: const Text('Settings',
                            style: TextStyle(color: Colors.white)),
                        onTap: () => navigateTo(3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top title bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  color: lightGreen,
                  child: const Center(
                    child: Text(
                      'Animal Tracker Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Info cards with Firestore data
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Registered animals count
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('animals')
                            .where('ownerId', isEqualTo: userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return InfoCard(
                              title: 'Registered Animals',
                              value: '...',
                              icon: Icons.pets,
                              color: cardColor,
                            );
                          }
                          final count = snapshot.data!.docs.length;
                          return InfoCard(
                            title: 'Registered Animals',
                            value: count.toString(),
                            icon: Icons.pets,
                            color: cardColor,
                          );
                        },
                      ),
                      const SizedBox(width: 16),

                      // Live location status (simplified: show Active if any location exists)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('locations')
                            .where(
                              'ownerId',
                              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                            )
                            .snapshots(),
                        builder: (context, snapshot) {
                          String status = 'Inactive';
                          if (snapshot.hasData &&
                              snapshot.data!.docs.isNotEmpty) {
                            status = 'Active';
                          }
                          return InfoCard(
                            title: 'Live Location',
                            value: status,
                            icon: Icons.location_on,
                            color: cardColor,
                          );
                        },
                      ),
                      const SizedBox(width: 16),

                      // Alerts count
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('alerts')
                            .where('ownerId', isEqualTo: userId)
                            .where('resolved', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return InfoCard(
                              title: 'Alerts',
                              value: '...',
                              icon: Icons.warning,
                              color: cardColor,
                            );
                          }
                          final count = snapshot.data!.docs.length;
                          return InfoCard(
                            title: 'Alerts',
                            value: count.toString(),
                            icon: Icons.warning,
                            color: cardColor,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Full-width, full-height image with overlay text
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/tagged_cattle.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Welcome to your cattle tracking dashboard!',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// InfoCard widget
class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color ?? Colors.grey[200],
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
