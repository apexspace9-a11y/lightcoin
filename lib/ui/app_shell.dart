import 'package:flutter/material.dart';

import '../models.dart';
import '../state/money_store.dart';
import 'screens/analytics_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/transactions_screen.dart';
import 'widgets.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final MoneyStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(store: widget.store, onAdd: _showAddTransaction),
      TransactionsScreen(store: widget.store, onAdd: _showAddTransaction),
      AnalyticsScreen(store: widget.store),
      GoalsScreen(store: widget.store),
      SettingsScreen(store: widget.store),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Tổng quan'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Giao dịch'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Phân tích'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag_rounded), label: 'Mục tiêu'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Cài đặt'),
        ],
      ),
    );
  }

  Future<void> _showAddTransaction() async {
    final amount = TextEditingController();
    final note = TextEditingController();
    var type = 'expense';
    var category = expenseCategories.first;
    var date = DateTime.now();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final categories = type == 'expense' ? expenseCategories : incomeCategories;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Thêm giao dịch', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', icon: Icon(Icons.north_east_rounded), label: Text('Khoản chi')),
                      ButtonSegment(value: 'income', icon: Icon(Icons.south_west_rounded), label: Text('Khoản thu')),
                    ],
                    selected: {type},
                    onSelectionChanged: (values) => setSheetState(() {
                      type = values.first;
                      category = type == 'expense' ? expenseCategories.first : incomeCategories.first;
                    }),
                  ),
                  const SizedBox(height: 14),
                  AmountField(controller: amount, currency: widget.store.currency),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Danh mục', prefixIcon: Icon(Icons.category_rounded)),
                    items: categories.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                    onChanged: (value) {
                      if (value != null) setSheetState(() => category = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Ghi chú', prefixIcon: Icon(Icons.notes_rounded)),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
                    leading: const Icon(Icons.event_rounded),
                    title: const Text('Ngày giao dịch'),
                    subtitle: Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2015),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setSheetState(() => date = picked);
                    },
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () {
                      final value = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                      if (value <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập số tiền lớn hơn 0.')));
                        return;
                      }
                      Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Padding(padding: EdgeInsets.all(14), child: Text('Lưu giao dịch')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (saved == true) {
      final value = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
      await widget.store.addTransaction(
        type: type,
        amount: value,
        category: category,
        note: note.text,
        occurredAt: date,
      );
    }
    amount.dispose();
    note.dispose();
  }
}
