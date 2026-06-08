import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_service.dart';

import '../models/expense.dart';
import '../services/firestore_service.dart';
import '../services/receipt_service.dart';
import 'receipt_review_screen.dart';

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
  String? imagePath;
  final imageService = ImageService();
  final receiptService = ReceiptService();

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
      imagePath: imagePath,
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
              onPressed: _scanReceipt,
              child: const Text("Scan Receipt"),
            ),
            if (imagePath != null) ...[
              const SizedBox(height: 12),
              Text(
                "Receipt attached",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: saveExpense,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final path = await imageService.pickAndSaveImage(source: source);
    if (path == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => imagePath = path);

    final extraction = await receiptService.extractReceiptDetails(path);
    if (!mounted) {
      return;
    }

    final draftExpense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptReviewScreen(
          extraction: extraction,
          initialCategory: category,
          initialNote: noteCtrl.text,
        ),
      ),
    );

    if (draftExpense == null || !mounted) {
      return;
    }

    await firestore.addExpense(FirebaseAuth.instance.currentUser!.uid, draftExpense);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }
}