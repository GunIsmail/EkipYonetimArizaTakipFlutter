import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Definitions.dart'; // Api.workers tanımının burada olduğunu varsayıyoruz

// --- MODEL SINIFI ---
class Worker {
  final String id;
  final String name;
  final String role;
  final String status;
  final Color statusColor;
  final String phone;

  const Worker({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.statusColor,
    required this.phone,
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
        case 'meşgul':
          return Colors.red;
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
    );
  }
}

// --- SERVİS SINIFI ---
class PersonelService {
  final String _apiUrl = Api.workers;

  // Veri Çekme Fonksiyonu
  Future<List<Worker>> fetchWorkers() async {
    // API çalışmazsa kullanılacak yedek veri
    final List<Map<String, dynamic>> simulatedData = [
      {
        'id': 1,
        'name': 'Ahmet Yılmaz',
        'role': 'Usta Elektrikçi',
        'statusText': 'Aktif Görevde',
        'phone': '5551234567',
      },
      {
        'id': 2,
        'name': 'Mehmet Kaya',
        'role': 'Teknisyen',
        'statusText': 'Müsait',
        'phone': '5559876543',
      },
      {
        'id': 3,
        'name': 'Ayşe Demir',
        'role': 'Asistan',
        'statusText': 'İzinli',
        'phone': '5551112233',
      },
      {
        'id': 4,
        'name': 'Can Yücel',
        'role': 'Stajyer',
        'statusText': 'Müsait',
        'phone': '5554445566',
      },
    ];

    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => Worker.fromJson(json)).toList();
      } else {
        // Hata durumunda simüle veriyi dönc
        return simulatedData.map((json) => Worker.fromJson(json)).toList();
      }
    } catch (e) {
      // Bağlantı hatasında simüle veriyi dön
      return simulatedData.map((json) => Worker.fromJson(json)).toList();
    }
  }
}
