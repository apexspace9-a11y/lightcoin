import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../state/money_store.dart';
import '../widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, required this.store});
  final MoneyStore store;

  @override
  Widget build(BuildContext context) {
    final byCategory = store.currentMonthExpensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = byCategory.fold<double>(0, (sum, e) => sum + e.value);
    final nets = store.lastSixMonthNet;
    final labels = store.lastSixMonthLabels;

    return Scaffold(
      appBar: AppBar(title: const Text('Phân tích', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Row(
            children: [
              Expanded(child: _MetricCard(label: 'Thu tháng', value: formatMoney(store.monthIncome, store.currency, compact: true), icon: Icons.south_west_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(label: 'Chi tháng', value: formatMoney(store.monthExpense, store.currency, compact: true), icon: Icons.north_east_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(label: 'Tiết kiệm', value: '${store.savingsRate.round()}%', icon: Icons.savings_rounded)),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle('Dòng tiền 6 tháng'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
              child: SizedBox(
                height: 190,
                child: _BarChart(values: nets, labels: labels),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Cơ cấu chi tháng này'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: byCategory.isEmpty
                  ? const EmptyState(
                      icon: Icons.pie_chart_rounded,
                      title: 'Chưa đủ dữ liệu',
                      subtitle: 'Ghi vài khoản chi để thấy tỷ trọng từng nhóm.',
                    )
                  : Column(
                      children: byCategory.map((entry) {
                        final ratio = total <= 0 ? 0.0 : entry.value / total;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 52,
                                height: 52,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(value: ratio, strokeWidth: 6, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest),
                                    Center(child: Text('${(ratio * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 3),
                                    Text(formatMoney(entry.value, store.currency)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values, required this.labels});
  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxAbs = values.fold<double>(1.0, (m, v) => math.max(m, v.abs()).toDouble());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (index) {
        final value = values[index];
        final height = 24 + (value.abs() / maxAbs) * 120;
        final positive = value >= 0;
        final color = positive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error;
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: height),
                    duration: Duration(milliseconds: 350 + index * 60),
                    curve: Curves.easeOutCubic,
                    builder: (_, h, __) => Container(
                      width: 24,
                      height: h,
                      decoration: BoxDecoration(color: color.withValues(alpha: .82), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(labels[index], style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        );
      }),
    );
  }
}
