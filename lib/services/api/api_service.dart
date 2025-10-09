import 'dart:convert';

import 'package:claim_survey_app/model/api_response.dart';
import 'package:claim_survey_app/services/encryption_service.dart';
import 'package:claim_survey_app/utils/app_config.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ApiService {
  final AppConfig _appConfig = AppConfig();

  // Replace with your actual API key from Android strings.xml
  static const String _apiKey = '8D494B40136EC90739D3959B52BE1864C245AGL';

  /// Main POST request method
  ///
  /// [actionName] - API action name (e.g., 'login', 'getClaims')
  /// [params] - Request parameters
  /// [includeToken] - Whether to include user token in request
  /// [additionalParams] - Additional parameters to add after signature
  Future<APIResponse> postRequest(
    String actionName,
    Map<String, dynamic> params, {
    bool includeToken = false,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      // Get API configuration
      final String apiUrl = await _appConfig.getApiUrl();
      final dbMode = await _appConfig.getDBMode();

      // Add db_mode to params
      params['db_mode'] = dbMode.name.toUpperCase();

      // Include token if required
      if (includeToken) {
        final userToken = await _getUserToken();
        if (userToken != null) {
          params['us'] = userToken['username'];
          params['token'] = userToken['token'];
        } else {
          params['ux'] = 'none';
        }
      }

      // Prepare post parameters
      final postParams = <String, dynamic>{};
      final itemKeys = <String>[];
      final items = <String>[];

      // Add action
      itemKeys.add('action');
      items.add(jsonEncode(actionName));
      postParams['action'] = actionName;

      // Add action time
      final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      itemKeys.add('action_time');
      items.add(jsonEncode(now));
      postParams['action_time'] = now;

      // Add all params
      params.forEach((key, value) {
        itemKeys.add(key);
        items.add(jsonEncode(value));
        postParams[key] = value;
      });

      // Create signature
      postParams['key_names'] = itemKeys.join(',');
      final strItems = items.join(',');
      final signature = _createHmacSha256Signature(_apiKey, strItems);
      postParams['signature'] = signature;

      // Add additional params after signature (if any)
      if (additionalParams != null) {
        postParams.addAll(additionalParams);
      }

      // Log request for debugging (remove in production)
      _logRequest(actionName, postParams);

      // Make HTTP request
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(postParams),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception(
                'Connection timeout - Please check your internet connection',
              );
            },
          );

      // Parse response
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      return APIResponse(
        status: 0,
        message: 'Network error: ${e.message}',
        error: 'CLIENT_EXCEPTION',
        data: null,
      );
    } catch (e) {
      return APIResponse(
        status: 0,
        message: 'Request failed: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Handle HTTP response
  APIResponse _handleResponse(http.Response response) {
    try {
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return APIResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 404) {
        return APIResponse(
          status: 404,
          message: 'API endpoint not found',
          error: 'NOT_FOUND',
          data: null,
        );
      } else if (response.statusCode == 500) {
        return APIResponse(
          status: 500,
          message: 'Server error - Please try again later',
          error: 'SERVER_ERROR',
          data: null,
        );
      } else {
        return APIResponse(
          status: response.statusCode,
          message: 'HTTP Error: ${response.statusCode}',
          error: response.body,
          data: null,
        );
      }
    } catch (e) {
      return APIResponse(
        status: 0,
        message: 'Failed to parse response',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Create HMAC SHA256 signature (same as Android implementation)
  String _createHmacSha256Signature(String key, String data) {
    try {
      final keyBytes = utf8.encode(key);
      final dataBytes = utf8.encode(data);
      final hmac = Hmac(sha256, keyBytes);
      final digest = hmac.convert(dataBytes);
      return base64Encode(digest.bytes).trim();
    } catch (e) {
      print('❌ Error creating signature: $e');
      return '';
    }
  }

  /// Get user token from secure storage
  /// Note: This is called by passing the user data directly to avoid circular dependency
  Future<Map<String, String>?> _getUserToken() async {
    try {
      // Read directly from secure storage to avoid circular dependency
      final storage = const FlutterSecureStorage();
      final encrypted = await storage.read(key: 'user_data');

      if (encrypted != null && encrypted.isNotEmpty) {
        // Import encryption service
        final encryptionService = EncryptionService();
        final decrypted = encryptionService.decrypt(encrypted);
        final Map<String, dynamic> json = jsonDecode(decrypted);

        return {
          'username': json['Username'] ?? '',
          'token': json['Token'] ?? '',
        };
      }
    } catch (e) {
      print('❌ Error getting user token: $e');
    }
    return null;
  }

  /// GET request method (if needed for future use)
  Future<APIResponse> getRequest(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final String apiUrl = await _appConfig.getApiUrl();
      Uri uri = Uri.parse('$apiUrl/$endpoint');

      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 60));

      return _handleResponse(response);
    } catch (e) {
      return APIResponse(
        status: 0,
        message: 'GET request failed: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Upload file with multipart request
  Future<APIResponse> uploadFile(
    String actionName,
    String filePath,
    Map<String, dynamic> params,
  ) async {
    try {
      final String apiUrl = await _appConfig.getMediaUploadUrl();
      final uri = Uri.parse(apiUrl);

      final request = http.MultipartRequest('POST', uri);

      // Add file
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      // Add other parameters
      params.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return APIResponse(
        status: 0,
        message: 'File upload failed: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Log request details for debugging
  void _logRequest(String action, Map<String, dynamic> params) {
    if (const bool.fromEnvironment('dart.vm.product')) {
      // Don't log in production/release mode
      return;
    }

    print('🔵 API Request: $action');
    print('📦 Parameters: ${params.keys.join(', ')}');

    // Don't log sensitive data
    final safeParams = Map<String, dynamic>.from(params);
    safeParams.remove('password');
    safeParams.remove('token');
    safeParams.remove('signature');

    print('📝 Data: $safeParams');
  }

  /// Verify API connection
  Future<bool> checkConnection() async {
    try {
      final apiUrl = await _appConfig.getApiUrl();
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      return false;
    }
  }
}
