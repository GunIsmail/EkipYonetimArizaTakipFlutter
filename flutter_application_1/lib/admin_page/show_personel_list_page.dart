// lib/admin_page/show_personel_list_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Definitions.dart';

class Worker {
  final String id;
  final String name;
  final String role;
  final String status;
  final Color statusColor;
  final String phone;

  const Worker({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.statusColor,
    required this.phone,
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
    );
  }
}

class ShowPersonelListPage extends StatefulWidget {
  const ShowPersonelListPage({super.key});

  @override
  State<ShowPersonelListPage> createState() => _ShowPersonelListPageState();
}

class _ShowPersonelListPageState extends State<ShowPersonelListPage> {
  late Future<List<Worker>> _workersFuture;
  final String _apiUrl = Api.workers; // Personel listesi API'ı

  @override
  void initState() {
    super.initState();
    _workersFuture = _fetchWorkers();
  }

  // --- Veri Çekme Fonksiyonu ---
  Future<List<Worker>> _fetchWorkers() async {
    final List<Map<String, dynamic>> simulatedData = [
      {
        'id': 1,
        'name': 'Ahmet Yılmaz',
        'role': 'Usta Elektrikçi',
        'statusText': 'Aktif Görevde',
        'phone': '5551234567',
      },
      {
        'id': 2,
        'name': 'Mehmet Kaya',
        'role': 'Teknisyen',
        'statusText': 'Müsait',
        'phone': '5559876543',
      },
      {
        'id': 3,
        'name': 'Ayşe Demir',
        'role': 'Asistan',
        'statusText': 'İzinli',
        'phone': '5551112233',
      },
      {
        'id': 4,
        'name': 'Can Yücel',
        'role': 'Stajyer',
        'statusText': 'Müsait',
        'phone': '5554445566',
      },
    ];

    try {
      final response = await http.get(Uri.parse(_apiUrl));
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

  // 🎯 GRUPLANDIRILMIŞ LİSTE OLUŞTURMA VE GÖRÜNTÜLEME FONKSİYONU
  Widget _buildGroupedWorkerList() {
    return FutureBuilder<List<Worker>>(
      future: _workersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Veri Yükleme Hatası: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final List<Worker> workers = snapshot.data!;

          // Durumlarına göre gruplandırma
          final Map<String, List<Worker>> groupedWorkers = {};
          for (var worker in workers) {
            final statusKey = worker.status;
            groupedWorkers.putIfAbsent(statusKey, () => []).add(worker);
          }

          // Grupları öncelik sırasına göre sıralama
          final List<String> orderedKeys = [
            'Müsait',
            'Aktif Görevde',
            'İzinli',
            'Bilinmiyor',
          ].where((key) => groupedWorkers.containsKey(key)).toList();

          // Gruplu Listeyi döndür
          return ListView.builder(
            itemCount: orderedKeys.length,
            itemBuilder: (context, index) {
              final statusKey = orderedKeys[index];
              final workerList = groupedWorkers[statusKey]!;
              final statusColor = workerList.first.statusColor;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grup Başlığı
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    child: Text(
                      '$statusKey (${workerList.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),

                  // Çalışanların Listesi (Bu gruba ait)
                  ...workerList
                      .map((worker) => _PersonelStatusCard(worker: worker))
                      .toList(),
                  const Divider(height: 20),
                ],
              );
            },
          );
        } else {
          return const Center(child: Text('Personel bulunamadı.'));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personel Durum Listesi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personel Durumuna Göre Gruplandırılmış Liste',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildGroupedWorkerList()),
          ],
        ),
      ),
    );
  }
}

// --- Basitleştirilmiş Personel Kartı (Bütçe Yönetimi Kısımları Olmadan) ---
class _PersonelStatusCard extends StatelessWidget {
  final Worker worker;

  const _PersonelStatusCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.person_pin_circle_outlined,
          size: 32,
          color: worker.statusColor, // Durum rengi
        ),
        title: Text(
          worker.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Rol: ${worker.role} | Tel: ${worker.phone}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: worker.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            worker.status,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: worker.statusColor,
            ),
          ),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${worker.name} detayları açılacak.')),
          );
        },
      ),
    );
  }
}
