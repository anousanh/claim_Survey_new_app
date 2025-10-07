// lib/screens/case_detail_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../model/task_model.dart';
import '../services/background_location_service.dart';
import '../services/database_service.dart';
import '../services/google_maps_service.dart';
import '../services/location_service.dart';
import '../services/map_controller_service.dart';
import '../services/navigation_service.dart';

class CaseDetailScreen extends StatefulWidget {
  final Task task;
  const CaseDetailScreen({super.key, required this.task});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late TaskStatus _currentStatus;
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
  StreamSubscription? _backgroundLocationSubscription;
  List<Map<String, dynamic>> _steps = [];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task.status;
    _loadCustomMarker();
    if (widget.task.lat != null && widget.task.lng != null) {
      _initializeLocation();
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _backgroundLocationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCustomMarker() async {
    _driverIcon = await MapControllerService.loadCustomMarkerIcon(
      hue: BitmapDescriptor.hueBlue,
    );
  }

  Future<void> _initializeLocation() async {
    final result = await LocationService.checkLocationPermission();

    if (!result['success']) {
      setState(() {
        _statusMessage = result['message'];
      });
      return;
    }

    _addDestinationMarker();
  }

  void _addDestinationMarker() {
    if (widget.task.lat == null || widget.task.lng == null) return;

    setState(() {
      _markers.add(
        MapControllerService.createDestinationMarker(
          lat: widget.task.lat!,
          lng: widget.task.lng!,
          title: 'ສະຖານທີ່ທີ່ມອບໝາຍ',
          snippet: widget.task.location,
        ),
      );
    });
  }

  Future<void> _handleCheckIn() async {
    if (widget.task.lat == null || widget.task.lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ບໍ່ມີຂໍ້ມູນສະຖານທີ່')));
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'ກຳລັງກວດສອບສະຖານທີ່...';
    });

    Position? position = await LocationService.getCurrentLocation();

    if (position == null) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'ບໍ່ສາມາດເອົາສະຖານທີ່ປັດຈຸບັນໄດ້';
      });
      return;
    }

    double distance = LocationService.calculateDistance(
      widget.task.lat!,
      widget.task.lng!,
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

    // Save check-in to database
    await DatabaseService.saveCheckIn(
      taskId: widget.task.policyNumber,
      position: position,
      distance: distance,
    );
  }

  void _addCurrentLocationMarker(Position position) {
    _markers.removeWhere((m) => m.markerId.value == 'current_location');
    setState(() {
      _markers.add(
        MapControllerService.createCurrentLocationMarker(
          position: position,
          customIcon: _driverIcon,
        ),
      );
    });
  }

  Future<void> _getDirectionsAndDrawRoute(Position position) async {
    final result = await GoogleMapsService.getDirections(
      originLat: position.latitude,
      originLng: position.longitude,
      destinationLat: widget.task.lat!,
      destinationLng: widget.task.lng!,
    );

    if (result != null && result['success']) {
      _steps = result['steps'];

      setState(() {
        _distanceInKm = result['distance'];
        _duration = result['duration'];
        _remainingDistance = _distanceInKm!;

        _polylines.clear();
        _polylines.add(
          GoogleMapsService.createPolylineFromEncoded(result['polyline']),
        );
      });

      if (_mapController != null) {
        MapControllerService.animateCameraToShowBothMarkers(
          mapController: _mapController!,
          currentPosition: position,
          destinationLat: widget.task.lat!,
          destinationLng: widget.task.lng!,
        );
      }
    } else {
      // Fallback to straight line
      setState(() {
        _polylines.clear();
        _polylines.add(
          GoogleMapsService.createStraightLine(
            startLat: position.latitude,
            startLng: position.longitude,
            endLat: widget.task.lat!,
            endLng: widget.task.lng!,
          ),
        );
      });

      if (_mapController != null) {
        MapControllerService.animateCameraToShowBothMarkers(
          mapController: _mapController!,
          currentPosition: position,
          destinationLat: widget.task.lat!,
          destinationLng: widget.task.lng!,
        );
      }
    }
  }

  void _startNavigation() async {
    if (_currentPosition == null) return;

    setState(() {
      _isNavigating = true;
      _statusMessage = 'ກຳລັງນຳທາງ...';
    });

    // Start background location service
    await BackgroundLocationService.startTracking(
      taskId: widget.task.policyNumber,
      taskTitle: widget.task.title,
    );

    // Start foreground tracking
    _positionStreamSubscription = LocationService.getPositionStream().listen((
      Position position,
    ) {
      _updateNavigationWithNewPosition(position);
    });

    // Listen to background updates
    _backgroundLocationSubscription = BackgroundLocationService.service
        .on('update')
        .listen((event) {
          if (event != null && mounted) {
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

  void _stopNavigation() async {
    await BackgroundLocationService.stopTracking();

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

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

    // Calculate remaining distance
    double distanceToDestination = NavigationService.calculateRemainingDistance(
      currentPosition: position,
      destinationLat: widget.task.lat!,
      destinationLng: widget.task.lng!,
    );

    setState(() {
      _remainingDistance = distanceToDestination;
    });

    // Check if destination reached
    if (NavigationService.isDestinationReached(
      currentPosition: position,
      destinationLat: widget.task.lat!,
      destinationLng: widget.task.lng!,
    )) {
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

    // Update camera to follow user
    if (_mapController != null) {
      MapControllerService.animateCameraToFollowUser(
        mapController: _mapController!,
        position: position,
      );
    }

    // Save location to database
    DatabaseService.saveLocationTracking(
      taskId: widget.task.policyNumber,
      position: position,
      distanceToDestination: distanceToDestination,
      status: _isNavigating ? 'navigating' : 'tracking',
    );
  }

  void _updateCurrentInstruction() {
    if (_steps.isEmpty || _currentPosition == null) return;

    final instruction = NavigationService.getCurrentInstruction(
      currentPosition: _currentPosition!,
      steps: _steps,
    );

    if (instruction['index'] >= 0) {
      setState(() {
        _currentInstruction = instruction['instruction'];
      });
    }
  }

  void _updateStatus(TaskStatus newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });

    DatabaseService.updateTaskStatus(
      taskId: widget.task.policyNumber,
      status: newStatus.toString(),
      position: _currentPosition,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ສະຖານະຖືກປ່ຽນແປງແລ້ວ'),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }

  void _confirmStatusChange(TaskStatus newStatus, String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ຢືນຢັນການປ່ຽນສະຖານະ'),
          content: Text('ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການ $action?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ຍົກເລີກ'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateStatus(newStatus);
              },
              child: const Text(
                'ຢືນຢັນ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // During navigation, use fixed map at top with scrollable details below
    if (_isNavigating) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Fixed Map Section during navigation
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  _buildMap(),
                  if (_currentInstruction.isNotEmpty)
                    _buildNavigationInstructionCard(),
                ],
              ),
            ),
            // Scrollable Details Section
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(children: [_buildStopNavigationButton()]),
              ),
            ),
          ],
        ),
      );
    }

    // Normal mode: Everything scrollable
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Section (scrollable)
            if (widget.task.lat != null && widget.task.lng != null)
              SizedBox(height: 300, child: _buildMap()),

            // All Details Below (scrollable)
            _buildHeaderSection(),

            // Location Check-in Status
            if (widget.task.lat != null && widget.task.lng != null)
              _buildCheckInSection(),

            // Customer Info Section
            _buildSection('ຂໍ້ມູນລູກຄ້າ', Icons.person, [
              _buildInfoRow('ຊື່ລູກຄ້າ:', widget.task.customerName),
              _buildInfoRow(
                'ປະເພດປະກັນໄພ:',
                _getPolicyTypeName(widget.task.policyType),
              ),
              _buildInfoRow('ສະຖານທີ່:', widget.task.location),
              _buildInfoRow(
                'ວັນທີ່ມອບໝາຍ:',
                _formatDate(widget.task.assignedDate),
              ),
            ]),

            // Description Section
            if (widget.task.description != null)
              _buildSection('ລາຍລະອຽດເພີ່ມເຕີມ', Icons.description, [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    widget.task.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              ]),

            // Navigation Button
            if (_isCheckedIn && widget.task.lat != null)
              _buildNavigationButton(),

            // Action Buttons
            _buildActionButtons(),

            // Additional Actions
            _buildAdditionalActions(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0099FF),
      title: const Text('ລາຍລະອຽດຄະດີ', style: TextStyle(color: Colors.white)),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (widget.task.lat != null &&
            widget.task.lng != null &&
            !_isNavigating)
          IconButton(
            icon: const Icon(Icons.navigation),
            onPressed: _isCheckedIn ? _startNavigation : _handleCheckIn,
            tooltip: 'ນຳທາງໄປຫາສະຖານທີ່',
          ),
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('ໂທຫາລູກຄ້າ')));
          },
          tooltip: 'ໂທຫາລູກຄ້າ',
        ),
      ],
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.task.lat!, widget.task.lng!),
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
    );
  }

  Widget _buildNavigationInstructionCard() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
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
              NavigationService.getNavigationStatusMessage(_remainingDistance),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.task.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ເລກທີກະທຳຜິດ: ${widget.task.policyNumber}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _getStatusChip(_currentStatus),
              const SizedBox(width: 12),
              if (widget.task.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.priority_high,
                        size: 16,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ດ່ວນ',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInSection() {
    if (_isNavigating) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isCheckedIn && _distanceInKm != null)
            _buildInfoCard(
              'ໄລຍະຫ່າງ',
              '${_distanceInKm!.toStringAsFixed(2)} ກມ${_duration != null ? ' • $_duration' : ''}',
              Icons.social_distance,
              Colors.orange,
            ),
          if (_statusMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCheckedIn ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCheckedIn ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCheckedIn ? Icons.check_circle : Icons.info,
                    color: _isCheckedIn ? Colors.green : Colors.orange,
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
          if (!_isCheckedIn)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: double.infinity,
              child: ElevatedButton(
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
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
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
    );
  }

  Widget _buildStopNavigationButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
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
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ປ່ຽນສະຖານະຄະດີ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 16),
          if (_currentStatus == TaskStatus.newTask) ...[
            _buildActionButton(
              'ຮັບວຽກ',
              Colors.blue,
              Icons.check_circle,
              () => _confirmStatusChange(TaskStatus.inProgress, 'ຮັບວຽກນີ້'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'ປະຕິເສດ',
              Colors.red,
              Icons.cancel,
              () => _confirmStatusChange(TaskStatus.cancelled, 'ປະຕິເສດວຽກນີ້'),
            ),
          ] else if (_currentStatus == TaskStatus.inProgress) ...[
            _buildActionButton(
              'ສຳເລັດວຽກ',
              Colors.green,
              Icons.task_alt,
              () => _confirmStatusChange(TaskStatus.completed, 'ສຳເລັດວຽກນີ້'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'ຍົກເລີກ',
              Colors.orange,
              Icons.pause_circle,
              () => _confirmStatusChange(TaskStatus.cancelled, 'ຍົກເລີກວຽກນີ້'),
            ),
          ] else if (_currentStatus == TaskStatus.completed) ...[
            _buildCompletedStatusCard(),
          ] else if (_currentStatus == TaskStatus.cancelled) ...[
            _buildCancelledStatusCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 24),
          const SizedBox(width: 12),
          Text(
            'ວຽກນີ້ສຳເລັດແລ້ວ',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel, color: Colors.red[700], size: 24),
          const SizedBox(width: 12),
          Text(
            'ວຽກນີ້ຖືກຍົກເລີກ',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ເພີ່ມຮູບພາບ')),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('ເພີ່ມຮູບ'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ເພີ່ມບັນທຶກ')),
                    );
                  },
                  icon: const Icon(Icons.note_add),
                  label: const Text('ເພີ່ມບັນທຶກ'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0099FF), size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3436),
                fontWeight: FontWeight.w600,
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

  Widget _buildActionButton(
    String text,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPolicyTypeName(String type) {
    switch (type) {
      case 'car':
        return 'ປະກັນໄພລົດ';
      case 'home':
        return 'ປະກັນໄພເຮືອນ';
      case 'health':
        return 'ປະກັນໄພສຸຂະພາບ';
      default:
        return type;
    }
  }

  Widget _getStatusChip(TaskStatus status) {
    String text;
    Color color;
    IconData icon;

    switch (status) {
      case TaskStatus.newTask:
        text = 'ໃໝ່';
        color = Colors.blue;
        icon = Icons.fiber_new;
        break;
      case TaskStatus.inProgress:
        text = 'ກຳລັງດຳເນີນການ';
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;
      case TaskStatus.completed:
        text = 'ສຳເລັດ';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case TaskStatus.cancelled:
        text = 'ຍົກເລີກ';
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
