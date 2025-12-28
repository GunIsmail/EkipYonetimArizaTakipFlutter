// lib/services/auth_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Definitions.dart';

class AuthService {
  static const String _adminLabel = 'Admin';

  // Telefon Numarası Formatlama (+90 ekleme)
  String? formatPhoneNumber(String onlyDigits10) {
    final d = onlyDigits10.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length != 10) return null;
    if (!d.startsWith('5')) return null; // GSM kuralı
    return '+90$d';
  }

  // Kayıt Payload'ını Oluşturma
  Map<String, dynamic> _buildPayload({
    required String username,
    required String password,
    required String e164Phone,
    required String? selectedRole,
  }) {
    final isAdmin = (selectedRole == _adminLabel);
    final body = <String, dynamic>{
      'username': username.trim(),
      'password': password.trim(),
      'phone': e164Phone,
      'is_staff': isAdmin,
    };

    if (!isAdmin && (selectedRole != null && selectedRole.isNotEmpty)) {
      body['role'] = selectedRole;
      body['availability'] = 'available';
    }

    return body;
  }

  // Kayıt İşlemi (API Çağrısı)
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String password,
    required String phoneDigits,
    required String? selectedRole,
  }) async {
    // Telefonu formatla
    final e164 = formatPhoneNumber(phoneDigits);
    if (e164 == null) {
      return {
        'success': false,
        'message': 'Geçerli bir telefon girin (5xx...)',
      };
    }

    final uri = Uri.parse('${Api.baseUrl}/api/register/');
    final bodyData = _buildPayload(
      username: username,
      password: password,
      e164Phone: e164,
      selectedRole: selectedRole,
    );

    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(bodyData),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return {'success': true, 'message': 'Kayıt başarılı'};
      } else {
        String msg = 'Kayıt başarısız (${resp.statusCode})';
        try {
          final data = jsonDecode(utf8.decode(resp.bodyBytes));
          if (data is Map && data['error'] != null) {
            msg = data['error'].toString();
          }
        } catch (_) {}
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Sunucuya bağlanılamadı: $e'};
    }
  }
}
