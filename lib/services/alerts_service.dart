import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

class AlertsService {
  /// Check temperature and create alert if needed
  static Future<void> checkTemperature({
    required String animalId,
    required String animalName,
    required double temperature,
    required String ownerId,
  }) async {
    String? alertType;
    String? severity;
    String? message;

    // Define your temperature thresholds
    if (temperature > 40.0) {
      alertType = 'temperature';
      severity = 'high';
      message =
          '$animalName has dangerously high temperature: ${temperature.toStringAsFixed(1)}°C';
    } else if (temperature < 35.0) {
      alertType = 'temperature';
      severity = 'high';
      message =
          '$animalName has dangerously low temperature: ${temperature.toStringAsFixed(1)}°C';
    } else if (temperature > 39.0 || temperature < 36.0) {
      alertType = 'temperature';
      severity = 'medium';
      message =
          '$animalName has abnormal temperature: ${temperature.toStringAsFixed(1)}°C';
    }

    if (alertType != null && severity != null && message != null) {
      await _createAlertIfNotExists(
        ownerId: ownerId,
        animalId: animalId,
        type: alertType,
        severity: severity,
        message: message,
      );
    }
  }

  /// Check location and create alert if needed
  static Future<void> checkLocation({
    required String animalId,
    required String animalName,
    required double lat,
    required double lng,
    required String ownerId,
  }) async {
    // Get the animal's safe zone from Firestore
    final animalDocs = await FirebaseFirestore.instance
        .collection('animals')
        .where('animalId', isEqualTo: animalId)
        .limit(1)
        .get();

    if (animalDocs.docs.isEmpty) return;

    final animalData = animalDocs.docs.first.data();
    final safeZoneLat = (animalData['safeZoneLat'] as num?)?.toDouble();
    final safeZoneLng = (animalData['safeZoneLng'] as num?)?.toDouble();
    final safeZoneRadius =
        (animalData['safeZoneRadius'] as num?)?.toDouble() ?? 100.0;

    if (safeZoneLat == null || safeZoneLng == null) return;

    // Calculate distance from safe zone center
    final distance = _calculateDistance(lat, lng, safeZoneLat, safeZoneLng);

    if (distance > safeZoneRadius) {
      await _createAlertIfNotExists(
        ownerId: ownerId,
        animalId: animalId,
        type: 'location',
        severity: distance > safeZoneRadius * 2 ? 'high' : 'medium',
        message:
            '$animalName is ${distance.toStringAsFixed(0)}m outside safe zone',
      );
    }
  }

  /// Create alert only if an unresolved one doesn't already exist
  static Future<void> _createAlertIfNotExists({
    required String ownerId,
    required String animalId,
    required String type,
    required String severity,
    required String message,
  }) async {
    try {
      // Check if an unresolved alert of this type already exists for this animal
      final existingAlerts = await FirebaseFirestore.instance
          .collection('alerts')
          .where('ownerId', isEqualTo: ownerId)
          .where('animalId', isEqualTo: animalId)
          .where('type', isEqualTo: type)
          .where('resolved', isEqualTo: false)
          .limit(1)
          .get();

      // If an unresolved alert already exists, just update its message and timestamp
      if (existingAlerts.docs.isNotEmpty) {
        debugPrint('Alert already exists for $animalId - $type, updating...');
        await existingAlerts.docs.first.reference.update({
          'message': message,
          'severity': severity,
          'timestamp': FieldValue.serverTimestamp(),
        });
        return;
      }

      // Create the new alert
      await FirebaseFirestore.instance.collection('alerts').add({
        'ownerId': ownerId,
        'animalId': animalId,
        'type': type,
        'severity': severity,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'resolved': false,
      });

      debugPrint('✅ Created new alert for $animalId - $type');
    } catch (e) {
      debugPrint('Error creating alert: $e');
    }
  }

  /// Calculate distance between two coordinates in meters
  static double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
