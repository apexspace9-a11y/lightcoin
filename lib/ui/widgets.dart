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
                    fontWeight: FontWeight.w800,
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
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 34),
              ),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.item,
    required this.store,
    this.onDelete,
  });

  final MoneyTransaction item;
  final MoneyStore store;
  final VoidCallback? onDelete;

  IconData _iconFor(String category) => switch (category) {
        'Ăn uống' => Icons.restaurant_rounded,
        'Di chuyển' => Icons.directions_car_filled_rounded,
        'Mua sắm' => Icons.shopping_bag_rounded,
        'Hóa đơn' => Icons.receipt_long_rounded,
        'Nhà ở' => Icons.home_rounded,
        'Sức khỏe' => Icons.favorite_rounded,
        'Giải trí' => Icons.movie_rounded,
        'Giáo dục' => Icons.school_rounded,
        'Gia đình' => Icons.family_restroom_rounded,
        'Lương' => Icons.payments_rounded,
        'Thưởng' => Icons.workspace_premium_rounded,
        'Kinh doanh' => Icons.storefront_rounded,
        'Đầu tư' => Icons.trending_up_rounded,
        _ => Icons.wallet_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final positive = item.isIncome;
    final color = positive ? const Color(0xFF16A34A) : Theme.of(context).colorScheme.error;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(_iconFor(item.category), color: color),
      ),
      title: Text(item.category, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        item.note.isEmpty
            ? DateFormat('dd/MM/yyyy').format(item.occurredAt)
            : '${item.note} • ${DateFormat('dd/MM').format(item.occurredAt)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${positive ? '+' : '-'}${formatMoney(item.amount, store.currency)}',
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          if (onDelete != null)
            PopupMenuButton<String>(
              onSelected: (_) => onDelete?.call(),
              itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Xóa'))],
            ),
        ],
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
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          labelText: 'Số tiền',
          suffixText: currency,
          prefixIcon: const Icon(Icons.payments_rounded),
        ),
      );
}
