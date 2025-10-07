// lib/services/navigation_service.dart
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

class NavigationService {
  /// Get current instruction based on position and route steps
  static Map<String, dynamic> getCurrentInstruction({
    required Position currentPosition,
    required List<Map<String, dynamic>> steps,
    double proximityThreshold = 0.1, // km
  }) {
    if (steps.isEmpty) {
      return {'index': -1, 'instruction': ''};
    }

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final stepLat = step['end_location']['lat'];
      final stepLng = step['end_location']['lng'];

      double distanceToStep = LocationService.calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        stepLat,
        stepLng,
      );

      if (distanceToStep < proximityThreshold) {
        return {
          'index': i,
          'instruction': removeHtmlTags(step['html_instructions']),
          'distance': step['distance']['text'] ?? '',
          'maneuver': step['maneuver'] ?? '',
        };
      }
    }

    // Return first step if no close step found
    return {
      'index': 0,
      'instruction': removeHtmlTags(steps[0]['html_instructions']),
      'distance': steps[0]['distance']['text'] ?? '',
      'maneuver': steps[0]['maneuver'] ?? '',
    };
  }

  /// Remove HTML tags from instruction text
  static String removeHtmlTags(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Check if destination is reached
  static bool isDestinationReached({
    required Position currentPosition,
    required double destinationLat,
    required double destinationLng,
    double threshold = 0.05, // km (50 meters)
  }) {
    double distance = LocationService.calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      destinationLat,
      destinationLng,
    );
    return distance < threshold;
  }

  /// Calculate remaining distance to destination
  static double calculateRemainingDistance({
    required Position currentPosition,
    required double destinationLat,
    required double destinationLng,
  }) {
    return LocationService.calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      destinationLat,
      destinationLng,
    );
  }

  /// Get navigation status message based on distance
  static String getNavigationStatusMessage(double distanceInKm) {
    if (distanceInKm < 0.05) {
      return 'ເຖິງຈຸດໝາຍແລ້ວ!';
    } else if (distanceInKm < 0.5) {
      return 'ໃກ້ຮອດແລ້ວ - ${(distanceInKm * 1000).toStringAsFixed(0)} ແມັດ';
    } else if (distanceInKm < 1) {
      return 'ເຫຼືອ ${distanceInKm.toStringAsFixed(2)} ກມ';
    } else {
      return 'ເຫຼືອ ${distanceInKm.toStringAsFixed(1)} ກມ';
    }
  }

  /// Parse step maneuver to Lao text
  static String getManeuverText(String? maneuver) {
    if (maneuver == null) return '';

    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return 'ລ້ຽວຊ້າຍ';
      case 'turn-right':
        return 'ລ້ຽວຂວາ';
      case 'turn-slight-left':
        return 'ລ້ຽວຊ້າຍເລັກນ້ອຍ';
      case 'turn-slight-right':
        return 'ລ້ຽວຂວາເລັກນ້ອຍ';
      case 'turn-sharp-left':
        return 'ລ້ຽວຊ້າຍແຮງ';
      case 'turn-sharp-right':
        return 'ລ້ຽວຂວາແຮງ';
      case 'uturn-left':
        return 'ກັບລົດຊ້າຍ';
      case 'uturn-right':
        return 'ກັບລົດຂວາ';
      case 'straight':
        return 'ໄປກົງ';
      case 'merge':
        return 'ເຂົ້າລວມ';
      case 'roundabout-left':
        return 'ວົງວຽນຊ້າຍ';
      case 'roundabout-right':
        return 'ວົງວຽນຂວາ';
      case 'ramp-left':
        return 'ທາງລາດຊ້າຍ';
      case 'ramp-right':
        return 'ທາງລາດຂວາ';
      case 'fork-left':
        return 'ແຍກຊ້າຍ';
      case 'fork-right':
        return 'ແຍກຂວາ';
      case 'ferry':
        return 'ຂຶ້ນເຮືອ';
      default:
        return maneuver;
    }
  }
}
