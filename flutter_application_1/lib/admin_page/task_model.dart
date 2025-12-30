// lib/admin_page/task_model.dart

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
    TaskStatus getStatus(String? statusStr) {
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
      title: json['title'] as String? ?? 'Başlık Yok',
      description: json['description'] as String? ?? 'Açıklama Yok',
      customerAddress: json['customer_address'] as String? ?? 'Adres Yok',
      customerPhone: json['customer_phone'] as String? ?? 'Telefon Yok',
      categoryName: json['category_name'] as String? ?? 'Bilinmiyor',
      status: getStatus(json['status'] as String?),
      statusDisplay: json['status_display'] as String? ?? 'Bilinmiyor',
      assignedWorkerId: json['assigned_worker'] as int?,
      assignedWorkerName: json['assigned_worker_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
