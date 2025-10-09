// lib/screens/case_detail_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../model/task_model.dart';
import '../services/api/api_service.dart';
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
  final ApiService _apiService = ApiService();

  late Task _task; // Mutable copy of task
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

  final List<ActivityStep> _activitySteps = [];

  final Map<String, bool> _actionCompleted = {
    'documents': false,
    'estimate': false,
    'responsible': false,
    'garage': false,
    'opponent': false,
    'agreement': false,
    'police': false,
  };

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _currentStatus = widget.task.status;
    _loadCustomMarker();
    _loadTaskFromAPI();
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

  /// Load task data from API
  Future<void> _loadTaskFromAPI() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final claimNo = int.tryParse(widget.task.policyNumber);
      if (claimNo == null) {
        throw Exception('Invalid claim number');
      }

      final response = await _apiService.getTaskList(
        status: 'claimNo',
        taskType: widget.task.taskType ?? 'SOLVING',
      );

      if (response.isSuccess) {
        // Parse activity steps
        final steps = response.getDataArray<ActivityStep>(
          'steps',
          (json) => ActivityStep.fromJson(json),
        );

        // Parse tasks
        final tasks = response.getDataArray<Task>(
          'claims',
          (json) => Task.fromJson(json),
        );

        if (tasks.isNotEmpty) {
          setState(() {
            _task = tasks[0];
            _currentStatus = tasks[0].status;
            _activitySteps.clear();
            _activitySteps.addAll(steps);

            // Update action completion status
            _actionCompleted['documents'] = tasks[0].btnDocuments ?? false;
            _actionCompleted['estimate'] = tasks[0].btnCostEstimate ?? false;
            _actionCompleted['responsible'] =
                tasks[0].btnResponsibility ?? false;
            _actionCompleted['garage'] = tasks[0].btnGarageRequest ?? false;
            _actionCompleted['opponent'] = tasks[0].btnOpponent ?? false;
            _actionCompleted['agreement'] = tasks[0].btnAgreement ?? false;
            _actionCompleted['police'] = tasks[0].btnPolice ?? false;
          });
        }

        _showMessage('ໂຫຼດຂໍ້ມູນສຳເລັດ', isError: false);
      } else {
        _showMessage(
          'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້: ${response.message}',
          isError: true,
        );
      }
    } catch (e) {
      print('Error loading task: $e');
      _showMessage('ເກີດຂໍ້ຜິດພາດ: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    if (_task.lat == null || _task.lng == null) return;

    setState(() {
      _markers.add(
        MapControllerService.createDestinationMarker(
          lat: _task.lat!,
          lng: _task.lng!,
          title: 'ສະຖານທີ່ທີ່ມອບໝາຍ',
          snippet: _task.location,
        ),
      );
    });
  }

  /// Refresh data from API (Pull to refresh)
  Future<void> _refreshData() async {
    await _loadTaskFromAPI();
  }

  /// Handle Accept Task
  Future<void> _handleAcceptTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final taskNo = int.tryParse(_task.policyNumber);
      if (taskNo == null) throw Exception('Invalid task number');

      final response = await _apiService.taskResponse(
        taskNo: taskNo,
        isAccepted: true,
        remark: '',
      );

      if (response.isSuccess) {
        _showMessage('ຮັບວຽກສຳເລັດ', isError: false);
        await _loadTaskFromAPI();
      } else {
        _showMessage('ບໍ່ສາມາດຮັບວຽກໄດ້: ${response.message}', isError: true);
      }
    } catch (e) {
      _showMessage('ເກີດຂໍ້ຜິດພາດ: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Handle Reject Task
  Future<void> _handleRejectTask(String remark) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final taskNo = int.tryParse(_task.policyNumber);
      if (taskNo == null) throw Exception('Invalid task number');

      final response = await _apiService.taskResponse(
        taskNo: taskNo,
        isAccepted: false,
        remark: remark,
      );

      if (response.isSuccess) {
        _showMessage('ປະຕິເສດວຽກສຳເລັດ', isError: false);
        Navigator.pop(context, true);
      } else {
        _showMessage(
          'ບໍ່ສາມາດປະຕິເສດວຽກໄດ້: ${response.message}',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage('ເກີດຂໍ້ຜິດພາດ: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Handle Check-in (Arrived at site)
  Future<void> _handleCheckIn() async {
    if (_task.lat == null || _task.lng == null) {
      _showMessage('ບໍ່ມີຂໍ້ມູນສະຖານທີ່', isError: true);
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
      _task.lat!,
      _task.lng!,
      position.latitude,
      position.longitude,
    );

    // Send to API
    try {
      final claimNo = int.tryParse(_task.policyNumber);
      if (claimNo != null) {
        final response = await _apiService.(
          claimNo: claimNo,
          latitude: position.latitude,
          longitude: position.longitude,
          distance: distance,
          isArrived: true,
        );

        if (!response.isSuccess) {
          _showMessage(
            'ບໍ່ສາມາດບັນທຶກຕຳແໜ່ງໄດ້: ${response.message}',
            isError: true,
          );
        }
      }
    } catch (e) {
      print('Error sending check-in: $e');
    }

    setState(() {
      _currentPosition = position;
      _distanceInKm = distance;
      _isCheckedIn = true;
      _statusMessage = 'ກຳລັງໂຫຼດເສັ້ນທາງ...';
    });

    _addCurrentLocationMarker(position);
    await _getDirectionsAndDrawRoute(position);

    _activitySteps.add(
      ActivityStep(
        date: DateTime.now(),
        description: 'ເຂົ້າເຮັດວຽກແລ້ວ (${distance.toStringAsFixed(2)} ກມ)',
        icon: Icons.location_on,
      ),
    );

    setState(() {
      _isLoading = false;
      _statusMessage = 'ເຂົ້າເຮັດວຽກສຳເລັດແລ້ວ!';
    });

    await DatabaseService.saveCheckIn(
      taskId: _task.policyNumber,
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
      destinationLat: _task.lat!,
      destinationLng: _task.lng!,
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
          destinationLat: _task.lat!,
          destinationLng: _task.lng!,
        );
      }
    } else {
      setState(() {
        _polylines.clear();
        _polylines.add(
          GoogleMapsService.createStraightLine(
            startLat: position.latitude,
            startLng: position.longitude,
            endLat: _task.lat!,
            endLng: _task.lng!,
          ),
        );
      });

      if (_mapController != null) {
        MapControllerService.animateCameraToShowBothMarkers(
          mapController: _mapController!,
          currentPosition: position,
          destinationLat: _task.lat!,
          destinationLng: _task.lng!,
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

    await BackgroundLocationService.startTracking(
      taskId: _task.policyNumber,
      taskTitle: _task.title,
    );

    _positionStreamSubscription = LocationService.getPositionStream().listen((
      Position position,
    ) {
      _updateNavigationWithNewPosition(position);
    });

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

    double distanceToDestination = NavigationService.calculateRemainingDistance(
      currentPosition: position,
      destinationLat: _task.lat!,
      destinationLng: _task.lng!,
    );

    setState(() {
      _remainingDistance = distanceToDestination;
    });

    if (NavigationService.isDestinationReached(
      currentPosition: position,
      destinationLat: _task.lat!,
      destinationLng: _task.lng!,
    )) {
      _stopNavigation();
      setState(() {
        _statusMessage = 'ເຖິງຈຸດໝາຍແລ້ວ!';
      });

      _activitySteps.add(
        ActivityStep(
          date: DateTime.now(),
          description: 'ເຖິງຈຸດໝາຍແລ້ວ',
          icon: Icons.flag,
        ),
      );

      _showMessage('ທ່ານໄດ້ເຖິງຈຸດໝາຍແລ້ວ!', isError: false);
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
      taskId: _task.policyNumber,
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

  /// Update task status
  Future<void> _updateStatus(TaskStatus newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // If completing task, call finish API
      if (newStatus == TaskStatus.completed) {
        final claimNo = int.tryParse(_task.policyNumber);
        final taskNo = _task.taskNo ?? claimNo;

        if (claimNo != null && taskNo != null) {
          final response = await _apiService.finishMotorTask(
            claimNo: claimNo,
            taskNo: taskNo,
            taskType: _task.taskType ?? 'SOLVING',
          );

          if (!response.isSuccess) {
            _showMessage('ບໍ່ສຳເລັດ: ${response.message}', isError: true);
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
      }

      setState(() {
        _currentStatus = newStatus;
      });

      _activitySteps.add(
        ActivityStep(
          date: DateTime.now(),
          description: 'ປ່ຽນສະຖານະເປັນ: ${_getStatusText(newStatus)}',
          icon: Icons.update,
        ),
      );

      await DatabaseService.updateTaskStatus(
        taskId: _task.policyNumber,
        status: newStatus.toString(),
        position: _currentPosition,
      );

      _showMessage('ສະຖານະຖືກປ່ຽນແປງແລ້ວ', isError: false);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      _showMessage('ເກີດຂໍ້ຜິດພາດ: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.newTask:
        return 'ໃໝ່';
      case TaskStatus.inProgress:
        return 'ກຳລັງດຳເນີນການ';
      case TaskStatus.completed:
        return 'ສຳເລັດ';
      case TaskStatus.cancelled:
        return 'ຍົກເລີກ';
    }
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
                if (newStatus == TaskStatus.inProgress) {
                  _handleAcceptTask();
                } else {
                  _updateStatus(newStatus);
                }
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

  void _showRejectDialog() {
    final TextEditingController remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ປະຕິເສດວຽກ'),
          content: TextField(
            controller: remarkController,
            decoration: const InputDecoration(
              labelText: 'ເຫດຜົນໃນການປະຕິເສດ',
              hintText: 'ກະລຸນາໃສ່ເຫດຜົນ...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ຍົກເລີກ'),
            ),
            TextButton(
              onPressed: () {
                final remark = remarkController.text.trim();
                if (remark.isEmpty) {
                  _showMessage('ກະລຸນາໃສ່ເຫດຜົນ', isError: true);
                  return;
                }
                Navigator.of(context).pop();
                _handleRejectTask(remark);
              },
              child: const Text(
                'ປະຕິເສດ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFinishTaskDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ສຳເລັດວຽກ'),
          content: const Text(
            'ຕ້ອງການແຈ້ງສູນໃຫຍ່ວ່າທ່ານໄດ້ເຮັດວຽກໃນຄະດີນີ້ແລ້ວບໍ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ກັບຄືນ'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateStatus(TaskStatus.completed);
              },
              child: const Text(
                'ແມ່ນ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleActionButton(String action, String title) {
    setState(() {
      _actionCompleted[action] = true;
    });

    _activitySteps.add(
      ActivityStep(
        date: DateTime.now(),
        description: 'ບັນທຶກ$title',
        icon: Icons.check,
      ),
    );

    _showMessage('ບັນທຶກ$titleສຳເລັດ', isError: false);

    // TODO: Navigate to specific screen or call specific API
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Navigation Mode Layout
    if (_isNavigating) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
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
            Expanded(
              flex: 1,
              child: SingleChildScrollView(child: _buildStopNavigationButton()),
            ),
          ],
        ),
      );
    }

    // Normal Mode Layout (Scrollable)
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map Section
              if (_task.lat != null && _task.lng != null)
                SizedBox(height: 300, child: _buildMap()),

              // Header Section
              _buildHeaderSection(),

              // Check-in Section
              if (_task.lat != null && _task.lng != null)
                _buildCheckInSection(),

              // Customer Info
              _buildSection('ຂໍ້ມູນລູກຄ້າ', Icons.person, [
                _buildInfoRow('ຊື່ລູກຄ້າ:', _task.customerName),
                _buildInfoRow(
                  'ປະເພດປະກັນໄພ:',
                  _getPolicyTypeName(_task.policyType),
                ),
                _buildInfoRow('ສະຖານທີ່:', _task.location),
                _buildInfoRow('ວັນທີ່ມອບໝາຍ:', _formatDate(_task.assignedDate)),
                if (_task.declarerMobile != null)
                  _buildInfoRow('ເບີໂທ:', _task.declarerMobile!),
              ]),

              // Description
              if (_task.description != null)
                _buildSection('ລາຍລະອຽດເພີ່ມເຕີມ', Icons.description, [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _task.description!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ]),

              // Activity Timeline
              if (_activitySteps.isNotEmpty)
                _buildSection('ປະຫວັດການດຳເນີນງານ', Icons.history, [
                  _buildActivityTimeline(),
                ]),

              // Action Buttons Grid
              if (_isCheckedIn && _currentStatus == TaskStatus.inProgress)
                _buildActionButtonsGrid(),

              // Navigation Button
              if (_isCheckedIn && _task.lat != null && !_isNavigating)
                _buildNavigationButton(),

              // Status Change Buttons
              _buildActionButtons(),

              // Additional Actions
              _buildAdditionalActions(),
            ],
          ),
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
        if (_task.lat != null && _task.lng != null && !_isNavigating)
          IconButton(
            icon: const Icon(Icons.navigation),
            onPressed: _isCheckedIn ? _startNavigation : _handleCheckIn,
            tooltip: 'ນຳທາງໄປຫາສະຖານທີ່',
          ),
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            _showMessage(
              'ໂທຫາລູກຄ້າ: ${_task.declarerMobile ?? "N/A"}',
              isError: false,
            );
          },
          tooltip: 'ໂທຫາລູກຄ້າ',
        ),
        if (_currentStatus == TaskStatus.inProgress && !_isNavigating)
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: _showFinishTaskDialog,
            tooltip: 'ສຳເລັດວຽກ',
          ),
      ],
    );
  }

  Widget _buildMap() {
    if (_task.lat == null || _task.lng == null) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Text('ບໍ່ມີຂໍ້ມູນແຜນທີ່')),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_task.lat!, _task.lng!),
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

  Widget _buildActivityTimeline() {
    return Column(
      children: _activitySteps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == _activitySteps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0099FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.icon,
                    size: 20,
                    color: const Color(0xFF0099FF),
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 40, color: Colors.grey[300]),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(step.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildActionButtonsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ການດຳເນີນການ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildActionGridButton(
                'ເອກະສານ',
                Icons.upload_file,
                'documents',
                Colors.green,
              ),
              _buildActionGridButton(
                'ປະເມີນຄ່າໃຊ້ຈ່າຍ',
                Icons.attach_money,
                'estimate',
                const Color(0xFF0099FF),
              ),
              _buildActionGridButton(
                'ຜູ້ຮັບຜິດຊອບ',
                Icons.person_outline,
                'responsible',
                const Color(0xFF0099FF),
              ),
              _buildActionGridButton(
                'ຮ້ານຊ່ອມ',
                Icons.garage,
                'garage',
                const Color(0xFF0099FF),
              ),
              _buildActionGridButton(
                'ຄູ່ກະຕິ',
                Icons.people_outline,
                'opponent',
                const Color(0xFF0099FF),
              ),
              _buildActionGridButton(
                'ຂໍ້ຕົກລົງ',
                Icons.handshake,
                'agreement',
                const Color(0xFF0099FF),
              ),
              _buildActionGridButton(
                'ຕຳຫຼວດ',
                Icons.local_police,
                'police',
                const Color(0xFF0099FF),
              ),
              _buildActionGridButton(
                'ຄຳແນະນຳ',
                Icons.lightbulb_outline,
                'advice',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGridButton(
    String title,
    IconData icon,
    String actionKey,
    Color color,
  ) {
    final isCompleted = _actionCompleted[actionKey] ?? false;

    return OutlinedButton(
      onPressed: () => _handleActionButton(actionKey, title),
      style: OutlinedButton.styleFrom(
        backgroundColor: isCompleted ? color.withOpacity(0.1) : Colors.white,
        side: BorderSide(
          color: isCompleted ? color : Colors.grey[300]!,
          width: isCompleted ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : icon,
            size: 18,
            color: isCompleted ? color : Colors.grey[700],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isCompleted ? color : Colors.grey[700],
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
            _task.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ເລກທີກະທຳຜິດ: ${_task.policyNumber}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _getStatusChip(_currentStatus),
              const SizedBox(width: 12),
              if (_task.isUrgent)
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
      child: SizedBox(
        width: double.infinity,
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
      ),
    );
  }

  Widget _buildStopNavigationButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
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
              _showRejectDialog,
            ),
          ] else if (_currentStatus == TaskStatus.inProgress) ...[
            _buildActionButton(
              'ສຳເລັດວຽກ',
              Colors.green,
              Icons.task_alt,
              _showFinishTaskDialog,
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
                    _showMessage('ເພີ່ມຮູບພາບ', isError: false);
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
                    _showMessage('ເພີ່ມບັນທຶກ', isError: false);
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
        onPressed: _isLoading ? null : onPressed,
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

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'ຫາກໍ່';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ນາທີກ່ອນ';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ຊົ່ວໂມງກ່ອນ';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ມື້ກ່ອນ';
    } else {
      return _formatDate(date);
    }
  }
}

/// Activity Step Model
class ActivityStep {
  final DateTime date;
  final String description;
  final IconData icon;

  ActivityStep({
    required this.date,
    required this.description,
    required this.icon,
  });

  factory ActivityStep.fromJson(Map<String, dynamic> json) {
    return ActivityStep(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      description: json['step'] ?? json['description'] ?? '',
      icon: _getIconFromString(json['icon'] ?? 'info'),
    );
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'check':
      case 'check_circle':
        return Icons.check_circle;
      case 'location':
      case 'location_on':
        return Icons.location_on;
      case 'flag':
        return Icons.flag;
      case 'update':
        return Icons.update;
      case 'upload':
        return Icons.upload_file;
      case 'navigation':
        return Icons.navigation;
      default:
        return Icons.info;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'description': description,
      'icon': icon.toString(),
    };
  }
}
