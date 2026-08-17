import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../state/money_store.dart';

String formatMoney(double value, String currency, {bool compact = false}) {
  final locale = currency == 'VND' ? 'vi_VN' : 'en_US';
  final digits = currency == 'VND' ? 0 : 2;
  if (compact) {
    return NumberFormat.compactCurrency(
      locale: locale,
      symbol: currency == 'VND' ? '₫' : '$currency ',
      decimalDigits: currency == 'VND' ? 0 : 1,
    ).format(value);
  }
  return NumberFormat.currency(
    locale: locale,
    symbol: currency == 'VND' ? '₫' : '$currency ',
    decimalDigits: digits,
  ).format(value);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(icon, size: 36, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      );
}

class SavingsRecordTile extends StatelessWidget {
  const SavingsRecordTile({
    super.key,
    required this.item,
    required this.store,
    this.onDelete,
  });

  final MoneyTransaction item;
  final MoneyStore store;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final deposit = item.isDeposit;
    final scheme = Theme.of(context).colorScheme;
    final accent = deposit ? scheme.primary : scheme.tertiary;
    final title = item.goalName;
    final date = DateFormat('dd/MM/yyyy').format(item.occurredAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(22),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              deposit ? Icons.savings_rounded : Icons.output_rounded,
              color: accent,
            ),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
            item.note.isEmpty ? date : '${item.note} • $date',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${deposit ? '+' : '-'}${formatMoney(item.amount, store.currency)}',
                style: TextStyle(fontWeight: FontWeight.w900, color: accent),
              ),
              if (onDelete != null)
                PopupMenuButton<String>(
                  tooltip: 'Tùy chọn',
                  onSelected: (_) => onDelete?.call(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Xóa khỏi lịch sử')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AmountField extends StatelessWidget {
  const AmountField({super.key, required this.controller, required this.currency});
  final TextEditingController controller;
  final String currency;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        decoration: InputDecoration(
          labelText: 'Số tiền',
          suffixText: currency,
          prefixIcon: const Icon(Icons.payments_rounded),
        ),
      );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
}
