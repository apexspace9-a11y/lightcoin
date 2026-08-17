import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../state/money_store.dart';
import '../widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.store,
    required this.onSave,
    required this.onOpenGoals,
  });

  final MoneyStore store;
  final VoidCallback onSave;
  final VoidCallback onOpenGoals;

  String _todayLabel() {
    final now = DateTime.now();
    const weekdays = ['Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật'];
    return '${weekdays[now.weekday - 1]}, ${now.day}/${now.month}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final challenge = store.activeChallenge;

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
                      'Tiết kiệm',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.8,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _todayLabel(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded, size: 19, color: scheme.primary),
                    const SizedBox(width: 5),
                    Text(
                      '${store.currentStreak} ngày',
                      style: TextStyle(fontWeight: FontWeight.w900, color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, const Color(0xFF0D7A3B)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: .22),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ĐÃ TIẾT KIỆM',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .78),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMoney(store.totalSaved, store.currency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (store.goals.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tiến độ tất cả hũ',
                          style: TextStyle(color: Colors.white.withValues(alpha: .82), fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${(store.overallGoalProgress * 100).round()}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: store.overallGoalProgress),
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 9,
                        backgroundColor: Colors.white.withValues(alpha: .2),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                ] else
                  Text(
                    'Mỗi khoản nhỏ đều là một bước tiến. Tạo hũ đầu tiên khi bạn đã có mục tiêu cụ thể.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .86),
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Bỏ tiền vào hũ', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              MetricCard(
                icon: Icons.today_rounded,
                label: 'Hôm nay',
                value: formatMoney(math.max(0, store.savedToday).toDouble(), store.currency, compact: true),
              ),
              const SizedBox(width: 10),
              MetricCard(
                icon: Icons.calendar_month_rounded,
                label: 'Tháng này',
                value: formatMoney(math.max(0, store.savedThisMonth).toDouble(), store.currency, compact: true),
              ),
              const SizedBox(width: 10),
              MetricCard(
                icon: Icons.event_available_rounded,
                label: 'Ngày đã lưu',
                value: '${store.savedDaysThisMonth}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle('Nhịp tiết kiệm hôm nay'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.track_changes_rounded, color: scheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.effectiveDailyTarget > 0
                                  ? 'Mục tiêu ${formatMoney(store.effectiveDailyTarget, store.currency)}'
                                  : 'Chưa có mục tiêu ngày',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              store.dailyTarget > 0
                                  ? 'Mục tiêu bạn đã đặt'
                                  : store.suggestedDailySaving > 0
                                      ? 'Tự tính từ các hũ đang theo đuổi'
                                      : 'Tạo hũ hoặc đặt mục tiêu trong Cài đặt',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (store.effectiveDailyTarget > 0)
                        Text(
                          '${(store.todayProgress * 100).round()}%',
                          style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary),
                        ),
                    ],
                  ),
                  if (store.effectiveDailyTarget > 0) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(value: store.todayProgress, minHeight: 10),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      store.savedToday >= store.effectiveDailyTarget
                          ? 'Đã đạt nhịp hôm nay. Phần còn lại là tiền thưởng cho tương lai.'
                          : 'Còn ${formatMoney(store.effectiveDailyTarget - math.max(0, store.savedToday), store.currency)} để đạt nhịp hôm nay.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('7 ngày gần đây'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
              child: _WeekBars(
                values: store.last7DaySavings,
                labels: store.last7DayLabels,
                currency: store.currency,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle(
            'Hũ đang theo đuổi',
            trailing: TextButton(onPressed: onOpenGoals, child: const Text('Xem tất cả')),
          ),
          const SizedBox(height: 10),
          if (store.goals.isEmpty)
            Card(
              child: EmptyState(
                icon: Icons.savings_outlined,
                title: 'Chưa có hũ tiết kiệm',
                subtitle: 'Tạo một hũ cho điều bạn thật sự muốn đạt tới.',
                action: FilledButton.tonalIcon(
                  onPressed: onOpenGoals,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tạo hũ đầu tiên'),
                ),
              ),
            )
          else
            ...store.goals.take(3).map(
                  (goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(17),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: goal.completed
                                        ? scheme.primaryContainer
                                        : scheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    goal.completed ? Icons.check_rounded : Icons.savings_rounded,
                                    color: goal.completed ? scheme.primary : scheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${formatMoney(goal.saved, store.currency)} / ${formatMoney(goal.target, store.currency)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Text('${(goal.progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 13),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(value: goal.progress, minHeight: 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          if (challenge != null) ...[
            const SizedBox(height: 14),
            const SectionTitle('Thử thách đang chạy'),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(Icons.local_fire_department_rounded, color: scheme.tertiary),
                ),
                title: Text(challenge.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text('${math.min(store.challengeProgress, challenge.target)}/${challenge.target} ${challenge.metric == 'days' ? 'ngày' : 'lần'}'),
                ),
                trailing: store.challengeCompleted
                    ? Icon(Icons.verified_rounded, color: scheme.primary)
                    : CircularProgressIndicator(
                        value: (store.challengeProgress / challenge.target).clamp(0.0, 1.0).toDouble(),
                        strokeWidth: 5,
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({
    required this.values,
    required this.labels,
    required this.currency,
  });

  final List<double> values;
  final List<String> labels;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = values.fold<double>(0, (max, value) => math.max(max, value));
    return SizedBox(
      height: 128,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final ratio = maxValue <= 0 ? 0.0 : values[index] / maxValue;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  values[index] <= 0 ? '' : formatMoney(values[index], currency, compact: true),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  width: 16,
                  height: 8 + 65 * ratio,
                  decoration: BoxDecoration(
                    color: ratio > 0 ? scheme.primary : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 7),
                Text(labels[index], style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          );
        }),
      ),
    );
  }
}
