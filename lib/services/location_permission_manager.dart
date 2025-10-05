// lib/services/location_permission_manager.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Manages location permission requests and status checks
class LocationPermissionManager {
  /// Request background location permission (Always Allow)
  static Future<bool> requestAlwaysLocationPermission() async {
    // Step 1: Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return false;
    }

    // Step 2: Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // Step 3: If denied, request permission
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return false;
      }
    }

    // Step 4: Check if permanently denied
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return false;
    }

    // Step 5: Request background location (iOS specific)
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Open device location settings
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings page
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Check current permission status
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }
}

/// Helper class for showing permission dialogs
class LocationPermissionHelper {
  /// Show welcome dialog explaining why we need location permission
  static Future<void> showWelcomePermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'ຍິນດີຕ້ອນຮັບ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ແອັບນີ້ຕ້ອງການການອະນຸຍາດສະຖານທີ່ຕະຫຼອດເວລາເພື່ອ:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFF0099FF), size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('ຕິດຕາມຕຳແໜ່ງຂອງທ່ານ')),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.navigation, color: Color(0xFF0099FF), size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('ນຳທາງໄປຫາສະຖານທີ່ເກີດເຫດ')),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.notifications, color: Color(0xFF0099FF), size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('ແຈ້ງເຕືອນລູກຄ້າເມື່ອທ່ານຢູ່ໃກ້ໆ')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('ຕົກລົງ'),
            ),
          ],
        );
      },
    );
  }

  /// Check and request permission with proper flow
  static Future<void> checkAndRequestPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          title: 'ການອະນຸຍາດສະຖານທີ່ຖືກປະຕິເສດ',
          message: 'ກະລຸນາເປີດການອະນຸຍາດໃນການຕັ້ງຄ່າເພື່ອໃຊ້ງານຄຸນສົມບັດນີ້',
          onConfirm: () {
            LocationPermissionManager.openAppSettings();
          },
        );
      }
      return;
    }

    bool granted =
        await LocationPermissionManager.requestAlwaysLocationPermission();

    if (!granted && context.mounted) {
      _showPermissionDialog(
        context,
        title: 'ຕ້ອງການການອະນຸຍາດສະຖານທີ່',
        message: 'ແອັບນີ້ຕ້ອງການສະຖານທີ່ເພື່ອຕິດຕາມຕຳແໜ່ງຂອງທ່ານ',
        onConfirm: () {
          LocationPermissionManager.requestAlwaysLocationPermission();
        },
      );
    }
  }

  /// Show permission dialog with custom message
  static void _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ຍົກເລີກ'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('ເປີດການຕັ້ງຄ່າ'),
            ),
          ],
        );
      },
    );
  }
}
