import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final String? merchant;
  final String? imagePath;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    this.merchant,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'merchant': merchant,
      'imagePath': imagePath,
    };
  }

  static Expense fromMap(String id, Map<String, dynamic> map) {
    final rawDate = map['date'];
    final parsedDate = rawDate is Timestamp
        ? rawDate.toDate()
        : DateTime.parse(rawDate as String);

    return Expense(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'],
      note: (map['note'] ?? '') as String,
      date: parsedDate,
      merchant: map['merchant'] as String?,
      imagePath: map['imagePath'],
    );
  }
}