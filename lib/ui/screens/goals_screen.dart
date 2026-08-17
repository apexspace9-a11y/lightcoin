import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models.dart';
import '../../state/money_store.dart';
import '../widgets.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key, required this.store});
  final MoneyStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Mục tiêu', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [IconButton.filledTonal(onPressed: () => _showAddGoal(context), icon: const Icon(Icons.add_rounded))],
        ),
        body: store.goals.isEmpty
            ? const EmptyState(
                icon: Icons.flag_rounded,
                title: 'Chưa có mục tiêu tiết kiệm',
                subtitle: 'Tạo một mục tiêu cụ thể để theo dõi tiến độ và duy trì kế hoạch tiết kiệm.',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                itemCount: store.goals.length,
                itemBuilder: (_, index) => _GoalCard(
                  goal: store.goals[index],
                  store: store,
                  onAdd: () => _showContribution(context, store.goals[index]),
                  onDelete: () => _delete(context, store.goals[index]),
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddGoal(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Mục tiêu mới'),
        ),
      );

  Future<void> _showAddGoal(BuildContext context) async {
    final name = TextEditingController();
    final target = TextEditingController();
    DateTime? deadline;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Mục tiêu tiết kiệm', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 18),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên mục tiêu', prefixIcon: Icon(Icons.flag_rounded))),
              const SizedBox(height: 12),
              AmountField(controller: target, currency: store.currency),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
                leading: const Icon(Icons.event_rounded),
                title: const Text('Hạn hoàn thành'),
                subtitle: Text(deadline == null ? 'Không bắt buộc' : DateFormat('dd/MM/yyyy').format(deadline!)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDate: deadline ?? DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setSheetState(() => deadline = picked);
                },
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(target.text.replaceAll(',', '.')) ?? 0;
                  if (name.text.trim().isEmpty || amount <= 0) return;
                  Navigator.pop(context, true);
                },
                child: const Padding(padding: EdgeInsets.all(14), child: Text('Tạo mục tiêu')),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == true) {
      final amount = double.tryParse(target.text.replaceAll(',', '.')) ?? 0;
      await store.addGoal(name: name.text, target: amount, deadline: deadline);
    }
    name.dispose();
    target.dispose();
  }

  Future<void> _showContribution(BuildContext context, SavingGoal goal) async {
    if (goal.id == null) return;
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm tiền vào “${goal.name}”'),
        content: AmountField(controller: controller, currency: store.currency),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
              if (parsed > 0) Navigator.pop(context, parsed);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount != null) await store.addToGoal(goal.id!, amount);
  }

  Future<void> _delete(BuildContext context, SavingGoal goal) async {
    if (goal.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa mục tiêu?'),
        content: Text('“${goal.name}” sẽ bị xóa. Giao dịch của bạn không bị ảnh hưởng.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Giữ lại')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true) await store.deleteGoal(goal.id!);
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.store, required this.onAdd, required this.onDelete});
  final SavingGoal goal;
  final MoneyStore store;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
                    child: Icon(goal.completed ? Icons.verified_rounded : Icons.flag_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(goal.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                  PopupMenuButton<String>(
                    onSelected: (_) => onDelete(),
                    itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Xóa mục tiêu'))],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Text(formatMoney(goal.saved, store.currency), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
                  Text('/ ${formatMoney(goal.target, store.currency)}'),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: LinearProgressIndicator(value: goal.progress, minHeight: 11),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('${(goal.progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (goal.deadline != null) ...[
                    const Spacer(),
                    Icon(Icons.event_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd/MM/yyyy').format(goal.deadline!), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(goal.completed ? 'Góp thêm' : 'Thêm tiền'),
                ),
              ),
            ],
          ),
        ),
      );
}
