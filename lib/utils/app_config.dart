import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DBMode { production, development, test }

class AppConfig {
  static const String _dbModeKey = 'DBMode';
  static const String _prefName = 'app_preferences';

  // API URLs from Android strings.xml
  static const String _apiUrlProduction =
      'https://apid.sales.agl-allianz.com/api/';
  static const String _apiUrlDevelopment =
      'https://it06.agl-allianz.com/claimapi/api/';
  static const String _apiUrlTest = 'https://uatd.sales.agl-allianz.com/api/';

  static const String _mediaUrlProduction =
      'https://apid.sales.agl-allianz.com/api/MediaUpload.ashx';
  static const String _mediaUrlDevelopment =
      'https://it06.agl-allianz.com/claimapi/api/MediaUpload.ashx';
  static const String _mediaUrlTest =
      'https://uatd.sales.agl-allianz.com/api/MediaUpload.ashx';

  static const String _photoUrlProduction =
      'https://apid.sales.agl-allianz.com/PhotoViewer.aspx';
  static const String _photoUrlDevelopment =
      'https://it06.agl-allianz.com/claimapi/PhotoViewer.aspx';
  static const String _photoUrlTest =
      'https://uatd.sales.agl-allianz.com/PhotoViewer.aspx';

  static const String _inspectionPhotoUrlProduction =
      'https://apid.sales.agl-allianz.com/api/Photo.aspx';
  static const String _inspectionPhotoUrlDevelopment =
      'https://inspectionuat.agl-allianz.com/api/Photo.aspx';
  static const String _inspectionPhotoUrlTest =
      'https://uatd.sales.agl-allianz.com/api/Photo.aspx';

  // Get DB Mode
  Future<DBMode> getDBMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_dbModeKey) ?? 'PRODUCTION';

      switch (modeString.toUpperCase()) {
        case 'DEVELOPMENT':
          return DBMode.development;
        case 'TEST':
          return DBMode.test;
        default:
          return DBMode.production;
      }
    } catch (e) {
      return DBMode.production;
    }
  }

  // Change DB Mode
  Future<void> changeDBMode(DBMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dbModeKey, mode.name.toUpperCase());
    } catch (e) {
      print('Error changing DB mode: $e');
    }
  }

  // Get API URL based on current mode
  Future<String> getApiUrl() async {
    final mode = await getDBMode();
    switch (mode) {
      case DBMode.development:
        return _apiUrlDevelopment;
      case DBMode.test:
        return _apiUrlTest;
      default:
        return _apiUrlProduction;
    }
  }

  // Get Media Upload URL
  Future<String> getMediaUploadUrl() async {
    final mode = await getDBMode();
    switch (mode) {
      case DBMode.development:
        return _mediaUrlDevelopment;
      case DBMode.test:
        return _mediaUrlTest;
      default:
        return _mediaUrlProduction;
    }
  }

  // Get Photo URL
  Future<String> getPhotoUrl({
    required int claimNo,
    required String type,
    required String filename,
    bool thumbnail = false,
  }) async {
    final mode = await getDBMode();
    String baseUrl;

    switch (mode) {
      case DBMode.development:
        baseUrl = _photoUrlDevelopment;
        break;
      case DBMode.test:
        baseUrl = _photoUrlTest;
        break;
      default:
        baseUrl = _photoUrlProduction;
    }

    String url = '$baseUrl?t=$type&c=$claimNo&f=$filename';
    if (thumbnail) {
      url += '&width=120';
    }
    if (mode == DBMode.test) {
      url += '&db_mode=Test';
    }

    return url;
  }

  // Get Inspection Photo URL
  Future<String> getInspectionPhotoUrl({
    required int id,
    bool compressed = false,
  }) async {
    final mode = await getDBMode();
    String baseUrl;

    switch (mode) {
      case DBMode.development:
        baseUrl = _inspectionPhotoUrlDevelopment;
        break;
      case DBMode.test:
        baseUrl = _inspectionPhotoUrlTest;
        break;
      default:
        baseUrl = _inspectionPhotoUrlProduction;
    }

    String url = '$baseUrl?id=$id';
    if (compressed) {
      url += '&width=200';
    }
    if (mode == DBMode.test) {
      url += '&db_mode=Test';
    }

    return url;
  }

  // Get App Version
  Future<String> getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.0.0';
    }
  }

  // Get App Build Number
  Future<String> getBuildNumber() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      return '1';
    }
  }

  // Save preference data
  Future<void> savePrefString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      print('Error saving preference: $e');
    }
  }

  // Get preference data
  Future<String?> getPrefString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      print('Error getting preference: $e');
      return null;
    }
  }

  // Save boolean preference
  Future<void> savePrefBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      print('Error saving boolean preference: $e');
    }
  }

  // Get boolean preference
  Future<bool> getPrefBool(String key, {bool defaultValue = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      print('Error getting boolean preference: $e');
      return defaultValue;
    }
  }

  // Clear all app data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  // Log data (for debugging)
  Future<void> logData(String tag, String message) async {
    print('[$tag] $message');
    // You can also save logs to a file if needed
  }
}
