// lib/services/api_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // TODO: Replace with your actual API base URL
  static const String baseUrl = 'https://your-api-url.com/api';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;

  /// Initialize API service with auth token
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  /// Save auth token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Clear auth token (logout)
  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Get headers with auth token
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  /// POST request to API
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> params, {
    bool requiresAuth = true,
  }) async {
    try {
      print('========== API REQUEST ==========');
      print('Endpoint: $endpoint');
      print('Params: $params');
      print('=================================');

      final response = await http
          .post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: _getHeaders(),
            body: json.encode(params),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      print('========== API RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('==================================');

      return ApiResponse.fromJson(json.decode(response.body));
    } catch (e) {
      print('API Error: $e');
      return ApiResponse(
        status: 500,
        message: 'Connection error',
        error: e.toString(),
        data: {},
      );
    }
  }

  /// GET request to API
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl/$endpoint');

      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(
          queryParameters: queryParams.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }

      print('========== API REQUEST ==========');
      print('GET: $uri');
      print('=================================');

      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      print('========== API RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('==================================');

      return ApiResponse.fromJson(json.decode(response.body));
    } catch (e) {
      print('API Error: $e');
      return ApiResponse(
        status: 500,
        message: 'Connection error',
        error: e.toString(),
        data: {},
      );
    }
  }

  // ==================== SPECIFIC API CALLS ====================

  /// Login
  Future<ApiResponse> login(String email, String password) async {
    return await post('login', {
      'email': email,
      'password': password,
    }, requiresAuth: false);
  }

  /// Get Motor Claim Task
  Future<ApiResponse> getMotorClaimTask({
    required int claimNo,
    required String taskType,
  }) async {
    return await post('getMotorClaimTask', {
      'claimNo': claimNo,
      'taskType': taskType,
    });
  }

  /// Get Motor Claim (for resolving)
  Future<ApiResponse> getMotorClaim({
    required int taskNo,
    required String taskType,
  }) async {
    return await post('getMotorClaim', {
      'taskNo': taskNo,
      'taskType': taskType,
    });
  }

  /// Task Response (Accept/Reject)
  Future<ApiResponse> taskResponse({
    required int taskNo,
    required bool isAccepted,
    String remark = '',
  }) async {
    return await post('taskResponse', {
      'taskNo': taskNo,
      'isAccepted': isAccepted,
      'remark': remark,
    });
  }

  /// Arrived at Site
  Future<ApiResponse> arrivedAtSite({
    required int claimNo,
    required double latitude,
    required double longitude,
    required double distance,
    required bool isArrived,
  }) async {
    return await post('arrivedAtSite', {
      'claimNo': claimNo,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'isArrived': isArrived,
    });
  }

  /// Finish Motor Task
  Future<ApiResponse> finishMotorTask({
    required int claimNo,
    required int taskNo,
    required String taskType,
  }) async {
    return await post('MTFinishTask', {
      'claimNo': claimNo,
      'taskNo': taskNo,
      'taskType': taskType,
    });
  }

  /// Upload Document
  Future<ApiResponse> uploadDocument({
    required int claimNo,
    required String documentType,
    required String base64Image,
  }) async {
    return await post('uploadDocument', {
      'claimNo': claimNo,
      'documentType': documentType,
      'image': base64Image,
    });
  }

  /// Save Estimate Cost
  Future<ApiResponse> saveEstimateCost({
    required int claimNo,
    required double estimatedCost,
    String? remarks,
  }) async {
    return await post('saveEstimateCost', {
      'claimNo': claimNo,
      'estimatedCost': estimatedCost,
      'remarks': remarks,
    });
  }

  /// Get Task List
  Future<ApiResponse> getTaskList({
    required String taskType,
    int? status,
  }) async {
    return await post('getTaskList', {
      'taskType': taskType,
      if (status != null) 'status': status,
    });
  }
}

/// API Response Model
class ApiResponse {
  final int status;
  final String message;
  final String error;
  final Map<String, dynamic> data;

  ApiResponse({
    required this.status,
    required this.message,
    required this.error,
    required this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] ?? 500,
      message: json['message'] ?? '',
      error: json['error'] ?? '',
      data: json['data'] ?? {},
    );
  }

  /// Check if request was successful
  bool get isSuccess => status == 200;

  /// Get single object from data
  T? getData<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      if (data.containsKey(key)) {
        return fromJson(data[key] as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error parsing data: $e');
    }
    return null;
  }

  /// Get array of objects from data
  List<T> getDataArray<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      if (data.containsKey(key)) {
        final List<dynamic> items = data[key] as List<dynamic>;
        return items
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error parsing data array: $e');
    }
    return [];
  }

  /// Get long value
  int getLongData(String key) {
    try {
      return data[key] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get int value
  int getIntData(String key) {
    try {
      return data[key] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get double value
  double getDoubleData(String key) {
    try {
      return (data[key] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get boolean value
  bool getBooleanData(String key) {
    try {
      return data[key] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get string value
  String getStringData(String key) {
    try {
      return data[key] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  @override
  String toString() {
    return 'ApiResponse{status: $status, message: $message, error: $error, data: $data}';
  }
}
