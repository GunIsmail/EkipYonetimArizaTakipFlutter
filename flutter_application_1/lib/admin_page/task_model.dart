// lib/admin_page/task_model.dart
// ignore: unused_import
import 'package:flutter/material.dart';

enum TaskStatus {
  NEW, // Yeni Kayıt
  IN_PROGRESS, // Süreçte
  COMPLETED, // Tamamlandı
  CANCELLED, // İptal Edildi
  UNKNOWN,
}

class WorkOrder {
  final int id;
  final String title;
  final String description;
  final String customerAddress;
  final String customerPhone;
  final String categoryName;
  final TaskStatus status;
  final String statusDisplay;
  final int? assignedWorkerId;
  final String? assignedWorkerName;
  final DateTime createdAt;

  WorkOrder({
    required this.id,
    required this.title,
    required this.description,
    required this.customerAddress,
    required this.customerPhone,
    required this.categoryName,
    required this.status,
    required this.statusDisplay,
    this.assignedWorkerId,
    this.assignedWorkerName,
    required this.createdAt,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    // Django'dan gelen durum string'ini Dart Enum'a çevirme
    TaskStatus _getStatus(String statusStr) {
      switch (statusStr) {
        case 'NEW':
          return TaskStatus.NEW;
        case 'IN_PROGRESS':
          return TaskStatus.IN_PROGRESS;
        case 'COMPLETED':
          return TaskStatus.COMPLETED;
        case 'CANCELLED':
          return TaskStatus.CANCELLED;
        default:
          return TaskStatus.UNKNOWN;
      }
    }

    return WorkOrder(
      id: json['id'] as int,
      title: json.get('title') as String? ?? 'Başlık Yok',
      description: json.get('description') as String? ?? 'Açıklama Yok',
      customerAddress: json.get('customer_address') as String? ?? 'Adres Yok',
      customerPhone: json.get('customer_phone') as String? ?? 'Telefon Yok',
      categoryName: json.get('category_name') as String? ?? 'Bilinmiyor',
      status: _getStatus(json.get('status') as String? ?? 'UNKNOWN'),
      statusDisplay: json.get('status_display') as String? ?? 'Bilinmiyor',

      // Atanmış personel bilgileri null gelebilir (Personel atamayı kaldırdık, bu alan null gelmeli)
      assignedWorkerId: json.get('assigned_worker') as int?,
      assignedWorkerName: json.get('assigned_worker_name') as String?,

      // Django ISO formatından DateTime'a dönüştürülür
      createdAt: DateTime.parse(json.get('created_at') as String).toLocal(),
    );
  }
}

// Map'ten güvenli okuma için uzantı (opsiyonel)
extension on Map {
  dynamic get(String key) => this[key];
}
