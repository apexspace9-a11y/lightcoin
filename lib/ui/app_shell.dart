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
      DashboardScreen(
        store: widget.store,
        onSave: () => _showSavingSheet(),
        onOpenGoals: () => setState(() => _index = 1),
      ),
      GoalsScreen(
        store: widget.store,
        onDeposit: (goal) => _showSavingSheet(goal: goal),
        onWithdraw: (goal) => _showSavingSheet(goal: goal, withdrawal: true),
      ),
      AnalyticsScreen(store: widget.store),
      TransactionsScreen(
        store: widget.store,
        onSave: () => _showSavingSheet(),
      ),
      SettingsScreen(store: widget.store),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Hôm nay',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings_rounded),
            label: 'Hũ',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department_rounded),
            label: 'Thử thách',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  Future<void> _showSavingSheet({SavingGoal? goal, bool withdrawal = false}) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    var action = withdrawal ? 'withdrawal' : 'saving';
    var selectedGoalId = goal?.id ?? -1;
    var date = DateTime.now();

    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  action == 'saving' ? 'Bỏ tiền vào hũ' : 'Rút khỏi hũ',
                  style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'saving',
                      icon: Icon(Icons.add_rounded),
                      label: Text('Tiết kiệm'),
                    ),
                    ButtonSegment(
                      value: 'withdrawal',
                      icon: Icon(Icons.output_rounded),
                      label: Text('Rút bớt'),
                    ),
                  ],
                  selected: {action},
                  onSelectionChanged: (values) => setSheetState(() => action = values.first),
                ),
                const SizedBox(height: 14),
                AmountField(controller: amount, currency: widget.store.currency),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedGoalId,
                  decoration: const InputDecoration(
                    labelText: 'Hũ nhận tiền',
                    prefixIcon: Icon(Icons.savings_rounded),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: -1,
                      child: Text('Quỹ tự do'),
                    ),
                    ...widget.store.goals.where((item) => item.id != null).map(
                          (item) => DropdownMenuItem<int>(
                            value: item.id!,
                            child: Text(item.name, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                  ],
                  onChanged: (value) {
                    if (value != null) setSheetState(() => selectedGoalId = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    hintText: 'Ví dụ: tiền cà phê hôm nay',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  tileColor: Theme.of(sheetContext).colorScheme.surfaceContainerLow,
                  leading: const Icon(Icons.event_rounded),
                  title: const Text('Ngày ghi nhận'),
                  subtitle: Text(
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: date,
                      firstDate: DateTime(2015),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setSheetState(() => date = picked);
                  },
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    final value = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                    if (value <= 0) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('Nhập số tiền lớn hơn 0.')),
                      );
                      return;
                    }
                    Navigator.pop(sheetContext, true);
                  },
                  icon: Icon(action == 'saving' ? Icons.savings_rounded : Icons.output_rounded),
                  label: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(action == 'saving' ? 'Bỏ vào hũ' : 'Rút tiền'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (accepted == true) {
      final value = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
      final goalId = selectedGoalId == -1 ? null : selectedGoalId;
      if (action == 'saving') {
        await widget.store.deposit(
          goalId: goalId,
          amount: value,
          note: note.text,
          occurredAt: date,
        );
      } else {
        final ok = await widget.store.withdraw(
          goalId: goalId,
          amount: value,
          note: note.text,
          occurredAt: date,
        );
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Số dư trong hũ không đủ cho khoản rút này.')),
          );
        }
      }
    }

    amount.dispose();
    note.dispose();
  }
}
