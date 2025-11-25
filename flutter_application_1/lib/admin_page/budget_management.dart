// lib/admin_page/budget_management_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../Definitions.dart'; // Api sınıfı burada tanımlanmalı
import 'budget_history_modal.dart'; // BudgetHistoryModal widget'ı burada olmalı

class Worker {
  final String id;
  final String name;
  final String role;
  final String status;
  final Color statusColor;
  final String phone;
  final double budget;

  const Worker({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.statusColor,
    required this.phone,
    required this.budget,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    Color _getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'aktif görevde':
          return Colors.green;
        case 'müsait':
          return Colors.orange;
        case 'izinli':
          return Colors.grey;
        default:
          return Colors.blue;
      }
    }

    final String statusText = json['statusText'] as String? ?? 'Bilinmiyor';

    return Worker(
      id: json['id']?.toString() ?? 'N/A',
      name: json['name'] as String? ?? 'Bilinmiyor',
      role: json['role'] as String? ?? 'Tanımlanmadı',
      status: statusText,
      statusColor: _getStatusColor(statusText),
      phone: json['phone'] as String? ?? 'Yok',
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BudgetManagementPage extends StatefulWidget {
  const BudgetManagementPage({super.key});

  @override
  State<BudgetManagementPage> createState() => _BudgetManagementPageState();
}

class _BudgetManagementPageState extends State<BudgetManagementPage> {
  late Future<List<Worker>> _workersFuture;
  final String _apiUrl = Api.workers;

  @override
  void initState() {
    super.initState();
    _workersFuture = _fetchWorkers();
  }

  // --- Veri Çekme Fonksiyonu ---
  Future<List<Worker>> _fetchWorkers() async {
    final List<Map<String, dynamic>> simulatedData = [];

    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        // headers: {'Authorization': 'Bearer $accessToken'}, // Todo token mantıgına gec .
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => Worker.fromJson(json)).toList();
      } else {
        return simulatedData.map((json) => Worker.fromJson(json)).toList();
      }
    } catch (e) {
      return simulatedData.map((json) => Worker.fromJson(json)).toList();
    }
  }

  // --- Bütçe Geçmişi Modalını Gösterme ---
  void _showBudgetHistoryModal(Worker worker) {
    const String adminAccessToken = 'YOUR_ADMIN_ACCESS_TOKEN';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BudgetHistoryModal(
          workerId: int.parse(worker.id),
          workerName: worker.name,
          accessToken: adminAccessToken,
        );
      },
    );
  }

  // --- Bütçeyi Mutlak Olarak Düzenleme Modalını Gösterme (Açıklama Eklendi) ---
  void _editBudget(Worker worker) {
    final TextEditingController _budgetController = TextEditingController(
      text: worker.budget.toStringAsFixed(2),
    );
    final TextEditingController _descriptionController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${worker.name} Bütçesini Düzenle (Mutlak Değer)'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Mevcut Bütçe: ${worker.budget.toStringAsFixed(2)} ₺'),
                const SizedBox(height: 16),
                // Yeni Bütçe Alanı
                TextField(
                  controller: _budgetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Yeni Mutlak Bütçe Değeri (₺)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama / Sebep (Zorunlu)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Kaydet'),
              onPressed: () {
                final double? newBudget = double.tryParse(
                  _budgetController.text.replaceAll(',', '.'),
                );
                final String customDescription = _descriptionController.text
                    .trim(); // DEĞER ALINDI

                if (newBudget != null &&
                    newBudget >= 0 &&
                    customDescription.isNotEmpty) {
                  // KONTROL EKLENDİ
                  Navigator.of(context).pop();
                  _updateBudgetOnBackend(
                    worker.id,
                    newBudget,
                    'Mutlak Değer Düzenlemesi: $customDescription', // GÖNDERİLİYOR
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Lütfen geçerli bir bütçe değeri ve açıklama girin.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Bütçe Ekleme/Çıkarma Modalını Gösterme (Açıklama Eklendi) ---
  void _showBudgetTransactionModal(Worker worker, {required bool isAddition}) {
    final TextEditingController _amountController = TextEditingController();
    final TextEditingController _descriptionController =
        TextEditingController();
    final String action = isAddition ? 'Ekleme' : 'Çıkarma';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${worker.name} Bütçesine $action Yap'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Mevcut Bütçe: ${worker.budget.toStringAsFixed(2)} ₺'),
                const SizedBox(height: 16),
                // Tutar Alanı
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tutar (₺)',
                    prefixIcon: Icon(
                      isAddition ? Icons.add : Icons.remove,
                      color: isAddition ? Colors.green : Colors.red,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama / Sebep (Zorunlu)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(action),
              onPressed: () {
                final double? amount = double.tryParse(
                  _amountController.text.replaceAll(',', '.'),
                );
                final String customDescription = _descriptionController.text
                    .trim(); // DEĞER ALINDI

                if (amount != null &&
                    amount > 0 &&
                    customDescription.isNotEmpty) {
                  // KONTROL EKLENDİ
                  double newBudget;
                  String descriptionToSend;

                  if (isAddition) {
                    newBudget = worker.budget + amount;
                  } else {
                    newBudget = worker.budget - amount;
                  }

                  descriptionToSend =
                      customDescription; // Nihai açıklamayı kullanıcının girdiği metin olarak alıyoruz

                  Navigator.of(context).pop();
                  _updateBudgetOnBackend(
                    worker.id,
                    newBudget,
                    descriptionToSend,
                  ); // GÖNDERİLİYOR
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Lütfen geçerli bir tutar ve açıklama girin.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Backend'e Bütçe Güncelleme (POST) Fonksiyonu ---
  Future<void> _updateBudgetOnBackend(
    String workerId,
    double newBudget,
    String description,
  ) async {
    const String updateUrl = '${Api.baseUrl}/api/workers/update_budget/';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bütçe güncelleme isteği gönderiliyor: $description'),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse(updateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'worker_id': workerId,
          'budget': newBudget,
          'description': description, // API'nizin bu alanı işlemesi gerekir
        }),
      );

      if (response.statusCode == 200) {
        // 1. ASENKRON İŞLEMİ setState DIŞINA TAŞIYIN
        _workersFuture = _fetchWorkers();

        // 2. WIDGET'I YENİDEN ÇİZMEK İÇİN SENKRON setState() çağrısı yapın.
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bütçe başarıyla güncellendi.')),
        );
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage =
            errorBody['error'] ??
            'Bilinmeyen API hatası. Status: ${response.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme Başarısız: $errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ağ Hatası: ${e.toString()}')));
    }
  }

  // --- Personel Listesini Oluşturan Widget ---
  Widget _buildWorkerList() {
    return FutureBuilder<List<Worker>>(
      future: _workersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Veri Yükleme Hatası: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView(
            children: snapshot.data!
                .map(
                  (worker) => _BudgetCard(
                    worker: worker,
                    onEdit: _editBudget, // Mutlak Değer Düzenle
                    onAdd: (w) => _showBudgetTransactionModal(
                      w,
                      isAddition: true,
                    ), // Ekle
                    onSubtract: (w) => _showBudgetTransactionModal(
                      w,
                      isAddition: false,
                    ), // Çıkar
                    onTap: _showBudgetHistoryModal, // Geçmişi Gör
                  ),
                )
                .toList(),
          );
        } else {
          return const Center(
            child: Text('Bütçe bilgisi olan personel bulunamadı.'),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bütçe Yönetimi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personel Bütçe Durumu (Geçmiş için karta dokunun)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildWorkerList()),
          ],
        ),
      ),
    );
  }
}

