import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/expense.dart';
import '../services/firestore_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  String category = "Misc";
  final firestore = FirestoreService();
  XFile? _pickedReceipt;

  @override
  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> saveExpense() async {
    // Null / invalid-amount guard
    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;

    final expense = Expense(
      id: "",
      amount: amount,
      category: category,
      note: noteCtrl.text,
      date: DateTime.now(),
      merchant: null,
      imagePath: _pickedReceipt?.path,
    );

    await firestore.addExpense(user.uid, expense);

    if (!mounted) return;

    Navigator.pop(context);
  }

  Future<void> _pickReceipt(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (!mounted || image == null) return;

    setState(() => _pickedReceipt = image);
  }

  void _showPickerDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_pickedReceipt == null ? "Add Receipt" : "Replace Receipt"),
        content: Text(
          _pickedReceipt == null
              ? "Choose how to add your receipt"
              : "This will replace your current receipt.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _pickReceipt(ImageSource.camera);
            },
            child: const Text("Take Photo"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _pickReceipt(ImageSource.gallery);
            },
            child: const Text("Pick from Gallery"),
          ),
        ],
      ),
    );
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

            // Full-width dropdown via isExpanded + InputDecorator
            InputDecorator(
              decoration: const InputDecoration(labelText: "Category"),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: "Food",
                      child: Row(
                        children: [
                          Icon(Icons.restaurant_rounded, size: 20),
                          SizedBox(width: 8),
                          Text("Food"),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: "Transport",
                      child: Row(
                        children: [
                          Icon(Icons.directions_car_rounded, size: 20),
                          SizedBox(width: 8),
                          Text("Transport"),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: "Bills",
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 20),
                          SizedBox(width: 8),
                          Text("Bills"),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: "Misc",
                      child: Row(
                        children: [
                          Icon(Icons.category, size: 20),
                          SizedBox(width: 8),
                          Text("Misc"),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => category = value!);
                  },
                ),
              ),
            ),

            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: "Note"),
            ),

            const SizedBox(height: 20),

            // Receipt preview — only shown once a receipt has been picked
            if (_pickedReceipt != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_pickedReceipt!.path),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // "Replace" badge in the top-right corner
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _showPickerDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "Replace",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Show "Add Receipt" button only when no receipt has been picked yet
            if (_pickedReceipt == null)
              ElevatedButton.icon(
                onPressed: _showPickerDialog,
                icon: const Icon(Icons.receipt_long),
                label: const Text("Add Receipt"),
              ),

            const SizedBox(height: 20),
            ElevatedButton(onPressed: saveExpense, child: const Text("Save")),
          ],
        ),
      ),
    );
  }
}