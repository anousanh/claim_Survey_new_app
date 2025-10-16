// lib/widgets/case_detail/status_chip.dart
import 'package:claim_survey_app/model/task_model.dart';
import 'package:flutter/material.dart';

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

  StatusConfig _getStatusConfig(TaskStatus status) {
    switch (status) {
      case TaskStatus.newTask:
        return StatusConfig('ໃໝ່', Colors.blue, Icons.fiber_new);
      case TaskStatus.inProgress:
        return StatusConfig(
          'ກຳລັງດຳເນີນການ',
          Colors.orange,
          Icons.pending_actions,
        );
      case TaskStatus.completed:
        return StatusConfig('ສຳເລັດ', Colors.green, Icons.check_circle);
      case TaskStatus.cancelled:
        return StatusConfig('ຍົກເລີກ', Colors.red, Icons.cancel);
    }
  }
}

class StatusConfig {
  final String text;
  final Color color;
  final IconData icon;

  StatusConfig(this.text, this.color, this.icon);
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
