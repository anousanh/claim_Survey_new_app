// lib/widgets/case_detail/activity_timeline.dart
import 'package:claim_survey_app/model/activity_step.dart';
import 'package:claim_survey_app/screen/case_detail_screen.dart';
import 'package:flutter/material.dart';

class ActivityTimeline extends StatelessWidget {
  final List<ActivityStep> steps;

  const ActivityTimeline({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return _ActivityTimelineItem(step: step, isLast: isLast);
      }).toList(),
    );
  }
}

class _ActivityTimelineItem extends StatelessWidget {
  final ActivityStep step;
  final bool isLast;

  const _ActivityTimelineItem({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0099FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, size: 20, color: const Color(0xFF0099FF)),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(step.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'ຫາກໍ່';
    if (difference.inMinutes < 60) return '${difference.inMinutes} ນາທີກ່ອນ';
    if (difference.inHours < 24) return '${difference.inHours} ຊົ່ວໂມງກ່ອນ';
    if (difference.inDays < 7) return '${difference.inDays} ມື້ກ່ອນ';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
