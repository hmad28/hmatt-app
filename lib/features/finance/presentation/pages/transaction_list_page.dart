import 'package:app_2/core/constants/app_spacing.dart';
import 'package:app_2/core/utils/currency_formatter.dart';
import 'package:app_2/core/utils/idr_currency_input_formatter.dart';
import 'package:app_2/features/auth/presentation/providers/auth_providers.dart';
import 'package:app_2/features/finance/domain/entities/finance_account.dart';
import 'package:app_2/features/finance/domain/entities/finance_category.dart';
import 'package:app_2/features/finance/domain/entities/transaction_item.dart';
import 'package:app_2/features/finance/presentation/providers/backup_provider.dart';
import 'package:app_2/features/finance/presentation/providers/transaction_providers.dart';
import 'package:app_2/features/finance/presentation/widgets/balance_header.dart';
import 'package:app_2/features/finance/presentation/widgets/transaction_card.dart';
import 'package:app_2/features/update/presentation/providers/app_update_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum TransactionFilter { all, income, expense, transfer }

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

  @override
  Widget build(BuildContext context) {
    final asyncTransactions = ref.watch(transactionsControllerProvider);
    final asyncAccounts = ref.watch(accountsControllerProvider);
    final asyncCategories = ref.watch(categoriesControllerProvider);
    final updateInfo = ref.watch(appUpdateProvider).valueOrNull;
    final accounts = asyncAccounts.valueOrNull ?? const <FinanceAccount>[];
    final categories = asyncCategories.valueOrNull ?? const <FinanceCategory>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        title: const Text('Hmatt'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/');
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          IconButton(
            tooltip: 'Kelola dompet/rekening dan kategori',
            onPressed: () => context.push('/masters'),
            icon: const Icon(Icons.tune_rounded),
          ),
          PopupMenuButton<_BackupAction>(
            tooltip: 'Backup data',
            onSelected: (action) async {
              switch (action) {
                case _BackupAction.export:
                  await _exportBackup(context, ref);
                  break;
                case _BackupAction.import:
                  await _importBackup(context, ref);
                  break;
                case _BackupAction.warning:
                  if (!context.mounted) {
                    return;
                  }
                  await showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Peringatan data lokal'),
                        content: const Text(
                          'Data Hmatt disimpan lokal di perangkat ini. '
                          'Jika aplikasi dihapus atau perangkat berganti tanpa backup, '
                          'data tidak dapat dipulihkan.',
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Mengerti'),
                          ),
                        ],
                      );
                    },
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _BackupAction.export,
                child: Text('Ekspor backup JSON'),
              ),
              PopupMenuItem(
                value: _BackupAction.import,
                child: Text('Impor backup JSON'),
              ),
              PopupMenuItem(
                value: _BackupAction.warning,
                child: Text('Lihat peringatan data'),
              ),
            ],
            icon: const Icon(Icons.backup_rounded),
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
          padding: AppSpacing.p16,
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
            final weeklyTrend = _buildWeeklyTrend(items);
            final hasExpenseData = expenseByCategory.isNotEmpty;
            final hasWeeklyExpense = weeklyTrend.any((item) => item.amount > 0);
            final isWide = MediaQuery.sizeOf(context).width >= 900;

            return ListView(
              children: [
                if (updateInfo != null && updateInfo.shouldShowBanner)
                  _UpdateBanner(
                    info: updateInfo,
                    onUpdate: () async {
                      await ref.read(appUpdateProvider.notifier).openUpdateUrl();
                    },
                    onDismiss: () async {
                      await ref.read(appUpdateProvider.notifier).dismissBanner();
                    },
                  ),
                if (updateInfo != null && updateInfo.shouldShowBanner)
                  const SizedBox(height: AppSpacing.s12),
                BalanceHeader(
                  totalIncome: totalIncome,
                  totalExpense: totalExpense,
                ),
                const SizedBox(height: AppSpacing.s16),
                if (hasExpenseData || hasWeeklyExpense)
                  if (isWide)
                    Row(
                      children: [
                        if (hasExpenseData)
                          Expanded(
                            child: _ExpenseByCategoryCard(data: expenseByCategory),
                          ),
                        if (hasExpenseData && hasWeeklyExpense)
                          const SizedBox(width: AppSpacing.s12),
                        if (hasWeeklyExpense)
                          Expanded(child: _WeeklyTrendCard(data: weeklyTrend)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        if (hasExpenseData)
                          _ExpenseByCategoryCard(data: expenseByCategory),
                        if (hasExpenseData && hasWeeklyExpense)
                          const SizedBox(height: AppSpacing.s12),
                        if (hasWeeklyExpense) _WeeklyTrendCard(data: weeklyTrend),
                      ],
                    ),
                if (hasExpenseData || hasWeeklyExpense)
                  const SizedBox(height: AppSpacing.s16),
                _FilterAndSortBar(
                  filter: _filter,
                  sort: _sort,
                  onFilterChanged: (value) => setState(() => _filter = value),
                  onSortChanged: (value) => setState(() => _sort = value),
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
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == visibleItems.length - 1
                            ? 0
                            : AppSpacing.s12,
                      ),
                      child: TransactionCard(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionForm(
          context,
          ref,
          accounts: accounts,
          categories: categories,
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final path = await ref
          .read(backupControllerProvider)
          .exportCurrentUserData();
      if (!context.mounted || path == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup berhasil disimpan: $path')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ekspor backup: $error')),
      );
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Impor backup'),
          content: const Text(
            'Impor akan menimpa seluruh akun, kategori, dan transaksi user yang sedang login. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Lanjut impor'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    try {
      final path = await ref
          .read(backupControllerProvider)
          .importCurrentUserData();
      if (!context.mounted || path == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup berhasil diimpor dari: $path')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal impor backup: $error')),
      );
    }
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

    final sorted = [...filtered];
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
    WidgetRef ref,
    {
    TransactionItem? initialItem,
    required List<FinanceAccount> accounts,
    required List<FinanceCategory> categories,
  }
  ) async {
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
      grouped.update(key, (value) => value + item.amount, ifAbsent: () => item.amount);
    }

    final result = grouped.entries
        .map((entry) => _CategoryTotal(name: entry.key, amount: entry.value))
        .toList();
    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result.take(5).toList();
  }

  List<_DailyExpensePoint> _buildWeeklyTrend(List<TransactionItem> items) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    final totals = <DateTime, double>{};
    for (var i = 0; i < 7; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      totals[day] = 0;
    }

    for (final item in items) {
      if (item.type != TransactionType.expense) {
        continue;
      }
      final day = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      if (totals.containsKey(day)) {
        totals.update(day, (value) => value + item.amount);
      }
    }

    const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final points = totals.entries
        .map(
          (entry) => _DailyExpensePoint(
            label: labels[entry.key.weekday - 1],
            amount: entry.value,
          ),
        )
        .toList();
    return points;
  }
}

