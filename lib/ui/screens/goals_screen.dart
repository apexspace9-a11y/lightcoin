import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state/money_store.dart';
import '../widgets.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({
    super.key,
    required this.store,
    required this.onDeposit,
    required this.onWithdraw,
  });

  final MoneyStore store;
  final ValueChanged<SavingGoal> onDeposit;
  final ValueChanged<SavingGoal> onWithdraw;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hũ tiết kiệm',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.8,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Chia mục tiêu lớn thành những hũ dễ chạm tới.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showCreateGoal(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tạo hũ'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TỔNG TIẾN ĐỘ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatMoney(store.goalSavedTotal, store.currency),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -.8,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        store.totalGoalTarget > 0
                            ? '${(store.overallGoalProgress * 100).round()}%'
                            : '0%',
                        style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    store.totalGoalTarget > 0
                        ? 'trên ${formatMoney(store.totalGoalTarget, store.currency)} mục tiêu'
                        : 'Tạo hũ để bắt đầu kế hoạch tiết kiệm.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: store.overallGoalProgress,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (store.unassignedSaved > 0) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.account_balance_wallet_rounded, color: scheme.secondary),
                ),
                title: const Text('Quỹ chưa gắn mục tiêu', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Khoản tiết kiệm đang nằm ngoài các hũ hiện tại.'),
                trailing: Text(
                  formatMoney(store.unassignedSaved, store.currency, compact: true),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const SectionTitle('Các hũ của bạn'),
          const SizedBox(height: 10),
          if (store.goals.isEmpty)
            Card(
              child: EmptyState(
                icon: Icons.savings_outlined,
                title: 'Tạo một lý do để tiết kiệm',
                subtitle: 'Điện thoại mới, quỹ khẩn cấp, chuyến đi hay bất cứ thứ gì khiến bạn muốn bắt đầu.',
                action: FilledButton.icon(
                  onPressed: () => _showCreateGoal(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tạo hũ đầu tiên'),
                ),
              ),
            )
          else
            ...store.goals.map((goal) => _GoalCard(
                  goal: goal,
                  store: store,
                  onDeposit: () => onDeposit(goal),
                  onWithdraw: () => onWithdraw(goal),
                  onDelete: () => _confirmDelete(context, goal),
                )),
        ],
      ),
    );
  }

  Future<void> _showCreateGoal(BuildContext context) async {
    final name = TextEditingController();
    final target = TextEditingController();
    DateTime? deadline;

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
                  'Tạo hũ mới',
                  style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Tên hũ',
                    hintText: 'Ví dụ: Quỹ khẩn cấp',
                    prefixIcon: Icon(Icons.savings_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: target,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Số tiền muốn đạt',
                    suffixText: store.currency,
                    prefixIcon: const Icon(Icons.flag_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  tileColor: Theme.of(sheetContext).colorScheme.surfaceContainerLow,
                  leading: const Icon(Icons.event_available_rounded),
                  title: const Text('Hạn hoàn thành'),
                  subtitle: Text(
                    deadline == null
                        ? 'Không bắt buộc'
                        : '${deadline!.day.toString().padLeft(2, '0')}/${deadline!.month.toString().padLeft(2, '0')}/${deadline!.year}',
                  ),
                  trailing: deadline == null
                      ? const Icon(Icons.chevron_right_rounded)
                      : IconButton(
                          onPressed: () => setSheetState(() => deadline = null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: deadline ?? now.add(const Duration(days: 30)),
                      firstDate: now,
                      lastDate: DateTime(now.year + 10, 12, 31),
                    );
                    if (picked != null) setSheetState(() => deadline = picked);
                  },
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    final value = double.tryParse(target.text.replaceAll(',', '.')) ?? 0;
                    if (name.text.trim().isEmpty || value <= 0) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('Nhập tên hũ và số tiền mục tiêu hợp lệ.')),
                      );
                      return;
                    }
                    Navigator.pop(sheetContext, true);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Tạo hũ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (accepted == true) {
      final value = double.tryParse(target.text.replaceAll(',', '.')) ?? 0;
      await store.addGoal(name: name.text, target: value, deadline: deadline);
    }
    name.dispose();
    target.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, SavingGoal goal) async {
    final accepted = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xóa hũ?'),
            content: Text('Hũ “${goal.name}” sẽ bị xóa. Lịch sử các khoản đã ghi vẫn được giữ.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Giữ lại')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Xóa hũ')),
            ],
          ),
        ) ??
        false;
    if (accepted && goal.id != null) await store.deleteGoal(goal.id!);
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.store,
    required this.onDeposit,
    required this.onWithdraw,
    required this.onDelete,
  });

  final SavingGoal goal;
  final MoneyStore store;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daily = store.dailyNeededForGoal(goal);
    final deadline = goal.deadline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: goal.completed ? scheme.primaryContainer : scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      goal.completed ? Icons.verified_rounded : Icons.savings_rounded,
                      color: goal.completed ? scheme.primary : scheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          goal.completed
                              ? 'Đã đạt mục tiêu'
                              : 'Còn ${formatMoney(goal.remaining, store.currency)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Tùy chọn',
                    onSelected: (_) => onDelete(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('Xóa hũ')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatMoney(goal.saved, store.currency),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '${(goal.progress * 100).round()}%',
                    style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Mục tiêu ${formatMoney(goal.target, store.currency)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: goal.progress, minHeight: 10),
              ),
              if (!goal.completed) ...[
                const SizedBox(height: 13),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_graph_rounded, size: 19, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nhịp gợi ý: ${formatMoney(daily, store.currency)}/ngày',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (deadline != null)
                        Text(
                          '${deadline.day}/${deadline.month}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onDeposit,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nạp thêm'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: goal.saved > 0 ? onWithdraw : null,
                      icon: const Icon(Icons.output_rounded),
                      label: const Text('Rút bớt'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
