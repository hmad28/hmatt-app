import 'package:app_2/core/constants/app_spacing.dart';
import 'package:app_2/core/utils/currency_formatter.dart';
import 'package:app_2/features/finance/domain/entities/calendar_event.dart';
import 'package:app_2/features/finance/domain/entities/transaction_item.dart';
import 'package:app_2/features/finance/presentation/providers/calendar_event_providers.dart';
import 'package:app_2/features/finance/presentation/providers/transaction_providers.dart';
import 'package:app_2/features/finance/presentation/widgets/mobile_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CalendarOverviewPage extends ConsumerStatefulWidget {
  const CalendarOverviewPage({super.key});

  @override
  ConsumerState<CalendarOverviewPage> createState() =>
      _CalendarOverviewPageState();
}

class _CalendarOverviewPageState extends ConsumerState<CalendarOverviewPage> {
  late DateTime _focusMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final transactions =
        ref.watch(transactionsControllerProvider).valueOrNull ??
        const <TransactionItem>[];
    final events =
        ref.watch(calendarEventsControllerProvider).valueOrNull ??
        const <CalendarEvent>[];

    final monthTransactions = transactions.where((item) {
      return item.createdAt.year == _focusMonth.year &&
          item.createdAt.month == _focusMonth.month;
    }).toList();

    final monthIncome = monthTransactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final monthExpense = monthTransactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final monthNet = monthIncome - monthExpense;

