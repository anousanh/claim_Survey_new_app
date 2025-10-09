import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'AGL Allianz Claim Survey';
  static const String appVersion = '1.0.0';

  // API Keys from Android strings.xml
  static const String apiKey = '8D494B40136EC90739D3959B52BE1864C245AGL';
  static const String secretKey = 'kJJtvY3c5s0HtpeVrrEblOuWbuFCefxv';
  static const String encryptionSalt = '32sadsss';

  // API Endpoints from Android strings.xml
  static const String apiEndpointProduction =
      'https://apid.sales.agl-allianz.com/api/';
  static const String apiEndpointDevelopment =
      'https://it06.agl-allianz.com/claimapi/api/';
  static const String apiEndpointTest =
      'https://uatd.sales.agl-allianz.com/api/';

  // Media URLs from Android strings.xml
  static const String mediaUrlProduction =
      'https://apid.sales.agl-allianz.com/api/MediaUpload.ashx';
  static const String mediaUrlDevelopment =
      'https://it06.agl-allianz.com/claimapi/api/MediaUpload.ashx';
  static const String mediaUrlTest =
      'https://uatd.sales.agl-allianz.com/api/MediaUpload.ashx';

  // Photo URLs from Android strings.xml
  static const String photoUrlProduction =
      'https://apid.sales.agl-allianz.com/PhotoViewer.aspx';
  static const String photoUrlDevelopment =
      'https://it06.agl-allianz.com/claimapi/PhotoViewer.aspx';
  static const String photoUrlTest =
      'https://uatd.sales.agl-allianz.com/PhotoViewer.aspx';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 180);

  // Image Settings
  static const int maxImageWidth = 1200;
  static const int imageQuality = 95;
  static const int thumbnailWidth = 120;

  // Shared Preferences Keys
  static const String prefUserData = 'user_data';
  static const String prefDbMode = 'DBMode';
  static const String prefAppSettings = 'app_settings';

  // Colors
  static const Color primaryColor = Color(0xFF0099FF);
  static const Color secondaryColor = Color(0xFF2D3436);
  static const Color successColor = Color(0xFF00B894);
  static const Color errorColor = Color(0xFFD63031);
  static const Color warningColor = Color(0xFFFDAA1A);
  static const Color infoColor = Color(0xFF0984E3);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: secondaryColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: secondaryColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: secondaryColor,
  );

  static TextStyle captionStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey[600],
  );

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // API Action Names
  static const String actionLogin = 'login';
  static const String actionLogout = 'logout';
  static const String actionGetClaims = 'getClaims';
  static const String actionGetClaimDetail = 'getClaimDetail';
  static const String actionUpdateClaim = 'updateClaim';
  static const String actionUploadPhoto = 'uploadPhoto';

  // Error Messages (Lao Language)
  static const String errorNetwork = 'ເກີດຂໍ້ຜິດພາດໃນການເຊື່ອມຕໍ່ເຄືອຂ່າຍ';
  static const String errorServer = 'ເກີດຂໍ້ຜິດພາດຈາກເຊີເວີ';
  static const String errorUnknown = 'ເກີດຂໍ້ຜິດພາດທີ່ບໍ່ຮູ້ຈັກ';
  static const String errorInvalidCredentials = 'ຊື່ ຫຼື ລະຫັດຜ່ານ ບໍ່ຖືກຕ້ອງ';
  static const String errorSessionExpired =
      'ເຊດຊັນໝົດອາຍຸ ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່';
  static const String errorNoInternet = 'ບໍ່ມີການເຊື່ອມຕໍ່ອິນເຕີເນັດ';

  // Success Messages
  static const String successLogin = 'ເຂົ້າສູ່ລະບົບສຳເລັດ';
  static const String successLogout = 'ອອກຈາກລະບົບສຳເລັດ';
  static const String successSave = 'ບັນທຶກສຳເລັດ';
  static const String successUpload = 'ອັບໂຫຼດສຳເລັດ';

  // Validation Messages
  static const String validationRequired = 'ກະລຸນາໃສ່ຂໍ້ມູນ';
  static const String validationEmail = 'ກະລຸນາໃສ່ອີເມລທີ່ຖືກຕ້ອງ';
  static const String validationPassword =
      'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວອັກສອນ';
  static const String validationUsername = 'ກະລຸນາໃສ່ຊື່ຜູ້ໃຊ້';

  // Button Labels
  static const String btnLogin = 'ເຂົ້າສູ່ລະບົບ';
  static const String btnLogout = 'ອອກຈາກລະບົບ';
  static const String btnSave = 'ບັນທຶກ';
  static const String btnCancel = 'ຍົກເລີກ';
  static const String btnConfirm = 'ຢືນຢັນ';
  static const String btnSubmit = 'ສົ່ງ';
  static const String btnUpload = 'ອັບໂຫຼດ';
  static const String btnTakePhoto = 'ຖ່າຍຮູບ';

  // Labels
  static const String labelUsername = 'ຊື່ຜູ້ໃຊ້';
  static const String labelPassword = 'ລະຫັດຜ່ານ';
  static const String labelEmail = 'ອີເມລ';
  static const String labelPhone = 'ເບີໂທ';
  static const String labelName = 'ຊື່';
  static const String labelVersion = 'ເວີຊັນ';

  // Hints
  static const String hintUsername = 'username';
  static const String hintPassword = '••••••••';
  static const String hintEmail = 'example@email.com';
  static const String hintSearch = 'ຄົ້ນຫາ...';
}
