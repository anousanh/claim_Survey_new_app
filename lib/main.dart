// lib/main.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/background_location_service.dart';
import 'model/task_model.dart';
import 'screen/task_list_screen.dart';
import 'screen/report/report_screen.dart';
import 'screen/user_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0099FF)),
      ),
      home: const SplashPermissionScreen(),
    );
  }
}

/// First splash screen — handles permissions & first-time setup
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('first_time') ?? true;

    if (isFirstTime) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _showWelcomeDialog();
        await _requestLocationPermission();
        await prefs.setBool('first_time', false);
      }
    } else {
      await _checkPermissionStatus();
    }

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
              Text('ແອັບນີ້ຕ້ອງການການອະນຸຍາດສະຖານທີ່ຕະຫຼອດເວລາເພື່ອ:'),
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
                  Expanded(child: Text('ແຈ້ງເຕືອນລູກຄ້າເມື່ອຢູ່ໃກ້ໆ')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
      await Geolocator.requestPermission();
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
    return const SplashScreen(message: 'ກຳລັງກຽມພ້ອມ...');
  }
}

/// SplashScreen used by both startup & permission screen
class SplashScreen extends StatelessWidget {
  final String message;
  const SplashScreen({super.key, required this.message});

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
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// MainScreen — bottom navigation with notifications
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TaskListScreen(category: TaskCategory.accident),
    const TaskListScreen(category: TaskCategory.additional),
    const ReportScreen(),
    const UserProfileScreen(),
  ];

  final List<String> _titles = [
    'ແກ້ໄຂອຸບັດຕິເຫດ',
    'ແກ້ໄຂຄະດີເພີ່ມເຕີ່ມ',
    'ລາຍງານ',
    'ຂໍ້ມູນຜູ້ໃຊ້',
  ];

  final List<IconData> _icons = [
    Icons.car_crash,
    Icons.add_task,
    Icons.bar_chart,
    Icons.person,
  ];

  final List<String> _labels = [
    'ອຸບັດຕິເຫດ',
    'ຄະດີເພີ່ມເຕີ່ມ',
    'ລາຍງານ',
    'ຂໍ້ມູນຜູ້ໃຊ້',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0099FF),
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _showNotifications,
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0099FF),
        unselectedItemColor: Colors.grey[400],
        items: List.generate(
          _icons.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(_icons[index]),
            label: _labels[index],
          ),
        ),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ການແຈ້ງເຕືອນ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildNotificationItem(
                'ຄະດີໃໝ່',
                'ທ່ານໄດ້ຮັບມອບໝາຍ POL-2024-006',
                '5 ນາທີກ່ອນ',
                Icons.assignment,
                Colors.blue,
              ),
              _buildNotificationItem(
                'ຄະດີດ່ວນ',
                'POL-2024-001 ຕ້ອງການການດຳເນີນການດ່ວນ',
                '1 ຊົ່ວໂມງກ່ອນ',
                Icons.warning,
                Colors.orange,
              ),
              _buildNotificationItem(
                'ລະບົບ',
                'ອັບເດດແອັບໃໝ່ພ້ອມໃຊ້ແລ້ວ',
                '2 ຊົ່ວໂມງກ່ອນ',
                Icons.system_update,
                Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(
    String title,
    String message,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
