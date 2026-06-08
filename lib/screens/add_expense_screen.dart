import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// OCR and image picking removed

import '../models/expense.dart';
import '../services/firestore_service.dart';
// receipt review screen removed

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  String category = "Food";
  final firestore = FirestoreService();
  // OCR/image scanning removed; no image fields or services

  @override
  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> saveExpense() async {
    final user = FirebaseAuth.instance.currentUser!;
    final expense = Expense(
      id: "",
      amount: double.tryParse(amountCtrl.text) ?? 0,
      category: category,
      note: noteCtrl.text,
      date: DateTime.now(),
      merchant: null,
      imagePath: null,
    );

    await firestore.addExpense(user.uid, expense);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),

            DropdownButton<String>(
              value: category,
              items: const [
                DropdownMenuItem(value: "Food", child: Text("Food")),
                DropdownMenuItem(value: "Transport", child: Text("Transport")),
                DropdownMenuItem(value: "Bills", child: Text("Bills")),
              ],
              onChanged: (value) {
                setState(() => category = value!);
              },
            ),

            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: "Note"),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveExpense,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}