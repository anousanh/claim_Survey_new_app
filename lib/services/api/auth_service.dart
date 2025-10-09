import 'dart:convert';

import 'package:claim_survey_app/model/User_account.dart';
import 'package:claim_survey_app/model/api_response.dart';
import 'package:claim_survey_app/services/encryption_service.dart';
import 'package:claim_survey_app/utils/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_service.dart';

class AuthService {
  static const String _userDataKey = 'user_data';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();
  final EncryptionService _encryptionService = EncryptionService();
  final AppConfig _appConfig = AppConfig();

  // Login method
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final params = {'username': username, 'password': password};

      final APIResponse response = await _apiService.postRequest(
        'login',
        params,
        includeToken: false,
      );

      if (response.status == 200) {
        final user = response.getData<UserAccount>(
          'user',
          (json) => UserAccount.fromJson(json),
        );

        if (user != null) {
          await saveUserAccount(user);
          return {
            'success': true,
            'user': user,
            'message': 'ເຂົ້າສູ່ລະບົບສຳເລັດ',
          };
        }
      } else if (response.status == 511) {
        return {'success': false, 'message': 'ຊື່ ຫຼື ລະຫັດຜ່ານ ບໍ່ຖືກຕ້ອງ'};
      }

      return {
        'success': false,
        'message': response.message.isNotEmpty
            ? response.message
            : 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ',
      };
    } catch (e) {
      return {'success': false, 'message': 'ເກີດຂໍ້ຜິດພາດ: ${e.toString()}'};
    }
  }

  // Save user account
  Future<void> saveUserAccount(UserAccount user) async {
    try {
      final jsonString = jsonEncode(user.toJson());
      final encrypted = _encryptionService.encrypt(jsonString);
      await _secureStorage.write(key: _userDataKey, value: encrypted);
    } catch (e) {
      print('Error saving user account: $e');
    }
  }

  // Get current user
  Future<UserAccount?> getCurrentUser() async {
    try {
      final encrypted = await _secureStorage.read(key: _userDataKey);
      if (encrypted == null || encrypted.isEmpty) {
        return null;
      }

      final decrypted = _encryptionService.decrypt(encrypted);
      final Map<String, dynamic> json = jsonDecode(decrypted);
      return UserAccount.fromJson(json);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _secureStorage.delete(key: _userDataKey);
      await _appConfig.clearAllData();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null && user.token.isNotEmpty;
  }

  // Update user token
  Future<void> updateToken(String newToken) async {
    try {
      final user = await getCurrentUser();
      if (user != null) {
        final updatedUser = UserAccount(
          id: user.id,
          adjusterCode: user.adjusterCode,
          username: user.username,
          name: user.name,
          mobile: user.mobile,
          adjusterType: user.adjusterType,
          pvId: user.pvId,
          dtId: user.dtId,
          mapLat: user.mapLat,
          mapLong: user.mapLong,
          token: newToken,
        );
        await saveUserAccount(updatedUser);
      }
    } catch (e) {
      print('Error updating token: $e');
    }
  }
}
