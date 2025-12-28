// lib/services/task_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Definitions.dart';
import '../admin_page/task_model.dart';

class TaskService {
  // 1. Görevleri Listeleme (Aynı kalabilir)
  Future<List<WorkOrder>> fetchTasksByStatus(String statusFilter) async {
    final uri = Uri.parse('${Api.baseUrl}/api/tasks/?status=$statusFilter');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        // Karakter sorununu çözmek için utf8.decode ekliyoruz
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => WorkOrder.fromJson(json)).toList();
      } else {
        print('Veri Çekme Hatası: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('TaskService Fetch Hatası: $e');
      return [];
    }
  }

  // 2. GÖREV ATAMA (Burası Güncellendi)
  Future<bool> assignTaskToWorker(
    int taskId,
    String workerId,
    String note,
  ) async {
    // Backend'de yeni açtığımız yol: /api/tasks/{id}/assign/
    final uri = Uri.parse('${Api.baseUrl}/api/tasks/$taskId/assign/');

    // DEBUG: Ne gönderdiğimizi konsolda görelim
    print("--- ATAMA İSTEĞİ BAŞLIYOR ---");
    print("URL: $uri");
    print("GİDEN VERİ: worker_id=$workerId, admin_note=$note");

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer ...' // Token kullanıyorsanız burayı açın
        },
        body: jsonEncode({
          'worker_id': workerId, // Backend'in beklediği anahtar
          'admin_note': note,
        }),
      );

      print("SUNUCU YANITI (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        // Hata varsa false dönüyoruz ama yukarıdaki print sayesinde hatayı görüyoruz
        return false;
      }
    } catch (e) {
      print('TaskService Assign BAĞLANTI HATASI: $e');
      return false;
    }
  }

  // 3. Görev Oluşturma (Create)
  Future<Map<String, dynamic>> createTask({
    required String title,
    required String description,
    required String address,
    required String phone,
  }) async {
    final uri = Uri.parse('${Api.baseUrl}/api/tasks/create/');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'customer_address': address,
          'customer_phone': phone,
          'status': 'NEW',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Arıza kaydı başarıyla oluşturuldu.',
        };
      } else {
        // Sunucu hata mesajını yakala
        var errorMessage = 'Bilinmeyen hata';
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
          errorMessage = errorBody['detail'] ?? errorBody.toString();
        } catch (_) {
          errorMessage = response.body;
        }

        return {
          'success': false,
          'message': 'Sunucu Hatası (${response.statusCode}): $errorMessage',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı Hatası: $e'};
    }
  }
}
