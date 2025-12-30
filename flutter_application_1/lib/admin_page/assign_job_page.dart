// lib/admin_page/assign_job_page.dart

import 'package:flutter/material.dart';
import '../services/personel_service.dart';
import '../services/task_service.dart';
import 'task_model.dart';
import '../constants/app_colors.dart';

class AssignJobPage extends StatefulWidget {
  final Worker worker;

  const AssignJobPage({super.key, required this.worker});

  @override
  State<AssignJobPage> createState() => _AssignJobPageState();
}

class _AssignJobPageState extends State<AssignJobPage> {
  final TaskService _taskService = TaskService();
  final TextEditingController _noteController = TextEditingController();

  List<WorkOrder> _availableTasks = [];
  WorkOrder? _selectedTask;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPendingTasks();
  }

  Future<void> _loadPendingTasks() async {
    final tasks = await _taskService.fetchTasksByStatus('NEW');

    if (mounted) {
      setState(() {
        _availableTasks = tasks;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen listeden bir iş seçiniz.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    bool success = await _taskService.assignTaskToWorker(
      _selectedTask!.id,
      widget.worker.id,
      _noteController.text,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.worker.name} başarıyla görevlendirildi!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atama yapılırken bir hata oluştu!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.worker.name} - İş Atama'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: widget.worker.statusColor.withOpacity(0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: widget.worker.statusColor.withOpacity(0.3),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: widget.worker.statusColor,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  widget.worker.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${widget.worker.role} - ${widget.worker.status}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Bekleyen İşler Listesi",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // --- İŞ SEÇİM DROPDOWN ---
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _availableTasks.isEmpty
                ? const Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Atanacak yeni iş bulunamadı.",
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  )
                : DropdownButtonFormField<WorkOrder>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: AppColors.surface, // <--- GÜNCELLENDİ
                      prefixIcon: const Icon(
                        Icons.assignment_outlined,
                        color: AppColors.primary, // <--- GÜNCELLENDİ
                      ),
                    ),
                    isExpanded: true,
                    hint: const Text("Listeden bir iş seçiniz..."),
                    value: _selectedTask,
                    items: _availableTasks.map((WorkOrder task) {
                      return DropdownMenuItem<WorkOrder>(
                        value: task,
                        child: Text(
                          "${task.title}",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (WorkOrder? newValue) {
                      setState(() {
                        _selectedTask = newValue;
                      });
                    },
                  ),

            // Seçilen işin detayı (Tasarım güncellendi)
            if (_selectedTask != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(
                    0.1,
                  ), // <--- GÜNCELLENDİ (Eskiden Maviydi)
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📍 Adres: ${_selectedTask!.customerAddress}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "ℹ️ Durum: ${_selectedTask!.statusDisplay}",
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            const Text(
              "Yönetici Notu / Açıklama",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Örn: Yedek parça almayı unutma...",
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface, // <--- GÜNCELLENDİ
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_isSubmitting || _availableTasks.isEmpty)
                    ? null
                    : _submitAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // <--- GÜNCELLENDİ
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSubmitting ? "Atama Yapılıyor..." : "İşi Ata",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
