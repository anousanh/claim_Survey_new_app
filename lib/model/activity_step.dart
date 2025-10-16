// lib/models/activity_step.dart
// Step 1: Extract ActivityStep from the screen file
// This separates data models from UI

import 'package:flutter/material.dart';

class ActivityStep {
  final DateTime date;
  final String description;
  final IconData icon;

  ActivityStep({
    required this.date,
    required this.description,
    required this.icon,
  });

  factory ActivityStep.fromJson(Map<String, dynamic> json) {
    return ActivityStep(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      description: json['step'] ?? json['description'] ?? '',
      icon: _getIconFromString(json['icon'] ?? 'info'),
    );
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'check':
      case 'check_circle':
        return Icons.check_circle;
      case 'location':
      case 'location_on':
        return Icons.location_on;
      case 'flag':
        return Icons.flag;
      case 'update':
        return Icons.update;
      case 'upload':
        return Icons.upload_file;
      case 'navigation':
        return Icons.navigation;
      default:
        return Icons.info;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'description': description,
      'icon': icon.toString(),
    };
  }
}
