// lib/screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkMode = false;
  String _selectedLanguage = 'ລາວ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0099FF), Color(0xFF0066CC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          'ANS',
                          style: TextStyle(
                            color: Color(0xFF0099FF),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Color(0xFF0099FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ທ. ອານຸສັນ ນັນທະວົງ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Claim Adjuster',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ID: ADJ-2024-001',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stats Row
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('156', 'ຄະດີທັງໝົດ'),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildStatItem('94%', 'ອັດຕາສຳເລັດ'),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildStatItem('4.8', 'ຄະແນນ'),
                ],
              ),
            ),

            // Personal Information Section
            _buildSection('ຂໍ້ມູນສ່ວນຕົວ', Icons.person_outline, [
              _buildInfoTile(
                'ເບີໂທລະສັບ',
                '+856 20 5555 5555',
                true,
                () => _editPhoneNumber(),
              ),
              _buildInfoTile('ອີເມລ', 'anousan@agl.com.la', false, null),
              _buildInfoTile('ພະແນກ', 'IT Department', false, null),
              _buildInfoTile('ສາຂາ', 'ສຳນັກງານໃຫຍ່', false, null),
              _buildInfoTile('ວັນທີ່ເລີ່ມງານ', '01/01/2024', false, null),
            ]),

            // App Settings Section
            _buildSection('ການຕັ້ງຄ່າແອັບ', Icons.settings, [
              _buildSwitchTile(
                'ການແຈ້ງເຕືອນ',
                'ຮັບການແຈ້ງເຕືອນຄະດີໃໝ່',
                Icons.notifications,
                _notificationsEnabled,
                (value) {
                  setState(() => _notificationsEnabled = value);
                  if (value) {
                    // TODO: Request notification permission
                    _requestNotificationPermission();
                  }
                },
              ),
              _buildSwitchTile(
                'ສະຖານທີ່',
                'ອະນຸຍາດການເຂົ້າເຖິງສະຖານທີ່',
                Icons.location_on,
                _locationEnabled,
                (value) {
                  setState(() => _locationEnabled = value);
                  if (value) {
                    // TODO: Request location permission
                    _requestLocationPermission();
                  }
                },
              ),
              _buildSwitchTile(
                'ໂໝດມືດ',
                'ປ່ຽນຮູບແບບສີຂອງແອັບ',
                Icons.dark_mode,
                _darkMode,
                (value) => setState(() => _darkMode = value),
              ),
              _buildLanguageSelector(),
            ]),

            // Account Actions
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildActionButton(
                    'ປ່ຽນລະຫັດຜ່ານ',
                    Icons.lock_outline,
                    Colors.blue,
                    () => _changePassword(),
                  ),
                  SizedBox(height: 12),
                  _buildActionButton(
                    'ກ່ຽວກັບພວກເຮົາ',
                    Icons.info_outline,
                    Colors.grey[600]!,
                    () => _showAboutDialog(),
                  ),
                  SizedBox(height: 12),
                  _buildActionButton(
                    'ອອກຈາກລະບົບ',
                    Icons.logout,
                    Colors.red,
                    () => _showLogoutDialog(),
                  ),
                ],
              ),
            ),

            // App Version
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '© 2024 Claim Survey App',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0099FF),
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF0099FF), size: 24),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    bool isEditable,
    VoidCallback? onEdit,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D3436),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            IconButton(
              icon: Icon(Icons.edit, size: 20, color: Color(0xFF0099FF)),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D3436),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF0099FF),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.language, color: Colors.grey[600], size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ພາສາ',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D3436),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ເລືອກພາສາທີ່ໃຊ້ໃນແອັບ',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              underline: SizedBox(),
              isDense: true,
              items: ['ລາວ', 'English'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editPhoneNumber() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String phoneNumber = '+856 20 5555 5555';
        return AlertDialog(
          title: Text('ແກ້ໄຂເບີໂທລະສັບ'),
          content: TextField(
            controller: TextEditingController(text: phoneNumber),
            decoration: InputDecoration(
              labelText: 'ເບີໂທລະສັບ',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ຍົກເລີກ'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ເບີໂທລະສັບຖືກບັນທຶກແລ້ວ')),
                );
              },
              child: Text('ບັນທຶກ'),
            ),
          ],
        );
      },
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ປ່ຽນລະຫັດຜ່ານ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'ລະຫັດຜ່ານເກົ່າ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'ລະຫັດຜ່ານໃໝ່',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'ຢືນຢັນລະຫັດຜ່ານໃໝ່',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ຍົກເລີກ'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('ລະຫັດຜ່ານຖືກປ່ຽນແລ້ວ')));
              },
              child: Text('ປ່ຽນລະຫັດ'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ກ່ຽວກັບ Claim Survey App'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 64, color: Color(0xFF0099FF)),
              SizedBox(height: 16),
              Text(
                'Claim Survey App',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Version 1.0.0', style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 16),
              Text(
                'ແອັບພລິເຄຊັນສຳລັບການຈັດການຄະດີປະກັນໄພ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                '© 2024 Insurance Company',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ປິດ'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ຢືນຢັນການອອກຈາກລະບົບ'),
          content: Text('ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການອອກຈາກລະບົບ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ຍົກເລີກ'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to login screen
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('ອອກຈາກລະບົບສຳເລັດ')));
              },
              child: Text('ອອກຈາກລະບົບ', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _requestNotificationPermission() {
    // TODO: Implement actual permission request
    // You can use permission_handler package
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('ຂໍອະນຸຍາດການແຈ້ງເຕືອນ')));
  }

  void _requestLocationPermission() {
    // TODO: Implement actual permission request
    // You can use permission_handler or geolocator package
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('ຂໍອະນຸຍາດສະຖານທີ່')));
  }
}
