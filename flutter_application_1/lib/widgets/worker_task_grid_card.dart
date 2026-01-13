// Dosya: lib/widgets/worker_task_grid_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../admin_page/task_model.dart';
import '../constants/app_colors.dart';

class WorkerTaskGridCard extends StatelessWidget {
  final WorkOrder task;
  final Function(int taskId) onTaskRequest;
  final Function(int taskId, String desc, double amount) onTaskComplete;

  const WorkerTaskGridCard({
    required this.task,
    required this.onTaskRequest,
    required this.onTaskComplete,
    super.key,
  });

  // Duruma göre renk seçimi
  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.NEW:
        return AppColors.primary;
      case TaskStatus.IN_PROGRESS:
        return AppColors.warning;
      case TaskStatus.COMPLETED:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  // --- KARTIN ANA YAPISI ---
  @override
  Widget build(BuildContext context) {
    final bool canRequest = task.status == TaskStatus.NEW;
    final bool isInProgress = task.status == TaskStatus.IN_PROGRESS;
    final statusColor = _getStatusColor(task.status);

    // İkon seçimi
    IconData iconData = Icons.build_circle_outlined;
    if (task.status == TaskStatus.COMPLETED)
      iconData = Icons.check_circle_outline;
    if (task.status == TaskStatus.IN_PROGRESS) iconData = Icons.hourglass_top;

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Center(child: Icon(iconData, size: 48, color: statusColor)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.statusDisplay,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ORTA BİLGİ (sabit/padding)
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.customerAddress ?? 'Adres yok',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // BUTON
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: SizedBox(
              height: 36,
              child: _buildActionButton(context, canRequest, isInProgress, statusColor),
            ),
          ),
        ],
      ),
    );
  } // <--- BURADAKİ PARANTEZ EKSİKTİ, EKLENDİ.

  Widget _buildActionButton(
    BuildContext context,
    bool canRequest,
    bool isInProgress,
    Color color,
  ) {
    if (canRequest) {
      return ElevatedButton(
        onPressed: () => _confirmTaskRequest(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Talep Et', style: TextStyle(fontSize: 12)),
      );
    } else if (isInProgress) {
      return ElevatedButton(
        onPressed: () => _showCompletionDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warning,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Tamamla', style: TextStyle(fontSize: 12)),
      );
    } else {
      // Tamamlanmışsa
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.success),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Text(
          "Bitti",
          style: TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  void _showCompletionDialog(BuildContext context) {
    final TextEditingController descController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Görevi Tamamla',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
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
                labelText: 'Tutar (₺)',
                border: OutlineInputBorder(),
                isDense: true,
                suffixText: '₺',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final desc = descController.text;
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (desc.isEmpty) return;
              Navigator.pop(ctx);
              onTaskComplete(task.id, desc, amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  void _confirmTaskRequest(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Al', style: TextStyle(fontSize: 18)),
        content: Text('${task.title}\nBu görevi almak istiyor musun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Vazgeç',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onTaskRequest(task.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet, Al'),
          ),
        ],
      ),
    );
  }
}