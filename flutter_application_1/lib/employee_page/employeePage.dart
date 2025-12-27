// Dosya: lib/pages/employee_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart'; // Tarih formatı için

// Proje dosyaları
import '../services/employee_service.dart';
import '../login_page/login_page.dart';
import '../admin_page/task_model.dart';
import '../services/budget_transaction_model.dart';
import 'employee_view.dart';

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

class _EmployeePageState extends State<EmployeePage> {
  final EmployeeService _employeeService = EmployeeService();

  double _workerBudget = 0.0;
  String _currentAvailability = 'Müsait';

  final List<String> _availabilityOptions = [
    'Müsait',
    'Aktif Görevde',
    'İzinli',
    'Meşgul',
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  // --- Logic Bölümü ---

  Future<void> _loadWorkerData() async {
    final data = await _employeeService.fetchWorkerData(widget.workerId);
    if (data != null && mounted) {
      setState(() {
        _workerBudget = (data['budget'] as num?)?.toDouble() ?? 0.0;
        _currentAvailability = data['statusText'] as String? ?? 'Bilinmiyor';
      });
    }
  }

  Future<void> _handleStatusUpdate(String newStatus) async {
    _showSnackBar('Durum güncelleniyor...', isSuccess: null);

    bool success = await _employeeService.updateStatus(
      widget.workerId,
      newStatus,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _currentAvailability = newStatus);
      _showSnackBar('Durum "$newStatus" oldu.', isSuccess: true);
    } else {
      _showSnackBar('Güncelleme başarısız.', isSuccess: false);
    }
  }

  Future<void> _handleTaskRequest(int taskId) async {
    _showSnackBar('Talep gönderiliyor...', isSuccess: null);

    int statusCode = await _employeeService.requestTask(
      taskId,
      widget.workerId,
    );

    if (!mounted) return;

    if (statusCode == 200 || statusCode == 201) {
      _showSnackBar('Talep başarılı!', isSuccess: true);
      setState(() {});
    } else {
      _showSnackBar('Talep başarısız.', isSuccess: false);
    }
  }

  Future<void> _handleTaskCompletion(
    int taskId,
    String desc,
    double amount,
  ) async {
    print("DEBUG (UI): Tamamla butonuna basıldı. ID: $taskId, Tutar: $amount");
    _showSnackBar('Onay talebi gönderiliyor...', isSuccess: null);

    bool success = await _employeeService.completeTaskWithBudget(
      taskId,
      widget.workerId,
      desc,
      amount,
    );

    print("DEBUG (UI): Servis işlemi bitirdi. Sonuç (success): $success");

    if (!mounted) return;

    if (success) {
      _showSnackBar('Talep Admin onayına gönderildi.', isSuccess: true);
      setState(() {});
    } else {
      _showSnackBar('İşlem başarısız oldu.', isSuccess: false);
    }
  }

  void _showBudgetHistoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Tam ekrana yakın açılması için
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75, // Ekranın %75'i
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // --- Başlık Kısmı ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bütçe Geçmişi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tarih / İşlemi Yapan / Açıklama',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- Liste Kısmı ---
              Expanded(
                child: FutureBuilder<List<BudgetTransaction>>(
                  future: _employeeService.fetchBudgetHistory(widget.workerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Henüz işlem geçmişi yok.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(0),
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = snapshot.data![index];
                        final isPositive = item.signedAmount.startsWith('+');

                        // Tarih Formatlama
                        DateTime? dateObj = DateTime.tryParse(item.timestamp);
                        String dateStr = dateObj != null
                            ? DateFormat(
                                'dd.MM.yyyy HH:mm',
                              ).format(dateObj.toLocal())
                            : item.timestamp;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: index % 2 == 0
                              ? Colors.white
                              : Colors.grey[50], // Zebra efekti
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // SOL TARAF: Detaylar
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Tarih
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),

                                    // 2. Yönetici Adı
                                    Text(
                                      'Yönetici: ${item.conductedBy}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // 3. AÇIKLAMA (Burayı istediğin gibi belirginleştirdik)
                                    Text(
                                      item.description.isNotEmpty
                                          ? item.description
                                          : 'Açıklama yok',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // SAĞ TARAF: Tutar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.signedAmount} ₺',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isPositive
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPositive ? 'Ekleme' : 'Çıkarma',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isPositive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // --- Kapat Butonu (Opsiyonel, zaten yukarıda çarpı var) ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Kapat"),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<WorkOrder>> _fetchTasksForView(String status) {
    return _employeeService.fetchTasks(widget.workerId, status);
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _showSnackBar(String message, {bool? isSuccess}) {
    Color? bgColor;
    if (isSuccess == true) bgColor = Colors.green;
    if (isSuccess == false) bgColor = Colors.redAccent;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EmployeeView(
      username: widget.username,
      budget: _workerBudget,
      currentAvailability: _currentAvailability,
      availabilityOptions: _availabilityOptions,
      onStatusChanged: _handleStatusUpdate,
      onLogout: _logout,
      onTaskRequest: _handleTaskRequest,
      onTaskComplete: _handleTaskCompletion,
      onShowHistory: _showBudgetHistoryModal, // <-- BAĞLANTI BURADA
      fetchTasks: _fetchTasksForView,
    );
  }
}
