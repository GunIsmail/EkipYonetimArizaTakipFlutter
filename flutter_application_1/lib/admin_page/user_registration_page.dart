// lib/auth/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();

  final _username = TextEditingController();
  final _phoneDigits = TextEditingController();
  final _password = TextEditingController();
  final _passwordAgain = TextEditingController();

  bool _isLoading = false;

  final List<String> _roleOptions = const [
    'Admin',
    'Usta Elektrikçi',
    'Elektrik Teknisyeni',
    'Teknisyen Yardımcısı',
    'Yazılımcı',
    'Yönetici Asistanı',
    "Frontendci",
  ];
  String? _selectedRole = 'Admin';

  @override
  void dispose() {
    _username.dispose();
    _phoneDigits.dispose();
    _password.dispose();
    _passwordAgain.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (_username.text.isEmpty ||
        _phoneDigits.text.isEmpty ||
        _password.text.isEmpty ||
        _passwordAgain.text.isEmpty) {
      _showSnackBar('Lütfen tüm alanları doldurun', isError: true);
      return;
    }

    if (_password.text != _passwordAgain.text) {
      _showSnackBar('Şifreler uyuşmuyor', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.registerUser(
      username: _username.text,
      password: _password.text,
      phoneDigits: _phoneDigits.text,
      selectedRole: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      _showSnackBar(result['message'], isError: false);
      Navigator.of(context).pop();
    } else {
      _showSnackBar(result['message'], isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yeni Personel Kaydı'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.person_add_alt_1_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),

              const Text(
                "Personel Bilgileri",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 30),

              _buildTextField(
                controller: _username,
                label: 'Kullanıcı Adı',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneDigits,
                label: 'Telefon',
                hint: '5xx xxx xx xx',
                icon: Icons.phone_android,
                isPhone: true,
                prefixText: '+90 ',
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _password,
                label: 'Şifre',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _passwordAgain,
                label: 'Şifre (Tekrar)',
                icon: Icons.lock_reset,
                isPassword: true,
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Rol Seçiniz',
                  prefixIcon: const Icon(
                    Icons.work_outline,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                value: _selectedRole,
                items: _roleOptions
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (v) => setState(() => _selectedRole = v),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Kayıt Ol',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? prefixText,
    bool isPassword = false,
    bool isPhone = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      inputFormatters: isPhone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      enabled: !_isLoading,
    );
  }
}
