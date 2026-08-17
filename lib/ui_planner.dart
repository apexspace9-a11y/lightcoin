part of 'main.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.store});
  final AppStore store;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selected = DateTime.now();
  DateTime focused = DateTime.now();

  List<CalendarItem> _for(DateTime day) => widget.store.events
      .where((event) => isSameDay(event.dateTime, day))
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _for(selected);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return PageFrame(
      title: 'Lịch',
      subtitle: 'Theo dõi lịch trình theo ngày',
      action: _RoundAdd(
        onTap: () => _showEventForm(
          context,
          widget.store,
          initial: selected,
        ),
      ),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
              child: TableCalendar<CalendarItem>(
                locale: 'vi_VN',
                firstDay: DateTime(2020),
                lastDay: DateTime(2035),
                focusedDay: focused,
                selectedDayPredicate: (day) => isSameDay(day, selected),
                eventLoader: _for,
                onDaySelected: (selectedDay, focusedDay) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    selected = selectedDay;
                    focused = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) => focused = focusedDay,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: _mint.withValues(alpha: .22),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: _purple,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: _mint,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                ),
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  weekendStyle: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat("d 'tháng' M, yyyy", 'vi_VN').format(selected),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${selectedEvents.length} mục',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedEvents.isEmpty)
            const _Empty(
              icon: Icons.event_note_rounded,
              title: 'Chưa có lịch trong ngày',
              text: 'Thêm lịch mới để Light Coin giúp bạn theo dõi đúng thời gian.',
            )
          else
            ...selectedEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DismissableEvent(
                  item: event,
                  onDelete: () => widget.store.deleteEvent(event),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DismissableEvent extends StatelessWidget {
  const DismissableEvent({
    super.key,
    required this.item,
    required this.onDelete,
  });

  final CalendarItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(
        context,
        title: 'Xóa lịch này?',
        message: 'Lịch và thông báo liên quan sẽ được xóa.',
      ),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: _Tile(
        icon: item.remind ? Icons.notifications_active_rounded : Icons.schedule_rounded,
        title: item.title,
        subtitle:
            '${_time.format(item.dateTime)} • ${item.category}${item.note.isEmpty ? '' : '\n${item.note}'}',
        accent: _purple,
      ),
    );
  }
}

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final total = store.totalSaved;
    final target = store.totalTarget;
    final remaining = (target - total).clamp(0.0, double.infinity).toDouble();

    return PageFrame(
      title: 'Tiết kiệm',
      subtitle: 'Theo dõi tiến độ theo từng mục tiêu',
      action: _RoundAdd(onTap: () => _showGoalForm(context, store)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _mint.withValues(alpha: .14),
                  _purple.withValues(alpha: .08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _mint.withValues(alpha: .20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: _mint,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đã tích lũy',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _money.format(total),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (target > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          remaining <= 0
                              ? 'Đã đạt tổng mục tiêu'
                              : 'Còn ${_money.format(remaining)} để đạt mục tiêu',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (store.goals.isEmpty)
            const _Empty(
              icon: Icons.flag_outlined,
              title: 'Chưa có mục tiêu tiết kiệm',
              text: 'Tạo mục tiêu với số tiền và thời hạn để bắt đầu theo dõi.',
            )
          else
            ...store.goals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GoalCard(
                  goal: goal,
                  onAdd: () => _showAddMoney(context, store, goal),
                  onDelete: () async {
                    final confirmed = await _confirmDelete(
                      context,
                      title: 'Xóa mục tiêu?',
                      message: 'Tiến độ của mục tiêu này sẽ bị xóa.',
                    );
                    if (confirmed) await store.deleteGoal(goal.id);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onAdd,
    this.onDelete,
    this.compact = false,
  });

  final SavingGoal goal;
  final VoidCallback onAdd;
  final VoidCallback? onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final completed = goal.progress >= 1;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 17 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: TextStyle(
                      fontSize: compact ? 15 : 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (completed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: _mint.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Hoàn thành',
                      style: TextStyle(
                        color: _mint,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Xóa mục tiêu',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _money.format(goal.current),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _purple,
                  ),
                ),
                Text(
                  _money.format(goal.target),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 9,
                backgroundColor: _purple.withValues(alpha: .10),
                valueColor: AlwaysStoppedAnimation(completed ? _mint : _purple),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${(goal.progress * 100).toStringAsFixed(0)}% • Hạn ${_day.format(goal.deadline)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onAdd();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nạp'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