    final selectedTransactions = _itemsByDay(transactions, _selectedDay);
    final selectedIncome = selectedTransactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final selectedExpense = selectedTransactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final selectedEvents = events
        .where((item) => _isSameDay(item.date, _selectedDay))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FBFC), Color(0xFFEFF3FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _MonthHeader(
              month: _focusMonth,
              net: monthNet,
              onPrevious: () {
                setState(() {
                  _focusMonth = DateTime(
                    _focusMonth.year,
                    _focusMonth.month - 1,
                    1,
                  );
                });
              },
              onNext: () {
                setState(() {
                  _focusMonth = DateTime(
                    _focusMonth.year,
                    _focusMonth.month + 1,
                    1,
                  );
                });
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                children: [
                  _MonthlySummaryCard(
                    income: monthIncome,
                    expense: monthExpense,
                    net: monthNet,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _CalendarGrid(
                    month: _focusMonth,
                    selectedDay: _selectedDay,
                    transactions: transactions,
                    events: events,
                    onDayTap: (day) => setState(() => _selectedDay = day),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _SelectedDaySummary(
                    day: _selectedDay,
                    income: selectedIncome,
                    expense: selectedExpense,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _SelectedDayEvents(
                    events: selectedEvents,
                    onDelete: (id) async {
                      await ref
                          .read(calendarEventsControllerProvider.notifier)
                          .deleteEvent(id);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: MobileBottomNav.isEnabledFor(context)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddEventDialog(context, _selectedDay),
              icon: const Icon(Icons.add_alert_rounded),
              label: const Text('Tambah Event'),
            ),
      bottomNavigationBar: null,
    );
  }

  List<TransactionItem> _itemsByDay(List<TransactionItem> items, DateTime day) {
    return items.where((item) => _isSameDay(item.createdAt, day)).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _showAddEventDialog(
    BuildContext context,
    DateTime initialDate,
  ) async {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    var selectedDate = initialDate;
    var selectedType = CalendarEventType.custom;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Tambah event kalender'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul event',
                          hintText: 'Contoh: Tanggal gajian',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      DropdownButtonFormField<CalendarEventType>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Tipe event',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: CalendarEventType.payday,
                            child: Text('Gajian'),
                          ),
                          DropdownMenuItem(
                            value: CalendarEventType.reminder,
                            child: Text('Pengingat'),
                          ),
                          DropdownMenuItem(
                            value: CalendarEventType.custom,
                            child: Text('Kustom'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setLocalState(() => selectedType = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked == null) {
                            return;
                          }
                          setLocalState(() => selectedDate = picked);
                        },
                        icon: const Icon(Icons.event_rounded),
                        label: Text(
                          DateFormat(
                            'dd MMM yyyy',
                            'id_ID',
                          ).format(selectedDate),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      TextField(
                        controller: notesController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Judul event wajib diisi'),
                        ),
                      );
                      return;
                    }
                    await ref
                        .read(calendarEventsControllerProvider.notifier)
                        .add(
                          title: title,
                          date: selectedDate,
                          type: selectedType,
                          notes: notesController.text,
                        );
                    if (!dialogContext.mounted) {
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.net,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final double net;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final netPositive = net >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 46, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                color: Colors.white,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(month),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                color: Colors.white,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Saldo bersih: ${netPositive ? '+' : ''}${CurrencyFormatter.idr(net)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.income,
    required this.expense,
    required this.net,
  });

  final double income;
  final double expense;
  final double net;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan bulan ini',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text('Pemasukan: ${CurrencyFormatter.idr(income)}'),
          Text('Pengeluaran: ${CurrencyFormatter.idr(expense)}'),
          Text(
            'Net: ${CurrencyFormatter.idr(net)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.selectedDay,
    required this.transactions,
    required this.events,
    required this.onDayTap,
  });

  final DateTime month;
  final DateTime selectedDay;
  final List<TransactionItem> transactions;
  final List<CalendarEvent> events;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final leading = firstDay.weekday - 1;
    final totalDays = DateUtils.getDaysInMonth(month.year, month.month);
    final cellCount = leading + totalDays;
    final rows = (cellCount / 7).ceil();

    final txByDay = <String, List<TransactionItem>>{};
    for (final item in transactions) {
      if (item.createdAt.year != month.year ||
          item.createdAt.month != month.month) {
        continue;
      }
      final key = _key(item.createdAt);
      txByDay.putIfAbsent(key, () => []).add(item);
    }

    final eventsByDay = <String, List<CalendarEvent>>{};
    for (final item in events) {
      if (item.date.year != month.year || item.date.month != month.month) {
        continue;
      }
      final key = _key(item.date);
      eventsByDay.putIfAbsent(key, () => []).add(item);
    }

    return Container(
      padding: AppSpacing.p12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EDF5)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(child: Center(child: Text('Sen'))),
              Expanded(child: Center(child: Text('Sel'))),
              Expanded(child: Center(child: Text('Rab'))),
              Expanded(child: Center(child: Text('Kam'))),
              Expanded(child: Center(child: Text('Jum'))),
              Expanded(child: Center(child: Text('Sab'))),
              Expanded(child: Center(child: Text('Min'))),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < rows; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: _buildCell(
                        context,
                        index: (row * 7) + col,
                        leading: leading,
                        totalDays: totalDays,
                        txByDay: txByDay,
                        eventsByDay: eventsByDay,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCell(
    BuildContext context, {
    required int index,
    required int leading,
    required int totalDays,
    required Map<String, List<TransactionItem>> txByDay,
    required Map<String, List<CalendarEvent>> eventsByDay,
  }) {
    final dayNumber = index - leading + 1;
    if (dayNumber < 1 || dayNumber > totalDays) {
      return const SizedBox(height: 56);
    }
    final day = DateTime(month.year, month.month, dayNumber);
    final key = _key(day);
    final items = txByDay[key] ?? const <TransactionItem>[];
    final events = eventsByDay[key] ?? const <CalendarEvent>[];
    final income = items
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expense = items
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final selected =
        selectedDay.year == day.year &&
        selectedDay.month == day.month &&
        selectedDay.day == day.day;

    return InkWell(
      onTap: () => onDayTap(day),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F766E) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 2),
            if (income > 0 || expense > 0 || events.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (income > 0)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (income > 0 && (expense > 0 || events.isNotEmpty))
                    const SizedBox(width: 3),
                  if (expense > 0)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white70
                            : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (events.isNotEmpty && (income > 0 || expense > 0))
                    const SizedBox(width: 3),
                  if (events.isNotEmpty)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white60
                            : const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _key(DateTime value) {
    return '${value.year}-${value.month}-${value.day}';
  }
}

class _SelectedDaySummary extends StatelessWidget {
  const _SelectedDaySummary({
    required this.day,
    required this.income,
    required this.expense,
  });

  final DateTime day;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.p12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, dd MMM', 'id_ID').format(day),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('Daily balance: ${CurrencyFormatter.idr(income - expense)}'),
          Text('Income: ${CurrencyFormatter.idr(income)}'),
          Text('Expense: ${CurrencyFormatter.idr(expense)}'),
        ],
      ),
    );
  }
}

class _SelectedDayEvents extends StatelessWidget {
  const _SelectedDayEvents({required this.events, required this.onDelete});

  final List<CalendarEvent> events;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.p12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event hari ini',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (events.isEmpty)
            const Text('Belum ada event di tanggal ini')
          else
            ...events.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                subtitle: Text(_labelForType(item.type)),
                trailing: IconButton(
                  onPressed: () async => onDelete(item.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _labelForType(CalendarEventType type) {
    return switch (type) {
      CalendarEventType.payday => 'Gajian',
      CalendarEventType.reminder => 'Pengingat',
      CalendarEventType.custom => 'Kustom',
    };
  }
}
