// lib/models/task_model.dart
class Task {
  final String id;
  final String title;
  final String policyNumber;
  final String policyType; // car, home, health
  final TaskStatus status;
  final DateTime assignedDate;
  final String customerName;
  final String location;
  final double? lat;
  final double? lng;
  final bool isUrgent;
  final String? description;
  final TaskCategory category;

  Task({
    required this.id,
    required this.title,
    required this.policyNumber,
    required this.policyType,
    required this.status,
    required this.assignedDate,
    required this.customerName,
    required this.location,
    this.lat,
    this.lng,
    this.isUrgent = false,
    this.description,
    required this.category,
  });
}

enum TaskStatus {
  newTask, // ໃໝ່
  inProgress, // ກຳລັງດຳເນີນການ
  completed, // ສຳເລັດ
  cancelled, // ຍົກເລີກ
}

enum TaskCategory {
  accident, // ແກ້ໄຂອຸບັດຕິເຫດ
  additional, // ແກ້ໄຂຄະດີເພີມເຕີ່ມ
}
