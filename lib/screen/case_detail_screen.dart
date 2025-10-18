// lib/screens/case_detail_screen.dart
// Updated: Auto check-in on navigation + reordered layout

import 'package:claim_survey_app/model/task_model.dart';
import 'package:claim_survey_app/widgets/case_detail/navigation_card.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as Geolocator;
import 'package:provider/provider.dart';

import '../controllers/case_detail_controller.dart';
import '../controllers/navigation_controller.dart';
import '../services/location_service.dart';
import '../widgets/case_detail/action_buttons_grid.dart';
import '../widgets/case_detail/activity_timeline.dart';
import '../widgets/case_detail/case_header.dart';
import '../widgets/case_detail/check_in_section.dart';
import '../widgets/case_detail/customer_info_section.dart';
import '../widgets/case_detail/navigation_buttons.dart';
import '../widgets/case_detail/status_action_buttons.dart';

/// Refactored Case Detail Screen with Auto Check-in
class CaseDetailScreen extends StatefulWidget {
  final Task task;
  const CaseDetailScreen({super.key, required this.task});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late CaseDetailController _controller;
  NavigationController? _navController;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    print('🔵 1. initState started');

    _controller = CaseDetailController(widget.task);
    print('🔵 2. Controller created');

    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Load task data from API
    await _controller.loadTaskFromAPI();
    print('🔵 3. API data loaded');

