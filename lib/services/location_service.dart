// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check if location services are enabled and permissions are granted
  static Future<Map<String, dynamic>> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return {'success': false, 'message': 'ກະລຸນາເປີດ GPS'};
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return {
          'success': false,
          'message': 'ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງສະຖານທີ່',
        };
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return {
        'success': false,
        'message': 'ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງສະຖານທີ່ໃນການຕັ້ງຄ່າ',
      };
    }

    return {'success': true, 'message': 'Location permission granted'};
  }

  /// Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Check if user is within a certain radius (in km) of destination
  static bool isWithinRadius(
    double currentLat,
    double currentLng,
    double destinationLat,
    double destinationLng,
    double radiusInKm,
  ) {
    double distance = calculateDistance(
      currentLat,
      currentLng,
      destinationLat,
      destinationLng,
    );
    return distance <= radiusInKm;
  }

  /// Get position stream for real-time tracking
  static Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
}
