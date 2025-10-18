// lib/models/case_status.dart
// Step 1: Define case status enums and mappings

import 'package:flutter/material.dart';

enum SolvingStatus {
  newCase(6, 'New Case'),
  onGoing(7, 'On Going'),
  finish(8, 'Finish'),
  taskRejected(9, 'Task-Rejected'),
  docPending(10, 'Doc-Pending'),
  docConfirmed(11, 'Doc-Confirmed'),
  docConfirmed2(12, 'Doc-Confirmed'),
  docRejected(13, 'Doc-Rejected');

  final int code;
  final String description;
  const SolvingStatus(this.code, this.description);

  static SolvingStatus? fromCode(int code) {
    try {
      return SolvingStatus.values.firstWhere((e) => e.code == code);
    } catch (e) {
      return null;
    }
  }
}

enum ResolvingStatus {
  request(17, 'Request'),
  approved(18, 'Approved'),
  rejected(19, 'Rejected'),
  finished(20, 'Finished'),
  paid(21, 'Paid');

  final int code;
  final String description;
  const ResolvingStatus(this.code, this.description);

  static ResolvingStatus? fromCode(int code) {
    try {
      return ResolvingStatus.values.firstWhere((e) => e.code == code);
    } catch (e) {
      return null;
    }
  }
}

enum CaseTab {
  newCase('New Case'),
  inProgress('In-Progress'),
  history('History');

  final String label;
  const CaseTab(this.label);
}

// Helper class to determine which tab a status belongs to
class StatusTabMapper {
  // Map Solving status to tab
  static CaseTab getSolvingTab(int statusCode) {
    switch (statusCode) {
      case 6: // New Case
        return CaseTab.newCase;

      case 7: // On Going
      case 10: // Doc-Pending
      case 11: // Doc-Confirmed
      case 12: // Doc-Confirmed
      case 13: // Doc-Rejected
        return CaseTab.inProgress;

      case 8: // Finish
      case 9: // Task-Rejected
        return CaseTab.history;

      default:
        return CaseTab.newCase;
    }
  }

  // Map Resolving status to tab
  static CaseTab getResolvingTab(int statusCode) {
    switch (statusCode) {
      case 17: // Request
        return CaseTab.newCase;

      case 18: // Approved
        return CaseTab.inProgress;

      case 19: // Rejected
      case 20: // Finished
      case 21: // Paid
        return CaseTab.history;

      default:
        return CaseTab.newCase;
    }
  }

  // Get status display name
  static String getSolvingStatusName(int statusCode) {
    final status = SolvingStatus.fromCode(statusCode);
    return status?.description ?? 'Unknown';
  }

  static String getResolvingStatusName(int statusCode) {
    final status = ResolvingStatus.fromCode(statusCode);
    return status?.description ?? 'Unknown';
  }

  // Get status color
  static Color getSolvingStatusColor(int statusCode) {
    switch (statusCode) {
      case 6: // New Case
        return Colors.blue;
      case 7: // On Going
        return Colors.orange;
      case 8: // Finish
        return Colors.green;
      case 9: // Task-Rejected
        return Colors.red;
      case 10: // Doc-Pending
        return Colors.amber;
      case 11: // Doc-Confirmed
      case 12: // Doc-Confirmed
        return Colors.teal;
      case 13: // Doc-Rejected
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  static Color getResolvingStatusColor(int statusCode) {
    switch (statusCode) {
      case 17: // Request
        return Colors.blue;
      case 18: // Approved
        return Colors.green;
      case 19: // Rejected
        return Colors.red;
      case 20: // Finished
        return Colors.teal;
      case 21: // Paid
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
