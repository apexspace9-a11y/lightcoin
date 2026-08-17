part of 'main.dart';

void _formMessage(BuildContext context, String text) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

DateTime _suggestedDateTime({DateTime? day}) {
  final now = DateTime.now();
  final fallback = now.add(const Duration(hours: 1));
  if (day == null) return fallback;

  final candidate = DateTime(day.year, day.month, day.day, 9);
  return candidate.isAfter(now) ? candidate : fallback;
}

Future<DateTime?> _pickDateTime(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
  final base = initial ?? _suggestedDateTime();
  final today = DateTime(now.year, now.month, now.day);
  final initialDate = base.isBefore(today) ? today : base;

  final date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: today,
    lastDate: DateTime(2035),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(base),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

Widget _formSheet(BuildContext context, Widget child) {
  return SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(child: child),
    ),
  );
}

Future<void> _showEventForm(
  BuildContext context,
  AppStore store, {
  DateTime? initial,
  CalendarItem? editing,
}) async {
  final title = TextEditingController(text: editing?.title ?? '');
  final note = TextEditingController(text: editing?.note ?? '');
  DateTime when = editing?.dateTime ?? _suggestedDateTime(day: initial);
  String category = editing?.category ?? 'Cá nhân';
  bool remind = editing?.remind ?? true;
  bool saving = false;
  final isEditing = editing != null;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => _formSheet(
        sheetContext,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Chỉnh sửa lịch' : 'Tạo lịch mới',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: title,
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                prefixIcon: Icon(Icons.edit_calendar_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(
                labelText: 'Nhóm',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: const [
                'Cá nhân',
                'Công việc',
                'Gia đình',
                'Sức khỏe',
                'Tài chính',
              ]
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => category = value ?? category,
            ),
            const SizedBox(height: 8),
            _DateTimeRow(
              icon: Icons.schedule_rounded,
              label: '${_day.format(when)} • ${_time.format(when)}',
              onTap: () async {
                final value = await _pickDateTime(sheetContext, initial: when);
                if (value != null) setSheetState(() => when = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Nhắc tôi'),
              subtitle: const Text('Gửi thông báo khi đến giờ'),
              value: remind,
              onChanged: (value) => setSheetState(() => remind = value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final cleanTitle = title.text.trim();
                        if (cleanTitle.isEmpty) {
                          _formMessage(sheetContext, 'Vui lòng nhập tiêu đề.');
                          return;
                        }
                        if (!when.isAfter(DateTime.now())) {
                          _formMessage(
                            sheetContext,
                            'Thời gian phải ở trong tương lai.',
                          );
                          return;
                        }

                        setSheetState(() => saving = true);
                        final item = CalendarItem(
                          id: editing?.id ?? store.nextId(),
                          title: cleanTitle,
                          dateTime: when,
                          note: note.text.trim(),
                          category: category,
                          remind: remind,
                        );
                        final notificationReady = isEditing
                            ? await store.updateEvent(item)
                            : await store.addEvent(item);

                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (remind && !notificationReady && context.mounted) {
                          await _showNotificationBlocked(context);
                        }
                      },
                child: Text(
                  saving
                      ? 'Đang lưu...'
                      : isEditing
                          ? 'Lưu thay đổi'
                          : 'Lưu lịch',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  title.dispose();
  note.dispose();
}

Future<void> _showGoalForm(
  BuildContext context,
  AppStore store, {
  SavingGoal? editing,
}) async {
  final name = TextEditingController(text: editing?.name ?? '');
  final target = TextEditingController(
    text: editing == null ? '' : editing.target.toStringAsFixed(0),
  );
  final current = TextEditingController(
    text: editing == null ? '0' : editing.current.toStringAsFixed(0),
  );
  DateTime deadline =
      editing?.deadline ?? DateTime.now().add(const Duration(days: 90));
  bool saving = false;
  final isEditing = editing != null;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => _formSheet(
        sheetContext,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Chỉnh sửa mục tiêu' : 'Mục tiêu tiết kiệm',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: name,
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tên mục tiêu',
                prefixIcon: Icon(Icons.flag_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: target,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Số tiền mục tiêu',
                prefixIcon: Icon(Icons.payments_rounded),
                suffixText: '₫',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: current,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Đã tích lũy',
                prefixIcon: Icon(Icons.savings_rounded),
                suffixText: '₫',
              ),
            ),
            const SizedBox(height: 8),
            _DateTimeRow(
              icon: Icons.event_rounded,
              label: 'Hạn ${_day.format(deadline)}',
              onTap: () async {
                final today = DateTime.now();
                final initialDate = deadline.isBefore(today) ? today : deadline;
                final date = await showDatePicker(
                  context: sheetContext,
                  initialDate: initialDate,
                  firstDate: DateTime(today.year, today.month, today.day),
                  lastDate: DateTime(2035),
                );
                if (date != null) setSheetState(() => deadline = date);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final cleanName = name.text.trim();
                        final targetValue = double.tryParse(target.text) ?? 0;
                        final currentValue = double.tryParse(current.text) ?? 0;

                        if (cleanName.isEmpty) {
                          _formMessage(sheetContext, 'Vui lòng nhập tên mục tiêu.');
                          return;
                        }
                        if (targetValue <= 0) {
                          _formMessage(
                            sheetContext,
                            'Số tiền mục tiêu phải lớn hơn 0.',
                          );
                          return;
                        }

                        setSheetState(() => saving = true);
                        final goal = SavingGoal(
                          id: editing?.id ?? store.nextId(),
                          name: cleanName,
                          target: targetValue,
                          current: currentValue.clamp(0.0, targetValue).toDouble(),
                          deadline: deadline,
                        );
                        if (isEditing) {
                          await store.updateGoal(goal);
                        } else {
                          await store.addGoal(goal);
                        }
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                child: Text(
                  saving
                      ? 'Đang lưu...'
                      : isEditing
                          ? 'Lưu thay đổi'
                          : 'Tạo mục tiêu',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  name.dispose();
  target.dispose();
  current.dispose();
}

Future<void> _showAddMoney(
  BuildContext context,
  AppStore store,
  SavingGoal goal,
) async {
  final controller = TextEditingController();
  bool saving = false;

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text('Nạp vào ${goal.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Số tiền',
            suffixText: '₫',
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    final value = double.tryParse(controller.text) ?? 0;
                    if (value <= 0) {
                      _formMessage(
                        dialogContext,
                        'Vui lòng nhập số tiền hợp lệ.',
                      );
                      return;
                    }
                    setDialogState(() => saving = true);
                    await store.addMoney(goal.id, value);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
            child: Text(saving ? 'Đang nạp...' : 'Nạp'),
          ),
        ],
      ),
    ),
  );

  controller.dispose();
}

Future<void> _showReminderForm(
  BuildContext context,
  AppStore store, {
  ReminderItem? editing,
}) async {
  final title = TextEditingController(text: editing?.title ?? '');
  final note = TextEditingController(text: editing?.note ?? '');
  DateTime when = editing?.dateTime ?? _suggestedDateTime();
  bool enabled = editing?.enabled ?? true;
  bool saving = false;
  final isEditing = editing != null;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => _formSheet(
        sheetContext,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Chỉnh sửa nhắc hẹn' : 'Nhắc hẹn mới',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: title,
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Việc cần nhớ',
                prefixIcon: Icon(Icons.notifications_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 8),
            _DateTimeRow(
              icon: Icons.alarm_rounded,
              label: '${_day.format(when)} • ${_time.format(when)}',
              onTap: () async {
                final value = await _pickDateTime(sheetContext, initial: when);
                if (value != null) setSheetState(() => when = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bật nhắc hẹn'),
              subtitle: const Text('Gửi notification khi đến giờ'),
              value: enabled,
              onChanged: (value) => setSheetState(() => enabled = value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final cleanTitle = title.text.trim();
                        if (cleanTitle.isEmpty) {
                          _formMessage(
                            sheetContext,
                            'Vui lòng nhập nội dung nhắc hẹn.',
                          );
                          return;
                        }
                        if (!when.isAfter(DateTime.now())) {
                          _formMessage(
                            sheetContext,
                            'Thời gian nhắc phải ở trong tương lai.',
                          );
                          return;
                        }

                        setSheetState(() => saving = true);
                        final reminder = ReminderItem(
                          id: editing?.id ?? store.nextId(),
                          title: cleanTitle,
                          dateTime: when,
                          note: note.text.trim(),
                          done: editing?.done ?? false,
                          enabled: enabled,
                        );
                        final notificationReady = isEditing
                            ? await store.updateReminder(reminder)
                            : await store.addReminder(reminder);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (enabled && !notificationReady && context.mounted) {
                          await _showNotificationBlocked(context);
                        }
                      },
                child: Text(
                  saving
                      ? 'Đang lưu...'
                      : isEditing
                          ? 'Lưu thay đổi'
                          : 'Lưu nhắc hẹn',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  title.dispose();
  note.dispose();
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: _purple),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
