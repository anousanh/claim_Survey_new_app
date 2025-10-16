// lib/controllers/case_detail_controller.dart
// Step 2: Create controller for business logic
// This handles all API calls, state management, and business operations

import 'package:claim_survey_app/model/activity_step.dart';
import 'package:claim_survey_app/model/task_model.dart';
import 'package:claim_survey_app/screen/case_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api/api_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

class CaseDetailController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State variables
  Task _task;
  TaskStatus _currentStatus;
  bool _isLoading = false;
  bool _isCheckedIn = false;
  bool _hasArrived = false;
  Position? _currentPosition;
  double? _distanceInKm;
  String? _duration;
  String _statusMessage = '';

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

  // Getters
  Task get task => _task;
  TaskStatus get currentStatus => _currentStatus;
  bool get isLoading => _isLoading;
  bool get isCheckedIn => _isCheckedIn;
  bool get hasArrived => _hasArrived;
  Position? get currentPosition => _currentPosition;
  double? get distanceInKm => _distanceInKm;
  String? get duration => _duration;
  String get statusMessage => _statusMessage;
  List<ActivityStep> get activitySteps => List.unmodifiable(_activitySteps);
  Map<String, bool> get actionCompleted => Map.unmodifiable(_actionCompleted);

  CaseDetailController(Task task) : _task = task, _currentStatus = task.status;

  /// Load task data from API
  Future<bool> loadTaskFromAPI() async {
    _setLoading(true);

    try {
      final claimNo = int.tryParse(_task.claimNumber);
      if (claimNo == null) throw Exception('Invalid claim number');

      final response = await _apiService.getMotorClaimTask(claimNo);

      if (response.isSuccess) {
        final steps = response.getDataArray<ActivityStep>(
          'steps',
          (json) => ActivityStep.fromJson(json),
        );
        final tasks = response.getDataArray<Task>(
          'claims',
          (json) => Task.fromJson(json),
        );

        if (tasks.isNotEmpty) {
          _task = tasks[0];
          _currentStatus = tasks[0].status;
          _activitySteps.clear();
          _activitySteps.addAll(steps);
          _updateActionCompletionStatus(tasks[0]);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error loading task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _updateActionCompletionStatus(Task task) {
    _actionCompleted['documents'] = task.btnDocuments ?? false;
    _actionCompleted['estimate'] = task.btnCostEstimate ?? false;
    _actionCompleted['responsible'] = task.btnResponsibility ?? false;
    _actionCompleted['garage'] = task.btnGarageRequest ?? false;
    _actionCompleted['opponent'] = task.btnOpponent ?? false;
    _actionCompleted['agreement'] = task.btnAgreement ?? false;
    _actionCompleted['police'] = task.btnPolice ?? false;
  }

  /// Handle Accept Task
  Future<bool> acceptTask() async {
    _setLoading(true);

    try {
      final taskNo = int.tryParse(_task.claimNumber);
      if (taskNo == null) throw Exception('Invalid task number');

      final response = await _apiService.taskResponse(
        taskNo: taskNo,
        isAccepted: true,
        remark: '',
      );

      if (response.isSuccess) {
        await loadTaskFromAPI();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error accepting task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Handle Reject Task
  Future<bool> rejectTask(String remark) async {
    _setLoading(true);

    try {
      final taskNo = int.tryParse(_task.claimNumber);
      if (taskNo == null) throw Exception('Invalid task number');

      final response = await _apiService.taskResponse(
        taskNo: taskNo,
        isAccepted: false,
        remark: remark,
      );

      return response.isSuccess;
    } catch (e) {
      debugPrint('Error rejecting task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Handle Check-in
  Future<bool> checkIn() async {
    if (_task.lat == null || _task.lng == null) return false;

    _setLoading(true);
    _setStatusMessage('ກຳລັງກວດສອບສະຖານທີ່...');

    try {
      Position? position = await LocationService.getCurrentLocation();
      if (position == null) {
        _setStatusMessage('ບໍ່ສາມາດເອົາສະຖານທີ່ປັດຈຸບັນໄດ້');
        return false;
      }

      double distance = LocationService.calculateDistance(
        _task.lat!,
        _task.lng!,
        position.latitude,
        position.longitude,
      );

      // Send to API
      try {
        final claimNo = int.tryParse(_task.claimNumber);
        if (claimNo != null) {
          await _apiService.taskResponse(
            taskNo: claimNo,
            isAccepted: true,
            remark: 'Check-in at site',
          );
        }
      } catch (e) {
        debugPrint('Error sending check-in: $e');
      }

      _currentPosition = position;
      _distanceInKm = distance;
      _isCheckedIn = true;
      _setStatusMessage('ຄຳນວນໄລຍຍະທາງສຳເລັດແລ້ວ!');

      _addActivityStep(
        'ຄຳນວນໄລຍຍະທາງແລ້ວ (${distance.toStringAsFixed(2)} ກມ)',
        Icons.location_on,
      );

      await DatabaseService.saveCheckIn(
        taskId: _task.claimNumber,
        position: position,
        distance: distance,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error during check-in: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Handle Arrive On Site
  Future<bool> arriveOnSite() async {
    if (_currentPosition == null) return false;

    _setLoading(true);
    _setStatusMessage('ກຳລັງບັນທຶກການເຂົ້າເຮັດວຽກ...');

    try {
      final claimNo = int.tryParse(_task.claimNumber);
      if (claimNo == null) throw Exception('Invalid claim number');

      Position? arrivalPosition = await LocationService.getCurrentLocation();
      arrivalPosition ??= _currentPosition!;

      double currentDistance = LocationService.calculateDistance(
        _task.lat!,
        _task.lng!,
        arrivalPosition.latitude,
        arrivalPosition.longitude,
      );

      final response = await _apiService.arriveResponse(
        taskNo: claimNo,
        isArrived: true,
        remark: 'Arrived at site',
        mapLat: arrivalPosition.latitude,
        mapLng: arrivalPosition.longitude,
        distance: currentDistance,
      );

      if (response.isSuccess) {
        _hasArrived = true;
        _currentPosition = arrivalPosition;
        _setStatusMessage('ບັນທຶກການເຂົ້າເຮັດວຽກສຳເລັດ!');

        _addActivityStep(
          'ເຂົ້າເຮັດວຽກແລ້ວ (ໄລຍະຫ່າງ: ${currentDistance.toStringAsFixed(2)} ກມ)',
          Icons.flag,
        );

        await DatabaseService.saveCheckIn(
          taskId: _task.claimNumber,
          position: arrivalPosition,
          distance: currentDistance,
        );

        await loadTaskFromAPI();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error arriving on site: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update task status
  Future<bool> updateStatus(TaskStatus newStatus) async {
    _setLoading(true);

    try {
      if (newStatus == TaskStatus.completed) {
        final claimNo = int.tryParse(_task.claimNumber);
        final taskNo = _task.taskNo ?? claimNo;

        if (claimNo != null && taskNo != null) {
          final response = await _apiService.mtFinishTask(
            claimNo: claimNo,
            taskNo: taskNo,
            taskType: _task.taskType ?? 'SOLVING',
          );

          if (!response.isSuccess) return false;
        }
      }

      _currentStatus = newStatus;
      _addActivityStep(
        'ປ່ຽນສະຖານະເປັນ: ${_getStatusText(newStatus)}',
        Icons.update,
      );

      await DatabaseService.updateTaskStatus(
        taskId: _task.claimNumber,
        status: newStatus.toString(),
        position: _currentPosition,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Handle action button
  void handleAction(String action, String title) {
    _actionCompleted[action] = true;
    _addActivityStep('ບັນທຶກ$title', Icons.check);
    notifyListeners();
  }

  /// Update position and distance info
  void updatePositionInfo(
    Position position,
    double distance,
    String? durationText,
  ) {
    _currentPosition = position;
    _distanceInKm = distance;
    _duration = durationText;
    notifyListeners();
  }

  void _addActivityStep(String description, IconData icon) {
    _activitySteps.add(
      ActivityStep(date: DateTime.now(), description: description, icon: icon),
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setStatusMessage(String message) {
    _statusMessage = message;
    notifyListeners();
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
}
