// lib/widgets/case_detail/status_action_buttons.dart
// Step 4d: Status action buttons

import 'package:claim_survey_app/model/task_model.dart';
import 'package:flutter/material.dart';

class StatusActionButtons extends StatelessWidget {
  final TaskStatus currentStatus;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final bool isLoading;

  const StatusActionButtons({
    super.key,
    required this.currentStatus,
    required this.onAccept,
    required this.onReject,
    required this.onComplete,
    required this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ປ່ຽນສະຖານະຄະດີ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 16),
          if (currentStatus == TaskStatus.newTask) ...[
            _ActionButton(
              text: 'ຮັບວຽກ',
              color: Colors.blue,
              icon: Icons.check_circle,
              onPressed: isLoading ? null : onAccept,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              text: 'ປະຕິເສດ',
              color: Colors.red,
              icon: Icons.cancel,
              onPressed: isLoading ? null : onReject,
            ),
          ] else if (currentStatus == TaskStatus.inProgress) ...[
            _ActionButton(
              text: 'ສຳເລັດວຽກ',
              color: Colors.green,
              icon: Icons.task_alt,
              onPressed: isLoading ? null : onComplete,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              text: 'ຍົກເລີກ',
              color: Colors.orange,
              icon: Icons.pause_circle,
              onPressed: isLoading ? null : onCancel,
            ),
          ] else if (currentStatus == TaskStatus.completed) ...[
            _StatusCard(
              text: 'ວຽກນີ້ສຳເລັດແລ້ວ',
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ] else if (currentStatus == TaskStatus.cancelled) ...[
            _StatusCard(
              text: 'ວຽກນີ້ຖືກຍົກເລີກ',
              color: Colors.red,
              icon: Icons.cancel,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.text,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String text;
  final MaterialColor color;
  final IconData icon;

  const _StatusCard({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.shade700, size: 24),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: color.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
