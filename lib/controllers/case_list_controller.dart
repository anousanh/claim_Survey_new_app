// // lib/controllers/case_list_controller.dart
// // Step 2: Controller for managing case lists

// import 'package:flutter/material.dart';
// import '../models/task_model.dart';
// import '../models/case_status.dart';
// import '../services/api/api_service.dart';

// enum PageType { solving, resolving }

// class CaseListController extends ChangeNotifier {
//   final ApiService _apiService = ApiService();
//   final PageType pageType;

//   bool _isLoading = false;
//   List<Task> _allCases = [];
//   String _errorMessage = '';

//   // Getters
//   bool get isLoading => _isLoading;
//   String get errorMessage => _errorMessage;
//   List<Task> get allCases => _allCases;

//   // Filtered cases by tab
//   List<Task> get newCases {
//     return _allCases.where((task) {
//       final tab = pageType == PageType.solving
//           ? StatusTabMapper.getSolvingTab(task.status.index)
//           : StatusTabMapper.getResolvingTab(task.status.index);
//       return tab == CaseTab.newCase;
//     }).toList();
//   }

//   List<Task> get inProgressCases {
//     return _allCases.where((task) {
//       final tab = pageType == PageType.solving
//           ? StatusTabMapper.getSolvingTab(task.status.index)
//           : StatusTabMapper.getResolvingTab(task.status.index);
//       return tab == CaseTab.inProgress;
//     }).toList();
//   }

//   List<Task> get historyCases {
//     return _allCases.where((task) {
//       final tab = pageType == PageType.solving
//           ? StatusTabMapper.getSolvingTab(task.status.index)
//           : StatusTabMapper.getResolvingTab(task.status.index);
//       return tab == CaseTab.history;
//     }).toList();
//   }

//   // Badge counts
//   int get newCaseCount => newCases.length;

//   CaseListController({required this.pageType});

//   /// Load cases based on page type
//   Future<void> loadCases({int? claimNo}) async {
//     _setLoading(true);
//     _errorMessage = '';

//     try {
//       final response = pageType == PageType.solving
//           ? await _loadSolvingCases()
//           : await _loadResolvingCases(claimNo);

//       if (response.isSuccess) {
//         final tasks = response.getDataArray<Task>(
//           pageType == PageType.solving ? 'claims' : 'tasks',
//           (json) => Task.fromJson(json),
//         );

//         _allCases = tasks;
//         notifyListeners();
//       } else {
//         _errorMessage = response.message ?? 'Failed to load cases';
//         notifyListeners();
//       }
//     } catch (e) {
//       _errorMessage = 'Error: $e';
//       notifyListeners();
//     } finally {
//       _setLoading(false);
//     }
//   }

//   Future<ApiResponse> _loadSolvingCases() async {
//     // Use existing API for solving cases
//     // Adjust according to your actual API method
//     return await _apiService.getMotorClaimTasks();
//   }

//   Future<ApiResponse> _loadResolvingCases(int? claimNo) async {
//     if (claimNo == null) {
//       return ApiResponse(
//         status: 0,
//         message: 'Claim number is required',
//         error: 'Missing claim number',
//         data: null,
//       );
//     }
//     return await _apiService.mtResolveTasks(claimNo);
//   }

//   /// Get cases for specific tab
//   List<Task> getCasesForTab(CaseTab tab) {
//     switch (tab) {
//       case CaseTab.newCase:
//         return newCases;
//       case CaseTab.inProgress:
//         return inProgressCases;
//       case CaseTab.history:
//         return historyCases;
//     }
//   }

//   /// Refresh data
//   Future<void> refresh({int? claimNo}) async {
//     await loadCases(claimNo: claimNo);
//   }

//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }

//   /// Get status display name
//   String getStatusName(int statusCode) {
//     return pageType == PageType.solving
//         ? StatusTabMapper.getSolvingStatusName(statusCode)
//         : StatusTabMapper.getResolvingStatusName(statusCode);
//   }

//   /// Get status color
//   Color getStatusColor(int statusCode) {
//     return pageType == PageType.solving
//         ? StatusTabMapper.getSolvingStatusColor(statusCode)
//         : StatusTabMapper.getResolvingStatusColor(statusCode);
//   }
// }
