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
      .toList();

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _for(selected);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return PageFrame(
      title: 'Lịch',
      subtitle: 'Tập trung vào điều đáng nhớ',
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
              Text(
                '${selectedEvents.length} mục',
                style: TextStyle(color: muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedEvents.isEmpty)
            const _Empty(
              icon: Icons.event_note_rounded,
              title: 'Ngày này còn trống',
              text: 'Bạn có thể giữ nó trống. Một khả năng hiếm hoi nhưng hợp pháp.',
            )
          else
            ...selectedEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DissmissableEvent(
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

class DissmissableEvent extends StatelessWidget {
  const DissmissableEvent({
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
        icon: Icons.schedule_rounded,
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
    final total = store.goals.fold<double>(0, (sum, goal) => sum + goal.current);

    return PageFrame(
      title: 'Tiết kiệm',
      subtitle: 'Biến mục tiêu thành con số',
      action: _RoundAdd(onTap: () => _showGoalForm(context, store)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _mint.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _mint.withValues(alpha: .2),
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
                      Text(
                        _money.format(total),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
              title: 'Tạo mục tiêu đầu tiên',
              text:
                  'Chuyến đi, quỹ dự phòng hay một món đồ. Đặt tên, số tiền và hạn hoàn thành.',
            )
          else
            ...store.goals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GoalCard(
                  goal: goal,
                  onAdd: () => _showAddMoney(context, store, goal),
                  onDelete: () => store.deleteGoal(goal.id),
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
                if (onDelete != null)
                  IconButton(
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
                backgroundColor: _purple.withValues(alpha: .1),
                valueColor: const AlwaysStoppedAnimation(_purple),
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
                  onPressed: onAdd,
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
