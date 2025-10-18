// lib/models/task_model.dart
// UPDATED: Better status parsing for statusCode 10

import 'package:flutter/material.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum TaskStatus { newTask, inProgress, completed, cancelled }

enum TaskCategory { accident, additional }

enum CaseTab {
  newCase('New Case'),
  inProgress('In-Progress'),
  history('History');

  final String label;
  const CaseTab(this.label);
}

// ============================================================================
// STATUS MAPPER - For Case List Tabs
// ============================================================================

class StatusMapper {
  /// Map Solving status code to tab
  static CaseTab getSolvingTab(int statusCode) {
    switch (statusCode) {
      case 6:
        return CaseTab.newCase; // New Case
      case 7:
        return CaseTab.inProgress; // On Going
      case 8:
        return CaseTab.history; // Finish
      case 9:
        return CaseTab.history; // Task-Rejected
      case 10:
        return CaseTab.inProgress; // Doc-Pending
      case 11:
        return CaseTab.inProgress; // Doc-Confirmed
      case 12:
        return CaseTab.inProgress; // Doc-Confirmed
      case 13:
        return CaseTab.inProgress; // Doc-Rejected
      default:
        return CaseTab.newCase;
    }
  }

  /// Map Resolving status code to tab
  static CaseTab getResolvingTab(int statusCode) {
    switch (statusCode) {
      case 17:
        return CaseTab.newCase; // Request
      case 18:
        return CaseTab.inProgress; // Approved
      case 19:
        return CaseTab.history; // Rejected
      case 20:
        return CaseTab.history; // Finished
      case 21:
        return CaseTab.history; // Paid
      default:
        return CaseTab.newCase;
    }
  }

  /// Get status display name
  static String getStatusName(int statusCode, bool isResolving) {
    if (isResolving) {
      switch (statusCode) {
        case 17:
          return 'Request';
        case 18:
          return 'Approved';
        case 19:
          return 'Rejected';
        case 20:
          return 'Finished';
        case 21:
          return 'Paid';
        default:
          return 'Unknown';
      }
    } else {
      switch (statusCode) {
        case 6:
          return 'New Case';
        case 7:
          return 'On Going';
        case 8:
          return 'Finish';
        case 9:
          return 'Task-Rejected';
        case 10:
          return 'Doc-Pending';
        case 11:
          return 'Doc-Confirmed';
        case 12:
          return 'Doc-Confirmed';
        case 13:
          return 'Doc-Rejected';
        default:
          return 'Unknown';
      }
    }
  }

  /// Get status color
  static Color getStatusColor(int statusCode, bool isResolving) {
    if (isResolving) {
      switch (statusCode) {
        case 17:
          return const Color(0xFF2196F3); // Blue
        case 18:
          return const Color(0xFF4CAF50); // Green
        case 19:
          return const Color(0xFFF44336); // Red
        case 20:
          return const Color(0xFF009688); // Teal
        case 21:
          return const Color(0xFF9C27B0); // Purple
        default:
          return const Color(0xFF9E9E9E); // Grey
      }
    } else {
      switch (statusCode) {
        case 6:
          return const Color(0xFF2196F3); // Blue
        case 7:
          return const Color(0xFFFF9800); // Orange
        case 8:
          return const Color(0xFF4CAF50); // Green
        case 9:
          return const Color(0xFFF44336); // Red
        case 10:
          return const Color(0xFFFFC107); // Amber
        case 11:
          return const Color(0xFF009688); // Teal
        case 12:
          return const Color(0xFF009688); // Teal
        case 13:
          return const Color(0xFFFF5722); // Deep Orange
        default:
          return const Color(0xFF9E9E9E); // Grey
      }
    }
  }
}

// ============================================================================
// TASK MODEL
// ============================================================================

class Task {
  final String claimNumber;
  final String title;
  final String customerName;
  final String location;
  final String policyType;
  final DateTime assignedDate;
  final TaskStatus status;
  final int statusCode; // Raw status code from API
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
  final String? customerEmail;

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
    this.statusCode = 6,
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
    this.customerEmail,
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
    final rawStatus = json['taskStatus'] ?? json['status'] ?? 6;

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
      status: _parseStatus(rawStatus),
      statusCode: rawStatus is int ? rawStatus : 6,
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
      customerEmail: json['customerEmail'],
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
      'statusCode': statusCode,
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

  static TaskStatus _parseStatus(dynamic status) {
    if (status is int) {
      switch (status) {
        case 6:
          return TaskStatus.newTask; // New Case
        case 7:
          return TaskStatus.inProgress; // On Going
        case 10:
          return TaskStatus.inProgress; // Doc-Pending (after accept)
        case 11:
          return TaskStatus.inProgress; // Doc-Confirmed
        case 12:
          return TaskStatus.inProgress; // Doc-Confirmed
        case 13:
          return TaskStatus.inProgress; // Doc-Rejected
        case 8:
          return TaskStatus.completed; // Finish
        case 9:
          return TaskStatus.cancelled; // Task-Rejected
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

  static TaskCategory _parseCategory(dynamic category) {
    if (category == null) return TaskCategory.accident;

    final categoryStr = category.toString().toLowerCase();
    if (categoryStr.contains('resolv') || categoryStr.contains('additional')) {
      return TaskCategory.additional;
    }
    return TaskCategory.accident;
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();

    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        try {
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

  Task copyWith({
    String? policyNumber,
    String? title,
    String? customerName,
    String? location,
    String? policyType,
    DateTime? assignedDate,
    TaskStatus? status,
    int? statusCode,
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
      statusCode: statusCode ?? this.statusCode,
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
      responseTime: this.responseTime,
      arriveTime: this.arriveTime,
      uploadTime: this.uploadTime,
      finishedTime: this.finishedTime,
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
