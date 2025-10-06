// lib/screens/case_detail_screen.dart
import 'package:flutter/material.dart';

import '../model/task_model.dart';

class CaseDetailScreen extends StatefulWidget {
  final Task task;
  const CaseDetailScreen({super.key, required this.task});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late TaskStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task.status;
  }

  void _updateStatus(TaskStatus newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });

    // TODO: Call API to update status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ສະຖານະຖືກປ່ຽນແປງແລ້ວ'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back after status update
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }

  void _navigateToMap() {
    // TODO: Implement actual map navigation
    // You can use url_launcher to open Google Maps or integrate a map package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ເປີດແຜນທີ່ໄປຍັງ: ${widget.task.location}'),
        action: SnackBarAction(
          label: 'ເປີດ Google Maps',
          onPressed: () {
            // Launch Google Maps with coordinates
            // final url = 'https://www.google.com/maps/search/?api=1&query=${widget.task.lat},${widget.task.lng}';
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0099FF),
        title: Text('ລາຍລະອຽດຄະດີ', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (widget.task.lat != null && widget.task.lng != null)
            IconButton(
              icon: Icon(Icons.navigation),
              onPressed: _navigateToMap,
              tooltip: 'ນຳທາງໄປຫາສະຖານທີ່',
            ),
          IconButton(
            icon: Icon(Icons.phone),
            onPressed: () {
              // TODO: Implement call functionality
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('ໂທຫາລູກຄ້າ')));
            },
            tooltip: 'ໂທຫາລູກຄ້າ',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ເລກທີກະທຳຜິດ: ${widget.task.policyNumber}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _getStatusChip(_currentStatus),
                      SizedBox(width: 12),
                      if (widget.task.isUrgent)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.priority_high,
                                size: 16,
                                color: Colors.red[700],
                              ),
                              SizedBox(width: 4),
                              Text(
                                'ດ່ວນ',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Customer Info Section
            _buildSection('ຂໍ້ມູນລູກຄ້າ', Icons.person, [
              _buildInfoRow('ຊື່ລູກຄ້າ:', widget.task.customerName),
              _buildInfoRow(
                'ປະເພດປະກັນໄພ:',
                _getPolicyTypeName(widget.task.policyType),
              ),
              _buildInfoRow('ສະຖານທີ່:', widget.task.location),
              _buildInfoRow(
                'ວັນທີ່ມອບໝາຍ:',
                _formatDate(widget.task.assignedDate),
              ),
            ]),

            // Location Section (if coordinates available)
            if (widget.task.lat != null && widget.task.lng != null)
              _buildSection('ພິກັດສະຖານທີ່', Icons.map, [
                _buildInfoRow('Latitude:', widget.task.lat.toString()),
                _buildInfoRow('Longitude:', widget.task.lng.toString()),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _navigateToMap,
                    icon: Icon(Icons.directions),
                    label: Text('ເປີດແຜນທີ່'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ]),

            // Description Section
            if (widget.task.description != null)
              _buildSection('ລາຍລະອຽດເພີ່ມເຕີມ', Icons.description, [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    widget.task.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              ]),

            // Action Buttons
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ປ່ຽນສະຖານະຄະດີ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (_currentStatus == TaskStatus.newTask) ...[
                    _buildActionButton(
                      'ຮັບວຽກ',
                      Colors.blue,
                      Icons.check_circle,
                      () => _confirmStatusChange(
                        TaskStatus.inProgress,
                        'ຮັບວຽກນີ້',
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildActionButton(
                      'ປະຕິເສດ',
                      Colors.red,
                      Icons.cancel,
                      () => _confirmStatusChange(
                        TaskStatus.cancelled,
                        'ປະຕິເສດວຽກນີ້',
                      ),
                    ),
                  ] else if (_currentStatus == TaskStatus.inProgress) ...[
                    _buildActionButton(
                      'ສຳເລັດວຽກ',
                      Colors.green,
                      Icons.task_alt,
                      () => _confirmStatusChange(
                        TaskStatus.completed,
                        'ສຳເລັດວຽກນີ້',
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildActionButton(
                      'ຍົກເລີກ',
                      Colors.orange,
                      Icons.pause_circle,
                      () => _confirmStatusChange(
                        TaskStatus.cancelled,
                        'ຍົກເລີກວຽກນີ້',
                      ),
                    ),
                  ] else if (_currentStatus == TaskStatus.completed) ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[700],
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'ວຽກນີ້ສຳເລັດແລ້ວ',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_currentStatus == TaskStatus.cancelled) ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, color: Colors.red[700], size: 24),
                          SizedBox(width: 12),
                          Text(
                            'ວຽກນີ້ຖືກຍົກເລີກ',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Additional Actions
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Divider(),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement add photo
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ເພີ່ມຮູບພາບ')),
                            );
                          },
                          icon: Icon(Icons.camera_alt),
                          label: Text('ເພີ່ມຮູບ'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement add note
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ເພີ່ມບັນທຶກ')),
                            );
                          },
                          icon: Icon(Icons.note_add),
                          label: Text('ເພີ່ມບັນທຶກ'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3436),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmStatusChange(TaskStatus newStatus, String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ຢືນຢັນການປ່ຽນສະຖານະ'),
          content: Text('ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການ $action?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ຍົກເລີກ'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateStatus(newStatus);
              },
              child: Text(
                'ຢືນຢັນ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getPolicyTypeName(String type) {
    switch (type) {
      case 'car':
        return 'ປະກັນໄພລົດ';
      case 'home':
        return 'ປະກັນໄພເຮືອນ';
      case 'health':
        return 'ປະກັນໄພສຸຂະພາບ';
      default:
        return type;
    }
  }

  Widget _getStatusChip(TaskStatus status) {
    String text;
    Color color;
    IconData icon;

    switch (status) {
      case TaskStatus.newTask:
        text = 'ໃໝ່';
        color = Colors.blue;
        icon = Icons.fiber_new;
        break;
      case TaskStatus.inProgress:
        text = 'ກຳລັງດຳເນີນການ';
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;
      case TaskStatus.completed:
        text = 'ສຳເລັດ';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case TaskStatus.cancelled:
        text = 'ຍົກເລີກ';
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
