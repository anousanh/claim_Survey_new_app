import 'package:claim_survey_app/screen/task/TaskDetailScreen.dart';
import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'ໜ້າວຽກ',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 20),
        _buildTaskCard(context, 'ແກ້ໄຂອຸບັດຕິເຫດ', Colors.orange, true),
        _buildTaskCard(context, 'ແກ້ໄຂຄະດີເພີມເຕີ່ມ', Colors.blue, false),
        _buildTaskCard(context, 'ຄະດີໃໝ່', Colors.green, false),
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    String title,
    Color color,
    bool isUrgent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.task_alt, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        trailing: isUrgent
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Urgent',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(
                taskTitle: title,
                assignedLat:
                    17.9659061, // Replace with actual coordinates from your database
                assignedLng:
                    102.6135339, // Replace with actual coordinates from your database
                taskId:
                    'TASK001', // Replace with actual task ID from your database
              ),
            ),
          );
        },
      ),
    );
  }
}


// start OT : for app claim survey