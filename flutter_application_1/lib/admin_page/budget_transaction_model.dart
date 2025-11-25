// lib/admin_page/budget_transaction_model.dart
class BudgetTransaction {
  final int id;
  final double amount;
  final String signedAmount;
  final String typeDisplay;
  final DateTime timestamp;
  final String description;
  final String conductedBy;

  // Helper: İşlem ekleme mi çıkarma mı olduğunu anlamak için
  bool get isAddition => signedAmount.startsWith('+');

  BudgetTransaction({
    required this.id,
    required this.amount,
    required this.signedAmount,
    required this.typeDisplay,
    required this.timestamp,
    required this.description,
    required this.conductedBy,
  });

  factory BudgetTransaction.fromJson(Map<String, dynamic> json) {
    return BudgetTransaction(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      signedAmount: json['signed_amount'] as String,
      typeDisplay: json['type_display'] as String,
      // API'dan gelen UTC zaman damgasını yerel saate dönüştürür
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      description: json['description'] as String,
      conductedBy: json['conducted_by'] as String? ?? 'Bilinmiyor',
    );
  }
}
