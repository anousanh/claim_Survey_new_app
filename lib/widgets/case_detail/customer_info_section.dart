// lib/widgets/case_detail/customer_info_section.dart
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
        _InfoRow(
          label: 'ຊື່ລູກຄ້າ',
          value: task.customerName,
          icon: Icons.person_outline,
        ),
        _InfoRow(
          label: 'ເບີໂທລະສັບ',
          value: task.declarerMobile ?? 'ບໍ່ລະບຸ',
          icon: Icons.phone,
        ),
        // if (task.customerEmail != null)
        //   _InfoRow(
        //     label: 'ອີເມວ',
        //     value: task.customerEmail!,
        //     icon: Icons.email,
        //   ),
        _InfoRow(
          label: 'ທະບຽນລົດ',
          value: '${task.plateNumber ?? ''} ${task.plateProvince ?? ''}',
          icon: Icons.directions_car,
        ),
        if (task.vehicle != null)
          _InfoRow(
            label: 'ຍານພາຫະນະ',
            value: task.vehicle!,
            icon: Icons.car_repair,
          ),
        _InfoRow(
          label: 'ສະຖານທີ່ເກີດອຸບັດຕິເຫດ',
          value: task.accidentPlace ?? task.location,
          icon: Icons.location_on,
        ),
        if (task.accidentDate != null)
          _InfoRow(
            label: 'ວັນທີ່ເກີດອຸບັດຕິເຫດ',
            value: task.accidentDate!,
            icon: Icons.calendar_today,
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0099FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF0099FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D3436),
                    fontWeight: FontWeight.w600,
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

// Description Section Widget
class DescriptionSection extends StatelessWidget {
  final String description;

  const DescriptionSection({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return InfoSection(
      title: 'ລາຍລະອຽດ',
      icon: Icons.description,
      children: [
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2D3436),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// Generic Info Section Container
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0099FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF0099FF)),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
