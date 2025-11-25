// lib/login_page/login_page.dart

import 'package:flutter/material.dart';
// import 'dart:nativewrappers/_internal/vm/lib/internal_patch.dart'; // Bu satırı silin (Hata veriyor)
import 'package:flutter_application_1/Definitions.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../admin_page/admin_panel_page.dart';
import '../employee_page/employeePage.dart'; // EmployeePage'in yolunun bu olduğundan emin olun

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 1. API'ye istek atıp cevabı bekleyen ve gerekli verileri döndüren fonksiyon (GÜNCELLENDİ)
  Future<Map<String, dynamic>?> _loginUserAndGetRole(
    String username,
    String password,
  ) async {
    // 🎯 setState'i sadece burada kontrol ediyoruz
    if (!mounted) return null;
    setState(() {
      _isLoading = true; // Yüklenme animasyonunu başlat
    });

    try {
      final response = await http.post(
        Uri.parse(Api.login),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('Giriş Başarılı! Admin mi: ${data['is_staff']}');

        return {
          'is_admin': data['is_staff'] as bool? ?? false,
          'user_id': data['id'] as int?, // Backend'den gelen ID
          'username': data['username'] as String? ?? username, // Kullanıcı adı
        };
      } else {
        final errorData = jsonDecode(response.body);
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${errorData['error'] ?? response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sunucuya bağlanılamadı! ${e}'),
          backgroundColor: Colors.red,
        ),
      );
      return null; // Hata durumunda null döndür
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleLogin() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kullanıcı adı ve şifreyi girin.')),
      );
      return;
    }

    final Map<String, dynamic>? loginData = await _loginUserAndGetRole(
      username,
      password,
    );

    if (!mounted) return;

    if (loginData != null) {
      final bool isAdmin = loginData['is_admin'] as bool;
      final int? userId = loginData['user_id'] as int?;

      if (!isAdmin && userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çalışan ID\'si alınamadı. Giriş başarısız.'),
          ),
        );
        return;
      }

      // Yönlendirme
      if (isAdmin) {
        // Admin Sayfasına Yönlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminPanelPage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                EmployeePage(workerId: userId!, username: username),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed:
                    _handleLogin, // Yönlendirme mantığını çağıran fonksiyon
                child: const Text('Giriş Yap'),
              ),
          ],
        ),
      ),
    );
  }
}
