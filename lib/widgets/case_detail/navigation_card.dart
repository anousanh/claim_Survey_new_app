import 'package:flutter/material.dart';
// lib/widgets/case_detail/navigation_instruction_card.dart

class NavigationInstructionCard extends StatelessWidget {
  final String instruction;
  final double remainingDistance;

  const NavigationInstructionCard({
    super.key,
    required this.instruction,
    required this.remainingDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.navigation,
                  color: Color(0xFF0099FF),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    instruction,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ໄລຍະຫ່າງ: ${remainingDistance.toStringAsFixed(2)} ກມ',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
