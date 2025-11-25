// lib/employee_page/employeePage.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../Definitions.dart';
import '../login_page/login_page.dart';
// Task Management'tan taşınan bileşenler/modeller buraya import edilmeli
// (Projeye göre yollarını kontrol edin)
import '../admin_page/task_model.dart';

// Worker ID ve Username artık StatefulWidget'a geliyor.

class EmployeePage extends StatefulWidget {
  final int workerId;
  final String username;

  const EmployeePage({
    required this.workerId,
    required this.username,
    super.key,
  });

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _workerBudget = 0.0;
  String _currentAvailability = 'Müsait'; // Mevcut durumu tutmak için
  Future<void>? _dataFuture;

  final List<String> _statusFilters = ['NEW', 'IN_PROGRESS'];
  final List<String> _tabTitles = ['Yeni Atanan', 'Süreçteki İşler'];

  // Backend'deki STATUS_CHOICES ile eşleşen seçenekler (Türkçe karşılıkları)
  final List<String> _availabilityOptions = [
    'Müsait',
    'Aktif Görevde',
    'İzinli',
    'Meşgul',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _dataFuture = _loadData(); // Bütçe ve işleri yükle
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _fetchWorkerBudgetAndStatus();
  }

  // Bütçe ve Durumu Çekme
  Future<void> _fetchWorkerBudgetAndStatus() async {
    final uri = Uri.parse(Api.workers);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));

        final workerIdString = widget.workerId.toString(); // ID'yi String yap

        final currentWorkerData = jsonList.firstWhere(
          // Worker listesinden, ID'si eşleşen ilk elemanı bul
          (worker) => worker['id'].toString() == workerIdString,
          orElse: () => null,
        );

        if (currentWorkerData != null) {
          setState(() {
            _workerBudget =
                (currentWorkerData['budget'] as num?)?.toDouble() ?? 0.0;
            _currentAvailability =
                currentWorkerData['statusText'] as String? ?? 'Bilinmiyor';
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _updateAvailability(String newStatus) async {
    const updateUrl = '${Api.baseUrl}/api/workers/update_status/';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Durum güncelleniyor...')));

    try {
      final response = await http.post(
        Uri.parse(updateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'worker_id': widget.workerId,
          'status':
              newStatus, // Türkçe durumu gönder (Backend'de karşılığı olmalı)
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _currentAvailability = newStatus; // Başarılıysa yerel durumu güncelle
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Durum başarıyla "$newStatus" olarak güncellendi.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Durum Güncelleme Başarısız. Kod: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ağ Hatası: $e')));
    }
  }

  // İş Emirlerini Duruma Göre Çekme
  Future<List<WorkOrder>> _fetchAssignedWorkOrders(String statusFilter) async {
    final uri = Uri.parse(
      '${Api.baseUrl}/api/tasks/?assigned_worker=${widget.workerId}&status=$statusFilter',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => WorkOrder.fromJson(json)).toList();
      } else {
        throw Exception('API Hatası: ${response.statusCode}');
      }
    } catch (e) {
      print('İş Emri Yükleme Hatası: $e');
      return [];
    }
  }

  // --- İŞ TALEP ETME (Request Assignment) Fonksiyonu ---
  Future<void> _requestTask(int taskId) async {
    const requestUrl = '${Api.baseUrl}/api/tasks/request_assignment/';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yöneticiye iş talep bildirimi gönderiliyor...'),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'task_id': taskId, 'worker_id': widget.workerId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İş talep isteği başarıyla gönderildi!'),
          ),
        );
        // Liste görünümünü yenile
        setState(() {
          _dataFuture = _loadData();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Talep Başarısız. Kod: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ağ Hatası: $e')));
    }
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // --- Arayüz Yapıları ---

  Widget _buildTaskListView(String statusFilter) {
    return FutureBuilder<List<WorkOrder>>(
      future: _dataFuture?.then((_) => _fetchAssignedWorkOrders(statusFilter)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Veri Yükleme Hatası: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final task = snapshot.data![index];
              return WorkerTaskCard(task: task, onTaskRequest: _requestTask);
            },
          );
        } else {
          return Center(
            child: Text(
              '${_tabTitles[_statusFilters.indexOf(statusFilter)]} iş emri bulunamadı.',
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalışan Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () => _logout(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
        ),
      ),

      body: Column(
        children: [
          // 1. Bütçe ve Durum Kartı
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş Geldin, ${widget.username}!',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 8),

                // Bütçe Satırı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mevcut Bütçeniz:',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      '${_workerBudget.toStringAsFixed(2)} ₺',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white54, height: 18),

                // 🎯 Müsaitlik Durumu Güncelleme Dropdown'ı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Durumunuzu Güncelleyin:',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    DropdownButton<String>(
                      value: _currentAvailability,
                      dropdownColor: Theme.of(context).primaryColor,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      items: _availabilityOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _updateAvailability(newValue);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. İş Emirleri Listesi
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statusFilters.map((status) {
                return _buildTaskListView(status);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Çalışan İş Emri Kartı Widget'ı ---
class WorkerTaskCard extends StatelessWidget {
  final WorkOrder task;
  // İş Talep Etme callback'i
  final Function(int taskId) onTaskRequest;

  const WorkerTaskCard({
    required this.task,
    required this.onTaskRequest,
    super.key,
  });

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.NEW:
        return Colors.blue.shade700;
      case TaskStatus.IN_PROGRESS:
        return Colors.orange.shade700;
      case TaskStatus.COMPLETED:
      case TaskStatus.CANCELLED:
      default:
        return Colors.grey;
    }
  }

  // İş Talep Etme Onayı
  void _confirmTaskRequest(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Talep Et'),
        content: Text(
          '${task.title} görevini üstlenmek istediğinizi onaylıyor musunuz? Yöneticiye bildirim gönderilecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onTaskRequest(task.id); // İş talep etme işlemini başlat
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'İş Talep Et',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sadece "NEW" durumundaki işler talep edilebilir.
    final bool canRequest = task.status == TaskStatus.NEW;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.build, color: _getStatusColor(task.status)),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Durum: ${task.statusDisplay}'),
            Text('Adres: ${task.customerAddress}'),
            Text('Telefon: ${task.customerPhone}'),
          ],
        ),
        trailing: canRequest
            ? ElevatedButton.icon(
                onPressed: () => _confirmTaskRequest(context),
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Talep Et'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              )
            : (task.status == TaskStatus.IN_PROGRESS
                  ? const Text(
                      'Süreçte',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Icon(Icons.done_all, color: Colors.green)),
        onTap: () {
          // Detay Sayfasına yönlendirme (Şimdilik Snackbar)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${task.description}')));
        },
      ),
    );
  }
}
