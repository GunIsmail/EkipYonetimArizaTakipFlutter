// lib/admin_page/task_management_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../Definitions.dart';
import 'task_model.dart';
import 'task_creation_modal.dart';
import '../constants/app_colors.dart';

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

  void _refreshTaskList() {
    _taskRefreshFuture = Future.value();
    setState(() {});
  }

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

  Future<void> _deleteWorkOrder(int taskId) async {
    final uri = Uri.parse('${Api.baseUrl}/api/tasks/$taskId/');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İş emri siliniyor...'),
        backgroundColor: AppColors.primary,
      ),
    );

    try {
      final response = await http.delete(uri);

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İş emri başarıyla silindi.'),
            backgroundColor: AppColors.success,
          ),
        );
        _refreshTaskList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme Başarısız. Hata kodu: ${response.statusCode}'),
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

  void _showCreateTaskModal() {
    showDialog(
      context: context,
      builder: (context) => TaskCreationModal(onTaskCreated: _refreshTaskList),
    );
  }

  Widget _buildTaskList(String statusFilter) {
    return FutureBuilder<List<WorkOrder>>(
      future: _taskRefreshFuture!.then((_) => _fetchWorkOrders(statusFilter)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Veri Yükleme Hatası: ${snapshot.error}',
              style: const TextStyle(color: AppColors.error),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final task = snapshot.data![index];
              return TaskCard(task: task, onDelete: _deleteWorkOrder);
            },
          );
        } else {
          final int index = _statusFilters.indexOf(statusFilter);
          return Center(
            child: Text(
              '${_tabTitles[index]} iş emri bulunamadı.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('İş Emri Yönetimi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statusFilters.map((status) {
          return _buildTaskList(status);
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskModal,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni İş Emri'),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final WorkOrder task;
  final ValueChanged<int> onDelete;

  const TaskCard({required this.task, required this.onDelete, super.key});

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.NEW:
        return AppColors.error;
      case TaskStatus.IN_PROGRESS:
        return AppColors.warning;
      case TaskStatus.COMPLETED:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'İş Emrini Sil',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '${task.title} başlıklı iş emrini silmek istediğinizden emin misiniz?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(task.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
      color: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.engineering, color: _getStatusColor(task.status)),
        title: Text(
          task.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durum: ${task.statusDisplay}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (task.assignedWorkerName != null)
              Text(
                'Atanan: ${task.assignedWorkerName}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            Text(
              'Adres: ${task.customerAddress}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              tooltip: 'İş Emrini Sil',
              onPressed: () => _confirmDelete(context),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Detaylar için ${task.title} görevine tıklandı'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}
