// lib/model/task_model.dart - Extended with API support

enum TaskStatus { newTask, inProgress, completed, cancelled }

enum TaskCategory { accident, additional }

class Task {
  final String claimNumber;
  final String title;
  final String customerName;
  final String location;
  final String policyType;
  final DateTime assignedDate;
  final TaskStatus status;
  final TaskCategory category;
  final bool isUrgent;
  final String? description;
  final double? lat;
  final double? lng;

  // Additional fields from API
  final String? plateNumber;
  final String? plateProvince;
  final String? plateColorID;
  final String? vehicle;
  final String? declarerMobile;
  final String? accidentPlace;
  final String? accidentDate;
  final String? vipRemark;
  final int? vip;
  final int? certificateNumber;
  final String? responseTime;
  final String? arriveTime;
  final String? uploadTime;
  final String? finishedTime;
  final int? taskNo;
  final String? taskType;

  // Button completion flags
  final bool? btnDocuments;
  final bool? btnCostEstimate;
  final bool? btnResponsibility;
  final bool? btnGarageRequest;
  final bool? btnOpponent;
  final bool? btnAgreement;
  final bool? btnPolice;

  Task({
    required this.claimNumber,
    required this.title,
    required this.customerName,
    required this.location,
    required this.policyType,
    required this.assignedDate,
    required this.status,
    required this.category,
    this.isUrgent = false,
    this.description,
    this.lat,
    this.lng,
    this.plateNumber,
    this.plateProvince,
    this.plateColorID,
    this.vehicle,
    this.declarerMobile,
    this.accidentPlace,
    this.accidentDate,
    this.vipRemark,
    this.vip,
    this.certificateNumber,
    this.responseTime,
    this.arriveTime,
    this.uploadTime,
    this.finishedTime,
    this.taskNo,
    this.taskType,
    this.btnDocuments,
    this.btnCostEstimate,
    this.btnResponsibility,
    this.btnGarageRequest,
    this.btnOpponent,
    this.btnAgreement,
    this.btnPolice,
  });

