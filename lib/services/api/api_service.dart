import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../model/api_response.dart';
import '../../utils/app_config.dart';
import '../encryption_service.dart';

class ApiService {
  final AppConfig _appConfig = AppConfig();

  // API Key from Android strings.xml
  static const String _apiKey = '8D494B40136EC90739D3959B52BE1864C245AGL';

  /// Login user with username and password
  /// C# endpoint: action = "login"
  Future<ApiResponse> login(String username, String password) async {
    try {
      final params = {'username': username, 'password': password};

      return await _postRequest('login', params, includeToken: false);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Login failed: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== MOTOR CLAIMS ====================

  /// Sync motor claims data with location
  /// C# endpoint: action = "MTSync"
  Future<ApiResponse> mtSync(double mapLat, double mapLng) async {
    try {
      final params = {'mapLat': mapLat, 'mapLng': mapLng};

      return await _postRequest('MTSync', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Sync failed: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get motor claims list
  /// C# endpoint: action = "get-motor-claims"
  Future<ApiResponse> getMotorClaims({
    String search = '',
    int statusId = 0,
  }) async {
    try {
      final params = {'search': search, 'statusId': statusId};

      return await _postRequest('get-motor-claims', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to load claims: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get motor claim task by claim number
  /// C# endpoint: action = "getMotorClaimTask"
  /// For find task solving (claim), use claimNo
  Future<ApiResponse> getMotorClaimTask(int claimNo) async {
    try {
      final params = {'claimNo': claimNo};

      return await _postRequest(
        'getMotorClaimTask',
        params,
        includeToken: true,
      );
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to load task: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get motor claim detail (supports both Solving and Resolving)
  /// C# endpoint: action = "getMotorClaim"
  /// for find list of resolving tasks, use taskType = "Resolving"
  Future<ApiResponse> getMotorClaim({
    required String taskType,
    int taskNo = 0,
    int claimNo = 0,
  }) async {
    try {
      final params = <String, dynamic>{'taskType': taskType};

      if (taskType == 'Resolving') {
        params['taskNo'] = taskNo;
      } else {
        params['claimNo'] = claimNo;
      }

      return await _postRequest('getMotorClaim', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to load claim: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Accept or reject task
  /// C# endpoint: action = "taskResponse" //  ຮັບວຽກ
  Future<ApiResponse> taskResponse({
    required int taskNo,
    required bool isAccepted,
    String remark = '',
  }) async {
    try {
      final params = {
        'taskNo': taskNo,
        'isAccepted': isAccepted,
        'remark': remark,
      };

      return await _postRequest('taskResponse', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to respond to task: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Mark task as arrived or not arrived
  /// C# endpoint: action = "arriveResponse". // ມາເຖິງສະຖານທີ່
  Future<ApiResponse> arriveResponse({
    required int taskNo,
    required bool isArrived,
    String remark = '',
    required double mapLat,
    required double mapLng,
    required double distance,
  }) async {
    try {
      final params = {
        'taskNo': taskNo,
        'isArrived': isArrived,
        'remark': remark,
        'mapLat': mapLat,
        'mapLng': mapLng,
        'distance': distance,
      };

      return await _postRequest('arriveResponse', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to update arrival status: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== DOCUMENTS ====================

  /// Get document count by category
  /// C# endpoint: action = "MTDocCount"
  Future<ApiResponse> mtDocCount(int claimNo) async {
    try {
      final params = {'claimNo': claimNo};

      return await _postRequest('MTDocCount', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get document count: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get document list by category
  /// C# endpoint: action = "MTDocList"
  Future<ApiResponse> mtDocList({
    required int claimNo,
    required int category,
  }) async {
    try {
      final params = {'claimNo': claimNo, 'category': category};

      return await _postRequest('MTDocList', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to load documents: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Upload document/photo
  /// C# endpoint: action = "MTUpload"
  Future<ApiResponse> mtUpload({
    required int claimNo,
    required int deliveryId,
    required int category,
    required double mapLat,
    required double mapLng,
    required String filePath,
    required String imageData,
  }) async {
    try {
      final params = {
        'claimNo': claimNo,
        'deliveryId': deliveryId,
        'category': category,
        'mapLat': mapLat,
        'mapLng': mapLng,
        'filePath': filePath,
        'imageData': imageData,
      };

      return await _postRequest('MTUpload', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to upload: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== RESERVE & COVERAGE ====================

  /// Get reserve amount
  /// C# endpoint: action = "MTGetReserve"
  Future<ApiResponse> mtGetReserve(int claimNo) async {
    try {
      final params = {'claimNo': claimNo};

      return await _postRequest('MTGetReserve', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get reserve: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get coverage details
  /// C# endpoint: action = "MTGetCover"
  Future<ApiResponse> mtGetCover(int claimNo) async {
    try {
      final params = {'claimNo': claimNo};

      return await _postRequest('MTGetCover', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get coverage: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Set reserve amounts
  /// C# endpoint: action = "MTSetReserve"
  Future<ApiResponse> mtSetReserve({
    required int claimNo,
    required double a,
    required double i,
    required double od,
  }) async {
    try {
      final params = {'claimNo': claimNo, 'a': a, 'i': i, 'od': od};

      return await _postRequest('MTSetReserve', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to set reserve: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== RESPONSIBILITY ====================

  /// Get responsible percentage
  /// C# endpoint: action = "MTGetResponsible"
  Future<ApiResponse> mtGetResponsible(int claimNo) async {
    try {
      final params = {'claimNo': claimNo};

      return await _postRequest('MTGetResponsible', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get responsible: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Set responsible percentage
  /// C# endpoint: action = "MTSetResponsible"
  Future<ApiResponse> mtSetResponsible({
    required int claimNo,
    required int percent,
  }) async {
    try {
      final params = {'claimNo': claimNo, 'percent': percent};

      return await _postRequest('MTSetResponsible', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to set responsible: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== OPPONENTS ====================

  /// Get opponents list
  /// C# endpoint: action = "MTGetOpponents"
  Future<ApiResponse> mtGetOpponents(int claimNo) async {
    try {
      final params = {'claimNo': claimNo};

      return await _postRequest('MTGetOpponents', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get opponents: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Save opponent information
  /// C# endpoint: action = "MTSaveOpponent"
  Future<ApiResponse> mtSaveOpponent({
    required int claimNo,
    required int opponentId,
    required int certNo,
    required String name,
    required String mobile,
    required String mark,
    required String model,
    required String plateNo,
    required int platePVID,
    required int platePrefixID,
    required int plateColorID,
    required int percent,
  }) async {
    try {
      final params = {
        'claimNo': claimNo,
        'opponentId': opponentId,
        'certNo': certNo,
        'name': name,
        'mobile': mobile,
        'mark': mark,
        'model': model,
        'plateNo': plateNo,
        'platePVID': platePVID,
        'platePrefixID': platePrefixID,
        'plateColorID': plateColorID,
        'percent': percent,
      };

      return await _postRequest('MTSaveOpponent', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to save opponent: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get certificate data
  /// C# endpoint: action = "MTGetCertificateData"
  Future<ApiResponse> mtGetCertificateData(int certNo) async {
    try {
      final params = {'certNo': certNo};

      return await _postRequest(
        'MTGetCertificateData',
        params,
        includeToken: true,
      );
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get certificate: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== PREPARE DATA ====================

  /// Prepare vehicle data
  /// C# endpoint: action = "MTPrepareVehicle"
  Future<ApiResponse> mtPrepareVehicle() async {
    try {
      return await _postRequest('MTPrepareVehicle', {}, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to prepare vehicle: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get districts by province ID
  /// C# endpoint: action = "getDistricts"
  Future<ApiResponse> getDistricts(int pvId) async {
    try {
      final params = {'pvId': pvId};

      return await _postRequest('getDistricts', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get districts: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== AGREEMENT & GARAGE ====================

  /// Set agreement details
  /// C# endpoint: action = "MTSetAgreement"
  Future<ApiResponse> mtSetAgreement({
    required int claimNo,
    required String legal,
    required String levelId,
    required String remark,
    String agreementType = 'Yes',
  }) async {
    try {
      final params = {
        'claimNo': claimNo,
        'legal': legal,
        'levelId': levelId,
        'remark': remark,
        'agreementType': agreementType,
      };

      return await _postRequest('MTSetAgreement', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to set agreement: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Set garage request
  /// C# endpoint: action = "MTSetGarageRequest"
  Future<ApiResponse> mtSetGarageRequest({
    required int claimNo,
    required bool required,
  }) async {
    try {
      final params = {'claimNo': claimNo, 'required': required};

      return await _postRequest(
        'MTSetGarageRequest',
        params,
        includeToken: true,
      );
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to set garage request: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== ADVICE REQUESTS ====================

  /// Save advice request
  /// C# endpoint: action = "MTSaveAdviceRequest"
  Future<ApiResponse> mtSaveAdviceRequest({
    required int claimNo,
    required String category,
    required String circumstance,
    required String summary,
    required String problem,
    required String remark,
    required bool cover,
  }) async {
    try {
      final params = {
        'claimNo': claimNo,
        'category': category,
        'circumstance': circumstance,
        'summary': summary,
        'problem': problem,
        'remark': remark,
        'cover': cover,
      };

      return await _postRequest(
        'MTSaveAdviceRequest',
        params,
        includeToken: true,
      );
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to save advice request: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get advice requests
  /// C# endpoint: action = "MTAdviceRequests"
  Future<ApiResponse> mtAdviceRequests(int claimNo) async {
    try {
      final params = {'claimNo': claimNo};

      return await _postRequest('MTAdviceRequests', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get advice requests: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Save advice comment
  /// C# endpoint: action = "MTAdviceComment"
  Future<ApiResponse> mtAdviceComment({
    required int topicId,
    required String message,
  }) async {
    try {
      final params = {'topicId': topicId, 'message': message};

      return await _postRequest('MTAdviceComment', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to save comment: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// View advice request
  /// C# endpoint: action = "viewAdviceRequest"
  Future<ApiResponse> viewAdviceRequest(int topicId) async {
    try {
      final params = {'topicId': topicId};

      return await _postRequest(
        'viewAdviceRequest',
        params,
        includeToken: true,
      );
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to view advice request: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get advice request list
  /// C# endpoint: action = "getAdviceRequestList"
  Future<ApiResponse> getAdviceRequestList() async {
    try {
      return await _postRequest('getAdviceRequestList', {}, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get advice list: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get unread advice requests count
  /// C# endpoint: action = "getAdviceRequestUnread"
  Future<ApiResponse> getAdviceRequestUnread() async {
    try {
      return await _postRequest(
        'getAdviceRequestUnread',
        {},
        includeToken: true,
      );
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get unread count: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Upload advice photo
  /// C# endpoint: action = "MTAdvicePhoto"
  Future<ApiResponse> mtAdvicePhoto({
    required int claimNo,
    required int topicId,
    required String imageData,
  }) async {
    try {
      final params = {
        'claimNo': claimNo,
        'topicId': topicId,
        'imageData': imageData,
      };

      return await _postRequest('MTAdvicePhoto', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to upload photo: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== RESOLVE TASKS ====================

  /// Create resolve request
  /// C# endpoint: action = "MTResolveRequest"
  Future<ApiResponse> mtResolveRequest({
    required int claimNo,
    required String requester,
    required String location,
    required String reason,
    required String date,
    required double mapLat,
    required double mapLng,
    required double distance,
    required int hour,
  }) async {
    try {
      final params = {
        'claimNo': claimNo,
        'requester': requester,
        'location': location,
        'reason': reason,
        'date': date,
        'mapLat': mapLat,
        'mapLng': mapLng,
        'distance': distance,
        'hour': hour,
      };

      return await _postRequest('MTResolveRequest', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to create resolve request: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get resolve tasks
  /// C# endpoint: action = "MTResolveTasks"
  Future<ApiResponse> mtResolveTasks(int claimNo) async {
    try {
      final params = {'claimNo': claimNo};

      return await _postRequest('MTResolveTasks', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get resolve tasks: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Finish task
  /// C# endpoint: action = "MTFinishTask"
  Future<ApiResponse> mtFinishTask({
    required int claimNo,
    int taskNo = 0,
    String taskType = 'Solving',
  }) async {
    try {
      final params = <String, dynamic>{
        'claimNo': claimNo,
        'taskType': taskType,
      };

      if (taskNo > 0) {
        params['taskNo'] = taskNo;
      }

      return await _postRequest('MTFinishTask', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to finish task: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== POLICE ====================

  /// Get police information
  /// C# endpoint: action = "getPolice"
  Future<ApiResponse> getPolice(int claimNo) async {
    try {
      final params = {'claimNo': claimNo};

      return await _postRequest('getPolice', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get police info: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Save police information
  /// C# endpoint: action = "savePolice"
  Future<ApiResponse> savePolice({
    required int claimNo,
    required String name,
    required String mobile,
    required int pvId,
    required int dtId,
    required String remark,
  }) async {
    try {
      final params = {
        'claimNo': claimNo,
        'name': name,
        'mobile': mobile,
        'pvId': pvId,
        'dtId': dtId,
        'remark': remark,
      };

      return await _postRequest('savePolice', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to save police: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== STATUS & REPORTS ====================

  /// Get claim status
  /// C# endpoint: action = "getClaimStatus"
  Future<ApiResponse> getClaimStatus(int claimNo) async {
    try {
      final params = {'claimNo': claimNo};

      return await _postRequest('getClaimStatus', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get claim status: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get inspection details
  /// C# endpoint: action = "getInspection"
  Future<ApiResponse> getInspection(int claimNo) async {
    try {
      final params = {'claimNo': claimNo};

      return await _postRequest('getInspection', params, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get inspection: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get monthly report
  /// C# endpoint: action = "getMyMonthlyReport"
  Future<ApiResponse> getMyMonthlyReport({
    required int year,
    required int month,
  }) async {
    try {
      final params = {'year': year, 'month': month};

      return await _postRequest(
        'getMyMonthlyReport',
        params,
        includeToken: true,
      );
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get report: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Get dashboard claims
  /// C# endpoint: action = "dashboard"
  Future<ApiResponse> getDashboard() async {
    try {
      return await _postRequest('dashboard', {}, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get dashboard: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== PNC CLAIMS ====================

  /// Get PnC claims
  /// C# endpoint: action = "get-pnc-claims"
  Future<ApiResponse> getPnCClaims() async {
    try {
      return await _postRequest('get-pnc-claims', {}, includeToken: true);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to get PnC claims: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  // ==================== CORE METHODS ====================

  /// Main POST request method
  Future<ApiResponse> _postRequest(
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
          // Use 'token' parameter name as per C# API
          params['token'] = userToken['token'];
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
              throw Exception('Connection timeout');
            },
          );

      // Parse response
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Network error: ${e.message}',
        error: 'CLIENT_EXCEPTION',
        data: null,
      );
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Request failed: ${e.toString()}',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Handle HTTP response
  ApiResponse _handleResponse(http.Response response) {
    try {
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return ApiResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 404) {
        return ApiResponse(
          status: 404,
          message: 'API endpoint not found',
          error: 'NOT_FOUND',
          data: null,
        );
      } else if (response.statusCode == 500) {
        return ApiResponse(
          status: 500,
          message: 'Server error',
          error: 'SERVER_ERROR',
          data: null,
        );
      } else {
        return ApiResponse(
          status: response.statusCode,
          message: 'HTTP Error: ${response.statusCode}',
          error: response.body,
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to parse response',
        error: e.toString(),
        data: null,
      );
    }
  }

  /// Create HMAC SHA256 signature (same as C# implementation)
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
  Future<Map<String, String>?> _getUserToken() async {
    try {
      const storage = FlutterSecureStorage();
      print(storage.read(key: 'user_data'));
      final encrypted = await storage.read(key: 'user_data');

      if (encrypted != null && encrypted.isNotEmpty) {
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

  /// Log request details for debugging
  void _logRequest(String action, Map<String, dynamic> params) {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return; // Don't log in production
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
