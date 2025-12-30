// lib/services/employee_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Definitions.dart';
import '../admin_page/task_model.dart';
import 'budget_transaction_model.dart';

class EmployeeService {
  // 1. Çalışan Bütçe ve Durum Bilgisini Getir
  Future<Map<String, dynamic>?> fetchWorkerData(int workerId) async {
    try {
      final response = await http.get(Uri.parse(Api.workers));

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));

        // ID eşleşmesi string/int dönüşümüne dikkat edilerek yapılıyor
        final workerData = jsonList.firstWhere(
          (worker) => worker['id'].toString() == workerId.toString(),
          orElse: () => null,
        );
        return workerData;
      }
    } catch (e) {
      print("Veri çekme hatası: $e");
    }
    return null;
  }

  // 2. Müsaitlik Durumunu Güncelle
  Future<bool> updateStatus(int workerId, String newStatus) async {
    const updateUrl = '${Api.baseUrl}/api/workers/update_status/';
    try {
      final response = await http.post(
        Uri.parse(updateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'worker_id': workerId, 'status': newStatus}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<WorkOrder>> fetchTasks(int workerId, String statusFilter) async {
    final uri = Uri.parse(
      '${Api.baseUrl}/api/tasks/?status=$statusFilter&worker_id=$workerId',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => WorkOrder.fromJson(json)).toList();
      }
    } catch (e) {
      print("Task yükleme hatası: $e");
    }
    return [];
  }

  // 4. İş Talep Et (Opsiyonel: Eğer havuzdan iş alacaksa)
  Future<int> requestTask(int taskId, int workerId) async {
    const requestUrl = '${Api.baseUrl}/api/tasks/request_assignment/';
    try {
      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'task_id': taskId, 'worker_id': workerId}),
      );
      return response.statusCode; // 200 veya 201 dönerse başarılı
    } catch (e) {
      return 500; // Hata kodu
    }
  }

  // 5. Bütçe Geçmişini Getir
  Future<List<BudgetTransaction>> fetchBudgetHistory(int workerId) async {
    final uri = Uri.parse(
      '${Api.baseUrl}/api/workers/$workerId/budget-history/',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => BudgetTransaction.fromJson(json)).toList();
      } else {
        print("Geçmiş çekilemedi: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Hata (Geçmiş): $e");
      return [];
    }
  }

  Future<List<WorkOrder>> fetchPoolTasks() async {
    // Status=NEW ve unassigned=true olanları istiyoruz
    final uri = Uri.parse(
      '${Api.baseUrl}/api/tasks/?status=NEW&unassigned=true',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => WorkOrder.fromJson(json)).toList();
      }
    } catch (e) {
      print("Havuz yükleme hatası: $e");
    }
    return [];
  }

  // 6. İşi Tamamla ve Bütçe Onayı İste
  Future<bool> completeTaskWithBudget(
    int taskId,
    int workerId,
    String description,
    double expenseAmount,
  ) async {
    final uri = Uri.parse('${Api.baseUrl}/api/budget/request_approval/');

    try {
      print("DEBUG: Sunucuya istek atılıyor... URL: $uri");

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'work_order_id': taskId,
          'worker_id': workerId,
          'description': description,
          'amount': expenseAmount,
          'status': 'PENDING',
        }),
      );

      print("DEBUG: Sunucu Cevabı (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("HATA: $e");
      return false;
    }
  }
}
