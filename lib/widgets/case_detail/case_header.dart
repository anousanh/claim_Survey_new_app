// lib/widgets/case_detail/case_header.dart
// Step 4a: Create reusable header widgets

import 'package:claim_survey_app/model/task_model.dart';
import 'package:flutter/material.dart';

class CaseHeader extends StatelessWidget {
  final Task task;
  final TaskStatus currentStatus;

  const CaseHeader({
    super.key,
    required this.task,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ເລກທີກະທຳຜິດ: ${task.claimNumber}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StatusChip(status: currentStatus),
              if (task.isUrgent) ...[
                const SizedBox(width: 12),
                const UrgentBadge(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// lib/widgets/case_detail/status_chip.dart
class StatusChip extends StatelessWidget {
  final TaskStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 16, color: config.color),
          const SizedBox(width: 6),
          Text(
            config.text,
            style: TextStyle(
              color: config.color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(TaskStatus status) {
    switch (status) {
      case TaskStatus.newTask:
        return _StatusConfig('ໃໝ່', Colors.blue, Icons.fiber_new);
      case TaskStatus.inProgress:
        return _StatusConfig(
          'ກຳລັງດຳເນີນການ',
          Colors.orange,
          Icons.pending_actions,
        );
      case TaskStatus.completed:
        return _StatusConfig('ສຳເລັດ', Colors.green, Icons.check_circle);
      case TaskStatus.cancelled:
        return _StatusConfig('ຍົກເລີກ', Colors.red, Icons.cancel);
    }
  }
}

class _StatusConfig {
  final String text;
  final Color color;
  final IconData icon;
  _StatusConfig(this.text, this.color, this.icon);
}

class UrgentBadge extends StatelessWidget {
  const UrgentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.priority_high, size: 16, color: Colors.red[700]),
          const SizedBox(width: 4),
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
    );
  }
}