enum _BackupAction { export, import, warning }

class _CategoryTotal {
  const _CategoryTotal({required this.name, required this.amount});

  final String name;
  final double amount;
}

class _DailyExpensePoint {
  const _DailyExpensePoint({required this.label, required this.amount});

  final String label;
  final double amount;
}

class _ExpenseByCategoryCard extends StatelessWidget {
  const _ExpenseByCategoryCard({required this.data});

  final List<_CategoryTotal> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.isEmpty
        ? 1.0
        : data
              .map((item) => item.amount)
              .reduce((a, b) => a > b ? a : b);

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
          FilledButton(
            onPressed: onUpdate,
            child: const Text('Update'),
          ),
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

class _WeeklyTrendCard extends StatelessWidget {
  const _WeeklyTrendCard({required this.data});

  final List<_DailyExpensePoint> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.isEmpty
        ? 1.0
        : data
              .map((item) => item.amount)
              .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: AppSpacing.p12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tren pengeluaran 7 hari',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s12),
            SizedBox(
              height: 140,
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
                                  child: Container(
                                    width: 16,
                                    height: maxValue == 0
                                        ? 2
                                        : ((item.amount / maxValue) * 100)
                                              .clamp(2, 100),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
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
          ],
        ),
      ),
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
      _selectedAccount = item.account;
      _selectedCategory = item.category;
      _selectedTransferToAccount = item.transferToAccount;
      _type = item.type;
    }
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
                final parsed = IdrCurrencyInputFormatter.parseToInt(value ?? '');
                if (parsed <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.s12),
            DropdownButtonFormField<String?>(
              initialValue: _selectedAccount,
              decoration: const InputDecoration(
                labelText: 'Dompet/Rekening',
              ),
              hint: const Text('Pilih dompet/rekening'),
              items: [
                if (_type != TransactionType.transfer)
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tanpa dompet/rekening'),
                  ),
                ...widget.accounts.map(
                  (item) => DropdownMenuItem<String?>(
                    value: item.name,
                    child: Text(item.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedAccount = value),
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
                initialValue: _availableCategories.any(
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
                  ? 'Pilih dompet asal dan tujuan transfer.'
                  : 'Kelola dompet/rekening dan kategori dari tombol pengaturan di AppBar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
          const SnackBar(
            content: Text('Transfer butuh akun asal dan tujuan'),
          ),
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
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _FilterAndSortBar extends StatelessWidget {
  const _FilterAndSortBar({
    required this.filter,
    required this.sort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final TransactionFilter filter;
  final TransactionSort sort;
  final ValueChanged<TransactionFilter> onFilterChanged;
  final ValueChanged<TransactionSort> onSortChanged;

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
                Text(
                  'Filter',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
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
                  child: SegmentedButton<TransactionFilter>(
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
                    onSelectionChanged: (value) => onFilterChanged(value.first),
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
