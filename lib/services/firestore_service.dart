import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> addExpense(String userId, Expense expense) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .add(expense.toMap());
  }

  Stream<List<Expense>> getExpenses(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }
}