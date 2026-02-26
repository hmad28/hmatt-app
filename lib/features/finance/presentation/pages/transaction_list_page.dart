import 'package:app_2/core/constants/app_spacing.dart';
import 'package:app_2/core/utils/currency_formatter.dart';
import 'package:app_2/core/utils/idr_currency_input_formatter.dart';
import 'package:app_2/core/utils/local_image_preview.dart';
import 'package:app_2/features/auth/presentation/providers/auth_providers.dart';
import 'package:app_2/features/finance/domain/entities/finance_account.dart';
import 'package:app_2/features/finance/domain/entities/finance_category.dart';
import 'package:app_2/features/finance/domain/entities/financial_plan.dart';
import 'package:app_2/features/finance/domain/entities/transaction_item.dart';
import 'package:app_2/features/finance/presentation/providers/financial_plan_providers.dart';
import 'package:app_2/features/finance/presentation/providers/transaction_providers.dart';
import 'package:app_2/features/finance/presentation/widgets/balance_header.dart';
import 'package:app_2/features/finance/presentation/widgets/mobile_bottom_nav.dart';
import 'package:app_2/features/finance/presentation/widgets/payment_mode_badge.dart';
import 'package:app_2/features/finance/presentation/widgets/transaction_card.dart';
import 'package:app_2/features/update/presentation/providers/app_update_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum TransactionFilter { all, income, expense, transfer }

enum PaymentFilter { all, cash, nonCash }

enum TransactionSort { newest, amountHigh, amountLow }

class TransactionListPage extends ConsumerStatefulWidget {
  const TransactionListPage({super.key});

  @override
  ConsumerState<TransactionListPage> createState() =>
      _TransactionListPageState();
}

class _TransactionListPageState extends ConsumerState<TransactionListPage> {
  var _filter = TransactionFilter.all;
  var _sort = TransactionSort.newest;
  var _paymentFilter = PaymentFilter.all;
  var _isBalanceVisible = false;

