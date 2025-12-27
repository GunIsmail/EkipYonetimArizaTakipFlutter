// lib/services/login_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Definitions.dart';

class LoginService {
  // Giriş yapma ve verileri kaydetme işlemini tek fonksiyonda topluyoruz
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(Api.login),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Verileri ayrıştır
        bool isAdmin = data['is_staff'] as bool? ?? false;
        int? userId = data['id'] as int?;
        String serverUsername = data['username'] as String? ?? username;

        // ID kontrolü
        if (!isAdmin && userId == null) {
          return {
            'success': false,
            'message': 'Çalışan ID bilgisi sunucudan gelmedi.',
          };
        }

        // --- Verileri Hafızaya Kaydet (SharedPreferences) ---
        // UI yerine bu işlemi burada yapmak daha temizdir via Service
        if (userId != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', userId);
          await prefs.setString('username', serverUsername);
        }
        // ---------------------------------------------------

        // UI tarafına başarılı olduğunu ve rolünü bildir
        return {
          'success': true,
          'is_admin': isAdmin,
          'user_id': userId,
          'username': serverUsername,
        };
      } else {
        // Sunucu hata döndürdü (400, 401 vb.)
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              errorData['error'] ??
              'Giriş başarısız (Kod: ${response.statusCode})',
        };
      }
    } catch (e) {
      // Bağlantı hatası
      return {'success': false, 'message': 'Sunucuya bağlanılamadı: $e'};
    }
  }
}
