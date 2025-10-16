// lib/widgets/case_detail/check_in_section.dart
import 'package:flutter/material.dart';
import '../../controllers/case_detail_controller.dart';

class CheckInSection extends StatelessWidget {
  final CaseDetailController controller;

  const CheckInSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (controller.isCheckedIn && controller.distanceInKm != null)
            _InfoCard(
              title: 'ໄລຍະຫ່າງ',
              content:
                  '${controller.distanceInKm!.toStringAsFixed(2)} ກມ${controller.duration != null ? ' • ${controller.duration}' : ''}',
              icon: Icons.social_distance,
              color: Colors.orange,
            ),
          if (controller.statusMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: controller.isCheckedIn
                    ? Colors.green[50]
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller.isCheckedIn ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    controller.isCheckedIn ? Icons.check_circle : Icons.info,
                    color: controller.isCheckedIn
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.statusMessage,
                      style: TextStyle(
                        color: controller.isCheckedIn
                            ? Colors.green[900]
                            : Colors.orange[900],
                        fontWeight: FontWeight.w500,
                      ),
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

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