// --- Bütçe Kartı Widget'ı ---
class _BudgetCard extends StatelessWidget {
  final Worker worker;
  final ValueChanged<Worker> onEdit; // Mutlak değer düzenleme
  final ValueChanged<Worker> onAdd; // Ekleme
  final ValueChanged<Worker> onSubtract; // Çıkarma
  final ValueChanged<Worker> onTap; // Geçmişi görme

  const _BudgetCard({
    required this.worker,
    required this.onEdit,
    required this.onAdd,
    required this.onSubtract,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => onTap(worker), // Kart tıklaması ile geçmişi açar
        leading: const Icon(
          Icons.account_balance_wallet_outlined,
          size: 40,
          color: Colors.blueGrey,
        ),
        title: Text(
          worker.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rol: ${worker.role} | Tel: ${worker.phone}'),
            const SizedBox(height: 4),
            // Bütçe Değerini Kartın Altında Vurgula
            Row(
              children: [
                const Text('Mevcut Bütçe:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${worker.budget.toStringAsFixed(2)} ₺',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: worker.budget < 1000
                        ? Colors.red
                        : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bütçe Ekle Butonu
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              tooltip: 'Bütçeye Ekle',
              onPressed: () => onAdd(worker),
            ),
            // Bütçeden Çıkar Butonu
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              tooltip: 'Bütçeden Çıkar',
              onPressed: () => onSubtract(worker),
            ),
            // Mutlak Değerle Düzenle Butonu
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Mutlak Değerle Düzenle',
              onPressed: () => onEdit(worker),
            ),
          ],
        ),
      ),
    );
  }
}