  /// Create Task from API JSON response
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      claimNumber:
          json['claimNo']?.toString() ?? json['policyNumber']?.toString() ?? '',
      title: json['title'] ?? 'ຄະດີອຸບັດຕິເຫດ',
      customerName: json['declarer'] ?? json['customerName'] ?? '',
      location: json['accidentPlace'] ?? json['location'] ?? '',
      policyType: _parsePolicyType(
        json['policyType'] ?? json['certificateType'] ?? 'car',
      ),
      assignedDate: _parseDate(json['assignedDate'] ?? json['accidentDate']),
      status: _parseStatus(json['taskStatus'] ?? json['status'] ?? 6),
      category: _parseCategory(json['taskType'] ?? json['category']),
      isUrgent: json['vip'] == 1 || json['isUrgent'] == true,
      description: json['description'] ?? json['remark'],
      lat: _parseDouble(json['accidentLat'] ?? json['lat']),
      lng: _parseDouble(json['accidentLong'] ?? json['lng']),
      plateNumber: json['plateNumber'],
      plateProvince: json['plateProvince'],
      plateColorID: json['plateColorID'],
      vehicle: json['vehicle'],
      declarerMobile: json['declarerMobile'] ?? json['mobile'],
      accidentPlace: json['accidentPlace'],
      accidentDate: json['accidentDate'],
      vipRemark: json['vipRemark'],
      vip: json['vip'],
      certificateNumber: json['certificateNumber'],
      responseTime: json['responseTime'],
      arriveTime: json['arriveTime'],
      uploadTime: json['uploadTime'],
      finishedTime: json['finishedTime'],
      taskNo: json['taskNo'],
      taskType: json['taskType'],
      btnDocuments: json['btnDocuments'] ?? false,
      btnCostEstimate: json['btnCostEstimate'] ?? false,
      btnResponsibility: json['btnResponsibility'] ?? false,
      btnGarageRequest: json['btnGarageRequest'] ?? false,
      btnOpponent: json['btnOpponent'] ?? false,
      btnAgreement: json['btnAgreement'] ?? false,
      btnPolice: json['btnPolice'] ?? false,
    );
  }

  /// Convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'claimNumber': claimNumber,
      'title': title,
      'customerName': customerName,
      'location': location,
      'policyType': policyType,
      'assignedDate': assignedDate.toIso8601String(),
      'status': status.index,
      'category': category.index,
      'isUrgent': isUrgent,
      'description': description,
      'lat': lat,
      'lng': lng,
      'plateNumber': plateNumber,
      'plateProvince': plateProvince,
      'vehicle': vehicle,
      'declarerMobile': declarerMobile,
      'taskNo': taskNo,
      'taskType': taskType,
    };
  }

  /// Parse policy type from API
  static String _parsePolicyType(dynamic type) {
    if (type == null) return 'car';
    final typeStr = type.toString().toLowerCase();
    if (typeStr.contains('car') ||
        typeStr.contains('motor') ||
        typeStr == 'mt') {
      return 'car';
    } else if (typeStr.contains('home') || typeStr.contains('house')) {
      return 'home';
    } else if (typeStr.contains('health') || typeStr.contains('medical')) {
      return 'health';
    }
    return 'car';
  }

  /// Parse status from API (Java uses integers)
  static TaskStatus _parseStatus(dynamic status) {
    if (status is int) {
      switch (status) {
        case 6:
          return TaskStatus.newTask; // New/Assigned
        case 7:
        case 8:
          return TaskStatus.inProgress; // Accepted/In Progress
        case 20:
          return TaskStatus.completed; // Finished
        case 9:
        case 10:
          return TaskStatus.cancelled; // Rejected/Cancelled
        default:
          return TaskStatus.newTask;
      }
    }

    if (status is String) {
      switch (status.toLowerCase()) {
        case 'new':
        case 'newtask':
          return TaskStatus.newTask;
        case 'inprogress':
        case 'in_progress':
          return TaskStatus.inProgress;
        case 'completed':
          return TaskStatus.completed;
        case 'cancelled':
          return TaskStatus.cancelled;
        default:
          return TaskStatus.newTask;
      }
    }

    return TaskStatus.newTask;
  }

  /// Parse category from API
  static TaskCategory _parseCategory(dynamic category) {
    if (category == null) return TaskCategory.accident;

    final categoryStr = category.toString().toLowerCase();
    if (categoryStr.contains('resolv') || categoryStr.contains('additional')) {
      return TaskCategory.additional;
    }
    return TaskCategory.accident;
  }

  /// Parse date from API
  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();

    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        // Try parsing different formats
        try {
          // Format: dd/MM/yyyy HH:mm
          final parts = date.split(' ');
          if (parts.length == 2) {
            final dateParts = parts[0].split('/');
            final timeParts = parts[1].split(':');
            if (dateParts.length == 3 && timeParts.length == 2) {
              return DateTime(
                int.parse(dateParts[2]),
                int.parse(dateParts[1]),
                int.parse(dateParts[0]),
                int.parse(timeParts[0]),
                int.parse(timeParts[1]),
              );
            }
          }
        } catch (e2) {
          print('Date parsing error: $e2');
        }
      }
    }

    return DateTime.now();
  }

  /// Parse double from API
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Create a copy with updated fields
  Task copyWith({
    String? policyNumber,
    String? title,
    String? customerName,
    String? location,
    String? policyType,
    DateTime? assignedDate,
    TaskStatus? status,
    TaskCategory? category,
    bool? isUrgent,
    String? description,
    double? lat,
    double? lng,
    String? plateNumber,
    String? plateProvince,
    String? vehicle,
    String? declarerMobile,
    int? taskNo,
    String? taskType,
  }) {
    return Task(
      claimNumber: claimNumber,
      title: title ?? this.title,
      customerName: customerName ?? this.customerName,
      location: location ?? this.location,
      policyType: policyType ?? this.policyType,
      assignedDate: assignedDate ?? this.assignedDate,
      status: status ?? this.status,
      category: category ?? this.category,
      isUrgent: isUrgent ?? this.isUrgent,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      plateNumber: plateNumber ?? this.plateNumber,
      plateProvince: plateProvince ?? this.plateProvince,
      vehicle: vehicle ?? this.vehicle,
      declarerMobile: declarerMobile ?? this.declarerMobile,
      taskNo: taskNo ?? this.taskNo,
      taskType: taskType ?? this.taskType,
      btnDocuments: this.btnDocuments,
      btnCostEstimate: this.btnCostEstimate,
      btnResponsibility: this.btnResponsibility,
      btnGarageRequest: this.btnGarageRequest,
      btnOpponent: this.btnOpponent,
      btnAgreement: this.btnAgreement,
      btnPolice: this.btnPolice,
    );
  }
}
