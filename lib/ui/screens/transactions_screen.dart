import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models.dart';
import '../../state/money_store.dart';
import '../widgets.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.store, required this.onAdd});
  final MoneyStore store;
  final VoidCallback onAdd;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _search = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final items = widget.store.transactions.where((item) {
      final matchesType = _filter == 'all' || item.type == _filter;
      final matchesSearch = q.isEmpty || item.category.toLowerCase().contains(q) || item.note.toLowerCase().contains(q);
      return matchesType && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao dịch', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton.filledTonal(onPressed: widget.onAdd, icon: const Icon(Icons.add_rounded))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Tìm danh mục hoặc ghi chú',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'Tất cả', value: 'all', selected: _filter, onTap: _setFilter),
                _FilterChip(label: 'Khoản chi', value: 'expense', selected: _filter, onTap: _setFilter),
                _FilterChip(label: 'Khoản thu', value: 'income', selected: _filter, onTap: _setFilter),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.manage_search_rounded,
                    title: 'Không có giao dịch phù hợp',
                    subtitle: 'Thử đổi bộ lọc hoặc thêm một giao dịch mới.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];
                      final showDate = index == 0 || !_sameDay(items[index - 1].occurredAt, item.occurredAt);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
                              child: Text(
                                _dateLabel(item.occurredAt),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                              child: TransactionTile(
                                item: item,
                                store: widget.store,
                                onDelete: () => _delete(item),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _setFilter(String value) => setState(() => _filter = value);

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    if (_sameDay(date, now)) return 'Hôm nay';
    final yesterday = now.subtract(const Duration(days: 1));
    if (_sameDay(date, yesterday)) return 'Hôm qua';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _delete(MoneyTransaction item) async {
    if (item.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: const Text('Khoản này sẽ bị xóa khỏi thống kê và không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Giữ lại')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed == true) await widget.store.deleteTransaction(item.id!);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap});
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected == value,
          onSelected: (_) => onTap(value),
        ),
      );
}
