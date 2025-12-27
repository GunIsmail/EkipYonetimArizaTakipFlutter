// Dosya: lib/services/task_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Definitions.dart';

/// Yeni bir görev oluşturur.
/// Geriye { 'success': bool, 'message': String? } formatında bir Map döndürür.

class TaskService {
  Future<Map<String, dynamic>> createTask({
    required String title,
    required String description,
    required String address,
    required String phone,
  }) async {
    final uri = Uri.parse('${Api.baseUrl}/api/tasks/create/');

    final Map<String, dynamic> bodyData = {
      'title': title,
      'description': description,
      'customer_address': address,
      'customer_phone': phone,
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Yeni iş emri başarıyla oluşturuldu.',
        };
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage =
            errorBody['error'] ?? errorBody['detail'] ?? jsonEncode(errorBody);
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': 'Ağ Hatası: $e'};
    }
  }
}
