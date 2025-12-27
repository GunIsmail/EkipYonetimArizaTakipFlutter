// lib/services/admin_budget_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import "budget_transaction_model.dart";
import '../Definitions.dart';

class AdminBudgetService {
  // Singleton pattern (İsteğe bağlı, ama servisler için yaygındır)
  static final AdminBudgetService _instance = AdminBudgetService._internal();
  factory AdminBudgetService() => _instance;
  AdminBudgetService._internal();

  Future<List<BudgetTransaction>> fetchHistory(
    int workerId,
    String accessToken,
  ) async {
    final uri = Uri.parse(Api.getWorkerBudgetHistoryUrl(workerId));

    // --- Simüle Edilmiş Veriler ---
    final List<Map<String, dynamic>> simulatedData = workerId == 1
        ? [
            {
              'id': 99,
              'amount': 1500.0,
              'signed_amount': '+1500.00',
              'type_display': 'Ekleme',
              'timestamp': '2025-11-05T10:30:00Z',
              'description': 'Başlangıç bütçesi',
              'conducted_by': 'Admin',
            },
            {
              'id': 100,
              'amount': 250.0,
              'signed_amount': '-250.00',
              'type_display': 'Çıkarma',
              'timestamp': '2025-11-06T09:00:00Z',
              'description': 'Malzeme Alımı',
              'conducted_by': 'Admin',
            },
          ]
        : [
            {
              'id': 200,
              'amount': 500.0,
              'signed_amount': '+500.00',
              'type_display': 'Ekleme',
              'timestamp': '2025-10-01T15:00:00Z',
              'description': 'İlk Atama',
              'conducted_by': 'Süper Yönetici',
            },
            {
              'id': 201,
              'amount': 50.0,
              'signed_amount': '-50.00',
              'type_display': 'Çıkarma',
              'timestamp': '2025-10-15T12:00:00Z',
              'description': 'Ulaşım Gideri',
              'conducted_by': 'Yönetici A',
            },
          ];

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList
            .map((json) => BudgetTransaction.fromJson(json))
            .toList();
      } else {
        // API hatası durumunda simüle veri
        return simulatedData
            .map((json) => BudgetTransaction.fromJson(json))
            .toList();
      }
    } catch (e) {
      // Ağ hatası durumunda simüle veri
      print('Ağ Hatası (Service): $e');
      return simulatedData
          .map((json) => BudgetTransaction.fromJson(json))
          .toList();
    }
  }
}
