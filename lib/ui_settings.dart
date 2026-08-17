part of 'main.dart';

Future<void> _showNotificationBlocked(BuildContext context) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Thông báo đang bị tắt. Hãy cấp quyền để nhận nhắc hẹn.'),
        action: SnackBarAction(
          label: 'Cài đặt',
          onPressed: () {
            NotificationService.instance.openSystemSettings();
          },
        ),
      ),
    );
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      ) ??
      false;
}

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final active = store.reminders.where((item) => !item.done).toList();
    final done = store.reminders.where((item) => item.done).toList();

    return PageFrame(
      title: 'Nhắc hẹn',
      subtitle: '${active.length} lời nhắc đang theo dõi',
      action: _RoundAdd(onTap: () => _showReminderForm(context, store)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active.isEmpty)
            const _Empty(
              icon: Icons.notifications_none_rounded,
              title: 'Chưa có lời nhắc',
              text: 'Tạo lời nhắc cho công việc, cuộc gọi, hóa đơn hoặc lịch cá nhân.',
            )
          else
            ...active.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReminderCard(reminder: item, store: store),
              ),
            ),
          if (done.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Đã hoàn thành',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...done.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReminderCard(reminder: item, store: store),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder, required this.store});
  final ReminderItem reminder;
  final AppStore store;

  Future<void> _toggle(
    BuildContext context, {
    bool? done,
    bool? enabled,
  }) async {
    HapticFeedback.selectionClick();
    final ok = await store.toggleReminder(
      reminder,
      done: done,
      enabled: enabled,
    );
    if (!ok && context.mounted) await _showNotificationBlocked(context);
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          children: [
            Checkbox(
              value: reminder.done,
              onChanged: (value) => _toggle(context, done: value),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      decoration:
                          reminder.done ? TextDecoration.lineThrough : null,
                      color: reminder.done ? muted : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_day.format(reminder.dateTime)} • ${_time.format(reminder.dateTime)}${reminder.note.isEmpty ? '' : '\n${reminder.note}'}',
                    style: TextStyle(fontSize: 12, color: muted, height: 1.35),
                  ),
                ],
              ),
            ),
            Switch(
              value: reminder.enabled && !reminder.done,
              onChanged: reminder.done
                  ? null
                  : (value) => _toggle(context, enabled: value),
            ),
            PopupMenuButton<String>(
              tooltip: 'Tùy chọn',
              onSelected: (value) async {
                if (value != 'delete') return;
                final confirmed = await _confirmDelete(
                  context,
                  title: 'Xóa lời nhắc?',
                  message: 'Lời nhắc này sẽ được xóa khỏi Light Coin.',
                );
                if (confirmed) await store.deleteReminder(reminder.id);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded),
                      SizedBox(width: 10),
                      Text('Xóa'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});
  final AppStore store;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  bool? _systemNotifications;
  bool _testing = false;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final enabled = await NotificationService.instance.areNotificationsEnabled();
    if (mounted) setState(() => _systemNotifications = enabled);
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_switching) return;
    setState(() => _switching = true);
    HapticFeedback.selectionClick();

    final ok = await widget.store.setNotifications(value);
    await _refreshPermission();

    if (mounted) setState(() => _switching = false);
    if (value && !ok && mounted) await _showNotificationBlocked(context);
  }

  Future<void> _testNotification() async {
    if (_testing) return;
    setState(() => _testing = true);
    HapticFeedback.mediumImpact();

    final result = await NotificationService.instance.test();
    await _refreshPermission();

    if (mounted) setState(() => _testing = false);
    if (!mounted) return;

    switch (result) {
      case NotificationTestResult.sent:
        _message('Đã gửi thông báo thử.');
        break;
      case NotificationTestResult.permissionDenied:
        await _showNotificationBlocked(context);
        break;
      case NotificationTestResult.failed:
        _message('Không thể gửi thông báo thử. Vui lòng thử lại.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final permission = _systemNotifications;
    final permissionText = permission == null
        ? 'Đang kiểm tra'
        : permission
            ? 'Được phép'
            : 'Đang bị chặn';
    final permissionColor = permission == false ? Colors.orange : _mint;

    return PageFrame(
      title: 'Cài đặt',
      subtitle: 'Cá nhân hóa Light Coin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('THÔNG BÁO'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: permissionColor.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          permission == false
                              ? Icons.notifications_off_rounded
                              : Icons.notifications_active_rounded,
                          color: permissionColor,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quyền thông báo',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Trạng thái quyền trên thiết bị',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: permissionColor.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          permissionText,
                          style: TextStyle(
                            color: permissionColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Nhắc hẹn trong Light Coin',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('Lịch, công việc và lời nhắc đã bật'),
                    value: widget.store.notifications,
                    onChanged: _switching ? null : _toggleNotifications,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _testing ? null : _testNotification,
                      icon: _testing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_active_rounded),
                      label: Text(
                        _testing ? 'Đang kiểm tra...' : 'Gửi thông báo thử',
                      ),
                    ),
                  ),
                  if (permission == false) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await NotificationService.instance.openSystemSettings();
                        },
                        icon: const Icon(Icons.settings_rounded),
                        label: const Text('Mở cài đặt thông báo'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('GIAO DIỆN'),
          const SizedBox(height: 10),
          _Setting(
            icon: Icons.dark_mode_rounded,
            title: 'Giao diện tối',
            subtitle: 'Tối ưu hiển thị trong môi trường thiếu sáng',
            trailing: Switch(
              value: widget.store.darkMode,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                widget.store.setDark(value);
              },
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('DỮ LIỆU'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: _DataMetric(
                      value: '${widget.store.events.length}',
                      label: 'Lịch',
                    ),
                  ),
                  Expanded(
                    child: _DataMetric(
                      value: '${widget.store.reminders.length}',
                      label: 'Nhắc hẹn',
                    ),
                  ),
                  Expanded(
                    child: _DataMetric(
                      value: '${widget.store.goals.length}',
                      label: 'Mục tiêu',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _purple.withValues(alpha: .10),
                  _mint.withValues(alpha: .10),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Light Coin 1.1.0',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                SizedBox(height: 6),
                Text(
                  'Lịch • Tiết kiệm • Nhắc hẹn',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _DataMetric extends StatelessWidget {
  const _DataMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Setting extends StatelessWidget {
  const _Setting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _purple.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: _purple),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}

class _RoundAdd extends StatelessWidget {
  const _RoundAdd({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      icon: const Icon(Icons.add_rounded),
      style: IconButton.styleFrom(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .35),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: _purple),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.4,
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
