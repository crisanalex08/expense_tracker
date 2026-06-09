import 'dart:io';

import 'package:flutter/material.dart';

import '../models/expense.dart';

class ReceiptReviewScreen extends StatefulWidget {
  final String imagePath;
  final String initialCategory;
  final String initialNote;

  const ReceiptReviewScreen({
    super.key,
    required this.imagePath,
    required this.initialCategory,
    required this.initialNote,
  });

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  late final TextEditingController amountCtrl;
  late final TextEditingController merchantCtrl;
  late final TextEditingController noteCtrl;
  late final TextEditingController dateCtrl;

  String category = 'Food';

  static const categories = [
    'Food',
    'Transport',
    'Bills',
  ];

  @override
  void initState() {
    super.initState();
    amountCtrl = TextEditingController();
    merchantCtrl = TextEditingController();
    noteCtrl = TextEditingController(text: widget.initialNote);
    dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    category = categories.contains(widget.initialCategory)
        ? widget.initialCategory
        : 'Food';
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    merchantCtrl.dispose();
    noteCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    final parsedDate = DateTime.tryParse(dateCtrl.text) ?? DateTime.now();

    Navigator.pop(
      context,
      Expense(
        id: '',
        amount: amount,
        category: category,
        note: noteCtrl.text,
        date: parsedDate,
        merchant: merchantCtrl.text.trim().isEmpty ? null : merchantCtrl.text.trim(),
        imagePath: widget.imagePath.isEmpty ? null : widget.imagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Receipt')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.imagePath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.imagePath),
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: merchantCtrl,
                decoration: const InputDecoration(labelText: 'Merchant'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: categories
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => category = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}