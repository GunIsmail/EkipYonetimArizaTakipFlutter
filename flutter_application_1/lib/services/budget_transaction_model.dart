// Dosya: lib/services/budget_transaction_model.dart (veya senin dosya yolun neyse)

class BudgetTransaction {
  final int id;
  final double amount;
  final String signedAmount; // Örn: "+500.0"
  final String typeDisplay;
  final String description;
  final String timestamp; // String olarak geliyor
  final String conductedBy;

  BudgetTransaction({
    required this.id,
    required this.amount,
    required this.signedAmount,
    required this.typeDisplay,
    required this.description,
    required this.timestamp,
    required this.conductedBy,
  });

  factory BudgetTransaction.fromJson(Map<String, dynamic> json) {
    return BudgetTransaction(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      signedAmount: json['signed_amount'] ?? '',
      typeDisplay: json['type_display'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] ?? '',
      conductedBy: json['conducted_by'] ?? 'Sistem',
    );
  }

  bool get isAddition => signedAmount.startsWith('+');

  DateTime get dateObj {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return DateTime.now();
    }
  }
}
