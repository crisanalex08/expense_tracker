import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/firestore_service.dart';

enum DashboardPeriod { weekly, monthly }

enum DashboardViewMode { table, pieChart }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardPeriod _period = DashboardPeriod.weekly;
  DashboardViewMode _viewMode = DashboardViewMode.table;

  DateTime _startOfWeek(DateTime date) {
    final midnight = DateTime(date.year, date.month, date.day);
    return midnight.subtract(Duration(days: midnight.weekday - 1));
  }

  DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _startForPeriod(DateTime now, DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.weekly:
        return _startOfWeek(now);
      case DashboardPeriod.monthly:
        return _startOfMonth(now);
    }
  }

  String _periodLabel(DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.weekly:
        return 'Weekly';
      case DashboardPeriod.monthly:
        return 'Monthly';
    }
  }

  Map<String, double> _totalsForRange(List<Expense> expenses, DateTime start) {
    final totals = <String, double>{};

    for (final expense in expenses) {
      if (expense.date.isBefore(start)) {
        continue;
      }

      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }

    return Map.fromEntries(
      totals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  List<Color> get _chartColors => const [
        Colors.teal,
        Colors.orange,
        Colors.blue,
        Colors.pink,
        Colors.green,
        Colors.purple,
        Colors.amber,
        Colors.indigo,
      ];

  Color _colorForIndex(int index) => _chartColors[index % _chartColors.length];

  List<PieChartSectionData> _pieSections(Map<String, double> totals) {
    final entries = totals.entries.toList();
    final totalAmount = entries.fold<double>(0, (sum, entry) => sum + entry.value);

    if (totalAmount <= 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey.shade300,
          radius: 70,
          showTitle: false,
        ),
      ];
    }

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final percent = (entry.value / totalAmount) * 100;

      return PieChartSectionData(
        value: entry.value,
        color: _colorForIndex(index),
        radius: 70,
        title: '${percent.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildControls(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_periodLabel(_period)} summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ToggleButtons(
                  isSelected: [
                    _period == DashboardPeriod.weekly,
                    _period == DashboardPeriod.monthly,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _period = index == 0 ? DashboardPeriod.weekly : DashboardPeriod.monthly;
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Weekly'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Monthly'),
                    ),
                  ],
                ),
                ToggleButtons(
                  isSelected: [
                    _viewMode == DashboardViewMode.table,
                    _viewMode == DashboardViewMode.pieChart,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _viewMode = index == 0 ? DashboardViewMode.table : DashboardViewMode.pieChart;
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Table'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Piechart'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, Map<String, double> totals) {
    final entries = totals.entries.toList();
    final totalAmount = entries.fold<double>(0, (sum, entry) => sum + entry.value);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: entries.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No expenses in this period')),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Share')),
                      ],
                      rows: entries.asMap().entries.map((indexedEntry) {
                        final index = indexedEntry.key;
                        final entry = indexedEntry.value;
                        final share = totalAmount == 0 ? 0 : (entry.value / totalAmount) * 100;

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _colorForIndex(index),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(entry.key),
                                ],
                              ),
                            ),
                            DataCell(Text('${entry.value.toStringAsFixed(2)} €')),
                            DataCell(Text('${share.toStringAsFixed(0)}%')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total: ${totalAmount.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, Map<String, double> totals) {
    final entries = totals.entries.toList();
    final totalAmount = entries.fold<double>(0, (sum, entry) => sum + entry.value);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: entries.isEmpty
            ? const SizedBox(
                height: 220,
                child: Center(child: Text('No expenses in this period')),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 36,
                        sections: _pieSections(totals),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total: ${totalAmount.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...entries.asMap().entries.map((indexedEntry) {
                    final index = indexedEntry.key;
                    final entry = indexedEntry.value;
                    final share = totalAmount == 0 ? 0 : (entry.value / totalAmount) * 100;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _colorForIndex(index),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(entry.key)),
                          Text('${entry.value.toStringAsFixed(2)} €'),
                          const SizedBox(width: 10),
                          Text('${share.toStringAsFixed(0)}%'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final firestore = FirestoreService();
    final now = DateTime.now();

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
            const Text('Dashboard'),
          ],
        ),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: firestore.getExpenses(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!;
          final selectedTotals = _totalsForRange(expenses, _startForPeriod(now, _period));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildControls(context),
              const SizedBox(height: 16),
              if (_viewMode == DashboardViewMode.table)
                _buildDataTable(context, selectedTotals)
              else
                _buildPieChart(context, selectedTotals),
            ],
          );
        },
      ),
    );
  }
}
