import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state/money_store.dart';
import '../widgets.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.store,
    required this.onSave,
  });

  final MoneyStore store;
  final VoidCallback onSave;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'all';
  String _query = '';

  List<MoneyTransaction> get _items {
    final query = _query.trim().toLowerCase();
    return widget.store.transactions.where((item) {
      if (_filter != 'all' && item.type != _filter) return false;
      if (query.isEmpty) return true;
      return item.goalName.toLowerCase().contains(query) || item.note.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = _items;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lịch sử tiết kiệm',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -.8,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.store.transactions.length} lần thay đổi số tiền trong hũ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: widget.onSave,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Bỏ ống'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo hũ hoặc ghi chú',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('Tất cả')),
                      ButtonSegment(value: 'saving', icon: Icon(Icons.add_rounded), label: Text('Bỏ vào')),
                      ButtonSegment(value: 'withdrawal', icon: Icon(Icons.output_rounded), label: Text('Rút ra')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (value) => setState(() => _filter = value.first),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.history_rounded,
                    title: widget.store.transactions.isEmpty ? 'Chưa có khoản tiết kiệm nào' : 'Không tìm thấy kết quả',
                    subtitle: widget.store.transactions.isEmpty
                        ? 'Khoản đầu tiên có thể rất nhỏ. Điều quan trọng là bắt đầu.'
                        : 'Thử đổi bộ lọc hoặc từ khóa tìm kiếm.',
                    action: widget.store.transactions.isEmpty
                        ? FilledButton.icon(
                            onPressed: widget.onSave,
                            icon: const Icon(Icons.savings_rounded),
                            label: const Text('Bỏ tiền vào hũ'),
                          )
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return SavingsRecordTile(
                        item: item,
                        store: widget.store,
                        onDelete: item.id == null ? null : () => _confirmDelete(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(MoneyTransaction item) async {
    final accepted = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xóa bản ghi?'),
            content: Text(
              item.isDeposit
                  ? 'Khoản đã bỏ vào hũ sẽ bị xóa và số tiền của hũ tương ứng được điều chỉnh lại.'
                  : 'Khoản rút sẽ bị xóa và số tiền của hũ tương ứng được hoàn lại.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Xóa')),
            ],
          ),
        ) ??
        false;
    if (accepted && item.id != null) await widget.store.deleteSavingRecord(item.id!);
  }
}
