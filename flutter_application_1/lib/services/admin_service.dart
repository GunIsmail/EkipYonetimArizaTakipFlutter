// lib/services/admin_service.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Definitions.dart';
import '../login_page/login_page.dart';

class AdminMenuItem {
  final String title;
  final IconData icon;
  final Widget page;

  AdminMenuItem({required this.title, required this.icon, required this.page});
}

class AdminService {
  void logout(BuildContext context) async {
    // Çıkış yaparken hafızayı temizleyelim
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // --- KİŞİSEL VERİ ÇEKME FONKSİYONU ---
  Future<Map<String, dynamic>?> fetchDashboardStats() async {
    final uri = Uri.parse(Api.workers);

    try {
      // 1. Önce telefonda kayıtlı olan giriş yapmış kişinin ID'sini alalım
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Login sayfasında ID'yi 'user_id' veya 'id' olarak kaydettiğinizi varsayıyorum
      // Eğer String olarak kaydettiyseniz getString kullanın
      int? currentAdminId = prefs.getInt('user_id');

      if (currentAdminId == null) {
        debugPrint("HATA: Giriş yapmış kullanıcı ID'si bulunamadı.");
        return null;
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> users = jsonDecode(utf8.decode(response.bodyBytes));

        // 2. Listeden bizim Admin'i bulalım
        // firstWhere metodu, şartı sağlayan ilk elemanı bulur.
        var adminUser = users.firstWhere(
          (user) => user['id'] == currentAdminId,
          orElse: () => null, // Bulamazsa null dönsün
        );

        if (adminUser != null) {
          // 3. Bulunan Admin'in verilerini al
          double myBudget = (adminUser['budget'] as num?)?.toDouble() ?? 0.0;
          String myName = adminUser['name'] ?? 'İsimsiz Admin';

          return {
            'budget': myBudget, // SADECE Adminin parası
            'name': myName, // Adminin ismi
            'system_status': 'Aktif',
            'worker_count': users
                .length, // Toplam çalışan sayısı hala bilgi olarak kalabilir
          };
        } else {
          debugPrint(
            "HATA: Bu ID'ye sahip kullanıcı veritabanında bulunamadı.",
          );
        }
      } else {
        debugPrint("API Hatası: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Bağlantı Hatası: $e");
    }
    return null;
  }
}
