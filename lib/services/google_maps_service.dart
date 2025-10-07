// lib/services/google_maps_service.dart
import 'dart:convert';
import 'dart:ui';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GoogleMapsService {
  static const String _googleApiKey = 'AIzaSyAb6DE0lT_HRUPvan8fcsH_lwUKUfEeXDw';

  /// Get directions from origin to destination
  static Future<Map<String, dynamic>?> getDirections({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String mode = 'driving',
  }) async {
    final origin = '$originLat,$originLng';
    final destination = '$destinationLat,$destinationLng';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=$origin&destination=$destination&key=$_googleApiKey&mode=$mode',
    );

    try {
      final response = await http.get(url);
      print('HTTP Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Status: ${data['status']}');

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          print(
            'SUCCESS! ${leg['distance']['text']}, ${leg['duration']['text']}',
          );

          return {
            'success': true,
            'polyline': route['overview_polyline']['points'],
            'distance': leg['distance']['value'] / 1000.0, // in km
            'distanceText': leg['distance']['text'],
            'duration': leg['duration']['text'],
            'durationValue': leg['duration']['value'], // in seconds
            'steps': List<Map<String, dynamic>>.from(leg['steps']),
          };
        } else {
          print('API ERROR: ${data['status']}');
          if (data['error_message'] != null) {
            print('Message: ${data['error_message']}');
          }
          return {
            'success': false,
            'error': data['status'],
            'message': data['error_message'] ?? 'Unknown error',
          };
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return {
          'success': false,
          'error': 'HTTP_ERROR',
          'message': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('EXCEPTION: $e');
      return {'success': false, 'error': 'EXCEPTION', 'message': e.toString()};
    } finally {
      print('========== END DEBUG ==========');
    }
  }

  /// Decode polyline string to list of LatLng points
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  /// Create a polyline from encoded string
  static Polyline createPolylineFromEncoded(
    String encoded, {
    String polylineId = 'route',
    Color color = const Color(0xFF0099FF),
    int width = 5,
    List<PatternItem>? patterns,
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: decodePolyline(encoded),
      color: color,
      width: width,
      patterns: patterns ?? [],
    );
  }

  /// Create a straight line polyline (fallback)
  static Polyline createStraightLine({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String polylineId = 'route',
    Color color = const Color(0xFF0099FF),
    int width = 5,
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: [LatLng(startLat, startLng), LatLng(endLat, endLng)],
      color: color,
      width: width,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    );
  }
}
