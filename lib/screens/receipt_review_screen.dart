import 'dart:io';

import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/receipt_service.dart';

class ReceiptReviewScreen extends StatefulWidget {
  final ReceiptExtractionResult extraction;
  final String initialCategory;
  final String initialNote;

  const ReceiptReviewScreen({
    super.key,
    required this.extraction,
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
    amountCtrl = TextEditingController(
      text: widget.extraction.amount?.toStringAsFixed(2) ?? '',
    );
    merchantCtrl = TextEditingController(text: widget.extraction.merchant ?? '');
    noteCtrl = TextEditingController(text: widget.initialNote);
    dateCtrl = TextEditingController(
      text: widget.extraction.date?.toIso8601String().split('T').first ??
          DateTime.now().toIso8601String().split('T').first,
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
        imagePath: widget.extraction.imagePath,
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
              if (widget.extraction.imagePath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.extraction.imagePath),
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
              const SizedBox(height: 12),
              Text(
                widget.extraction.rawText.isEmpty
                    ? 'No receipt text recognized.'
                    : 'Recognized text is available for review if the fields need adjustment.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}