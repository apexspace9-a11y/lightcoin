import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state/money_store.dart';
import '../widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, required this.store});

  final MoneyStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = store.activeChallenge;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Text(
            'Thử thách',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            'Biến tiết kiệm thành thói quen bằng những mốc đủ nhỏ để theo đến cùng.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              MetricCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Chuỗi hiện tại',
                value: '${store.currentStreak} ngày',
              ),
              const SizedBox(width: 10),
              MetricCard(
                icon: Icons.emoji_events_rounded,
                label: 'Chuỗi tốt nhất',
                value: '${store.bestStreak} ngày',
              ),
              const SizedBox(width: 10),
              MetricCard(
                icon: Icons.savings_rounded,
                label: 'Lần bỏ ống',
                value: '${store.depositCount}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle('Đang tham gia'),
          const SizedBox(height: 10),
          if (active == null)
            Card(
              child: const EmptyState(
                icon: Icons.local_fire_department_outlined,
                title: 'Chưa có thử thách đang chạy',
                subtitle: 'Chọn một thử thách bên dưới. Không cần bắt đầu bằng số tiền lớn.',
              ),
            )
          else
            _ActiveChallengeCard(store: store, challenge: active),
          const SizedBox(height: 24),
          const SectionTitle('Chọn thử thách'),
          const SizedBox(height: 10),
          ...savingsChallenges.map(
            (challenge) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: store.activeChallengeId == challenge.id
                              ? scheme.tertiaryContainer
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          challenge.metric == 'days'
                              ? Icons.calendar_view_week_rounded
                              : Icons.savings_rounded,
                          color: store.activeChallengeId == challenge.id
                              ? scheme.tertiary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(challenge.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(
                              challenge.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (store.activeChallengeId == challenge.id)
                        Icon(Icons.check_circle_rounded, color: scheme.primary)
                      else
                        FilledButton.tonal(
                          onPressed: () => _startChallenge(context, challenge),
                          child: const Text('Bắt đầu'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const SectionTitle('Dấu chân tiết kiệm'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _InsightRow(
                    icon: Icons.calendar_month_rounded,
                    title: 'Ngày có tiết kiệm trong tháng',
                    value: '${store.savedDaysThisMonth} ngày',
                  ),
                  const Divider(height: 26),
                  _InsightRow(
                    icon: Icons.add_card_rounded,
                    title: 'Tổng số lần bỏ tiền vào hũ',
                    value: '${store.depositCount} lần',
                  ),
                  const Divider(height: 26),
                  _InsightRow(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Tổng tiền đang được giữ',
                    value: formatMoney(store.totalSaved, store.currency, compact: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startChallenge(
    BuildContext context,
    SavingsChallengeDefinition challenge,
  ) async {
    if (store.activeChallenge != null && store.activeChallengeId != challenge.id) {
      final replace = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Đổi thử thách?'),
              content: Text('Tiến độ của “${store.activeChallenge!.title}” sẽ dừng và thử thách mới bắt đầu từ hôm nay.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Giữ thử thách cũ')),
                FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Đổi thử thách')),
              ],
            ),
          ) ??
          false;
      if (!replace) return;
    }
    await store.startChallenge(challenge.id);
  }
}

class _ActiveChallengeCard extends StatelessWidget {
  const _ActiveChallengeCard({required this.store, required this.challenge});

  final MoneyStore store;
  final SavingsChallengeDefinition challenge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (store.challengeProgress / challenge.target).clamp(0.0, 1.0).toDouble();
    final count = math.min(store.challengeProgress, challenge.target);
    final unit = challenge.metric == 'days' ? 'ngày' : 'lần';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.tertiary, scheme.tertiary.withValues(alpha: .72)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      store.challengeCompleted ? 'Đã hoàn thành' : '$count/${challenge.target} $unit',
                      style: TextStyle(color: Colors.white.withValues(alpha: .82)),
                    ),
                  ],
                ),
              ),
              if (store.challengeCompleted)
                const Icon(Icons.verified_rounded, color: Colors.white, size: 30),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: .2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 11),
          Text(
            store.challengeCompleted
                ? 'Bạn đã đi hết thử thách này. Tiếp tục bỏ ống để giữ nhịp.'
                : challenge.subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: .88), height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: store.stopChallenge,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: .5)),
            ),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Dừng thử thách'),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      );
}
