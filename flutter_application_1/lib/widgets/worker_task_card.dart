// Dosya: lib/widgets/worker_task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../admin_page/task_model.dart';

class WorkerTaskCard extends StatelessWidget {
  final WorkOrder task;
  // Mevcut callback
  final Function(int taskId) onTaskRequest;
  // YENİ CALLBACK: Tamamlama işlemi için
  final Function(int taskId, String desc, double amount) onTaskComplete;

  const WorkerTaskCard({
    required this.task,
    required this.onTaskRequest,
    required this.onTaskComplete, // Constructor'a ekledik
    super.key,
  });

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.NEW:
        return const Color(0xFF6C63FF);
      case TaskStatus.IN_PROGRESS:
        return Colors.orangeAccent;
      case TaskStatus.COMPLETED:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // --- YENİ EKLENEN KISIM: Tamamlama Dialog'u ---
  void _showCompletionDialog(BuildContext context) {
    final TextEditingController descController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Görevi Tamamla & Bütçe İste'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Görevi tamamlarken yaptığınız harcamayı ve yapılan işlemin özetini giriniz.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Yapılan İşlemler (Açıklama)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Talep Edilen Tutar (₺)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final desc = descController.text;
              final amount = double.tryParse(amountController.text) ?? 0.0;

              if (desc.isEmpty) {
                // Basit validasyon
                return;
              }

              Navigator.pop(ctx);
              // Logic katmanına verileri yolluyoruz
              onTaskComplete(task.id, desc, amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Onaya Gönder'),
          ),
        ],
      ),
    );
  }

  // --- Mevcut Talep Onayı ---
  void _confirmTaskRequest(BuildContext context) {
    // ... (Eski kodunuzla aynı, burayı kısalttım yer kaplamasın diye)
    // Buradaki kod aynen kalacak, sadece onTaskRequest çağırılıyor.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Talep Et'),
        content: Text('${task.title} görevini almak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onTaskRequest(task.id);
            },
            child: const Text('Talep Et'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canRequest = task.status == TaskStatus.NEW;
    final bool isInProgress = task.status == TaskStatus.IN_PROGRESS;
    final statusColor = _getStatusColor(task.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Üst Kısım (Icon, Title, Status) - Değişmedi
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.build_rounded, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.statusDisplay,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bilgiler
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  task.customerAddress ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- BUTONLAR ---
            if (canRequest)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _confirmTaskRequest(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Görevi Talep Et'),
                ),
              )
            else if (isInProgress)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCompletionDialog(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Tamamla & Bütçe İste'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Dikkat çekici renk
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
