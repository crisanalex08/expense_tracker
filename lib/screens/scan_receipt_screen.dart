import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/expense.dart';
import '../services/firestore_service.dart';

// ─────────────────────────────────────────────
// Category keyword map — extend as needed
// ─────────────────────────────────────────────
const _categoryKeywords = <String, List<String>>{
  'Food': [
    'restaurant', 'cafe', 'coffee', 'pizza', 'burger', 'sushi', 'bakery',
    'bistro', 'grill', 'diner', 'mcdonald', 'kfc', 'subway', 'starbucks',
    'bar', 'pub', 'tavern', 'kebab', 'shawarma', 'food', 'eat', 'lunch',
    'dinner', 'breakfast', 'snack', 'supermarket', 'grocery', 'lidl',
    'kaufland', 'aldi', 'carrefour', 'mega image',
  ],
  'Transport': [
    'uber', 'bolt', 'taxi', 'cab', 'lyft', 'bus', 'metro', 'subway',
    'train', 'railway', 'airline', 'airport', 'flight', 'fuel', 'petrol',
    'gasoline', 'diesel', 'parking', 'garage', 'toll', 'rompetrol',
    'mol ', 'omv', 'socar',
  ],
  'Bills': [
    'electric', 'electricity', 'gas ', 'water ', 'internet', 'broadband',
    'phone', 'mobile', 'telecom', 'vodafone', 'orange', 'digi', 'telekom',
    'rent', 'lease', 'insurance', 'subscription', 'netflix', 'spotify',
    'invoice', 'utility', 'factura',
  ],
  'Misc': [], // catch-all category with no specific keywords
};

String _detectCategory(String rawText) {
  final lower = rawText.toLowerCase();
  for (final entry in _categoryKeywords.entries) {
    for (final keyword in entry.value) {
      if (lower.contains(keyword)) return entry.key;
    }
  }
  return 'Misc'; // sensible default
}

// ─────────────────────────────────────────────
// Amount extractor — grabs the largest number
// on the receipt (usually the total)
// ─────────────────────────────────────────────
double? _extractAmount(String text) {
  // Matches patterns like: 12.50  12,50  RON 12.50  €12  12.50 lei
  final pattern = RegExp(r'(\d{1,6}[.,]\d{2})', multiLine: true);
  final matches = pattern.allMatches(text).map((m) {
    final raw = m.group(1)!.replaceAll(',', '.');
    return double.tryParse(raw);
  }).whereType<double>().toList();

  if (matches.isEmpty) return null;
  matches.sort((a, b) => b.compareTo(a)); // largest = most likely total
  return matches.first;
}

// ─────────────────────────────────────────────
// Merchant extractor — first non-empty line
// that is long enough to be a business name
// ─────────────────────────────────────────────
String? _extractMerchant(String text) {
  final lines = text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.length >= 3 && !RegExp(r'^\d').hasMatch(l))
      .toList();
  return lines.isNotEmpty ? lines.first : null;
}

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────
class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  XFile? _image;
  bool _scanning = false;

  // Editable fields pre-filled from OCR
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = 'Food';

  final _firestore = FirestoreService();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Pick image ──────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null || !mounted) return;

    setState(() {
      _image = picked;
      _scanning = true;
      // Reset fields while scanning
      _amountCtrl.clear();
      _noteCtrl.clear();
      _category = 'Food';
    });

    await _runOcr(picked.path);
  }

  // ── OCR + extraction ────────────────────────
  Future<void> _runOcr(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();

      final raw = result.text;

      final amount = _extractAmount(raw);
      final merchant = _extractMerchant(raw);
      final category = _detectCategory(raw);

      if (!mounted) return;
      setState(() {
        if (amount != null) _amountCtrl.text = amount.toStringAsFixed(2);
        if (merchant != null) _noteCtrl.text = merchant;
        _category = category;
        _scanning = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the receipt. Try a clearer photo.')),
      );
    }
  }

  // ── Save ────────────────────────────────────
  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final expense = Expense(
      id: '',
      amount: amount,
      category: _category,
      note: _noteCtrl.text,
      date: DateTime.now(),
      merchant: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
      imagePath: _image?.path,
    );

    await _firestore.addExpense(user.uid, expense);
    if (!mounted) return;
    Navigator.pop(context);
  }

  // ── Source picker dialog ─────────────────────
  void _showSourceDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Receipt'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Pick from Gallery'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Receipt image area ──────────────
            GestureDetector(
              onTap: _showSourceDialog,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 220,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline, width: 1.5),
                ),
                clipBehavior: Clip.hardEdge,
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.document_scanner_outlined,
                              size: 48, color: cs.onSurfaceVariant),
                          const SizedBox(height: 10),
                          Text('Tap to scan a receipt',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(_image!.path), fit: BoxFit.cover),
                          // Scanning overlay
                          if (_scanning)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(color: Colors.white),
                                    SizedBox(height: 12),
                                    Text('Reading receipt…',
                                        style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          // Re-scan badge
                          if (!_scanning)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _showSourceDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh,
                                          color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text('Re-scan',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Extracted fields ────────────────
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
              ),
            ),

            const SizedBox(height: 16),

            InputDecorator(
              decoration: const InputDecoration(labelText: 'Category'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'Food',
                      child: Row(children: [
                        Icon(Icons.fastfood, size: 20),
                        SizedBox(width: 8),
                        Text('Food'),
                      ]),
                    ),
                    DropdownMenuItem(
                      value: 'Transport',
                      child: Row(children: [
                        Icon(Icons.directions_bus, size: 20),
                        SizedBox(width: 8),
                        Text('Transport'),
                      ]),
                    ),
                    DropdownMenuItem(
                      value: 'Bills',
                      child: Row(children: [
                        Icon(Icons.account_balance, size: 20),
                        SizedBox(width: 8),
                        Text('Bills'),
                      ]),
                    ),
                      DropdownMenuItem(
                        value: 'Misc',
                        child: Row(children: [
                          Icon(Icons.category, size: 20),
                          SizedBox(width: 8),
                          Text('Misc'),
                        ]),
                      ),
                  ],
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Merchant / Note',
                // prefixIcon: Icon(Icons.store_outlined),
              ),
            ),

            const SizedBox(height: 28),

            ElevatedButton.icon(
              onPressed: _scanning ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}