  @override
  Widget build(BuildContext context) {
    final isAndroidMobile = MobileBottomNav.isEnabledFor(context);
    final asyncTransactions = ref.watch(transactionsControllerProvider);
    final asyncAccounts = ref.watch(accountsControllerProvider);
    final asyncCategories = ref.watch(categoriesControllerProvider);
    final asyncPlans = ref.watch(financialPlansControllerProvider);
    final updateInfo = ref.watch(appUpdateProvider).valueOrNull;
    final accounts = asyncAccounts.valueOrNull ?? const <FinanceAccount>[];
    final categories = asyncCategories.valueOrNull ?? const <FinanceCategory>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: isAndroidMobile
          ? null
          : AppBar(
              title: const Text('Hmatt'),
              actions: [
                IconButton(
                  tooltip: 'Kelola dompet/rekening dan kategori',
                  onPressed: () => context.push('/masters'),
                  icon: const Icon(Icons.tune_rounded),
                ),
                IconButton(
                  tooltip: 'Plan keuangan',
                  onPressed: () => context.push('/plans'),
                  icon: const Icon(Icons.savings_rounded),
                ),
                IconButton(
                  tooltip: 'Kalender keuangan',
                  onPressed: () => context.push('/calendar'),
                  icon: const Icon(Icons.calendar_month_rounded),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Profil akun',
                  onSelected: (value) async {
                    switch (value) {
                      case 'account':
                        context.go('/account');
                        break;
                      case 'logout':
                        await ref.read(authControllerProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/');
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'account',
                      child: Text('Profil & Backup'),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ],
                  icon: const Icon(Icons.account_circle_rounded),
                ),
              ],
            ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FBFC), Color(0xFFEFF3FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: isAndroidMobile ? EdgeInsets.zero : AppSpacing.p16,
          child: asyncTransactions.when(
            data: (items) {
              final visibleItems = _applyFilterAndSort(items);
              final totalIncome = items
                  .where((item) => item.type == TransactionType.income)
                  .fold<double>(0, (sum, item) => sum + item.amount);
              final totalExpense = items
                  .where((item) => item.type == TransactionType.expense)
                  .fold<double>(0, (sum, item) => sum + item.amount);
              final expenseByCategory = _buildExpenseByCategory(items);
              final cashFlowTrend = _buildCashFlowTrend(items);
              final hasExpenseData = expenseByCategory.isNotEmpty;
              final hasCashFlow = cashFlowTrend.any(
                (item) => item.income > 0 || item.expense > 0,
              );
              final isWide = MediaQuery.sizeOf(context).width >= 900;
              if (isAndroidMobile) {
                final recentItems = visibleItems.take(6).toList();
                final avgDailyExpense = cashFlowTrend.isEmpty
                    ? 0.0
                    : cashFlowTrend.fold<double>(
                            0,
                            (sum, point) => sum + point.expense,
                          ) /
                          cashFlowTrend.length;

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _MobileHomeHero(
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      isBalanceVisible: _isBalanceVisible,
                      onToggleVisibility: () {
                        setState(() => _isBalanceVisible = !_isBalanceVisible);
                      },
                      onCalendarTap: () => context.push('/calendar'),
                       onProfileTap: () => context.push('/account'),
                       onLogout: () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .logout();
                        if (context.mounted) {
                          context.go('/');
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (updateInfo != null &&
                              updateInfo.shouldShowBanner) ...[
                            _UpdateBanner(
                              info: updateInfo,
                              onUpdate: () async {
                                await ref
                                    .read(appUpdateProvider.notifier)
                                    .openUpdateUrl();
                              },
                              onDismiss: () async {
                                await ref
                                    .read(appUpdateProvider.notifier)
                                    .dismissBanner();
                              },
                            ),
                            const SizedBox(height: AppSpacing.s12),
                          ],
                          _CashFlowTrendCard(data: cashFlowTrend),
                          const SizedBox(height: AppSpacing.s16),
                          Text(
                            'Insights',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          SizedBox(
                            height: 148,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _MobileInsightCard(
                                  title: 'Top Category',
                                  subtitle: expenseByCategory.isEmpty
                                      ? 'Belum ada'
                                      : expenseByCategory.first.name,
                                  value: expenseByCategory.isEmpty
                                      ? '-'
                                      : CurrencyFormatter.idr(
                                          expenseByCategory.first.amount,
                                        ),
                                  icon: Icons.local_dining_rounded,
                                  accent: const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 10),
                                _MobileInsightCard(
                                  title: 'Weekly Trend',
                                  subtitle: 'Avg Expense Daily',
                                  value: CurrencyFormatter.idr(avgDailyExpense),
                                  icon: Icons.trending_up_rounded,
                                  accent: const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 10),
                                _MobileInsightCard(
                                  title: 'Safe to Spend',
                                  subtitle: 'Remainder',
                                  value: CurrencyFormatter.idr(
                                    (totalIncome - totalExpense).clamp(
                                      0,
                                      double.infinity,
                                    ),
                                  ),
                                  icon: Icons.account_balance_wallet_rounded,
                                  accent: const Color(0xFF7C3AED),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Recent Activity',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    showDragHandle: true,
                                    isScrollControlled: true,
                                    builder: (sheetContext) {
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          8,
                                          16,
                                          16,
                                        ),
                                        child: _FilterAndSortBar(
                                          filter: _filter,
                                          sort: _sort,
                                          paymentFilter: _paymentFilter,
                                          onFilterChanged: (value) {
                                            setState(() => _filter = value);
                                          },
                                          onSortChanged: (value) {
                                            setState(() => _sort = value);
                                          },
                                          onPaymentFilterChanged: (value) {
                                            setState(
                                              () => _paymentFilter = value,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(
                                  Icons.filter_list_rounded,
                                  size: 18,
                                ),
                                label: const Text('Filter'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          if (recentItems.isEmpty)
                            const _EmptyState()
                          else
                            ...recentItems.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _MobileRecentTransactionTile(
                                  item: item,
                                  onEdit: () {
                                    _showAddTransactionForm(
                                      context,
                                      ref,
                                      initialItem: item,
                                      accounts: accounts,
                                      categories: categories,
                                    );
                                  },
                                  onDelete: () {
                                    _confirmDelete(context, item.id);
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return ListView(
                children: [
                  if (updateInfo != null && updateInfo.shouldShowBanner)
                    _UpdateBanner(
                      info: updateInfo,
                      onUpdate: () async {
                        await ref
                            .read(appUpdateProvider.notifier)
                            .openUpdateUrl();
                      },
                      onDismiss: () async {
                        await ref
                            .read(appUpdateProvider.notifier)
                            .dismissBanner();
                      },
                    ),
                  if (updateInfo != null && updateInfo.shouldShowBanner)
                    const SizedBox(height: AppSpacing.s12),
                  BalanceHeader(
                    totalIncome: totalIncome,
                    totalExpense: totalExpense,
                    isBalanceVisible: _isBalanceVisible,
                    onToggleVisibility: () {
                      setState(() => _isBalanceVisible = !_isBalanceVisible);
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  if (hasExpenseData || hasCashFlow)
                    if (isWide)
                      Row(
                        children: [
                          if (hasExpenseData)
                            Expanded(
                              child: _ExpenseByCategoryCard(
                                data: expenseByCategory,
                              ),
                            ),
                          if (hasExpenseData && hasCashFlow)
                            const SizedBox(width: AppSpacing.s12),
                          if (hasCashFlow)
                            Expanded(
                              child: _CashFlowTrendCard(data: cashFlowTrend),
                            ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          if (hasExpenseData)
                            _ExpenseByCategoryCard(data: expenseByCategory),
                          if (hasExpenseData && hasCashFlow)
                            const SizedBox(height: AppSpacing.s12),
                          if (hasCashFlow)
                            _CashFlowTrendCard(data: cashFlowTrend),
                        ],
                      ),
                  if (hasExpenseData || hasCashFlow)
                    const SizedBox(height: AppSpacing.s16),
                  _FilterAndSortBar(
                    filter: _filter,
                    sort: _sort,
                    paymentFilter: _paymentFilter,
                    onFilterChanged: (value) => setState(() => _filter = value),
                    onSortChanged: (value) => setState(() => _sort = value),
                    onPaymentFilterChanged: (value) =>
                        setState(() => _paymentFilter = value),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  if (visibleItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: _EmptyState(),
                    )
                  else
                    ...visibleItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final relatedPlans = _findRelatedPlanTitles(
                        item,
                        asyncPlans.valueOrNull ?? const <FinancialPlan>[],
                      );
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == visibleItems.length - 1
                              ? 0
                              : AppSpacing.s12,
                        ),
                        child: TransactionCard(
                          item: item,
                          planHints: relatedPlans,
                          onEdit: () {
                            _showAddTransactionForm(
                              context,
                              ref,
                              initialItem: item,
                              accounts: accounts,
                              categories: categories,
                            );
                          },
                          onDelete: () {
                            _confirmDelete(context, item.id);
                          },
                        ),
                      );
                    }),
                ],
              );
            },
            error: (error, stackTrace) =>
                Center(child: Text('Terjadi error: $error')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      floatingActionButton: isAndroidMobile
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddTransactionForm(
                context,
                ref,
                accounts: accounts,
                categories: categories,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah'),
            ),
      bottomNavigationBar: isAndroidMobile
          ? MobileBottomNav(
              selectedIndex: 0,
              addTooltip: 'Tambah transaksi',
              onAddPressed: () => _showAddTransactionForm(
                context,
                ref,
                accounts: accounts,
                categories: categories,
              ),
            )
          : null,
    );
  }

  List<TransactionItem> _applyFilterAndSort(List<TransactionItem> items) {
    final filtered = switch (_filter) {
      TransactionFilter.all => items,
      TransactionFilter.income =>
        items.where((item) => item.type == TransactionType.income).toList(),
      TransactionFilter.expense =>
        items.where((item) => item.type == TransactionType.expense).toList(),
      TransactionFilter.transfer =>
        items.where((item) => item.type == TransactionType.transfer).toList(),
    };

    final paymentFiltered = switch (_paymentFilter) {
      PaymentFilter.all => filtered,
      PaymentFilter.cash =>
        filtered.where((item) => !_isNonCashTransaction(item)).toList(),
      PaymentFilter.nonCash =>
        filtered.where((item) => _isNonCashTransaction(item)).toList(),
    };

    final sorted = [...paymentFiltered];
    switch (_sort) {
      case TransactionSort.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TransactionSort.amountHigh:
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
      case TransactionSort.amountLow:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return sorted;
  }

  bool _isNonCashTransaction(TransactionItem item) {
    if (item.type == TransactionType.transfer) {
      return true;
    }
    final account = item.account;
    if (account == null || account.trim().isEmpty) {
      return false;
    }
    final lower = account.toLowerCase();
    return !(lower.contains('cash') || lower.contains('kas'));
  }

  List<String> _findRelatedPlanTitles(
    TransactionItem item,
    List<FinancialPlan> plans,
  ) {
    final related = <String>[];
    for (final plan in plans) {
      if (!plan.autoTrackFromTransactions) {
        continue;
      }
      if (item.createdAt.isBefore(_startOfDay(plan.startDate)) ||
          item.createdAt.isAfter(_endOfDay(plan.endDate))) {
        continue;
      }
      final linkedCategory = plan.linkedCategory?.toLowerCase();
      if (linkedCategory != null && linkedCategory.isNotEmpty) {
        final itemCategory = item.category?.toLowerCase();
        if (itemCategory != linkedCategory) {
          continue;
        }
      }
      final linkedAccount = plan.linkedAccount?.toLowerCase();
      if (linkedAccount != null && linkedAccount.isNotEmpty) {
        final itemAccount = item.account?.toLowerCase();
        if (itemAccount != linkedAccount) {
          continue;
        }
      }
      if (plan.type == FinancialPlanType.saving &&
          item.type != TransactionType.income) {
        continue;
      }
      if (plan.type == FinancialPlanType.spendingItem &&
          item.type != TransactionType.expense) {
        continue;
      }
      related.add(plan.title);
    }
    return related;
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus transaksi'),
          content: const Text('Transaksi ini akan dihapus permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await ref.read(transactionsControllerProvider.notifier).remove(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
      }
    }
  }

  Future<void> _showAddTransactionForm(
    BuildContext context,
    WidgetRef ref, {
    TransactionItem? initialItem,
    required List<FinanceAccount> accounts,
    required List<FinanceCategory> categories,
  }) async {
    final form = _AddTransactionForm(
      initialItem: initialItem,
      accounts: accounts,
      categories: categories,
      onSubmit:
          ({
            required title,
            required amount,
            required type,
            notes,
            account,
            category,
            transferToAccount,
            proofImagePath,
          }) async {
            if (initialItem == null) {
              await ref
                  .read(transactionsControllerProvider.notifier)
                  .add(
                    title: title,
                    amount: amount,
                    type: type,
                    notes: notes,
                    account: account,
                    category: category,
                    transferToAccount: transferToAccount,
                    proofImagePath: proofImagePath,
                  );
            } else {
              await ref
                  .read(transactionsControllerProvider.notifier)
                  .editItem(
                    initialItem.copyWith(
                      title: title,
                      amount: amount,
                      type: type,
                      notes: notes,
                      account: account,
                      category: category,
                      transferToAccount: transferToAccount,
                      proofImagePath: proofImagePath,
                    ),
                  );
            }

            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    initialItem == null
                        ? 'Transaksi berhasil ditambahkan'
                        : 'Transaksi berhasil diperbarui',
                  ),
                ),
              );
            }
          },
    );

    final isDesktop = kIsWeb || defaultTargetPlatform == TargetPlatform.windows;
    final title = initialItem == null ? 'Tambah transaksi' : 'Edit transaksi';
    if (isDesktop) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(width: 520, child: form),
          );
        },
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(padding: AppSpacing.p16, child: form),
          ),
        );
      },
    );
  }

  List<_CategoryTotal> _buildExpenseByCategory(List<TransactionItem> items) {
    final grouped = <String, double>{};
    for (final item in items) {
      if (item.type != TransactionType.expense) {
        continue;
      }
      final key = (item.category == null || item.category!.trim().isEmpty)
          ? 'Tanpa kategori'
          : item.category!.trim();
      grouped.update(
        key,
        (value) => value + item.amount,
        ifAbsent: () => item.amount,
      );
    }

    final result = grouped.entries
        .map((entry) => _CategoryTotal(name: entry.key, amount: entry.value))
        .toList();
    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result.take(5).toList();
  }

  List<_DailyCashFlowPoint> _buildCashFlowTrend(List<TransactionItem> items) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final totals = <DateTime, _DailyCashFlowPoint>{};
    for (var i = 0; i < 7; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      totals[day] = _DailyCashFlowPoint(label: '', income: 0, expense: 0);
    }

    for (final item in items) {
      final day = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      if (totals.containsKey(day)) {
        final current = totals[day]!;
        if (item.type == TransactionType.income) {
          totals[day] = current.copyWith(income: current.income + item.amount);
        } else if (item.type == TransactionType.expense) {
          totals[day] = current.copyWith(expense: current.expense + item.amount);
        }
      }
    }

    const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final points = totals.entries
        .map(
          (entry) => _DailyCashFlowPoint(
            label: labels[entry.key.weekday - 1],
            income: entry.value.income,
            expense: entry.value.expense,
          ),
        )
        .toList();
    return points;
  }
}

class _CategoryTotal {
  const _CategoryTotal({required this.name, required this.amount});

  final String name;
  final double amount;
}

class _DailyCashFlowPoint {
  const _DailyCashFlowPoint({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final double income;
  final double expense;

  _DailyCashFlowPoint copyWith({
    String? label,
    double? income,
    double? expense,
  }) {
    return _DailyCashFlowPoint(
      label: label ?? this.label,
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }
}

class _ExpenseByCategoryCard extends StatelessWidget {
  const _ExpenseByCategoryCard({required this.data});

  final List<_CategoryTotal> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.isEmpty
        ? 1.0
        : data.map((item) => item.amount).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: AppSpacing.p12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengeluaran per kategori',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s12),
            if (data.isEmpty)
              const Text('Belum ada data pengeluaran')
            else
              ...data.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.name),
                          Text(CurrencyFormatter.idr(item.amount)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: item.amount / maxValue,
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

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({
    required this.info,
    required this.onUpdate,
    required this.onDismiss,
  });

  final UpdateInfo info;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF9A826)),
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update_rounded, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update tersedia: v${info.latestVersion}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  info.updateMessage,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: onUpdate, child: const Text('Update')),
          IconButton(
            tooltip: 'Sembunyikan',
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _CashFlowTrendCard extends StatelessWidget {
  const _CashFlowTrendCard({required this.data});

  final List<_DailyCashFlowPoint> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.isEmpty
        ? 1.0
        : data
              .map((item) => item.income > item.expense ? item.income : item.expense)
              .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: AppSpacing.p12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tren pemasukan vs pengeluaran (7 hari)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s12),
            SizedBox(
              height: 160,
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
                                            : ((item.income / maxValue) * 100)
                                                  .clamp(2, 100),
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
                                            : ((item.expense / maxValue) * 100)
                                                  .clamp(2, 100),
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
                              Text(
                                item.label,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
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
                const SizedBox(width: 10),
                _LegendDot(color: Color(0xFFDC2626), label: 'Pengeluaran'),
              ],
            ),
          ],
        ),
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

class _AddTransactionForm extends StatefulWidget {
  const _AddTransactionForm({
    required this.onSubmit,
    required this.accounts,
    required this.categories,
    this.initialItem,
  });

  final TransactionItem? initialItem;
  final List<FinanceAccount> accounts;
  final List<FinanceCategory> categories;

  final Future<void> Function({
    required String title,
    required double amount,
    required TransactionType type,
    String? notes,
    String? account,
    String? category,
    String? transferToAccount,
    String? proofImagePath,
  })
  onSubmit;

  @override
  State<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<_AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  var _type = TransactionType.expense;
  String? _selectedAccount;
  String? _selectedCategory;
  String? _selectedTransferToAccount;
  String? _proofImagePath;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _titleController.text = item.title;
      _amountController.text = IdrCurrencyInputFormatter.formatFromInt(
        item.amount.round(),
      );
      _notesController.text = item.notes ?? '';
      _selectedAccount = item.account ?? _defaultCashAccountOrFallback();
      _selectedCategory = item.category;
      _selectedTransferToAccount = item.transferToAccount;
      _proofImagePath = item.proofImagePath;
      _type = item.type;
    } else {
      _selectedAccount = _defaultCashAccountOrFallback();
      _proofImagePath = null;
    }
  }

  String? _defaultCashAccountOrFallback() {
    String? cash;
    for (final item in widget.accounts) {
      final lower = item.name.toLowerCase();
      if (lower.contains('cash') || lower.contains('kas')) {
        cash = item.name;
        break;
      }
    }
    if (cash != null) {
      return cash;
    }
    if (widget.accounts.isNotEmpty) {
      return widget.accounts.first.name;
    }
    return null;
  }

  bool get _requiresProof {
    return _type == TransactionType.transfer;
  }

  bool get _canAttachProof {
    return _type == TransactionType.expense ||
        _type == TransactionType.income ||
        _type == TransactionType.transfer;
  }

  List<FinanceCategory> get _availableCategories {
    if (_type == TransactionType.transfer) {
      return const [];
    }
    return widget.categories.where((item) {
      if (item.scope == CategoryScope.both) {
        return true;
      }
      if (_type == TransactionType.income) {
        return item.scope == CategoryScope.income;
      }
      return item.scope == CategoryScope.expense;
    }).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Pengeluaran'),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Pemasukan'),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text('Transfer'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) {
                setState(() {
                  _type = value.first;
                  _selectedAccount ??= _defaultCashAccountOrFallback();
                  final allowedNames = _availableCategories
                      .map((item) => item.name)
                      .toSet();
                  if (_selectedCategory != null &&
                      !allowedNames.contains(_selectedCategory)) {
                    _selectedCategory = null;
                  }
                  if (_type != TransactionType.transfer) {
                    _selectedTransferToAccount = null;
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.s12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul transaksi'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.s12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                hintText: 'Contoh: 200.000',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                IdrCurrencyInputFormatter(),
              ],
              validator: (value) {
                final parsed = IdrCurrencyInputFormatter.parseToInt(
                  value ?? '',
                );
                if (parsed <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.s12),
            DropdownButtonFormField<String?>(
              initialValue: _selectedAccount,
              decoration: const InputDecoration(labelText: 'Dompet/Rekening'),
              hint: const Text('Pilih dompet/rekening'),
              items: [
                ...widget.accounts.map(
                  (item) => DropdownMenuItem<String?>(
                    value: item.name,
                    child: Text(item.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedAccount = value),
            ),
            if (_selectedAccount != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Akun terpilih: ${_selectedAccount!}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    PaymentModeBadge(isNonCash: _requiresProof),
                  ],
                ),
              ),
            if (_type == TransactionType.transfer) ...[
              const SizedBox(height: AppSpacing.s12),
              DropdownButtonFormField<String?>(
                initialValue: _selectedTransferToAccount,
                decoration: const InputDecoration(
                  labelText: 'Ke dompet/rekening',
                ),
                hint: const Text('Pilih tujuan transfer'),
                items: widget.accounts
                    .where((item) => item.name != _selectedAccount)
                    .map(
                      (item) => DropdownMenuItem<String?>(
                        value: item.name,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedTransferToAccount = value),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.s12),
              DropdownButtonFormField<String?>(
                initialValue:
                    _availableCategories.any(
                      (item) => item.name == _selectedCategory,
                    )
                    ? _selectedCategory
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Kategori (opsional)',
                ),
                hint: const Text('Pilih kategori'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tanpa kategori'),
                  ),
                  ..._availableCategories.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.name,
                      child: Text(item.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _type == TransactionType.transfer
                  ? 'Pilih dompet asal dan tujuan transfer. Bukti gambar wajib dilampirkan.'
                  : 'Bukti gambar pengeluaran/pemasukan bersifat opsional, tetapi disarankan untuk arsip.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_canAttachProof) ...[
              const SizedBox(height: AppSpacing.s12),
              if (_proofImagePath != null) ...[
                GestureDetector(
                  onTap: () => showLocalImageViewer(
                    context,
                    path: _proofImagePath!,
                    title: 'Preview bukti transaksi',
                  ),
                  child: buildLocalImageThumbnail(
                    path: _proofImagePath!,
                    width: 96,
                    height: 96,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _pickProofImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  _proofImagePath == null
                      ? 'Pilih gambar bukti (non-cash)'
                      : 'Ganti gambar bukti',
                ),
              ),
              if (_proofImagePath != null)
                TextButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Hapus bukti gambar'),
                          content: const Text(
                            'Bukti transaksi akan dihapus dari input ini. Lanjutkan?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Batal'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirmed == true && mounted) {
                      setState(() => _proofImagePath = null);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Bukti transaksi dihapus dari input'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Hapus bukti'),
                ),
              if (_proofImagePath != null) ...[
                const SizedBox(height: 4),
                Text(
                  'File bukti: ${_proofImagePath!.split('\\').last}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.s12),
            TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(
                  _isSubmitting
                      ? 'Menyimpan...'
                      : widget.initialItem == null
                      ? 'Simpan transaksi'
                      : 'Simpan perubahan',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_type == TransactionType.transfer) {
      if (_selectedAccount == null || _selectedTransferToAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer butuh akun asal dan tujuan')),
        );
        return;
      }
      if (_selectedAccount == _selectedTransferToAccount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun asal dan tujuan tidak boleh sama'),
          ),
        );
        return;
      }
    }

    if (_selectedAccount == null || _selectedAccount!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet/rekening terlebih dahulu')),
      );
      return;
    }

    if (_requiresProof &&
        (_proofImagePath == null || _proofImagePath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi non-cash wajib lampirkan bukti gambar'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        title: _titleController.text.trim(),
        amount: IdrCurrencyInputFormatter.parseToInt(
          _amountController.text,
        ).toDouble(),
        type: _type,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        account: _selectedAccount,
        category: _type == TransactionType.transfer ? null : _selectedCategory,
        transferToAccount: _type == TransactionType.transfer
            ? _selectedTransferToAccount
            : null,
        proofImagePath: _proofImagePath,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickProofImage() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    final path = picked.files.single.path;
    if (path == null || path.trim().isEmpty) {
      return;
    }
    setState(() => _proofImagePath = path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bukti dipilih: ${path.split('\\').last}')),
      );
    }
  }
}

class _FilterAndSortBar extends StatelessWidget {
  const _FilterAndSortBar({
    required this.filter,
    required this.sort,
    required this.paymentFilter,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onPaymentFilterChanged,
  });

  final TransactionFilter filter;
  final TransactionSort sort;
  final PaymentFilter paymentFilter;
  final ValueChanged<TransactionFilter> onFilterChanged;
  final ValueChanged<TransactionSort> onSortChanged;
  final ValueChanged<PaymentFilter> onPaymentFilterChanged;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 640;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      selected: filter == TransactionFilter.all,
                      onTap: () => onFilterChanged(TransactionFilter.all),
                    ),
                    _FilterChip(
                      label: 'Pemasukan',
                      selected: filter == TransactionFilter.income,
                      onTap: () => onFilterChanged(TransactionFilter.income),
                    ),
                    _FilterChip(
                      label: 'Pengeluaran',
                      selected: filter == TransactionFilter.expense,
                      onTap: () => onFilterChanged(TransactionFilter.expense),
                    ),
                    _FilterChip(
                      label: 'Transfer',
                      selected: filter == TransactionFilter.transfer,
                      onTap: () => onFilterChanged(TransactionFilter.transfer),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Mode pembayaran',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(
                      label: 'Semua mode',
                      selected: paymentFilter == PaymentFilter.all,
                      onTap: () => onPaymentFilterChanged(PaymentFilter.all),
                    ),
                    _FilterChip(
                      label: 'Tunai',
                      selected: paymentFilter == PaymentFilter.cash,
                      onTap: () => onPaymentFilterChanged(PaymentFilter.cash),
                    ),
                    _FilterChip(
                      label: 'Non-tunai',
                      selected: paymentFilter == PaymentFilter.nonCash,
                      onTap: () =>
                          onPaymentFilterChanged(PaymentFilter.nonCash),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                PopupMenuButton<TransactionSort>(
                  initialValue: sort,
                  onSelected: onSortChanged,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: TransactionSort.newest,
                      child: Text('Urutkan: Terbaru'),
                    ),
                    PopupMenuItem(
                      value: TransactionSort.amountHigh,
                      child: Text('Urutkan: Nilai tertinggi'),
                    ),
                    PopupMenuItem(
                      value: TransactionSort.amountLow,
                      child: Text('Urutkan: Nilai terendah'),
                    ),
                  ],
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCCD5E1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_sortLabel(sort)),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<TransactionFilter>(
                        segments: const [
                          ButtonSegment(
                            value: TransactionFilter.all,
                            label: Text('Semua'),
                          ),
                          ButtonSegment(
                            value: TransactionFilter.income,
                            label: Text('Pemasukan'),
                          ),
                          ButtonSegment(
                            value: TransactionFilter.expense,
                            label: Text('Pengeluaran'),
                          ),
                          ButtonSegment(
                            value: TransactionFilter.transfer,
                            label: Text('Transfer'),
                          ),
                        ],
                        selected: {filter},
                        onSelectionChanged: (value) =>
                            onFilterChanged(value.first),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<PaymentFilter>(
                        segments: const [
                          ButtonSegment(
                            value: PaymentFilter.all,
                            label: Text('Semua mode'),
                          ),
                          ButtonSegment(
                            value: PaymentFilter.cash,
                            label: Text('Tunai'),
                          ),
                          ButtonSegment(
                            value: PaymentFilter.nonCash,
                            label: Text('Non-tunai'),
                          ),
                        ],
                        selected: {paymentFilter},
                        onSelectionChanged: (value) =>
                            onPaymentFilterChanged(value.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                DropdownButton<TransactionSort>(
                  value: sort,
                  onChanged: (value) {
                    if (value != null) {
                      onSortChanged(value);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: TransactionSort.newest,
                      child: Text('Terbaru'),
                    ),
                    DropdownMenuItem(
                      value: TransactionSort.amountHigh,
                      child: Text('Nilai tertinggi'),
                    ),
                    DropdownMenuItem(
                      value: TransactionSort.amountLow,
                      child: Text('Nilai terendah'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  String _sortLabel(TransactionSort value) {
    return switch (value) {
      TransactionSort.newest => 'Urutkan: Terbaru',
      TransactionSort.amountHigh => 'Urutkan: Nilai tertinggi',
      TransactionSort.amountLow => 'Urutkan: Nilai terendah',
    };
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

class _MobileHomeHero extends StatelessWidget {
  const _MobileHomeHero({
    required this.totalIncome,
    required this.totalExpense,
    required this.isBalanceVisible,
    required this.onToggleVisibility,
    required this.onCalendarTap,
    required this.onProfileTap,
    required this.onLogout,
  });

  final double totalIncome;
  final double totalExpense;
  final bool isBalanceVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onCalendarTap;
  final VoidCallback onProfileTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final net = totalIncome - totalExpense;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 46, 12, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F756D), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_done_rounded,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Synced',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onCalendarTap,
                icon: const Icon(Icons.calendar_today_rounded),
                color: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Profil akun',
                onPressed: onProfileTap,
                icon: const Icon(Icons.account_circle_rounded),
                color: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Keluar',
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                color: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total Saldo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  isBalanceVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                color: Colors.white,
                iconSize: 18,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            isBalanceVisible ? CurrencyFormatter.idr(net) : '***',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HeroStatCard(
                  label: 'Income',
                  value: isBalanceVisible
                      ? CurrencyFormatter.idr(totalIncome)
                      : '***',
                  color: const Color(0xFFB6F5D8),
                  icon: Icons.arrow_outward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStatCard(
                  label: 'Expense',
                  value: isBalanceVisible
                      ? CurrencyFormatter.idr(totalExpense)
                      : '***',
                  color: const Color(0xFFFECACA),
                  icon: Icons.arrow_outward_rounded,
                  rotateIcon: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.rotateIcon = false,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool rotateIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Transform.rotate(
                angle: rotateIcon ? 3.14159 : 0,
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileInsightCard extends StatelessWidget {
  const _MobileInsightCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const Spacer(),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MobileRecentTransactionTile extends StatelessWidget {
  const _MobileRecentTransactionTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == TransactionType.income;
    final isTransfer = item.type == TransactionType.transfer;
    final amountColor = isTransfer
        ? const Color(0xFF334155)
        : isIncome
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final amountPrefix = isTransfer
        ? ''
        : isIncome
        ? '+ '
        : '- ';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EDF5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: amountColor.withValues(alpha: 0.12),
            child: Icon(
              isTransfer
                  ? Icons.swap_horiz_rounded
                  : isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: amountColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  item.type == TransactionType.transfer
                      ? '${item.account ?? 'Tanpa akun'} • ${item.transferToAccount ?? 'Tanpa akun tujuan'} • ${DateFormat('dd MMM', 'id_ID').format(item.createdAt)}'
                      : '${item.category ?? 'Tanpa kategori'} • ${DateFormat('dd MMM', 'id_ID').format(item.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (item.proofImagePath != null && item.proofImagePath!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: InkWell(
                      onTap: () => showLocalImageViewer(
                        context,
                        path: item.proofImagePath!,
                        title: 'Bukti transaksi',
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildLocalImageThumbnail(
                            path: item.proofImagePath!,
                            width: 36,
                            height: 36,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Lihat bukti',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF0F766E),
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
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix${CurrencyFormatter.idr(item.amount)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined, size: 16),
                    ),
                  ),
                  InkWell(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_rounded, size: 48),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Belum ada transaksi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap tombol tambah untuk membuat catatan pertama kamu.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
