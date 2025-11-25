// lib/admin_page/admin_panel_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/admin_page/show_personel_list_page.dart';
import '../login_page/login_page.dart';
import 'user_registration_page.dart';
import 'task_management.dart';
import 'budget_management.dart';
import 'admin_approval_page.dart';
// ignore: duplicate_import
import 'show_personel_list_page.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Hızlı İşlemler',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Yeni Arıza Kaydı
            _ActionButton(
              icon: Icons.add_circle_outline,
              label: 'Yeni Arıza Kaydı',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TaskManagementPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.playlist_add_check,
              label: 'İş & Bütçe Onay Merkezi',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminApprovalPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Yeni Kullanıcı Kaydı
            _ActionButton(
              icon: Icons.person_add_alt_1_outlined,
              label: 'Yeni Kullanıcı Kaydı',
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => RegisterPage()));
              },
            ),
            const SizedBox(height: 12),

            // İş Ata / Yönlendir butonu, yeni sayfaya yönlendirildi!
            _ActionButton(
              icon: Icons.assignment_turned_in_outlined,
              label: 'İş Ata / Personel Durumu',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ShowPersonelListPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Bütçe Yönetimi
            _ActionButton(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Bütçe Yönetimi',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BudgetManagementPage(),
                  ),
                );
              },
            ), //Actionbutton enndline

            const SizedBox(height: 24),
            const Divider(),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
