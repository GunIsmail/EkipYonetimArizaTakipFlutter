// lib/admin_page/assign_job_page.dart
import 'package:flutter/material.dart';
import '../services/personel_service.dart'; // Worker modeli için
import '../services/task_service.dart'; // YENİ: Gerçek veri servisi
import 'task_model.dart'; // YENİ: Gerçek WorkOrder modeli

class AssignJobPage extends StatefulWidget {
  final Worker worker;

  const AssignJobPage({super.key, required this.worker});

  @override
  State<AssignJobPage> createState() => _AssignJobPageState();
}

class _AssignJobPageState extends State<AssignJobPage> {
  final TaskService _taskService = TaskService(); // Servisi başlattık
  final TextEditingController _noteController = TextEditingController();

  List<WorkOrder> _availableTasks = []; // Gerçek model listesi
  WorkOrder? _selectedTask;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPendingTasks();
  }

  // Sadece 'NEW' (Yeni/Atanmamış) durumundaki işleri çekiyoruz
  Future<void> _loadPendingTasks() async {
    // API'den "NEW" statüsündeki işleri istiyoruz
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
        const SnackBar(content: Text('Lütfen listeden bir iş seçiniz.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Servis üzerinden gerçek atama işlemi
    bool success = await _taskService.assignTaskToWorker(
      _selectedTask!.id, // WorkOrder id'si (int)
      widget.worker.id, // Worker id'si (String)
      _noteController.text,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.worker.name} başarıyla görevlendirildi!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // İşlem bitince sayfayı kapat
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atama yapılırken bir hata oluştu!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.worker.name} - İş Atama')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PERSONEL KARTI ---
            Card(
              color: widget.worker.statusColor.withOpacity(0.1),
              elevation: 0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: widget.worker.statusColor,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  widget.worker.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${widget.worker.role} - ${widget.worker.status}',
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Bekleyen İşler Listesi (API)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // --- İŞ SEÇİM DROPDOWN ---
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _availableTasks.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Atanacak yeni iş bulunamadı.",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                : DropdownButtonFormField<WorkOrder>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.assignment_outlined),
                    ),
                    isExpanded: true, // Metin uzunsa taşmasın diye
                    hint: const Text("Listeden bir iş seçiniz..."),
                    value: _selectedTask,
                    items: _availableTasks.map((WorkOrder task) {
                      return DropdownMenuItem<WorkOrder>(
                        value: task,
                        child: Text(
                          "${task.title}", // Başlık
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (WorkOrder? newValue) {
                      setState(() {
                        _selectedTask = newValue;
                      });
                    },
                  ),

            // Seçilen işin detayını gösterme
            if (_selectedTask != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📍 Adres: ${_selectedTask!.customerAddress}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text("ℹ️ Durum: ${_selectedTask!.statusDisplay}"),
                    // Eğer WorkOrder modelinde tarih varsa buraya ekleyebilirsiniz:
                    // Text("📅 Tarih: ${_selectedTask!.date}"),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            const Text(
              "Yönetici Notu / Açıklama",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Örn: Yedek parça almayı unutma...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
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
                label: Text(_isSubmitting ? "Atama Yapılıyor..." : "İşi Ata"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
