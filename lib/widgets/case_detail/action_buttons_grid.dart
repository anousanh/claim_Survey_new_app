// lib/widgets/case_detail/action_buttons_grid.dart
// Step 4b: Create action buttons grid widget

import 'package:flutter/material.dart';

class ActionButtonsGrid extends StatelessWidget {
  final Map<String, bool> actionCompleted;
  final Function(String action, String title) onActionPressed;

  const ActionButtonsGrid({
    super.key,
    required this.actionCompleted,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ການດຳເນີນການ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _ActionGridButton(
                title: 'ເອກະສານ',
                icon: Icons.upload_file,
                actionKey: 'documents',
                color: Colors.green,
                isCompleted: actionCompleted['documents'] ?? false,
                onPressed: onActionPressed,
              ),
              _ActionGridButton(
                title: 'ປະເມີນຄ່າໃຊ້ຈ່າຍ',
                icon: Icons.attach_money,
                actionKey: 'estimate',
                color: const Color(0xFF0099FF),
                isCompleted: actionCompleted['estimate'] ?? false,
                onPressed: onActionPressed,
              ),
              _ActionGridButton(
                title: 'ຜູ້ຮັບຜິດຊອບ',
                icon: Icons.person_outline,
                actionKey: 'responsible',
                color: const Color(0xFF0099FF),
                isCompleted: actionCompleted['responsible'] ?? false,
                onPressed: onActionPressed,
              ),
              _ActionGridButton(
                title: 'ຮ້ານຊ່ອມ',
                icon: Icons.garage,
                actionKey: 'garage',
                color: const Color(0xFF0099FF),
                isCompleted: actionCompleted['garage'] ?? false,
                onPressed: onActionPressed,
              ),
              _ActionGridButton(
                title: 'ຄູ່ກະຕິ',
                icon: Icons.people_outline,
                actionKey: 'opponent',
                color: const Color(0xFF0099FF),
                isCompleted: actionCompleted['opponent'] ?? false,
                onPressed: onActionPressed,
              ),
              _ActionGridButton(
                title: 'ຂໍ້ຕົກລົງ',
                icon: Icons.handshake,
                actionKey: 'agreement',
                color: const Color(0xFF0099FF),
                isCompleted: actionCompleted['agreement'] ?? false,
                onPressed: onActionPressed,
              ),
              _ActionGridButton(
                title: 'ຕຳຫຼວດ',
                icon: Icons.local_police,
                actionKey: 'police',
                color: const Color(0xFF0099FF),
                isCompleted: actionCompleted['police'] ?? false,
                onPressed: onActionPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionGridButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final String actionKey;
  final Color color;
  final bool isCompleted;
  final Function(String, String) onPressed;

  const _ActionGridButton({
    required this.title,
    required this.icon,
    required this.actionKey,
    required this.color,
    required this.isCompleted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => onPressed(actionKey, title),
      style: OutlinedButton.styleFrom(
        backgroundColor: isCompleted ? color.withOpacity(0.1) : Colors.white,
        side: BorderSide(
          color: isCompleted ? color : Colors.grey[300]!,
          width: isCompleted ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : icon,
            size: 18,
            color: isCompleted ? color : Colors.grey[700],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isCompleted ? color : Colors.grey[700],
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
