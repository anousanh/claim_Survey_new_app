// lib/controllers/navigation_controller.dart
// FIXED: Map not showing current location issue

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/background_location_service.dart';
import '../services/database_service.dart';
import '../services/google_maps_service.dart';
import '../services/location_service.dart';
import '../services/navigation_service.dart';
import '../services/map_controller_service.dart';

class NavigationController extends ChangeNotifier {
  final String taskId;
  final String taskTitle;
  final double destinationLat;
  final double destinationLng;

  bool _isNavigating = false;
  Position? _currentPosition;
  double _remainingDistance = 0;
  String _currentInstruction = '';
  List<Map<String, dynamic>> _steps = [];

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _driverIcon;

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription? _backgroundLocationSubscription;

  // Add this flag to track if initial camera animation is done
  bool _initialCameraSet = false;

  // Getters
  bool get isNavigating => _isNavigating;
  Position? get currentPosition => _currentPosition;
  double get remainingDistance => _remainingDistance;
  String get currentInstruction => _currentInstruction;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;

  NavigationController({
    required this.taskId,
    required this.taskTitle,
    required this.destinationLat,
    required this.destinationLng,
  });

  Future<void> initialize() async {
    _driverIcon = await MapControllerService.loadCustomMarkerIcon(
      hue: BitmapDescriptor.hueBlue,
    );
    _addDestinationMarker();

    // Try to get current location immediately on initialization
    await _initializeCurrentLocation();
  }

  /// NEW: Initialize current location on map load
  Future<void> _initializeCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        _currentPosition = position;
        _addCurrentLocationMarker(position);

        // Animate camera to show both markers after a brief delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_mapController != null && !_initialCameraSet) {
            _animateCameraToShowBothMarkers(position);
            _initialCameraSet = true;
          }
        });

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error initializing current location: $e');
    }
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;

    // If we already have current position, animate camera
    if (_currentPosition != null && !_initialCameraSet) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _animateCameraToShowBothMarkers(_currentPosition!);
        _initialCameraSet = true;
      });
    }
  }

  void _addDestinationMarker() {
    _markers.add(
      MapControllerService.createDestinationMarker(
        lat: destinationLat,
        lng: destinationLng,
        title: 'ສະຖານທີ່ທີ່ມອບໝາຍ',
        snippet: '',
      ),
    );
    notifyListeners();
  }

  /// NEW: Separate method to animate camera to show both markers
  void _animateCameraToShowBothMarkers(Position currentPosition) {
    if (_mapController == null) return;

    try {
      MapControllerService.animateCameraToShowBothMarkers(
        mapController: _mapController!,
        currentPosition: currentPosition,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
      );
    } catch (e) {
      debugPrint('Error animating camera: $e');
    }
  }

  Future<Map<String, dynamic>?> getDirectionsAndDrawRoute(
    Position position,
  ) async {
    _currentPosition = position;
    _addCurrentLocationMarker(position);

    final result = await GoogleMapsService.getDirections(
      originLat: position.latitude,
      originLng: position.longitude,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    );

    if (result != null && result['success']) {
      _steps = result['steps'];
      _remainingDistance = result['distance'];

      _polylines.clear();
      _polylines.add(
        GoogleMapsService.createPolylineFromEncoded(result['polyline']),
      );

      // Animate camera after getting directions
      if (_mapController != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _animateCameraToShowBothMarkers(position);
        });
      }

      notifyListeners();
      return {'distance': result['distance'], 'duration': result['duration']};
    } else {
      // Fallback: straight line
      _polylines.clear();
      _polylines.add(
        GoogleMapsService.createStraightLine(
          startLat: position.latitude,
          startLng: position.longitude,
          endLat: destinationLat,
          endLng: destinationLng,
        ),
      );

      // Animate camera even with straight line
      if (_mapController != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _animateCameraToShowBothMarkers(position);
        });
      }

      notifyListeners();
      return null;
    }
  }

  Future<void> startNavigation(Position currentPosition) async {
    _currentPosition = currentPosition;
    _isNavigating = true;
    notifyListeners();

    await BackgroundLocationService.startTracking(
      taskId: taskId,
      taskTitle: taskTitle,
    );

    _positionStreamSubscription = LocationService.getPositionStream().listen(
      _updateNavigationWithNewPosition,
    );

    _backgroundLocationSubscription = BackgroundLocationService.service
        .on('update')
        .listen((event) {
          if (event != null) {
            final data = event as Map<String, dynamic>;
            Position newPosition = Position(
              latitude: data['latitude'],
              longitude: data['longitude'],
              timestamp: DateTime.parse(data['timestamp']),
              accuracy: 0,
              altitude: 0,
              heading: data['heading'] ?? 0,
              speed: data['speed'] ?? 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
            _updateNavigationWithNewPosition(newPosition);
          }
        });

    _updateCurrentInstruction();
  }

  Future<void> stopNavigation() async {
    await BackgroundLocationService.stopTracking();
    _positionStreamSubscription?.cancel();
    _backgroundLocationSubscription?.cancel();

    _isNavigating = false;
    _currentInstruction = '';
    notifyListeners();
  }

  bool checkIfArrived() {
    if (_currentPosition == null) return false;

    return NavigationService.isDestinationReached(
      currentPosition: _currentPosition!,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    );
  }

  void _updateNavigationWithNewPosition(Position position) {
    _currentPosition = position;
    _addCurrentLocationMarker(position);

    double distanceToDestination = NavigationService.calculateRemainingDistance(
      currentPosition: position,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    );

    _remainingDistance = distanceToDestination;

    if (checkIfArrived()) {
      stopNavigation();
      notifyListeners();
      return;
    }

    _updateCurrentInstruction();

    if (_mapController != null) {
      MapControllerService.animateCameraToFollowUser(
        mapController: _mapController!,
        position: position,
      );
    }

    DatabaseService.saveLocationTracking(
      taskId: taskId,
      position: position,
      distanceToDestination: distanceToDestination,
      status: 'navigating',
    );

    notifyListeners();
  }

  void _addCurrentLocationMarker(Position position) {
    _markers.removeWhere((m) => m.markerId.value == 'current_location');
    _markers.add(
      MapControllerService.createCurrentLocationMarker(
        position: position,
        customIcon: _driverIcon,
      ),
    );
    notifyListeners(); // Add this to ensure UI updates
  }

  void _updateCurrentInstruction() {
    if (_steps.isEmpty || _currentPosition == null) return;

    final instruction = NavigationService.getCurrentInstruction(
      currentPosition: _currentPosition!,
      steps: _steps,
    );

    if (instruction['index'] >= 0) {
      _currentInstruction = instruction['instruction'];
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _backgroundLocationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
