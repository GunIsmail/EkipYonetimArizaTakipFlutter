// lib/admin_page/budget_history_modal.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_budget_service.dart';
import '../services/budget_transaction_model.dart';

class BudgetHistoryModal extends StatefulWidget {
  final int workerId;
  final String workerName;
  final String accessToken;

  const BudgetHistoryModal({
    super.key,
    required this.workerId,
    required this.workerName,
    required this.accessToken,
  });

  @override
  State<BudgetHistoryModal> createState() => _BudgetHistoryModalState();
}

class _BudgetHistoryModalState extends State<BudgetHistoryModal> {
  late Future<List<BudgetTransaction>> _historyFuture;
  final AdminBudgetService _budgetService = AdminBudgetService();

  @override
  void initState() {
    super.initState();
    // Servis üzerinden veriyi çekiyoruz
    _historyFuture = _budgetService.fetchHistory(
      widget.workerId,
      widget.accessToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      backgroundColor: Colors.white,
      child: Container(
        // Yüksekliği ekranın %75'i yaptık
        height: MediaQuery.of(context).size.height * 0.75,
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(
          0,
        ), // Padding'i kaldırdık, içeride vereceğiz
        child: Column(
          children: [
            // --- Modal Başlığı ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    widget.workerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bütçe Geçmişi (ID: ${widget.workerId})',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

            // --- Tablo Başlık Satırı (Renkli Arkaplan) ---
            Container(
              color: Colors.grey[100], // Hafif gri arka plan
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Tarih / İşlemi Yapan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Tutar',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // --- Liste Alanı ---
            Expanded(
              child: FutureBuilder<List<BudgetTransaction>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Hata: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Kayıt bulunamadı.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  final history = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: history.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = history[index];
                      // YANLIŞ OLAN:
                      // DOĞRU OLAN (String'i DateTime'a çeviriyoruz):
                      final formattedDate = DateFormat(
                        'dd.MM.yyyy HH:mm',
                      ).format(DateTime.parse(tx.timestamp));

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sol Taraf: Tarih ve Açıklama
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Yönetici: ${tx.conductedBy}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (tx.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      tx.description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${tx.signedAmount} ₺',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: tx.isAddition
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    tx.isAddition ? "Ekleme" : "Çıkarma",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: tx.isAddition
                                          ? Colors.green.shade300
                                          : Colors.red.shade300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // --- Alt Buton ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors
                        .blueAccent, // Tema renginize göre değiştirebilirsiniz
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
