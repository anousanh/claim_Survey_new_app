// lib/services/map_controller_service.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapControllerService {
  /// Create marker for assigned/destination location
  static Marker createDestinationMarker({
    required double lat,
    required double lng,
    String title = 'ສະຖານທີ່ທີ່ມອບໝາຍ',
    String snippet = 'ຈຸດໝາຍປາກທາງ',
    String markerId = 'assigned_location',
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(title: title, snippet: snippet),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
  }

  /// Create marker for current user location
  static Marker createCurrentLocationMarker({
    required Position position,
    BitmapDescriptor? customIcon,
    String markerId = 'current_location',
    String title = 'ສະຖານທີ່ປັດຈຸບັນ',
    String snippet = 'ຕຳແໜ່ງຂອງຂ້ອຍ',
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: InfoWindow(title: title, snippet: snippet),
      icon:
          customIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      rotation: position.heading,
    );
  }

  /// Animate camera to show both markers
  static void animateCameraToShowBothMarkers({
    required GoogleMapController mapController,
    required Position currentPosition,
    required double destinationLat,
    required double destinationLng,
    double padding = 80,
  }) {
    double minLat = currentPosition.latitude < destinationLat
        ? currentPosition.latitude
        : destinationLat;
    double maxLat = currentPosition.latitude > destinationLat
        ? currentPosition.latitude
        : destinationLat;
    double minLng = currentPosition.longitude < destinationLng
        ? currentPosition.longitude
        : destinationLng;
    double maxLng = currentPosition.longitude > destinationLng
        ? currentPosition.longitude
        : destinationLng;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
  }

  /// Animate camera to follow user position (navigation mode)
  static void animateCameraToFollowUser({
    required GoogleMapController mapController,
    required Position position,
    double zoom = 17,
    double tilt = 45,
  }) {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: zoom,
          bearing: position.heading,
          tilt: tilt,
        ),
      ),
    );
  }

  /// Animate camera to specific location
  static void animateCameraToLocation({
    required GoogleMapController mapController,
    required double lat,
    required double lng,
    double zoom = 15,
    double bearing = 0,
    double tilt = 0,
  }) {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: zoom,
          bearing: bearing,
          tilt: tilt,
        ),
      ),
    );
  }

  /// Load custom marker icon
  static Future<BitmapDescriptor> loadCustomMarkerIcon({
    String assetPath = '',
    double hue = BitmapDescriptor.hueBlue,
  }) async {
    if (assetPath.isNotEmpty) {
      try {
        return await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
          assetPath,
        );
      } catch (e) {
        print('Error loading custom marker: $e');
      }
    }

    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  /// Calculate camera bounds for multiple markers
  static LatLngBounds calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (var pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );
  }

  /// Fit camera to bounds
  static void fitBounds({
    required GoogleMapController mapController,
    required LatLngBounds bounds,
    double padding = 80,
  }) {
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
  }
}
