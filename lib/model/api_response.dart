import 'dart:convert';

/// API Response wrapper class
/// Handles all API responses with consistent structure
class ApiResponse {
  final int status;
  final String message;
  final String error;
  final Map<String, dynamic>? data;

  ApiResponse({
    required this.status,
    required this.message,
    required this.error,
    this.data,
  });

  /// Create ApiResponse from JSON
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      error: json['error'] ?? '',
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'error': error, 'data': data};
  }

  /// Check if request was successful
  bool get isSuccess => status == 200;

  /// Check if request failed
  bool get isFailure => status != 200;

  /// Get raw data object
  Map<String, dynamic>? get rawData => data;

  /// Get single data object by key and convert to model
  T? getData<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      if (data != null && data!.containsKey(key)) {
        final jsonData = data![key];
        if (jsonData is Map<String, dynamic>) {
          return fromJson(jsonData);
        }
      }
    } catch (e) {
      print('❌ Error getting data for key $key: $e');
    }
    return null;
  }

  /// Get array of data objects by key and convert to list of models
  List<T> getDataArray<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    List<T> objects = [];
    try {
      if (data != null && data!.containsKey(key)) {
        final items = data![key];
        if (items is List) {
          for (var item in items) {
            if (item is Map<String, dynamic>) {
              objects.add(fromJson(item));
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error getting data array for key $key: $e');
    }
    return objects;
  }

  /// Get integer value from data
  int getIntData(String key, {int defaultValue = 0}) {
    try {
      if (data != null && data!.containsKey(key)) {
        final value = data![key];
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? defaultValue;
        if (value is double) return value.toInt();
      }
    } catch (e) {
      print('❌ Error getting int data for key $key: $e');
    }
    return defaultValue;
  }

  /// Get double value from data
  double getDoubleData(String key, {double defaultValue = 0.0}) {
    try {
      if (data != null && data!.containsKey(key)) {
        final value = data![key];
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? defaultValue;
      }
    } catch (e) {
      print('❌ Error getting double data for key $key: $e');
    }
    return defaultValue;
  }

  /// Get string value from data
  String getStringData(String key, {String defaultValue = ''}) {
    try {
      if (data != null && data!.containsKey(key)) {
        return data![key]?.toString() ?? defaultValue;
      }
    } catch (e) {
      print('❌ Error getting string data for key $key: $e');
    }
    return defaultValue;
  }

  /// Get boolean value from data
  bool getBooleanData(String key, {bool defaultValue = false}) {
    try {
      if (data != null && data!.containsKey(key)) {
        final value = data![key];
        if (value is bool) return value;
        if (value is int) return value != 0;
        if (value is String) {
          return value.toLowerCase() == 'true' || value == '1';
        }
      }
    } catch (e) {
      print('❌ Error getting boolean data for key $key: $e');
    }
    return defaultValue;
  }

  /// Get long value from data
  int getLongData(String key, {int defaultValue = 0}) {
    return getIntData(key, defaultValue: defaultValue);
  }

  /// Check if data contains a key
  bool hasData(String key) {
    return data != null && data!.containsKey(key);
  }

  /// Get nested data object
  Map<String, dynamic>? getNestedData(String key) {
    try {
      if (data != null && data!.containsKey(key)) {
        final value = data![key];
        if (value is Map<String, dynamic>) {
          return value;
        }
      }
    } catch (e) {
      print('❌ Error getting nested data for key $key: $e');
    }
    return null;
  }

  @override
  String toString() {
    return 'ApiResponse{status: $status, message: $message, error: $error, hasData: ${data != null}}';
  }

  /// Create a success response
  factory ApiResponse.success({
    String message = 'Success',
    Map<String, dynamic>? data,
  }) {
    return ApiResponse(status: 200, message: message, error: '', data: data);
  }

  /// Create an error response
  factory ApiResponse.failure({
    int status = 0,
    String message = 'Request failed',
    String error = '',
  }) {
    return ApiResponse(
      status: status,
      message: message,
      error: error,
      data: null,
    );
  }
}
