// lib/auth/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/Definitions.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _username = TextEditingController();
  final _phoneDigits = TextEditingController(); // sadece 10 hane (5xx...)
  final _password = TextEditingController();
  final _passwordAgain = TextEditingController();

  bool _isLoading = false;

  // --- ROLLER ---
  // İlk seçenek Admin: seçilirse is_staff=true olur.
  static const String _adminLabel = 'Admin';
  final List<String> _roleOptions = const [
    _adminLabel,
    'Usta Elektrikçi',
    'Elektrik Teknisyeni',
    'Teknisyen Yardımcısı',
    'Yazılımcı',
    'Yönetici Asistanı',
    "Frontendci",
    "cu",
  ];
  String? _selectedRole = _adminLabel;

  @override
  void dispose() {
    _username.dispose();
    _phoneDigits.dispose();
    _password.dispose();
    _passwordAgain.dispose();
    super.dispose();
  }

  // 10 hane ve 5 ile başlamalı → +90 ile E.164 üret
  String? _toTrE164(String onlyDigits10) {
    final d = onlyDigits10.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length != 10) return null;
    if (!d.startsWith('5')) return null; // GSM kuralı
    return '+90$d';
  }

  Map<String, dynamic> _buildPayloadFromRole({
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
      'is_staff': isAdmin, // Admin seçiliyse true
    };

    // Admin değilse role & availability de gönder
    if (!isAdmin && (selectedRole != null && selectedRole.isNotEmpty)) {
      body['role'] = selectedRole;
      body['availability'] = 'available';
    }

    return body;
  }

  Future<void> _onRegister() async {
    // ------------------- Alan Kontrolleri -------------------
    if (_username.text.isEmpty ||
        _phoneDigits.text.isEmpty ||
        _password.text.isEmpty ||
        _passwordAgain.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    if (_password.text != _passwordAgain.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Şifreler uyuşmuyor')));
      return;
    }

    final e164 = _toTrE164(_phoneDigits.text);
    if (e164 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir telefon girin (5xx...)')),
      );
      return;
    }
    // ------------------- End Kontroller -------------------

    final baseUrl = Api.baseUrl;
    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('$baseUrl/api/register/');
      final bodyData = _buildPayloadFromRole(
        username: _username.text,
        password: _password.text,
        e164Phone: e164,
        selectedRole: _selectedRole,
      );

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(bodyData),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kayıt başarılı')));
        Navigator.of(context).pop();
      } else {
        String msg = 'Kayıt başarısız (${resp.statusCode})';
        try {
          final data = jsonDecode(resp.body);
          if (data is Map && data['error'] != null) {
            msg = data['error'].toString();
          } else {
            msg = utf8.decode(resp.bodyBytes);
          }
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sunucuya bağlanılamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Edilecek Personel Bilgisi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kullanıcı Adı
          TextField(
            controller: _username,
            decoration: const InputDecoration(
              labelText: 'Kullanıcı Adı',
              border: OutlineInputBorder(),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 12),

          // Telefon
          TextField(
            controller: _phoneDigits,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'Telefon',
              hintText: '5xx xxx xx xx',
              border: OutlineInputBorder(),
              prefixText: '+90 ',
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 12),

          // Şifre
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Şifre',
              border: OutlineInputBorder(),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 12),

          // Şifre Tekrar
          TextField(
            controller: _passwordAgain,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Şifre (Tekrar)',
              border: OutlineInputBorder(),
            ),
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // --- Rol Seçimi (Admin + personel rolleri tek listede) ---
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Rol Seçiniz',
              border: OutlineInputBorder(),
            ),
            value: _selectedRole,
            hint: const Text('Rol'),
            items: _roleOptions
                .map(
                  (role) =>
                      DropdownMenuItem<String>(value: role, child: Text(role)),
                )
                .toList(),
            onChanged: _isLoading
                ? null
                : (String? newValue) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  },
          ),

          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _onRegister,
                    child: const Text('Kayıt Ol'),
                  ),
          ),
        ],
      ),
    );
  }
}
