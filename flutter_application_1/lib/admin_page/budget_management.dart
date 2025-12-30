// lib/admin_page/budget_management_page.dart

import 'package:flutter/material.dart';
import '../services/budget_management_service.dart';
import 'budget_history_modal.dart';
import '../constants/app_colors.dart';

class BudgetManagementPage extends StatefulWidget {
  const BudgetManagementPage({super.key});

  @override
  State<BudgetManagementPage> createState() => _BudgetManagementPageState();
}

class _BudgetManagementPageState extends State<BudgetManagementPage> {
  late Future<List<Worker>> _workersFuture;
  final WorkerBudgetService _service = WorkerBudgetService();

  @override
  void initState() {
    super.initState();
    _workersFuture = _service.fetchWorkers();
  }

  void _refreshList() {
    setState(() {
      _workersFuture = _service.fetchWorkers();
    });
  }

  // --- İş Mantığı (Güncelleme) ---
  Future<void> _handleBudgetUpdate(
    String workerId,
    double newBudget,
    String description,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$description...'),
        backgroundColor: AppColors.primary.withOpacity(0.8),
        duration: const Duration(milliseconds: 800),
      ),
    );

    final result = await _service.updateBudget(
      workerId: workerId,
      newBudget: newBudget,
      description: description,
    );

    if (!mounted) return;

    if (result['success']) {
      _refreshList();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşlem Başarılı'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // --- Modallar ---
  void _editBudget(Worker worker) {
    final budgetController = TextEditingController(
      text: worker.budget.toStringAsFixed(2),
    );
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${worker.name} - Mutlak Düzenleme',
          style: const TextStyle(color: AppColors.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: budgetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Yeni Bütçe (₺)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Açıklama (Zorunlu)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final val = double.tryParse(
                budgetController.text.replaceAll(',', '.'),
              );
              final desc = descController.text.trim();
              if (val != null && val >= 0 && desc.isNotEmpty) {
                Navigator.pop(context);
                _handleBudgetUpdate(worker.id, val, 'Mutlak Değer: $desc');
              }
            },
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTransactionModal(Worker worker, {required bool isAddition}) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final action = isAddition ? 'Ekleme' : 'Çıkarma';
    final actionColor = isAddition ? AppColors.success : AppColors.error;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${worker.name} - Bütçe $action',
          style: TextStyle(color: actionColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Tutar (₺)',
                prefixIcon: Icon(
                  isAddition ? Icons.add : Icons.remove,
                  color: actionColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: actionColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Açıklama (Zorunlu)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: actionColor, width: 2),
                ),
              ),
            ),
          ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final amount = double.tryParse(
                amountController.text.replaceAll(',', '.'),
              );
              final desc = descController.text.trim();
              if (amount != null && amount > 0 && desc.isNotEmpty) {
                Navigator.pop(context);
                final newBudget = isAddition
                    ? worker.budget + amount
                    : worker.budget - amount;
                _handleBudgetUpdate(worker.id, newBudget, desc);
              }
            },
            child: Text(action, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBudgetHistoryModal(Worker worker) {
    const String adminAccessToken = 'YOUR_ADMIN_ACCESS_TOKEN';
    showDialog(
      context: context,
      builder: (context) => BudgetHistoryModal(
        workerId: int.parse(worker.id),
        workerName: worker.name,
        accessToken: adminAccessToken,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Bütçe Yönetimi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personel Listesi',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<Worker>>(
                  future: _workersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Kayıtlı personel yok.'));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (ctx, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final worker = snapshot.data![index];
                        return _WorkerBudgetCard(
                          worker: worker,
                          onEdit: _editBudget,
                          onAdd: (w) =>
                              _showTransactionModal(w, isAddition: true),
                          onSubtract: (w) =>
                              _showTransactionModal(w, isAddition: false),
                          onTap: _showBudgetHistoryModal,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Admin Paneli Tarzı Kart Tasarımı ---
class _WorkerBudgetCard extends StatelessWidget {
  final Worker worker;
  final ValueChanged<Worker> onEdit;
  final ValueChanged<Worker> onAdd;
  final ValueChanged<Worker> onSubtract;
  final ValueChanged<Worker> onTap;

  const _WorkerBudgetCard({
    required this.worker,
    required this.onEdit,
    required this.onAdd,
    required this.onSubtract,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(worker),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: worker.statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                worker.role,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(height: 1),
                ),

                // Alt Kısım: Bütçe ve Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bütçe Değeri
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Mevcut Bütçe",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${worker.budget.toStringAsFixed(2)} ₺',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: worker.budget < 0
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    // Butonlar
                    Row(
                      children: [
                        _MiniActionButton(
                          icon: Icons.remove,
                          color: AppColors.error,
                          onTap: () => onSubtract(worker),
                        ),
                        const SizedBox(width: 10),
                        _MiniActionButton(
                          icon: Icons.add,
                          color: AppColors.success,
                          onTap: () => onAdd(worker),
                        ),
                        const SizedBox(width: 10),
                        _MiniActionButton(
                          icon: Icons.edit,
                          color: AppColors.primary,
                          isOutlined: true,
                          onTap: () => onEdit(worker),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Yardımcı Buton Widget'ı
class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isOutlined;

  const _MiniActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
          border: isOutlined ? Border.all(color: color.withOpacity(0.5)) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
