import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskTitle;
  final double assignedLat;
  final double assignedLng;
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskTitle,
    required this.assignedLat,
    required this.assignedLng,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isLoading = false;
  bool _isCheckedIn = false;
  Position? _currentPosition;
  double? _distanceInKm;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  // Check and request location permissions
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = 'ກະລຸນາເປີດ GPS';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = 'ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງສະຖານທີ່';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage = 'ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງສະຖານທີ່ໃນການຕັ້ງຄ່າ';
      });
      return;
    }
  }

  // Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      setState(() {
        _statusMessage = 'ບໍ່ສາມາດເອົາສະຖານທີ່ປັດຈຸບັນໄດ້: $e';
      });
      return null;
    }
  }

  // Calculate distance between two coordinates
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Convert to km
  }

  // Handle check-in
  Future<void> _handleCheckIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'ກຳລັງກວດສອບສະຖານທີ່...';
    });

    Position? position = await _getCurrentLocation();

    if (position == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    double distance = _calculateDistance(
      widget.assignedLat,
      widget.assignedLng,
      position.latitude,
      position.longitude,
    );

    setState(() {
      _currentPosition = position;
      _distanceInKm = distance;
      _isCheckedIn = true;
      _isLoading = false;
      _statusMessage = 'ເຂົ້າເຮັດວຽກສຳເລັດແລ້ວ!';
    });

    // TODO: Save to database
    await _saveLocationToDatabase(position, distance);
  }

  // Save location to database (implement your backend call here)
  Future<void> _saveLocationToDatabase(
    Position position,
    double distance,
  ) async {
    // Example: Send to your backend API
    /*
    final response = await http.post(
      Uri.parse('YOUR_API_ENDPOINT'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'task_id': widget.taskId,
        'adjuster_lat': position.latitude,
        'adjuster_lng': position.longitude,
        'distance_km': distance,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
    */

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    print('Location saved: ${position.latitude}, ${position.longitude}');
    print('Distance: $distance km');
  }

  // Handle case acceptance
  Future<void> _handleAcceptCase() async {
    if (!_isCheckedIn || _currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ກະລຸນາເຂົ້າເຮັດວຽກກ່ອນ')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Update case status in database
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ຍອມຮັບຄະດີສຳເລັດແລ້ວ!')));
    }
  }

  // Open directions in maps app
  Future<void> _openDirections() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ກະລຸນາເຂົ້າເຮັດວຽກກ່ອນ')));
      return;
    }

    // Google Maps URL with directions
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
      '&destination=${widget.assignedLat},${widget.assignedLng}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ບໍ່ສາມາດເປີດແຜນທີ່ໄດ້')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0099FF),
        elevation: 0,
        title: Text(
          widget.taskTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Location Info Card
            _buildInfoCard(
              'ສະຖານທີ່ທີ່ມອບໝາຍ',
              'Lat: ${widget.assignedLat.toStringAsFixed(6)}\n'
                  'Lng: ${widget.assignedLng.toStringAsFixed(6)}',
              Icons.location_on,
              Colors.blue,
            ),

            const SizedBox(height: 12),

            // Current Location Card (if checked in)
            if (_isCheckedIn && _currentPosition != null)
              _buildInfoCard(
                'ສະຖານທີ່ປັດຈຸບັນ',
                'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                    'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                Icons.my_location,
                Colors.green,
              ),

            if (_isCheckedIn && _currentPosition != null)
              const SizedBox(height: 12),

            // Distance Card (if checked in)
            if (_isCheckedIn && _distanceInKm != null)
              _buildInfoCard(
                'ໄລຍະຫ່າງ',
                '${_distanceInKm!.toStringAsFixed(2)} ກິໂລແມັດ',
                Icons.social_distance,
                Colors.orange,
              ),

            if (_isCheckedIn && _distanceInKm != null)
              const SizedBox(height: 12),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCheckedIn ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isCheckedIn ? Colors.green : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isCheckedIn ? Icons.check_circle : Icons.info,
                      color: _isCheckedIn ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _isCheckedIn
                              ? Colors.green[900]
                              : Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Check-In Button
            if (!_isCheckedIn)
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0099FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ເຂົ້າເຮັດວຽກ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

            // Action Buttons (if checked in)
            if (_isCheckedIn) ...[
              ElevatedButton(
                onPressed: _isLoading ? null : _handleAcceptCase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ຍອມຮັບຄະດີ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openDirections,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF0099FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.directions, color: Color(0xFF0099FF)),
                label: const Text(
                  'ເປີດເສັ້ນທາງນຳທາງ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0099FF),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
