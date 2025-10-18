// lib/models/resolve_task_model.dart
// FINAL VERSION - Uses CaseTab and StatusMapper from task_model.dart

import 'package:flutter/material.dart';

import 'task_model.dart'; // Import to use CaseTab and StatusMapper

class ResolveTask {
  final int? id;
  final String requester;
  final String? adjusterCode;
  final int claimNo;
  final int status;
  final String? statusDescription;
  final int? num;
  final String? requestDate;
  final String? responseDate;
  final String? finishDate;
  final String? paidDate;
  final String? location;
  final double? mapLat;
  final double? mapLng;
  final double? distance;
  final String? resolveDate;
  final int? resolveHour;
  final String? reason;

  ResolveTask({
    this.id,
    required this.requester,
    this.adjusterCode,
    required this.claimNo,
    required this.status,
    this.statusDescription,
    this.num,
    this.requestDate,
    this.responseDate,
    this.finishDate,
    this.paidDate,
    this.location,
    this.mapLat,
    this.mapLng,
    this.distance,
    this.resolveDate,
    this.resolveHour,
    this.reason,
  });

  factory ResolveTask.fromJson(Map<String, dynamic> json) {
    return ResolveTask(
      id: json['id'],
      requester: json['requester'] ?? '',
      adjusterCode: json['adjusterCode'],
      claimNo: json['claimNo'] ?? 0,
      status: json['status'] ?? 17,
      statusDescription: json['statusDescription'],
      num: json['num'],
      requestDate: json['requestDate'],
      responseDate: json['responseDate'],
      finishDate: json['finishDate'],
      paidDate: json['paidDate'],
      location: json['location'],
      mapLat: _parseDouble(json['mapLat']),
      mapLng: _parseDouble(json['mapLng']),
      distance: _parseDouble(json['distance']),
      resolveDate: json['resolveDate'],
      resolveHour: json['resolveHour'],
      reason: json['reason'],
    );
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester': requester,
      'adjusterCode': adjusterCode,
      'claimNo': claimNo,
      'status': status,
      'statusDescription': statusDescription,
      'num': num,
      'requestDate': requestDate,
      'responseDate': responseDate,
      'finishDate': finishDate,
      'paidDate': paidDate,
      'location': location,
      'mapLat': mapLat,
      'mapLng': mapLng,
      'distance': distance,
      'resolveDate': resolveDate,
      'resolveHour': resolveHour,
      'reason': reason,
    };
  }

  // Helper methods using StatusMapper from task_model.dart
  CaseTab getTab() => StatusMapper.getResolvingTab(status);

  String getStatusName() => StatusMapper.getStatusName(status, true);

  Color getStatusColor() => StatusMapper.getStatusColor(status, true);

  String getFormattedDate() {
    final date = requestDate ?? resolveDate;
    if (date == null) return '';

    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    } catch (e) {
      return date;
    }
  }

  String get title => 'ຄຳຂໍແກ້ໄຂ #$claimNo';
  String get displayLocation => location ?? 'ບໍ່ລະບຸສະຖານທີ່';
}
