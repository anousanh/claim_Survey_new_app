import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
// Import the background service
import 'package:claim_survey_app/services/background_location_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskTitle;
  final double assignedLat;
  final double assignedLng;
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskTitle,
    required this.assignedLat,
    required this.assignedLng,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  static const String _googleApiKey = 'AIzaSyAb6DE0lT_HRUPvan8fcsH_lwUKUfEeXDw';

  bool _isLoading = false;
  bool _isCheckedIn = false;
  bool _isNavigating = false;
  Position? _currentPosition;
  double? _distanceInKm;
  String? _duration;
  String _statusMessage = '';
  String _currentInstruction = '';
  double _remainingDistance = 0;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _driverIcon;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription? _backgroundLocationSubscription; // For background updates
  List<Map<String, dynamic>> _steps = [];
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _backgroundLocationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCustomMarker() async {
    _driverIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueBlue,
    );
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = 'ກະລຸນາເປີດ GPS';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = 'ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງສະຖານທີ່';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage = 'ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງສະຖານທີ່ໃນການຕັ້ງຄ່າ';
      });
      return;
    }

    _addAssignedLocationMarker();
  }

  void _addAssignedLocationMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('assigned_location'),
          position: LatLng(widget.assignedLat, widget.assignedLng),
          infoWindow: const InfoWindow(
            title: 'ສະຖານທີ່ທີ່ມອບໝາຍ',
            snippet: 'ຈຸດໝາຍປາຍທາງ',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      setState(() {
        _statusMessage = 'ບໍ່ສາມາດເອົາສະຖານທີ່ປັດຈຸບັນໄດ້: $e';
      });
      return null;
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  Future<void> _handleCheckIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'ກຳລັງກວດສອບສະຖານທີ່...';
    });

    Position? position = await _getCurrentLocation();

    if (position == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    double distance = _calculateDistance(
      widget.assignedLat,
      widget.assignedLng,
      position.latitude,
      position.longitude,
    );

    setState(() {
      _currentPosition = position;
      _distanceInKm = distance;
      _isCheckedIn = true;
      _statusMessage = 'ກຳລັງໂຫຼດເສັ້ນທາງ...';
    });

    _addCurrentLocationMarker(position);
    await _getDirectionsAndDrawRoute(position);

    setState(() {
      _isLoading = false;
      _statusMessage = 'ເຂົ້າເຮັດວຽກສຳເລັດແລ້ວ!';
    });

    await _saveLocationToDatabase(position, distance);
  }

  void _addCurrentLocationMarker(Position position) {
    _markers.removeWhere((m) => m.markerId.value == 'current_location');
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(
            title: 'ສະຖານທີ່ປັດຈຸບັນ',
            snippet: 'ຕຳແໜ່ງຂອງຂ້ອຍ',
          ),
          icon:
              _driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          rotation: position.heading,
        ),
      );
    });
  }

  Future<void> _getDirectionsAndDrawRoute(Position position) async {
    final origin = '${position.latitude},${position.longitude}';
    final destination = '${widget.assignedLat},${widget.assignedLng}';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=$origin&destination=$destination&key=$_googleApiKey&mode=driving',
    );

    print('========== DIRECTIONS API DEBUG ==========');
    print('From: $origin');
    print('To: $destination');

    try {
      final response = await http.get(url);
      print('HTTP Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Status: ${data['status']}');

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = _decodePolyline(
            route['overview_polyline']['points'],
          );

          final leg = route['legs'][0];
          _steps = List<Map<String, dynamic>>.from(leg['steps']);

          print(
            'SUCCESS! ${polylinePoints.length} points, ${leg['distance']['text']}, ${leg['duration']['text']}',
          );

          setState(() {
            _distanceInKm = leg['distance']['value'] / 1000.0;
            _duration = leg['duration']['text'];
            _remainingDistance = _distanceInKm!;

            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylinePoints,
                color: const Color(0xFF0099FF),
                width: 5,
              ),
            );
          });

          _animateCameraToShowBothMarkers(position);
        } else {
          print('API ERROR: ${data['status']}');
          if (data['error_message'] != null) {
            print('Message: ${data['error_message']}');
          }
          _drawStraightLine(position);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('API Error: ${data['status']}')),
            );
          }
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        _drawStraightLine(position);
      }
    } catch (e) {
      print('EXCEPTION: $e');
      _drawStraightLine(position);
    }
    print('========== END DEBUG ==========');
  }

  List<LatLng> _decodePolyline(String encoded) {
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

  void _drawStraightLine(Position position) {
    print('Drawing fallback straight line');
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(position.latitude, position.longitude),
            LatLng(widget.assignedLat, widget.assignedLng),
          ],
          color: const Color(0xFF0099FF),
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    });
    _animateCameraToShowBothMarkers(position);
  }

  void _animateCameraToShowBothMarkers(Position position) {
    if (_mapController == null) return;

    double minLat = position.latitude < widget.assignedLat
        ? position.latitude
        : widget.assignedLat;
    double maxLat = position.latitude > widget.assignedLat
        ? position.latitude
        : widget.assignedLat;
    double minLng = position.longitude < widget.assignedLng
        ? position.longitude
        : widget.assignedLng;
    double maxLng = position.longitude > widget.assignedLng
        ? position.longitude
        : widget.assignedLng;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  // UPDATED METHOD - Start navigation with background service
  void _startNavigation() async {
    if (_currentPosition == null) return;

    setState(() {
      _isNavigating = true;
      _statusMessage = 'ກຳລັງນຳທາງ...';
    });

    // Start background location service
    await BackgroundLocationService.startTracking(
      taskId: widget.taskId,
      taskTitle: widget.taskTitle,
    );

    // Listen to location updates from background service
    _backgroundLocationSubscription = BackgroundLocationService.service
        .on('update')
        .listen((event) {
          if (event != null && mounted) {
            final data = event;

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

  // UPDATED METHOD - Stop navigation and background service
  void _stopNavigation() async {
    // Stop background service
    await BackgroundLocationService.stopTracking();

    // Cancel subscription
    _backgroundLocationSubscription?.cancel();
    _backgroundLocationSubscription = null;

    setState(() {
      _isNavigating = false;
      _statusMessage = 'ຢຸດການນຳທາງ';
      _currentInstruction = '';
    });
  }

  void _updateNavigationWithNewPosition(Position position) {
    setState(() {
      _currentPosition = position;
    });

    _addCurrentLocationMarker(position);

    double distanceToDestination = _calculateDistance(
      position.latitude,
      position.longitude,
      widget.assignedLat,
      widget.assignedLng,
    );

    setState(() {
      _remainingDistance = distanceToDestination;
    });

    if (distanceToDestination < 0.05) {
      _stopNavigation();
      setState(() {
        _statusMessage = 'ເຖິງຈຸດໝາຍແລ້ວ!';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ທ່ານໄດ້ເຖິງຈຸດໝາຍແລ້ວ!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    _updateCurrentInstruction();
    _updateCameraToFollowUser(position);
    _saveLocationToDatabase(position, distanceToDestination);
  }

  void _updateCurrentInstruction() {
    if (_steps.isEmpty) return;

    for (int i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      final stepLat = step['end_location']['lat'];
      final stepLng = step['end_location']['lng'];

      if (_currentPosition != null) {
        double distanceToStep = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          stepLat,
          stepLng,
        );

        if (distanceToStep < 0.1) {
          setState(() {
            _currentStepIndex = i;
            _currentInstruction = _removeHtmlTags(step['html_instructions']);
          });
          break;
        }
      }
    }
  }

  String _removeHtmlTags(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  void _updateCameraToFollowUser(Position position) {
    if (_mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 17,
          bearing: position.heading,
          tilt: 45,
        ),
      ),
    );
  }

  Future<void> _saveLocationToDatabase(
    Position position,
    double distance,
  ) async {
    print(
      'Saving: ${position.latitude}, ${position.longitude}, Distance: $distance km',
    );
  }

  Future<void> _handleAcceptCase() async {
    if (!_isCheckedIn || _currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ກະລຸນາເຂົ້າເຮັດວຽກກ່ອນ')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ຮັບຄະດີສຳເລັດແລ້ວ!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0099FF),
        elevation: 0,
        title: Text(
          widget.taskTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: _isNavigating ? 4 : 3,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(widget.assignedLat, widget.assignedLng),
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  compassEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                ),
                if (_isNavigating && _currentInstruction.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.navigation,
                                color: Color(0xFF0099FF),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _currentInstruction,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ເຫຼືອ ${_remainingDistance.toStringAsFixed(2)} ກມ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: _isNavigating ? 1 : 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isCheckedIn && _distanceInKm != null && !_isNavigating)
                      _buildInfoCard(
                        'ໄລຍະຫ່າງ',
                        '${_distanceInKm!.toStringAsFixed(2)} ກມ${_duration != null ? ' • $_duration' : ''}',
                        Icons.social_distance,
                        Colors.orange,
                      ),
                    if (_isCheckedIn && _distanceInKm != null && !_isNavigating)
                      const SizedBox(height: 12),
                    if (_statusMessage.isNotEmpty && !_isNavigating)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isCheckedIn
                              ? Colors.green[50]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCheckedIn ? Colors.green : Colors.orange,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isCheckedIn ? Icons.check_circle : Icons.info,
                              color: _isCheckedIn
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  color: _isCheckedIn
                                      ? Colors.green[900]
                                      : Colors.orange[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_isNavigating) const SizedBox(height: 16),
                    if (!_isCheckedIn)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleCheckIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0099FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'ຄຳນວນໄລຍະທາງ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    if (_isCheckedIn && !_isNavigating) ...[
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleAcceptCase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ຮັບຄະດີ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _startNavigation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0099FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.navigation, color: Colors.white),
                        label: const Text(
                          'ເລີ່ມນຳທາງ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    if (_isNavigating) ...[
                      ElevatedButton.icon(
                        onPressed: _stopNavigation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.stop, color: Colors.white),
                        label: const Text(
                          'ຢຸດນຳທາງ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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
