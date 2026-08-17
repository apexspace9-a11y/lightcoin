part of 'main.dart';

class Shell extends StatefulWidget {
  const Shell({super.key, required this.store});
  final AppStore store;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;

  void _select(int value) {
    if (value == index) return;
    HapticFeedback.selectionClick();
    setState(() => index = value);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(store: widget.store, onGo: _select),
      CalendarPage(store: widget.store),
      SavingsPage(store: widget.store),
      RemindersPage(store: widget.store),
      SettingsPage(store: widget.store),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Hôm nay',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings_rounded),
            label: 'Tiết kiệm',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_active_rounded),
            label: 'Nhắc hẹn',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.7,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}

class _UpcomingItem {
  const _UpcomingItem({
    required this.at,
    required this.title,
    required this.icon,
    required this.accent,
  });

  final DateTime at;
  final String title;
  final IconData icon;
  final Color accent;
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.store,
    required this.onGo,
  });

  final AppStore store;
  final ValueChanged<int> onGo;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = <_UpcomingItem>[
      ...store.events.where((item) => item.dateTime.isAfter(now)).map(
            (item) => _UpcomingItem(
              at: item.dateTime,
              title: item.title,
              icon: Icons.calendar_today_rounded,
              accent: _purple,
            ),
          ),
      ...store.reminders
          .where((item) => item.dateTime.isAfter(now) && !item.done)
          .map(
            (item) => _UpcomingItem(
              at: item.dateTime,
              title: item.title,
              icon: Icons.notifications_rounded,
              accent: _mint,
            ),
          ),
    ]..sort((a, b) => a.at.compareTo(b.at));

    final saved = store.totalSaved;
    final target = store.totalTarget;
    final progress = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);

    return PageFrame(
      title: 'Light Coin',
      subtitle: DateFormat("EEEE, d 'tháng' M", 'vi_VN').format(now),
      action: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_purple, _mint]),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.bolt_rounded, color: Colors.white),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6554F6),
                  Color(0xFF7D68FF),
                  Color(0xFF31CDAE),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _purple.withValues(alpha: .20),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TỔNG TIẾT KIỆM',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  _money.format(saved),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  target <= 0
                      ? 'Tạo mục tiêu để bắt đầu theo dõi tiến độ'
                      : '${((saved / target) * 100).clamp(0, 999).toStringAsFixed(0)}% của ${_money.format(target)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Hôm nay',
                  value: '${store.todayCount}',
                  icon: Icons.today_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Đang nhắc',
                  value: '${store.activeReminderCount}',
                  icon: Icons.alarm_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Mục tiêu',
                  value: '${store.goals.length}',
                  icon: Icons.flag_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Quick(
                  icon: Icons.event_available_rounded,
                  label: 'Tạo lịch',
                  onTap: () => _showEventForm(context, store),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Quick(
                  icon: Icons.add_card_rounded,
                  label: 'Tiết kiệm',
                  onTap: () => _showGoalForm(context, store),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Quick(
                  icon: Icons.alarm_add_rounded,
                  label: 'Nhắc hẹn',
                  onTap: () => _showReminderForm(context, store),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _section(context, 'Sắp tới', onTap: () => onGo(1)),
          const SizedBox(height: 10),
          if (upcoming.isEmpty)
            const _Empty(
              icon: Icons.wb_sunny_outlined,
              title: 'Chưa có lịch sắp tới',
              text: 'Tạo lịch hoặc lời nhắc để theo dõi những việc quan trọng.',
            )
          else
            ...upcoming.take(3).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _Tile(
                      icon: item.icon,
                      title: item.title,
                      subtitle:
                          '${_day.format(item.at)} • ${_time.format(item.at)}',
                      accent: item.accent,
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          _section(context, 'Mục tiêu', onTap: () => onGo(2)),
          const SizedBox(height: 10),
          if (store.goals.isEmpty)
            const _Empty(
              icon: Icons.savings_outlined,
              title: 'Chưa có mục tiêu tiết kiệm',
              text: 'Đặt một mục tiêu cụ thể để bắt đầu theo dõi tiến độ.',
            )
          else
            ...store.goals.take(2).map(
                  (goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _GoalCard(
                      goal: goal,
                      compact: true,
                      onAdd: () => _showAddMoney(context, store, goal),
                      onDelete: null,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title, {
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(onPressed: onTap, child: const Text('Xem tất cả')),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: _purple),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({
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
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _purple, size: 21),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
