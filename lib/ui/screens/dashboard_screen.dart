import 'package:flutter/material.dart';

import '../../state/money_store.dart';
import '../widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.store, required this.onAdd});
  final MoneyStore store;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Chào buổi sáng'
        : now.hour < 18
            ? 'Chào buổi chiều'
            : 'Chào buổi tối';
    final recent = store.transactions.take(4).toList();
    final categories = store.currentMonthExpensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          floating: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Theme.of(context).textTheme.bodyMedium),
              const Text('Tài chính của bạn'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton.filledTonal(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Thêm giao dịch',
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          sliver: SliverList.list(
            children: [
              _BalanceCard(store: store),
              const SizedBox(height: 16),
              _BudgetCard(store: store),
              const SizedBox(height: 26),
              SectionTitle(
                'Chi tiêu theo danh mục',
                trailing: Text('${categories.length} nhóm'),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: categories.isEmpty
                      ? const EmptyState(
                          icon: Icons.donut_large_rounded,
                          title: 'Chưa có chi tiêu tháng này',
                          subtitle: 'Thêm giao dịch để thấy tiền đang chảy đi đâu.',
                        )
                      : Column(
                          children: categories.take(5).map((entry) {
                            final maxValue = categories.first.value;
                            final progress = maxValue <= 0 ? 0.0 : entry.value / maxValue;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700))),
                                      Text(formatMoney(entry.value, store.currency, compact: true)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: LinearProgressIndicator(value: progress, minHeight: 8),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 26),
              const SectionTitle('Giao dịch gần đây'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: recent.isEmpty
                      ? const EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'Chưa có giao dịch',
                          subtitle: 'Bắt đầu ghi lại một khoản thu hoặc chi. Không cần hoàn hảo, chỉ cần đều.',
                        )
                      : Column(
                          children: recent.map((item) => TransactionTile(item: item, store: store)).toList(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.store});
  final MoneyStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primary.withValues(alpha: .78)],
        ),
        boxShadow: [
          BoxShadow(color: scheme.primary.withValues(alpha: .18), blurRadius: 28, offset: const Offset(0, 12)),
        ],
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: scheme.onPrimary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số dư hiện tại', style: TextStyle(color: scheme.onPrimary.withValues(alpha: .8))),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: store.balance),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => Text(
                formatMoney(value, store.currency),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -.6),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: _MiniStat(icon: Icons.south_west_rounded, label: 'Thu tháng này', value: formatMoney(store.monthIncome, store.currency, compact: true))),
                const SizedBox(width: 12),
                Expanded(child: _MiniStat(icon: Icons.north_east_rounded, label: 'Chi tháng này', value: formatMoney(store.monthExpense, store.currency, compact: true))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.store});
  final MoneyStore store;

  @override
  Widget build(BuildContext context) {
    final hasBudget = store.monthlyBudget > 0;
    final progress = store.budgetProgress.clamp(0.0, 1.0).toDouble();
    final isOver = store.remainingBudget < 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: hasBudget
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Ngân sách tháng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
                      Text('${(store.budgetProgress * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w900, color: isOver ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 550),
                      builder: (_, value, __) => LinearProgressIndicator(value: value, minHeight: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _BudgetMetric(
                          label: isOver ? 'Vượt ngân sách' : 'Còn lại',
                          value: formatMoney(store.remainingBudget.abs(), store.currency, compact: true),
                        ),
                      ),
                      Expanded(
                        child: _BudgetMetric(
                          label: 'Chi an toàn/ngày',
                          value: formatMoney(store.safeDailySpend, store.currency, compact: true),
                        ),
                      ),
                      Expanded(
                        child: _BudgetMetric(
                          label: 'Tỷ lệ tiết kiệm',
                          value: '${store.savingsRate.isFinite ? store.savingsRate.round() : 0}%',
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : const EmptyState(
                icon: Icons.speed_rounded,
                title: 'Chưa đặt ngân sách tháng',
                subtitle: 'Đặt một giới hạn để ứng dụng tính mức chi an toàn mỗi ngày và cảnh báo khi sắp vượt.',
              ),
      ),
    );
  }
}

class _BudgetMetric extends StatelessWidget {
  const _BudgetMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
        ],
      );
}
