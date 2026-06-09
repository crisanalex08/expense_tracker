import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_service.dart';
import '../services/snackbar_service.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';
import 'dashboard_screen.dart';
import 'scan_receipt_screen.dart'; // create this screen for the scan flow

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _fabExpanded = false;

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Bills':
        return Icons.receipt_long_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Future<void> _openReceipt(BuildContext context, Expense expense) async {
    final imagePath = expense.imagePath;

    if (imagePath == null || imagePath.isEmpty || !File(imagePath).existsSync()) {
      SnackbarService.showMessage(
        context,
        'No receipt image available for this expense.',
        success: false,
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final firestore = FirestoreService();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo/app_logo.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 10),
            const Text('Expenses'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: firestore.getExpenses(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!;

          if (expenses.isEmpty) {
            return const Center(child: Text("No expenses yet"));
          }

          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final e = expenses[index];

              return ListTile(
                onTap: () => _openReceipt(context, e),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  child: Icon(_categoryIcon(e.category)),
                ),
                title: Text("${e.amount}€ - ${e.category}"),
                subtitle: Text(
                  [
                    // if (e.merchant != null && e.merchant!.isNotEmpty) e.merchant!,
                    if (e.note.isNotEmpty) e.note,
                  ].join(" • "),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    firestore.deleteExpense(user.uid, e.id);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mini options — visible only when expanded
          AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            offset: _fabExpanded ? Offset.zero : const Offset(0, 0.3),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _fabExpanded ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_fabExpanded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _FabOption(
                      icon: Icons.document_scanner_outlined,
                      label: 'Scan Receipt',
                      color: cs.secondaryContainer,
                      onColor: cs.onSecondaryContainer,
                      onTap: () {
                        setState(() => _fabExpanded = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanReceiptScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _FabOption(
                      icon: Icons.edit_outlined,
                      label: 'Add Manually',
                      color: cs.primaryContainer,
                      onColor: cs.onPrimaryContainer,
                      onTap: () {
                        setState(() => _fabExpanded = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // Main FAB
          FloatingActionButton(
            onPressed: () => setState(() => _fabExpanded = !_fabExpanded),
            child: AnimatedRotation(
              turns: _fabExpanded ? 0.125 : 0, // rotates to an ✕ shape
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _FabOption extends StatelessWidget {
  const _FabOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: 12),
          // Mini FAB
          FloatingActionButton.small(
            heroTag: label,
            backgroundColor: color,
            foregroundColor: onColor,
            elevation: 2,
            onPressed: onTap,
            child: Icon(icon),
          ),
        ],
      ),
    );
  }
}