    // Initialize navigation controller if coordinates exist
    if (widget.task.lat != null && widget.task.lng != null) {
      print(
        '🔵 4. Task has coordinates: ${widget.task.lat}, ${widget.task.lng}',
      );
      await _initNavController();
      print('🔵 5. NavController initialized');

      // Auto check-in
      await _performAutoCheckIn();
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _initNavController() async {
    print('🗺️ Creating NavController...');
    _navController = NavigationController(
      taskId: widget.task.claimNumber,
      taskTitle: widget.task.title,
      destinationLat: widget.task.lat!,
      destinationLng: widget.task.lng!,
    );

    print('🗺️ Initializing NavController...');
    await _navController!.initialize();
    print('🗺️ NavController initialized!');

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _performAutoCheckIn() async {
    print('🎯 Starting auto check-in...');

    // Check location permission
    final permResult = await LocationService.checkLocationPermission();
    if (!permResult['success']) {
      print('❌ Location permission denied');
      if (mounted) {
        if (permResult['openSettings'] == true) {
          _showOpenSettingsDialog(permResult['message']);
        } else {
          _showMessage(permResult['message'], isError: true);
        }
      }
      return;
    }

    // Get current location
    final position = await LocationService.getCurrentLocation();
    if (position == null) {
      print('❌ Could not get current location');
      if (mounted) {
        _showMessage('ບໍ່ສາມາດເອົາສະຖານທີ່ປັດຈຸບັນໄດ້', isError: true);
      }
      return;
    }

    print('✅ Location obtained: ${position.latitude}, ${position.longitude}');

    // Perform check-in
    final success = await _controller.checkIn();
    if (!mounted) return;

    if (success) {
      print('✅ Check-in successful');
      _showMessage('ເຂົ້າເຮັດວຽກສຳເລັດ', isError: false);

      // Get directions and draw route
      if (_navController != null && _controller.currentPosition != null) {
        final result = await _navController!.getDirectionsAndDrawRoute(
          _controller.currentPosition!,
        );

        if (result != null) {
          _controller.updatePositionInfo(
            _controller.currentPosition!,
            result['distance'],
            result['duration'],
          );
        }

        if (mounted) {
          setState(() {});
        }
      }
    } else {
      print('❌ Check-in failed');
      _showMessage('ບໍ່ສາມາດເຂົ້າເຮັດວຽກໄດ້', isError: true);
    }
  }

  @override
  void dispose() {
    _navController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0099FF),
          title: const Text(
            'ລາຍລະອຽດຄະດີ',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF0099FF)),
              SizedBox(height: 16),
              Text('ກຳລັງໂຫຼດຂໍ້ມູນ...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _controller),
        if (_navController != null)
          ChangeNotifierProvider.value(value: _navController!),
      ],
      child: Consumer<CaseDetailController>(
        builder: (context, controller, _) {
          final navController = _navController != null
              ? context.watch<NavigationController>()
              : null;

          // Navigation Mode
          if (navController?.isNavigating ?? false) {
            return _buildNavigationMode(navController!);
          }

          // Normal Mode
          return _buildNormalMode(controller, navController);
        },
      ),
    );
  }

  Widget _buildNavigationMode(NavigationController navController) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                _buildMap(navController),
                if (navController.currentInstruction.isNotEmpty)
                  NavigationInstructionCard(
                    instruction: navController.currentInstruction,
                    remainingDistance: navController.remainingDistance,
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: StopNavigationButton(
                onPressed: () => navController.stopNavigation(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalMode(
    CaseDetailController controller,
    NavigationController? navController,
  ) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.loadTaskFromAPI();
          if (navController != null && controller.currentPosition != null) {
            await navController.getDirectionsAndDrawRoute(
              controller.currentPosition!,
            );
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map
              if (navController != null)
                SizedBox(height: 300, child: _buildMap(navController)),

              // Header
              CaseHeader(
                task: controller.task,
                currentStatus: controller.currentStatus,
              ),

              // Check-in Info Section
              if (controller.isCheckedIn)
                CheckInSection(controller: controller),

              // Status Action Buttons (MOVED UP - above customer info)
              StatusActionButtons(
                currentStatus: controller.currentStatus,
                onAccept: () => _handleAccept(controller),
                onReject: () => _showRejectDialog(controller),
                onComplete: () => _showCompleteDialog(controller),
                onCancel: () => _handleCancel(controller),
                isLoading: controller.isLoading,
              ),

              // Customer Info (NOW BELOW status buttons)
              CustomerInfoSection(task: controller.task),

              // Description
              if (controller.task.description != null)
                DescriptionSection(description: controller.task.description!),

              // Activity Timeline
              if (controller.activitySteps.isNotEmpty)
                InfoSection(
                  title: 'ປະຫວັດການດຳເນີນງານ',
                  icon: Icons.history,
                  children: [ActivityTimeline(steps: controller.activitySteps)],
                ),

              // Navigation Button
              if (controller.isCheckedIn &&
                  navController != null &&
                  !navController.isNavigating &&
                  !controller.hasArrived)
                NavigationButton(
                  onPressed: () => _startNavigation(controller, navController),
                ),

              // Arrive Button (only show if not arrived yet)
              if (controller.isCheckedIn &&
                  !controller.hasArrived &&
                  controller.currentStatus == TaskStatus.inProgress)
                ArriveButton(
                  onPressed: () => _handleArrive(controller),
                  currentDistance: _calculateCurrentDistance(controller),
                  isLoading: controller.isLoading,
                ),

              // Action Buttons Grid (show after accepting task - status is inProgress)
              if (controller.currentStatus == TaskStatus.inProgress) ...[
                // Debug info
                Builder(
                  builder: (context) {
                    debugPrint('🎨 Rendering Action Grid');
                    debugPrint('🎨 Status: ${controller.currentStatus}');
                    debugPrint('🎨 StatusCode: ${controller.task.statusCode}');
                    return const SizedBox.shrink();
                  },
                ),
                ActionButtonsGrid(
                  actionCompleted: controller.actionCompleted,
                  onActionPressed: controller.handleAction,
                ),
              ],

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
        Consumer2<CaseDetailController, NavigationController?>(
          builder: (context, controller, navController, _) {
            if (navController == null || navController.isNavigating) {
              return const SizedBox();
            }

            return IconButton(
              icon: const Icon(Icons.navigation),
              onPressed: () {
                if (controller.isCheckedIn) {
                  _startNavigation(controller, navController);
                }
              },
              tooltip: 'ນຳທາງ',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () => _showMessage('ໂທຫາລູກຄ້າ', isError: false),
          tooltip: 'ໂທຫາລູກຄ້າ',
        ),
        Consumer<CaseDetailController>(
          builder: (context, controller, _) {
            if (controller.currentStatus != TaskStatus.inProgress) {
              return const SizedBox();
            }
            return IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () => _showCompleteDialog(controller),
              tooltip: 'ສຳເລັດວຽກ',
            );
          },
        ),
      ],
    );
  }

  Widget _buildMap(NavigationController navController) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          navController.destinationLat,
          navController.destinationLng,
        ),
        zoom: 14,
      ),
      markers: navController.markers,
      polylines: navController.polylines,
      onMapCreated: (GoogleMapController controller) {
        navController.setMapController(controller);
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
      compassEnabled: true,
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
                  onPressed: () => _showMessage('ເພີ່ມຮູບພາບ', isError: false),
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
                  onPressed: () => _showMessage('ເພີ່ມບັນທຶກ', isError: false),
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

  Future<void> _startNavigation(
    CaseDetailController controller,
    NavigationController navController,
  ) async {
    if (controller.currentPosition == null) return;
    await navController.startNavigation(controller.currentPosition!);
  }

  Future<void> _handleArrive(CaseDetailController controller) async {
    final success = await controller.arriveOnSite();
    if (!mounted) return;

    if (success) {
      _showMessage('ບັນທຶກການເຂົ້າເຮັດວຽກສຳເລັດ!', isError: false);
    } else {
      _showMessage('ບໍ່ສາມາດບັນທຶກໄດ້', isError: true);
    }
  }

  Future<void> _handleAccept(CaseDetailController controller) async {
    debugPrint('🔵 Starting accept task...');
    debugPrint(
      '🔵 Current status before accept: ${controller.currentStatus} (statusCode: ${controller.task.statusCode})',
    );

    final success = await controller.acceptTask();
    if (!mounted) return;

    if (success) {
      debugPrint('✅ Accept success!');
      debugPrint(
        '✅ Current status after accept: ${controller.currentStatus} (statusCode: ${controller.task.statusCode})',
      );

      _showMessage('ຮັບວຽກສຳເລັດ', isError: false);

      // Force UI rebuild to show action grid
      setState(() {});

      debugPrint('✅ UI rebuilt');
    } else {
      debugPrint('❌ Accept failed');
      _showMessage('ບໍ່ສາມາດຮັບວຽກໄດ້', isError: true);
    }
  }

  Future<void> _handleCancel(CaseDetailController controller) async {
    final success = await controller.updateStatus(TaskStatus.cancelled);
    if (!mounted) return;

    if (success) {
      _showMessage('ຍົກເລີກວຽກສຳເລັດ', isError: false);
      Navigator.pop(context, true);
    }
  }

  void _showRejectDialog(CaseDetailController controller) {
    final remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ'),
          ),
          TextButton(
            onPressed: () async {
              final remark = remarkController.text.trim();
              if (remark.isEmpty) {
                _showMessage('ກະລຸນາໃສ່ເຫດຜົນ', isError: true);
                return;
              }
              Navigator.pop(context);

              final success = await controller.rejectTask(remark);
              if (mounted) {
                if (success) {
                  _showMessage('ປະຕິເສດວຽກສຳເລັດ', isError: false);
                  Navigator.pop(context, true);
                } else {
                  _showMessage('ບໍ່ສາມາດປະຕິເສດວຽກໄດ້', isError: true);
                }
              }
            },
            child: const Text(
              'ປະຕິເສດ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(CaseDetailController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ສຳເລັດວຽກ'),
        content: const Text(
          'ຕ້ອງການແຈ້ງສູນໃຫ້ຫວ່າທ່ານໄດ້ເຮັດວຽກໃນຄະດີນີ້ແລ້ວບໍ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ກັບຄືນ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await controller.updateStatus(
                TaskStatus.completed,
              );
              if (mounted) {
                if (success) {
                  _showMessage('ສຳເລັດວຽກແລ້ວ', isError: false);
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) Navigator.pop(context, true);
                  });
                } else {
                  _showMessage('ບໍ່ສຳເລັດ', isError: true);
                }
              }
            },
            child: const Text(
              'ແມ່ນ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ຕ້ອງການສິດອະນຸຍາດ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text(
              'ເປີດການຕັ້ງຄ່າ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  double? _calculateCurrentDistance(CaseDetailController controller) {
    if (controller.currentPosition == null ||
        widget.task.lat == null ||
        widget.task.lng == null) {
      return null;
    }

    return LocationService.calculateDistance(
      widget.task.lat!,
      widget.task.lng!,
      controller.currentPosition!.latitude,
      controller.currentPosition!.longitude,
    );
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
}
