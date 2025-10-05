// lib/main.dart
import 'package:claim_survey_app/screen/mainscreen.dart';
import 'package:claim_survey_app/services/background_location_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await BackgroundLocationService.initializeService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Claim Survey App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0099FF),
        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: true,
      ),
      home: const SplashPermissionScreen(),
    );
  }
}

/// Splash screen to handle first-time permission request
class SplashPermissionScreen extends StatefulWidget {
  const SplashPermissionScreen({super.key});

  @override
  State<SplashPermissionScreen> createState() => _SplashPermissionScreenState();
}

class _SplashPermissionScreenState extends State<SplashPermissionScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTimeAndRequestPermission();
  }

  Future<void> _checkFirstTimeAndRequestPermission() async {
    // Check if this is first time opening the app
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('first_time') ?? true;

    if (isFirstTime) {
      // Show welcome dialog
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _showWelcomeDialog();
        await _requestLocationPermission();
        await prefs.setBool('first_time', false);
      }
    } else {
      // Not first time, just check permission status
      await _checkPermissionStatus();
    }

    // Navigate to main screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  Future<void> _showWelcomeDialog() async {
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

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> _checkPermissionStatus() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('Location permission not granted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0099FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Claim Survey App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ກຳລັງກຽມພ້ອມ...',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
