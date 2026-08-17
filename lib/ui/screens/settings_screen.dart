import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state/money_store.dart';
import '../widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});
  final MoneyStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cài đặt', style: TextStyle(fontWeight: FontWeight.w900))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            const SectionTitle('Kế hoạch chi tiêu'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded),
                    title: const Text('Ngân sách tháng'),
                    subtitle: Text(store.monthlyBudget <= 0 ? 'Chưa đặt' : formatMoney(store.monthlyBudget, store.currency)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _editMonthlyBudget(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.category_rounded),
                    title: const Text('Ngân sách theo danh mục'),
                    subtitle: Text('${store.categoryBudgets.length} danh mục đang áp dụng'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _editCategoryBudgets(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Nhắc nhở'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_rounded),
                    title: const Text('Nhắc ghi chép mỗi ngày'),
                    subtitle: Text('Lúc ${_timeText(store.reminderHour, store.reminderMinute)}'),
                    value: store.dailyReminder,
                    onChanged: (value) => store.setReminder(enabled: value),
                  ),
                  if (store.dailyReminder)
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('Giờ nhắc'),
                      trailing: Text(_timeText(store.reminderHour, store.reminderMinute), style: const TextStyle(fontWeight: FontWeight.w800)),
                      onTap: () => _pickReminderTime(context),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Hiển thị'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.currency_exchange_rounded),
                    title: const Text('Đơn vị tiền'),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: store.currency,
                        items: const ['VND', 'USD', 'EUR', 'JPY', 'KRW', 'CNY', 'THB', 'SGD']
                            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) store.setCurrency(value);
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.palette_rounded),
                    title: const Text('Giao diện'),
                    subtitle: const Text('Sáng, tối hoặc theo hệ thống'),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'system', icon: Icon(Icons.brightness_auto_rounded), label: Text('Tự động')),
                        ButtonSegment(value: 'light', icon: Icon(Icons.light_mode_rounded), label: Text('Sáng')),
                        ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode_rounded), label: Text('Tối')),
                      ],
                      selected: {store.theme},
                      onSelectionChanged: (values) => store.setTheme(values.first),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Dữ liệu'),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Icon(Icons.delete_forever_rounded, color: Theme.of(context).colorScheme.error),
                title: Text('Xóa toàn bộ dữ liệu', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w800)),
                subtitle: const Text('Xóa giao dịch, mục tiêu và ngân sách'),
                onTap: () => _clearData(context),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: Text('Tiết Kiệm • 1.0.0', style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      );

  String _timeText(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  Future<void> _editMonthlyBudget(BuildContext context) async {
    final controller = TextEditingController(text: store.monthlyBudget > 0 ? store.monthlyBudget.toStringAsFixed(0) : '');
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ngân sách tháng'),
        content: AmountField(controller: controller, currency: store.currency),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, 0.0), child: const Text('Bỏ giới hạn')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
              Navigator.pop(context, value);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) await store.setMonthlyBudget(result);
  }

  Future<void> _editCategoryBudgets(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .78,
        maxChildSize: .92,
        minChildSize: .45,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: [
            Text('Ngân sách theo danh mục', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Đặt giới hạn riêng cho từng nhóm chi tiêu quan trọng.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            ...expenseCategories.map((category) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(category, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text((store.categoryBudgets[category] ?? 0) <= 0 ? 'Không giới hạn' : formatMoney(store.categoryBudgets[category]!, store.currency)),
                  trailing: const Icon(Icons.edit_rounded),
                  onTap: () => _editOneCategory(context, category),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _editOneCategory(BuildContext context, String category) async {
    final current = store.categoryBudgets[category] ?? 0;
    final controller = TextEditingController(text: current > 0 ? current.toStringAsFixed(0) : '');
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category),
        content: AmountField(controller: controller, currency: store.currency),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 0.0), child: const Text('Bỏ giới hạn')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text.replaceAll(',', '.')) ?? 0),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await store.setCategoryBudget(category, value);
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: store.reminderHour, minute: store.reminderMinute),
    );
    if (picked != null) {
      await store.setReminder(enabled: true, hour: picked.hour, minute: picked.minute);
    }
  }

  Future<void> _clearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa toàn bộ dữ liệu?'),
        content: const Text('Mọi giao dịch, mục tiêu và ngân sách sẽ bị xóa vĩnh viễn trên thiết bị này.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa tất cả')),
        ],
      ),
    );
    if (confirmed == true) await store.clearEverything();
  }
}
