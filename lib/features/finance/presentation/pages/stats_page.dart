import 'package:app_2/core/constants/app_spacing.dart';
import 'package:app_2/core/utils/currency_formatter.dart';
import 'package:app_2/features/finance/domain/entities/transaction_item.dart';
import 'package:app_2/features/finance/presentation/providers/transaction_providers.dart';
import 'package:app_2/features/finance/presentation/widgets/mobile_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MobileBottomNav.isEnabledFor(context);
    final transactions =
        ref.watch(transactionsControllerProvider).valueOrNull ??
        const <TransactionItem>[];

    final categoryExpense = _byCategory(
      transactions.where((item) => item.type == TransactionType.expense).toList(),
    );
    final categoryIncome = _byCategory(
      transactions.where((item) => item.type == TransactionType.income).toList(),
    );

    final incomeTotal = transactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenseTotal = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final transferTotal = transactions
        .where((item) => item.type == TransactionType.transfer)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final cashFlow7d = _buildCashFlowTrend7d(transactions);
    final accountDistribution = _byAccount(transactions);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: isMobile ? null : AppBar(title: const Text('Statistik')),
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
            if (isMobile)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 46, 20, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F756D), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Text(
                  'Statistik Keuangan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                children: [
                  _QuickSummaryCard(
                    incomeTotal: incomeTotal,
                    expenseTotal: expenseTotal,
                    transferTotal: transferTotal,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _CashFlowChartCard(data: cashFlow7d),
                  const SizedBox(height: AppSpacing.s12),
                  _CategoryStatCard(
                    title: 'Pengeluaran per kategori',
                    items: categoryExpense,
                    emptyText: 'Belum ada data pengeluaran.',
                    icon: Icons.arrow_upward_rounded,
                    accent: const Color(0xFFB23A48),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _CategoryStatCard(
                    title: 'Pemasukan per kategori',
                    items: categoryIncome,
                    emptyText: 'Belum ada data pemasukan.',
                    icon: Icons.arrow_downward_rounded,
                    accent: const Color(0xFF197B4B),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _CategoryStatCard(
                    title: 'Distribusi transaksi per akun',
                    items: accountDistribution,
                    emptyText: 'Belum ada data akun.',
                    icon: Icons.account_balance_wallet_rounded,
                    accent: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isMobile
          ? MobileBottomNav(
              selectedIndex: 3,
              addTooltip: 'Tambah transaksi',
              onAddPressed: () => context.go('/home'),
            )
          : null,
    );
  }

  List<_StatAmount> _byCategory(List<TransactionItem> items) {
    final grouped = <String, double>{};
    for (final item in items) {
      final key =
          (item.category == null || item.category!.trim().isEmpty)
          ? 'Tanpa kategori'
          : item.category!.trim();
      grouped.update(key, (value) => value + item.amount, ifAbsent: () => item.amount);
    }
    final result = grouped.entries
        .map((entry) => _StatAmount(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  List<_StatAmount> _byAccount(List<TransactionItem> items) {
    final grouped = <String, double>{};
    for (final item in items) {
      final key =
          (item.account == null || item.account!.trim().isEmpty)
          ? 'Tanpa akun'
          : item.account!.trim();
      grouped.update(key, (value) => value + item.amount, ifAbsent: () => item.amount);
    }
    final result = grouped.entries
        .map((entry) => _StatAmount(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  List<_CashFlowPoint> _buildCashFlowTrend7d(List<TransactionItem> items) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(
      const Duration(days: 6),
    );

    final result = <_CashFlowPoint>[];
    for (var i = 0; i < 7; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      var income = 0.0;
      var expense = 0.0;
      for (final item in items) {
        final sameDay =
            item.createdAt.year == day.year &&
            item.createdAt.month == day.month &&
            item.createdAt.day == day.day;
        if (!sameDay) {
          continue;
        }
        if (item.type == TransactionType.income) {
          income += item.amount;
        } else if (item.type == TransactionType.expense) {
          expense += item.amount;
        }
      }
      result.add(
        _CashFlowPoint(
          label: const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][day.weekday - 1],
          income: income,
          expense: expense,
        ),
      );
    }
    return result;
  }
}

class _StatAmount {
  const _StatAmount(this.name, this.amount);

  final String name;
  final double amount;
}

class _QuickSummaryCard extends StatelessWidget {
  const _QuickSummaryCard({
    required this.incomeTotal,
    required this.expenseTotal,
    required this.transferTotal,
  });

  final double incomeTotal;
  final double expenseTotal;
  final double transferTotal;

  @override
  Widget build(BuildContext context) {
    final net = incomeTotal - expenseTotal;
    return Container(
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text('Pemasukan: ${CurrencyFormatter.idr(incomeTotal)}'),
          Text('Pengeluaran: ${CurrencyFormatter.idr(expenseTotal)}'),
          Text('Transfer: ${CurrencyFormatter.idr(transferTotal)}'),
          const SizedBox(height: 4),
          Text(
            'Net: ${CurrencyFormatter.idr(net)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F766E),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashFlowPoint {
  const _CashFlowPoint({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final double income;
  final double expense;
}

class _CashFlowChartCard extends StatelessWidget {
  const _CashFlowChartCard({required this.data});

  final List<_CashFlowPoint> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.isEmpty
        ? 1.0
        : data
              .map((item) => item.income > item.expense ? item.income : item.expense)
              .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren 7 hari (Income vs Expense)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data
                  .map(
                    (item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: maxValue == 0
                                          ? 2
                                          : ((item.income / maxValue) * 110)
                                                .clamp(2, 110),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 10,
                                      height: maxValue == 0
                                          ? 2
                                          : ((item.expense / maxValue) * 110)
                                                .clamp(2, 110),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(item.label, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: Color(0xFF16A34A), label: 'Pemasukan'),
              const SizedBox(width: 12),
              _LegendDot(color: Color(0xFFDC2626), label: 'Pengeluaran'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CategoryStatCard extends StatelessWidget {
  const _CategoryStatCard({
    required this.title,
    required this.items,
    required this.emptyText,
    required this.icon,
    required this.accent,
  });

  final String title;
  final List<_StatAmount> items;
  final String emptyText;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EDF5)),
      ),
      child: Padding(
        padding: AppSpacing.p16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.12),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${CurrencyFormatter.idr(total)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(emptyText, style: Theme.of(context).textTheme.bodyMedium)
            else
              ...items.take(10).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.idr(item.amount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
