// lib/services/worker_budget_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Definitions.dart'; // Api sınıfının yolu

// --- Worker Modeli ---
class Worker {
  final String id;
  final String name;
  final String role;
  final String status;
  final Color statusColor;
  final String phone;
  final double budget;

  const Worker({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.statusColor,
    required this.phone,
    required this.budget,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    Color _getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'aktif görevde':
          return Colors.green;
        case 'müsait':
          return Colors.orange;
        case 'izinli':
          return Colors.grey;
        default:
          return Colors.blue;
      }
    }

    final String statusText = json['statusText'] as String? ?? 'Bilinmiyor';

    return Worker(
      id: json['id']?.toString() ?? 'N/A',
      name: json['name'] as String? ?? 'Bilinmiyor',
      role: json['role'] as String? ?? 'Tanımlanmadı',
      status: statusText,
      statusColor: _getStatusColor(statusText),
      phone: json['phone'] as String? ?? 'Yok',
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// --- Service Katmanı ---
class WorkerBudgetService {
  static final WorkerBudgetService _instance = WorkerBudgetService._internal();
  factory WorkerBudgetService() => _instance;
  WorkerBudgetService._internal();

  // Personel Listesini Getir
  Future<List<Worker>> fetchWorkers() async {
    final List<Map<String, dynamic>> simulatedData =
        []; // Hata durumunda boş döner veya mock data ekleyebilirsiniz.

    try {
      final response = await http.get(Uri.parse(Api.workers));

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => Worker.fromJson(json)).toList();
      } else {
        return simulatedData.map((json) => Worker.fromJson(json)).toList();
      }
    } catch (e) {
      print('Service Hatası: $e');
      return simulatedData.map((json) => Worker.fromJson(json)).toList();
    }
  }

  // Bütçe Güncelle (True dönerse başarılı, False dönerse başarısız)
  Future<Map<String, dynamic>> updateBudget({
    required String workerId,
    required double newBudget,
    required String description,
  }) async {
    const String updateUrl = '${Api.baseUrl}/api/workers/update_budget/';

    try {
      final response = await http.post(
        Uri.parse(updateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'worker_id': workerId,
          'budget': newBudget,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Bütçe başarıyla güncellendi.'};
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'message': errorBody['error'] ?? 'Bilinmeyen API hatası.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Ağ Hatası: $e'};
    }
  }
}
