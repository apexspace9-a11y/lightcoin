import 'package:flutter/material.dart';

import '../../state/money_store.dart';
import '../widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});

  final MoneyStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Text(
            'Cài đặt',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            'Chỉnh nhịp tiết kiệm theo cách phù hợp với bạn.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Kế hoạch tiết kiệm'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 10, 10, 8),
                  leading: _SettingIcon(icon: Icons.track_changes_rounded, color: scheme.primaryContainer),
                  title: const Text('Mục tiêu mỗi ngày', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    store.dailyTarget > 0
                        ? formatMoney(store.dailyTarget, store.currency)
                        : store.suggestedDailySaving > 0
                            ? 'Tự tính: ${formatMoney(store.suggestedDailySaving, store.currency)}'
                            : 'Tự động theo các hũ',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showDailyTarget(context),
                ),
                const Divider(height: 1, indent: 78),
                SwitchListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
                  secondary: _SettingIcon(icon: Icons.notifications_active_rounded, color: scheme.secondaryContainer),
                  title: const Text('Nhắc tiết kiệm mỗi ngày', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    store.dailyReminder
                        ? '${store.reminderHour.toString().padLeft(2, '0')}:${store.reminderMinute.toString().padLeft(2, '0')}'
                        : 'Đang tắt',
                  ),
                  value: store.dailyReminder,
                  onChanged: (value) => store.setReminder(enabled: value),
                ),
                if (store.dailyReminder) ...[
                  const Divider(height: 1, indent: 78),
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(78, 4, 10, 4),
                    title: const Text('Giờ nhắc'),
                    trailing: Text(
                      '${store.reminderHour.toString().padLeft(2, '0')}:${store.reminderMinute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary),
                    ),
                    onTap: () => _pickReminderTime(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Hiển thị'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SettingIcon(icon: Icons.payments_rounded, color: scheme.tertiaryContainer),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Đơn vị tiền', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      DropdownButton<String>(
                        value: store.currency,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 'VND', child: Text('VND')),
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                          DropdownMenuItem(value: 'KRW', child: Text('KRW')),
                          DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                          DropdownMenuItem(value: 'THB', child: Text('THB')),
                          DropdownMenuItem(value: 'SGD', child: Text('SGD')),
                        ],
                        onChanged: (value) {
                          if (value != null) store.setCurrency(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Giao diện', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'system', icon: Icon(Icons.brightness_auto_rounded), label: Text('Máy')),
                        ButtonSegment(value: 'light', icon: Icon(Icons.light_mode_rounded), label: Text('Sáng')),
                        ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode_rounded), label: Text('Tối')),
                      ],
                      selected: {store.theme},
                      onSelectionChanged: (value) => store.setTheme(value.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Dữ liệu'),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              leading: _SettingIcon(icon: Icons.delete_sweep_rounded, color: scheme.errorContainer),
              title: Text(
                'Xóa toàn bộ dữ liệu tiết kiệm',
                style: TextStyle(fontWeight: FontWeight.w800, color: scheme.error),
              ),
              subtitle: const Text('Xóa hũ, lịch sử, thử thách và mục tiêu ngày.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _confirmClear(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDailyTarget(BuildContext context) async {
    final controller = TextEditingController(
      text: store.dailyTarget > 0 ? store.dailyTarget.toStringAsFixed(store.currency == 'VND' ? 0 : 2) : '',
    );

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mục tiêu mỗi ngày',
              style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              'Đặt một mức cố định hoặc để app tự chia số tiền còn thiếu của các hũ thành nhịp mỗi ngày.',
              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            AmountField(controller: controller, currency: store.currency),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
                if (value <= 0) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(content: Text('Nhập số tiền lớn hơn 0.')),
                  );
                  return;
                }
                Navigator.pop(sheetContext, 'save');
              },
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Dùng mục tiêu này'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.pop(sheetContext, 'auto'),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Để app tự tính'),
            ),
          ],
        ),
      ),
    );

    if (result == 'save') {
      final value = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
      await store.setDailyTarget(value);
    } else if (result == 'auto') {
      await store.setDailyTarget(0);
    }
    controller.dispose();
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: store.reminderHour, minute: store.reminderMinute),
    );
    if (picked != null) {
      await store.setReminder(
        enabled: true,
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final accepted = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xóa toàn bộ dữ liệu?'),
            content: const Text('Các hũ, lịch sử tiết kiệm, thử thách và mục tiêu ngày sẽ bị xóa khỏi thiết bị.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Xóa tất cả')),
            ],
          ),
        ) ??
        false;
    if (accepted) await store.clearEverything();
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Icon(icon),
      );
}
