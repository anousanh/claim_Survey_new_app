// lib/screens/report_screen.dart
import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement refresh logic
          await Future.delayed(Duration(seconds: 2));
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Performance Overview Card
              _buildPerformanceCard(),
              SizedBox(height: 16),

              // Statistics Grid
              _buildStatisticsGrid(),
              SizedBox(height: 16),

              // Chart Section
              _buildChartCard(),
              SizedBox(height: 16),

              // Recent Activity
              _buildRecentActivityCard(),
              SizedBox(height: 16),

              // Pending Cases Alert
              _buildPendingCasesAlert(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Color(0xFF0099FF), Color(0xFF0066CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ສະຫຼຸບຜົນງານ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.trending_up, color: Colors.white, size: 28),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPerformanceMetric('ວັນນີ້', '3', 'ຄະດີ', Colors.white),
                Container(width: 1, height: 50, color: Colors.white30),
                _buildPerformanceMetric('ອາທິດນີ້', '12', 'ຄະດີ', Colors.white),
                Container(width: 1, height: 50, color: Colors.white30),
                _buildPerformanceMetric('ເດືອນນີ້', '45', 'ຄະດີ', Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.9), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'ຄະດີທັງໝົດ',
          '156',
          Icons.folder_open,
          Colors.blue,
          '+12%',
        ),
        _buildStatCard(
          'ເວລາສະເລ່ຍ',
          '2.5 ຊົ່ວໂມງ',
          Icons.timer,
          Colors.orange,
          '-15%',
        ),
        _buildStatCard(
          'ອັດຕາສຳເລັດ',
          '94%',
          Icons.trending_up,
          Colors.green,
          '+5%',
        ),
        _buildStatCard('ຄະດີຄ້າງ', '7', Icons.warning_amber, Colors.red, null),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String? trend,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                if (trend != null) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: trend.startsWith('+')
                          ? Colors.green[50]
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trend,
                      style: TextStyle(
                        fontSize: 10,
                        color: trend.startsWith('+')
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ສະຖິຕິ 7 ວັນຫຼ້າສຸດ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar('ຈັນ', 0.7, '5'),
                  _buildBar('ອັງຄານ', 0.9, '7'),
                  _buildBar('ພຸດ', 0.5, '3'),
                  _buildBar('ພະຫັດ', 0.8, '6'),
                  _buildBar('ສຸກ', 0.6, '4'),
                  _buildBar('ເສົາ', 0.3, '2'),
                  _buildBar('ອາທິດ', 0.4, '3'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double height, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0099FF),
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: 35,
          height: 100 * height,
          decoration: BoxDecoration(
            color: Color(0xFF0099FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        SizedBox(height: 8),
        Text(day, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ກິດຈະກຳຫຼ້າສຸດ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full history
                  },
                  child: Text('ເບິ່ງທັງໝົດ'),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildActivityItem(
              'ສຳເລັດຄະດີ POL-2024-003',
              '2 ຊົ່ວໂມງກ່ອນ',
              Colors.green,
              Icons.check_circle,
            ),
            _buildActivityItem(
              'ເລີ່ມຄະດີ POL-2024-004',
              '5 ຊົ່ວໂມງກ່ອນ',
              Colors.blue,
              Icons.play_circle,
            ),
            _buildActivityItem(
              'ຮັບຄະດີໃໝ່ POL-2024-005',
              '1 ວັນກ່ອນ',
              Colors.orange,
              Icons.add_circle,
            ),
            _buildActivityItem(
              'ຍົກເລີກຄະດີ POL-2024-002',
              '2 ວັນກ່ອນ',
              Colors.red,
              Icons.cancel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String text,
    String time,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Color(0xFF2D3436)),
            ),
          ),
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildPendingCasesAlert() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ຄະດີທີ່ຕ້ອງຕິດຕາມ',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ທ່ານມີ 3 ຄະດີທີ່ໃກ້ຈະເກີນກຳນົດເວລາ',
                      style: TextStyle(color: Colors.orange[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                // TODO: Navigate to pending cases
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'ເບິ່ງລາຍລະອຽດ',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
