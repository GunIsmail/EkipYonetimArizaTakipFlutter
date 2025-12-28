// lib/admin_page/task_management_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../Definitions.dart';
import 'task_model.dart';
import 'task_creation_modal.dart';

class TaskManagementPage extends StatefulWidget {
  const TaskManagementPage({super.key});

  @override
  State<TaskManagementPage> createState() => _TaskManagementPageState();
}

class _TaskManagementPageState extends State<TaskManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _statusFilters = ['NEW', 'IN_PROGRESS', 'COMPLETED'];
  final List<String> _tabTitles = ['Yeni (Aktif)', 'Süreçte', 'Tamamlandı'];

  Future<void>? _taskRefreshFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _taskRefreshFuture = Future.value();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Liste Yenileme Fonksiyonu ---
  void _refreshTaskList() {
    // setState asenkron hatasını önlemek için Future'ı dışarıda atayıp boş setState kullanıyoruz.
    _taskRefreshFuture = Future.value();
    setState(() {});
  }

  // --- API: İş Emirlerini Duruma Göre Çekme Fonksiyonu ---
  Future<List<WorkOrder>> _fetchWorkOrders(String statusFilter) async {
    final uri = Uri.parse('${Api.baseUrl}/api/tasks/?status=$statusFilter');

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

  // --- API: İş Emri Silme Fonksiyonu ---
  Future<void> _deleteWorkOrder(int taskId) async {
    // API: /api/tasks/{id}/
    final uri = Uri.parse('${Api.baseUrl}/api/tasks/$taskId/');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('İş emri siliniyor...')));

    try {
      // Silme isteği gönder (headers boş - token'sız çözüm)
      final response = await http.delete(uri);

      if (response.statusCode == 204) {
        // 204 No Content = Başarılı Silme
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İş emri başarıyla silindi.')),
        );
        _refreshTaskList(); // Listeyi yenile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme Başarısız. Hata kodu: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ağ Hatası: $e')));
    }
  }

  // --- Yeni İş Emri Oluşturma Modalını Açma ---
  void _showCreateTaskModal() {
    showDialog(
      context: context,
      builder: (context) => TaskCreationModal(onTaskCreated: _refreshTaskList),
    );
  }

  // --- İş Emri Listesini Gösteren Widget ---
  Widget _buildTaskList(String statusFilter) {
    return FutureBuilder<List<WorkOrder>>(
      // Hem _taskRefreshFuture hem de _fetchWorkOrders'ı bağlar
      future: _taskRefreshFuture!.then((_) => _fetchWorkOrders(statusFilter)),
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
              return TaskCard(
                task: task,
                onDelete: _deleteWorkOrder, // 🎯 Silme fonksiyonu bağlandı
              );
            },
          );
        } else {
          final int index = _statusFilters.indexOf(statusFilter);
          return Center(
            child: Text('${_tabTitles[index]} iş emri bulunamadı.'),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İş Emri Yönetimi'),
        bottom: TabBar(
          // Sekme Başlıkları
          controller: _tabController,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        // Sekme İçerikleri
        controller: _tabController,
        children: _statusFilters.map((status) {
          return _buildTaskList(status); // Her duruma göre listeyi çeker
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskModal,
        icon: const Icon(Icons.add),
        label: const Text('Yeni İş Emri'),
      ),
    );
  }
}

// --- İş Emri Kartı Widgetı  ---
class TaskCard extends StatelessWidget {
  final WorkOrder task;
  final ValueChanged<int> onDelete; // Silme callback'i

  const TaskCard({required this.task, required this.onDelete, super.key});

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.NEW:
        return Colors.red.shade700;
      case TaskStatus.IN_PROGRESS:
        return Colors.orange.shade700;
      case TaskStatus.COMPLETED:
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  // Silme Onayı Modalı
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İş Emrini Sil'),
        content: Text(
          '${task.title} başlıklı iş emrini silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(task.id); // Silme işlemini başlat
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.engineering, color: _getStatusColor(task.status)),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Durum: ${task.statusDisplay}'),
            if (task.assignedWorkerName != null)
              Text('Atanan: ${task.assignedWorkerName}'),
            Text('Adres: ${task.customerAddress}'),
          ],
        ),
        trailing: Row(
          // Trailing'i Row yaparak silme ve detay butonunu ayırıyoruz
          mainAxisSize: MainAxisSize.min,
          children: [
            // Silme Butonu
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'İş Emrini Sil',
              onPressed: () => _confirmDelete(context), // Onay modalını aç
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Detaylar için ${task.title} görevine tıklandı'),
            ),
          );
        },
      ),
    );
  }
}
