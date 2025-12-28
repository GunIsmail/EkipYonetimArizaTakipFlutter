// lib/admin_page/show_personel_list_page.dart
import 'package:flutter/material.dart';
import '../services/personel_service.dart';
import 'assign_job_page.dart'; // İş atama sayfasını import ettik

class ShowPersonelListPage extends StatefulWidget {
  const ShowPersonelListPage({super.key});

  @override
  State<ShowPersonelListPage> createState() => _ShowPersonelListPageState();
}

class _ShowPersonelListPageState extends State<ShowPersonelListPage> {
  // Servis sınıfını başlat
  final PersonelService _personelService = PersonelService();
  late Future<List<Worker>> _workersFuture;

  @override
  void initState() {
    super.initState();
    _workersFuture = _personelService.fetchWorkers();
  }

  // GRUPLANDIRILMIŞ LİSTE OLUŞTURMA VE GÖRÜNTÜLEME
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
          // 'Meşgul' durumunu buraya ekledik.
          List<String> orderedKeys = [
            'Müsait',
            'Aktif Görevde',
            'Meşgul',
            'İzinli',
            'Bilinmiyor',
          ];

          // EĞER listede olmayan yeni bir durum gelirse (örn: Raporlu),
          // kaybolmaması için listenin sonuna ekliyoruz:
          final otherKeys = groupedWorkers.keys
              .where((key) => !orderedKeys.contains(key))
              .toList();
          orderedKeys.addAll(otherKeys);

          // Sadece verisi olan grupları filtrele
          final finalKeys = orderedKeys
              .where((key) => groupedWorkers.containsKey(key))
              .toList();

          return ListView.builder(
            itemCount: finalKeys.length,
            itemBuilder: (context, index) {
              final statusKey = finalKeys[index];
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

// --- CARD WIDGET ---
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
          color: worker.statusColor,
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
          // Tıklandığında İş Atama Sayfasına Git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssignJobPage(worker: worker),
            ),
          );
        },
      ),
    );
  }
}
