// lib/widgets/case_detail/customer_info_section.dart
// Step 4c: Customer info and other info sections

import 'package:claim_survey_app/model/task_model.dart';
import 'package:flutter/material.dart';

class CustomerInfoSection extends StatelessWidget {
  final Task task;

  const CustomerInfoSection({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return InfoSection(
      title: 'ຂໍ້ມູນລູກຄ້າ',
      icon: Icons.person,
      children: [
        InfoRow(label: 'ຊື່ລູກຄ້າ:', value: task.customerName),
        InfoRow(
          label: 'ປະເພດປະກັນໄພ:',
          value: _getPolicyTypeName(task.policyType),
        ),
        InfoRow(label: 'ສະຖານທີ່:', value: task.location),
        InfoRow(label: 'ວັນທີ່ມອບໝາຍ:', value: _formatDate(task.assignedDate)),
        if (task.declarerMobile != null)
          InfoRow(label: 'ເບີໂທ:', value: task.declarerMobile!),
      ],
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const InfoSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0099FF), size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              style: const TextStyle(
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
}

class DescriptionSection extends StatelessWidget {
  final String description;

  const DescriptionSection({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return InfoSection(
      title: 'ລາຍລະອຽດເພີ່ມເຕີມ',
      icon: Icons.description,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            description,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
