import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'alerts_service.dart';

class MonitoringService {
  static StreamSubscription? _temperatureSubscription;
  static StreamSubscription? _locationSubscription;
  static bool _isMonitoring = false;

  /// Start monitoring temperature and location data for alerts
  static void startMonitoring() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Prevent multiple monitoring instances
    if (_isMonitoring) {
      debugPrint('⚠️ Monitoring already active, skipping duplicate start');
      return;
    }

    // Cancel any existing subscriptions first (safety check)
    stopMonitoring();

    _isMonitoring = true;

    debugPrint('🚀 Starting monitoring service for user: $userId');

    // Check all existing animals immediately on startup
    checkAllAnimals();

    // Monitor temperature changes
    _temperatureSubscription = FirebaseFirestore.instance
        .collection('temperatures')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          await _checkTemperatureAlert(data, userId);
        }
      }
    });

    // Monitor location changes
    _locationSubscription = FirebaseFirestore.instance
        .collection('locations')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          await _checkLocationAlert(data, userId);
        }
      }
    });

    debugPrint('✅ Monitoring service started');
  }

  /// Stop monitoring
  static void stopMonitoring() {
    _temperatureSubscription?.cancel();
    _locationSubscription?.cancel();
    _temperatureSubscription = null;
    _locationSubscription = null;
    _isMonitoring = false;
    debugPrint('🛑 Monitoring service stopped');
  }

  /// Check if temperature reading requires an alert
  static Future<void> _checkTemperatureAlert(
    Map<String, dynamic> data,
    String userId,
  ) async {
    final animalId = data['animalId'] as String?;
    final temp = (data['temp'] as num?)?.toDouble();

    if (animalId == null || temp == null) return;

    // Get animal name
    final animalName = await _getAnimalName(animalId);

    await AlertsService.checkTemperature(
      animalId: animalId,
      animalName: animalName,
      temperature: temp,
      ownerId: userId,
    );
  }

  /// Check if location requires an alert
  static Future<void> _checkLocationAlert(
    Map<String, dynamic> data,
    String userId,
  ) async {
    final animalId = data['animalId'] as String?;
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();

    if (animalId == null || lat == null || lng == null) return;

    // Get animal name
    final animalName = await _getAnimalName(animalId);

    await AlertsService.checkLocation(
      animalId: animalId,
      animalName: animalName,
      lat: lat,
      lng: lng,
      ownerId: userId,
    );
  }

  /// Get animal name from Firestore
  static Future<String> _getAnimalName(String animalId) async {
    try {
      debugPrint('🔍 Looking for animal with ID: $animalId');

      // First try: query by animalId field
      var animalDocs = await FirebaseFirestore.instance
          .collection('animals')
          .where('animalId', isEqualTo: animalId)
          .limit(1)
          .get();

      if (animalDocs.docs.isNotEmpty) {
        final data = animalDocs.docs.first.data();
        final name = data['name'] ?? 'Unknown Animal';
        debugPrint('✅ Found animal by field: $name');
        return name;
      }

      // Second try: use the animalId as the document ID
      final animalDoc = await FirebaseFirestore.instance
          .collection('animals')
          .doc(animalId)
          .get();

      if (animalDoc.exists) {
        final data = animalDoc.data();
        final name = data?['name'] ?? 'Unknown Animal';
        debugPrint('✅ Found animal by doc ID: $name');
        return name;
      }

      debugPrint('❌ Animal not found: $animalId');
    } catch (e) {
      debugPrint('❌ Error getting animal name: $e');
    }
    return 'Unknown Animal';
  }

  /// Manually check all animals for issues (useful for testing)
  static Future<void> checkAllAnimals() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    debugPrint('🔍 Checking all animals...');

    // Check latest temperatures
    final animals = await FirebaseFirestore.instance
        .collection('animals')
        .where('ownerId', isEqualTo: userId)
        .get();

    debugPrint('📊 Found ${animals.docs.length} animals to check');

    for (var animalDoc in animals.docs) {
      final animalData = animalDoc.data();
      final animalId = animalData['animalId'] ?? animalDoc.id;
      final animalName = animalData['name'] ?? 'Unknown';

      debugPrint('🐄 Checking animal: $animalName (ID: $animalId)');

      // Check latest temperature
      try {
        final tempDocs = await FirebaseFirestore.instance
            .collection('temperatures')
            .where('animalId', isEqualTo: animalId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (tempDocs.docs.isNotEmpty) {
          final tempData = tempDocs.docs.first.data();
          final temp = (tempData['temp'] as num?)?.toDouble();
          if (temp != null) {
            debugPrint('  🌡️ Temperature: $temp°C');
            await AlertsService.checkTemperature(
              animalId: animalId,
              animalName: animalName,
              temperature: temp,
              ownerId: userId,
            );
          }
        }
      } catch (e) {
        debugPrint('  ⚠️ Error checking temperature: $e');
      }

      // Check latest location
      try {
        final locDocs = await FirebaseFirestore.instance
            .collection('locations')
            .where('animalId', isEqualTo: animalId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (locDocs.docs.isNotEmpty) {
          final locData = locDocs.docs.first.data();
          final lat = (locData['lat'] as num?)?.toDouble();
          final lng = (locData['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            debugPrint('  📍 Location: $lat, $lng');
            await AlertsService.checkLocation(
              animalId: animalId,
              animalName: animalName,
              lat: lat,
              lng: lng,
              ownerId: userId,
            );
          }
        }
      } catch (e) {
        debugPrint('  ⚠️ Error checking location: $e');
      }
    }

    debugPrint('✅ Animal check completed');
  }
}
