// lib/services/background_location_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Background service for continuous location tracking
class BackgroundLocationService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize background service - Call this in main()
  static Future<void> initializeService() async {
    // Initialize notifications
    await _initializeNotifications();

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_tracking_channel',
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'ກຳລັງຕິດຕາມຕຳແໜ່ງຂອງທ່ານ...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Initialize notification channels
  static Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(initializationSettings);

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_tracking_channel',
      'Location Tracking',
      description: 'This channel is used for location tracking notifications',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Start tracking service
  static Future<void> startTracking({
    required String taskId,
    required String taskTitle,
  }) async {
    // Save task info to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_task_id', taskId);
    await prefs.setString('current_task_title', taskTitle);
    await prefs.setBool('is_tracking', true);

    await _service.startService();
  }

  /// Stop tracking service
  static Future<void> stopTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tracking', false);
    await prefs.remove('current_task_id');
    await prefs.remove('current_task_title');

    _service.invoke('stopService');
  }

  /// Check if service is running
  static Future<bool> isServiceRunning() async {
    return await _service.isRunning();
  }

  /// Get service instance for listening to updates
  static FlutterBackgroundService get service => _service;

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Main background service logic
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // For Android, set up foreground notification
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });

      // Set as foreground immediately
      service.setAsForegroundService();
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Start location tracking every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // Get current location
          try {
            final prefs = await SharedPreferences.getInstance();
            bool isTracking = prefs.getBool('is_tracking') ?? false;

            if (!isTracking) {
              timer.cancel();
              service.stopSelf();
              return;
            }

            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );

            String taskId = prefs.getString('current_task_id') ?? '';
            String taskTitle = prefs.getString('current_task_title') ?? '';

            // Update notification with current location
            service.setForegroundNotificationInfo(
              title: 'ກຳລັງຕິດຕາມ: $taskTitle',
              content:
                  'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
            );

            // Send to server
            await _sendLocationToServer(
              taskId: taskId,
              latitude: position.latitude,
              longitude: position.longitude,
              speed: position.speed,
              heading: position.heading,
            );

            // Send update to UI (if app is open)
            service.invoke('update', {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'speed': position.speed,
              'heading': position.heading,
              'timestamp': DateTime.now().toIso8601String(),
            });

            debugPrint(
              'Background location: ${position.latitude}, ${position.longitude}',
            );
          } catch (e) {
            debugPrint('Error getting location: $e');
          }
        }
      }
    });
  }

  /// Send location to your backend server
  static Future<void> _sendLocationToServer({
    required String taskId,
    required double latitude,
    required double longitude,
    required double speed,
    required double heading,
  }) async {
    try {
      // Replace with your actual API endpoint
      final url = Uri.parse('https://your-api.com/api/location/update');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Add your auth token here if needed
          // 'Authorization': 'Bearer YOUR_TOKEN',
        },
        body: json.encode({
          'task_id': taskId,
          'latitude': latitude,
          'longitude': longitude,
          'speed': speed,
          'heading': heading,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Location sent successfully');
      } else {
        debugPrint('Failed to send location: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending location: $e');
      // You can store location offline here if server is unreachable
    }
  }
}
