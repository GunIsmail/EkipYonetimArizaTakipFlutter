// lib/admin_page/admin_approval_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../Definitions.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({super.key});

  @override
  State<AdminApprovalPage> createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _fetchRequests(String requestType) async {
    final uri = Uri.parse('${Api.baseUrl}/api/approvals/$requestType/');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        print(
          "DEBUG: Bekleyen Talepler ($requestType): ${jsonList.length} adet bulundu.",
        );
        return jsonList;
      } else {
        print("Talep Listesi API Hatası: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print('Ağ Hatası (Talep Çekme): $e');
      return [];
    }
  }

  // --- API: Onaylama/Reddetme İşlemi ---
  void _processApproval(
    int requestId,
    String requestType,
    String action,
  ) async {
    // action: 'approve' veya 'reject'
    // API yolu: /api/approvals/{requestType}/{id}/process/
    final uri = Uri.parse(
      '${Api.baseUrl}/api/approvals/$requestType/$requestId/process/',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${requestType} talebi (${action} ediliyor)...')),
    );

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': action}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['success'] ?? 'İşlem Başarılı!'),
            backgroundColor: AppColors.success,
          ),
        );
        _refreshList(); // Liste verisini yenile
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'İşlem Başarısız: ${errorBody['error'] ?? response.statusCode}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ağ Hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // --- Liste Yenileme ---
  void _refreshList() {
    setState(() {}); // TabBarView'daki FutureBuilder'ları tetikler
  }

  // --- Talep Listesi Widget'ı ---
  Widget _buildRequestList(String type) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchRequests(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Veri yükleme hatası: ${snapshot.error}'));
        }
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final request = snapshot.data![index];
              return ApprovalCard(
                request: request,
                requestType: type,
                onProcess: _processApproval, // Onay/Red fonksiyonunu gönder
              );
            },
          );
        }
        return Center(
          child: Text(
            'Bekleyen ${type.replaceAll("_", " ")} talebi bulunmamaktadır.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yönetici Onay Merkezi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'İş Atama Talepleri'),
            Tab(text: 'Bütçe Harcama Talepleri'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // İş Atama Talepleri Sekmesi
          _buildRequestList('task_assignment'),
          // Bütçe Talepleri Sekmesi
          _buildRequestList('budget_approval'), // Backend path'i ile eşleşmeli
        ],
      ),
    );
  }
}

// --- Onay Kartı Widget'ı ---
class ApprovalCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final String requestType; // task_assignment veya budget_approval
  final Function(int requestId, String type, String action)
  onProcess; // Onaylama/Reddetme fonksiyonu

  const ApprovalCard({
    required this.request,
    required this.requestType,
    required this.onProcess,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Talep tipine göre detayları belirleme
    final isTaskRequest = requestType == 'task_assignment';

    // Detaylandırma
    final workerName = request['worker_name'] ?? 'Bilinmiyor';
    final requestDate = request['request_date'] != null
        ? DateFormat(
            'dd.MM.yyyy HH:mm',
          ).format(DateTime.parse(request['request_date']).toLocal())
        : 'Tarih Yok';

    Widget _buildContent() {
      if (isTaskRequest) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İş: ${request['task_title'] ?? 'N/A'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Talep Eden: $workerName',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        );
      } else {
        // Bütçe Talebi
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Miktar: ${request['amount'] ?? 0.0} ₺',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Talep Eden: $workerName',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            Text(
              'Gerekçe: ${request['description'] ?? 'Açıklama Yok'}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Icon(
          isTaskRequest ? Icons.assignment_ind : Icons.attach_money,
          color: isTaskRequest ? AppColors.primary : AppColors.success,
        ),
        title: _buildContent(),
        subtitle: Text(
          'Tarih: $requestDate',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: SizedBox(
          width: 120, // Butonları sığdırmak için sabit genişlik
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reddet Butonu
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.error),
                tooltip: 'Reddet',
                onPressed: () =>
                    onProcess(request['id'], requestType, 'reject'),
              ),
              const SizedBox(width: 4),
              // Onayla Butonu
              ElevatedButton(
                onPressed: () =>
                    onProcess(request['id'], requestType, 'approve'),
                child: const Text(
                  'Onayla',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
