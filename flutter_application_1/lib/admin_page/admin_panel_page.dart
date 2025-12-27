// lib/admin_page/admin_panel_page.dart

import 'package:flutter/material.dart';
import '../services/admin_service.dart';

// Sayfa Importları
import 'task_management.dart';
import 'budget_management.dart';
import 'admin_approval_page.dart';
import 'user_registration_page.dart';
import 'show_personel_list_page.dart';

class AdminPanelPage extends StatelessWidget {
  // ARTIK BURADA İSİM DEĞİŞKENİNE GEREK YOK
  // Çünkü ismi veritabanından çekeceğiz.
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminService adminService = AdminService();
    const Color primaryColor = Color(0xFF6C63FF);

    final List<AdminMenuItem> menuItems = [
      AdminMenuItem(
        title: 'Yeni Arıza Kaydı',
        icon: Icons.add_circle_outline,
        page: const TaskManagementPage(),
      ),
      AdminMenuItem(
        title: 'İş & Bütçe Onay Merkezi',
        icon: Icons.playlist_add_check,
        page: const AdminApprovalPage(),
      ),
      AdminMenuItem(
        title: 'Yeni Kullanıcı Kaydı',
        icon: Icons.person_add_alt_1_outlined,
        page: RegisterPage(),
      ),
      AdminMenuItem(
        title: 'İş Ata / Personel Durumu',
        icon: Icons.assignment_turned_in_outlined,
        page: const ShowPersonelListPage(),
      ),
      AdminMenuItem(
        title: 'Bütçe Yönetimi',
        icon: Icons.account_balance_wallet_outlined,
        page: const BudgetManagementPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Üst Bar
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 25, 25, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Admin Paneli',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // Bilgi Kartı (İsim artık parametre olarak gitmiyor)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _AdminInfoCard(
                primaryColor: primaryColor,
                adminService: adminService,
              ),
            ),

            const SizedBox(height: 10),

            // Menü Listesi
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 0, bottom: 20),
                  itemCount: menuItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _ActionButton(
                      item: menuItems[index],
                      primaryColor: primaryColor,
                    );
                  },
                ),
              ),
            ),

            // Çıkış Butonu
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => adminService.logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.red.withOpacity(0.2)),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  "Oturumu Kapat",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- GÜNCELLENEN BİLGİ KARTI ---
class _AdminInfoCard extends StatefulWidget {
  final Color primaryColor;
  final AdminService adminService;
  // adminName değişkenini buradan da kaldırdık

  const _AdminInfoCard({
    required this.primaryColor,
    required this.adminService,
  });

  @override
  State<_AdminInfoCard> createState() => _AdminInfoCardState();
}

class _AdminInfoCardState extends State<_AdminInfoCard> {
  late Future<Map<String, dynamic>?> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = widget.adminService.fetchDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _statsFuture,
      builder: (context, snapshot) {
        // Varsayılan Değerler
        String budgetText = "--- ₺";
        String statusText = "Yükleniyor...";
        String nameText = "Yükleniyor..."; // İsim için varsayılan

        Color statusContentColor = Colors.white;
        Color statusBgColor = Colors.white.withOpacity(0.2);

        // Veri Geldiğinde Değerleri Güncelle
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;

          // 1. BÜTÇE
          final double budget = (data['budget'] as num?)?.toDouble() ?? 0.0;
          budgetText = "${budget.toStringAsFixed(2)} ₺";

          // 2. SİSTEM DURUMU
          final status = data['system_status'] ?? 'Aktif';
          statusText = "Sistem $status";

          // 3. İSİM (VERİTABANINDAN GELEN)
          nameText = data['name'] ?? "Admin";
        } else if (snapshot.hasError) {
          statusText = "Hata";
          nameText = "Bağlantı Hatası";
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.primaryColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              colors: [widget.primaryColor, const Color(0xFF4B45B2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // Hoş Geldin ve İsim Kısmı
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hoş Geldiniz,",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      // VERİTABANINDAN GELEN İSMİ YAZIYORUZ
                      Text(
                        nameText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 24),

              // Bütçe ve Durum Bilgileri
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.amberAccent,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Kasa Bakiyesi", // 'Toplam Bütçe' yerine 'Kasa Bakiyesi' daha mantıklı olabilir admin için
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Yüklenirken Loading ikonu, veri gelince Bütçe
                      snapshot.connectionState == ConnectionState.waiting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              budgetText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                              ),
                            ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: statusContentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusContentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Buton Tasarımı (Değişmedi, aynı kalıyor)
class _ActionButton extends StatelessWidget {
  final AdminMenuItem item;
  final Color primaryColor;

  const _ActionButton({required this.item, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => item.page));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 26, color: primaryColor),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
