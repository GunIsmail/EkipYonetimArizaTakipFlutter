// lib/admin_page/budget_history_modal.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'budget_transaction_model.dart';
import '../Definitions.dart'; // Api sınıfının yolu
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// --- Bütçe Geçmişi Veri Çekme Fonksiyonu ---
Future<List<BudgetTransaction>> _fetchHistory(
  int workerId,
  String accessToken,
) async {
  // 💡 ÖNEMLİ: Bu URL'in doğru workerId ile çalışıp çalışmadığını kontrol edin
  final uri = Uri.parse(Api.getWorkerBudgetHistoryUrl(workerId));

  final List<Map<String, dynamic>> simulatedData = workerId == 1
      ? [
          {
            'id': 99,
            'amount': 1500.0,
            'signed_amount': '+1500.00',
            'type_display': 'Ekleme',
            'timestamp': '2025-11-05T10:30:00Z',
            'description': 'Başlangıç bütçesi',
            'conducted_by': 'Admin',
          },
          {
            'id': 100,
            'amount': 250.0,
            'signed_amount': '-250.00',
            'type_display': 'Çıkarma',
            'timestamp': '2025-11-06T09:00:00Z',
            'description': 'Malzeme Alımı',
            'conducted_by': 'Admin',
          },
        ]
      : [
          {
            'id': 200,
            'amount': 500.0,
            'signed_amount': '+500.00',
            'type_display': 'Ekleme',
            'timestamp': '2025-10-01T15:00:00Z',
            'description': 'İlk Atama',
            'conducted_by': 'Süper Yönetici',
          },
          {
            'id': 201,
            'amount': 50.0,
            'signed_amount': '-50.00',
            'type_display': 'Çıkarma',
            'timestamp': '2025-10-15T12:00:00Z',
            'description': 'Ulaşım Gideri',
            'conducted_by': 'Yönetici A',
          },
        ];

  try {
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
      return jsonList.map((json) => BudgetTransaction.fromJson(json)).toList();
    } else {
      // Hata durumunda, workerId'ye göre farklı simülasyon verisi döndürerek testi kolaylaştırırız.
      return simulatedData
          .map((json) => BudgetTransaction.fromJson(json))
          .toList();
    }
  } catch (e) {
    // Ağ hatası durumunda, workerId'ye göre farklı simülasyon verisi döndür
    print('Ağ Hatası: $e');
    return simulatedData
        .map((json) => BudgetTransaction.fromJson(json))
        .toList();
  }
}

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

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory(widget.workerId, widget.accessToken);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          children: [
            Text(
              '${widget.workerName} Bütçe Geçmişi (ID: ${widget.workerId})', // ID eklendi
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const Divider(),

            // Başlık Çubuğu
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0, top: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Tarih ve Saat / Yapan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Tutar',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            Expanded(
              child: FutureBuilder<List<BudgetTransaction>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Hata: ${snapshot.error.toString()}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Bu personel için bütçe hareketi bulunamadı.',
                      ),
                    );
                  }

                  final history = snapshot.data!;
                  return ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final tx = history[index];
                      // intl paketinden gelen DateFormat kullanılır
                      final formattedDate = DateFormat(
                        'dd.MM.yyyy HH:mm',
                      ).format(tx.timestamp);

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Yönetici: ${tx.conductedBy}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    // Signed Amount kullanılıyor
                                    '${tx.signedAmount} ₺',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: tx.isAddition
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: tx.description.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Açıklama: ${tx.description}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  )
                                : null,
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    );
  }
}
