class APIResponse {
  final int status;
  final String message;
  final String error;
  final Map<String, dynamic>? data;

  APIResponse({
    required this.status,
    required this.message,
    required this.error,
    this.data,
  });

  factory APIResponse.fromJson(Map<String, dynamic> json) {
    return APIResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      error: json['error'] ?? '',
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
    );
  }

  T? getData<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      if (data != null && data!.containsKey(key)) {
        final jsonData = data![key];
        if (jsonData is Map<String, dynamic>) {
          return fromJson(jsonData);
        }
      }
    } catch (e) {
      print('Error getting data for key $key: $e');
    }
    return null;
  }

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
      print('Error getting data array for key $key: $e');
    }
    return objects;
  }

  int getIntData(String key) {
    try {
      return data?[key] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  double getDoubleData(String key) {
    try {
      return (data?[key] ?? 0).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  String getStringData(String key) {
    try {
      return data?[key]?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  bool getBooleanData(String key) {
    try {
      return data?[key] ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  String toString() {
    return 'APIResponse{status: $status, message: $message, error: $error, data: $data}';
  }
}
