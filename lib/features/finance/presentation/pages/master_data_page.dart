import 'package:app_2/core/constants/app_spacing.dart';
import 'package:app_2/core/utils/currency_formatter.dart';
import 'package:app_2/features/finance/domain/entities/finance_account.dart';
import 'package:app_2/features/finance/domain/entities/finance_category.dart';
import 'package:app_2/features/finance/domain/entities/transaction_item.dart';
import 'package:app_2/features/finance/presentation/providers/transaction_providers.dart';
import 'package:app_2/features/finance/presentation/widgets/mobile_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MasterDataPage extends ConsumerWidget {
  const MasterDataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MobileBottomNav.isEnabledFor(context);
    final accountsAsync = ref.watch(accountsControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final transactions =
        ref.watch(transactionsControllerProvider).valueOrNull ??
        const <TransactionItem>[];

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (tabContext) {
          return Scaffold(
            appBar: isMobile
                ? null
                : AppBar(
                    title: const Text('Data Master'),
                    bottom: const TabBar(
                      tabs: [
                        Tab(text: 'Dompet/Rekening'),
                        Tab(text: 'Kategori'),
                      ],
                    ),
                  ),
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
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(34),
                        ),
                      ),
                      child: const Text(
                        'Data Master',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: const Color(0xFF0F766E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF475569),
                      tabs: const [
                        Tab(text: 'Dompet/Rekening'),
                        Tab(text: 'Kategori'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _AccountsTab(
                          asyncValue: accountsAsync,
                          transactions: transactions,
                          onAdd: (name) async {
                            await ref
                                .read(accountsControllerProvider.notifier)
                                .add(name);
                          },
                          onDelete: (id) async {
                            await ref
                                .read(accountsControllerProvider.notifier)
                                .delete(id);
                          },
                        ),
                        _CategoriesTab(
                          asyncValue: categoriesAsync,
                          onAdd: ({required name, required scope}) async {
                            await ref
                                .read(categoriesControllerProvider.notifier)
                                .add(name: name, scope: scope);
                          },
                          onDelete: (id) async {
                            await ref
                                .read(categoriesControllerProvider.notifier)
                                .delete(id);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: isMobile
                ? MobileBottomNav(
                    selectedIndex: 1,
                    addTooltip: 'Tambah data',
                    onAddPressed: () async {
                      final controller = DefaultTabController.of(tabContext);
                      if (controller.index == 0) {
                        await _showAddAccountDialog(tabContext, (name) async {
                          await ref
                              .read(accountsControllerProvider.notifier)
                              .add(name);
                        });
                        return;
                      }
                      await _showAddCategoryDialog(tabContext, ({
                        required name,
                        required scope,
                      }) async {
                        await ref
                            .read(categoriesControllerProvider.notifier)
                            .add(name: name, scope: scope);
                      });
                    },
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _AccountsTab extends StatelessWidget {
  const _AccountsTab({
    required this.asyncValue,
    required this.transactions,
    required this.onAdd,
    required this.onDelete,
  });

  final AsyncValue<List<FinanceAccount>> asyncValue;
  final List<TransactionItem> transactions;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Terjadi error: $error')),
      data: (items) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Belum ada dompet/rekening'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.s8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final balance = _balanceByAccount(item.name);
                          final accent = _walletAccent(item.name);
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE6EDF5),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 94,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(18),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: accent.withValues(
                                        alpha: 0.14,
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: accent,
                                      ),
                                    ),
                                    title: Text(
                                      item.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    subtitle: Text(
                                      'Current Balance\n${CurrencyFormatter.idr(balance)}',
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Hapus dompet/rekening',
                                      onPressed: () => _confirmDeleteAccount(
                                        context,
                                        item,
                                        onDelete,
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _walletAccent(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cash') ||
        lower.contains('kas') ||
        lower.contains('dompet')) {
      return const Color(0xFF10B981);
    }
    if (lower.contains('bca') ||
        lower.contains('bni') ||
        lower.contains('bank')) {
      return const Color(0xFF2563EB);
    }
    if (lower.contains('gopay') ||
        lower.contains('ovo') ||
        lower.contains('dana')) {
      return const Color(0xFF0EA5E9);
    }
    return const Color(0xFF64748B);
  }

  double _balanceByAccount(String accountName) {
    var total = 0.0;
    for (final item in transactions) {
      if (item.type == TransactionType.transfer) {
        if (item.account == accountName) {
          total -= item.amount;
        }
        if (item.transferToAccount == accountName) {
          total += item.amount;
        }
        continue;
      }
      if (item.account != accountName) {
        continue;
      }
      if (item.type == TransactionType.income) {
        total += item.amount;
      } else if (item.type == TransactionType.expense) {
        total -= item.amount;
      }
    }
    return total;
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    FinanceAccount item,
    Future<void> Function(String id) onDelete,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus dompet/rekening'),
          content: Text('Dompet/Rekening "${item.name}" akan dihapus.'),
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

    if (result == true) {
      await onDelete(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dompet/Rekening berhasil dihapus')),
        );
      }
    }
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab({
    required this.asyncValue,
    required this.onAdd,
    required this.onDelete,
  });

  final AsyncValue<List<FinanceCategory>> asyncValue;
  final Future<void> Function({
    required String name,
    required CategoryScope scope,
  })
  onAdd;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Terjadi error: $error')),
      data: (items) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Belum ada kategori'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.s8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE6EDF5),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 21,
                                backgroundColor: _categoryAccent(
                                  item.scope,
                                ).withValues(alpha: 0.14),
                                child: Icon(
                                  Icons.label_outline_rounded,
                                  color: _categoryAccent(item.scope),
                                ),
                              ),
                              title: Text(
                                item.name,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                _labelForScope(item.scope),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: IconButton(
                                tooltip: 'Hapus kategori',
                                onPressed: () => _confirmDeleteCategory(
                                  context,
                                  item,
                                  onDelete,
                                ),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _labelForScope(CategoryScope scope) {
    return switch (scope) {
      CategoryScope.income => 'Pemasukan',
      CategoryScope.expense => 'Pengeluaran',
      CategoryScope.both => 'Pemasukan & Pengeluaran',
    };
  }

  Color _categoryAccent(CategoryScope scope) {
    return switch (scope) {
      CategoryScope.income => const Color(0xFF10B981),
      CategoryScope.expense => const Color(0xFFEF4444),
      CategoryScope.both => const Color(0xFF0F766E),
    };
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    FinanceCategory item,
    Future<void> Function(String id) onDelete,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus kategori'),
          content: Text('Kategori "${item.name}" akan dihapus.'),
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

    if (result == true) {
      await onDelete(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori berhasil dihapus')),
        );
      }
    }
  }
}

Future<void> _showAddAccountDialog(
  BuildContext context,
  Future<void> Function(String name) onAdd,
) async {
  final controller = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Tambah dompet/rekening'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama dompet/rekening'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              await onAdd(controller.text);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      );
    },
  );
  controller.dispose();
}

Future<void> _showAddCategoryDialog(
  BuildContext context,
  Future<void> Function({required String name, required CategoryScope scope})
  onAdd,
) async {
  final controller = TextEditingController();
  var scope = CategoryScope.expense;
  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Tambah kategori'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Nama kategori'),
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.s12),
                DropdownButtonFormField<CategoryScope>(
                  initialValue: scope,
                  decoration: const InputDecoration(labelText: 'Tipe kategori'),
                  items: const [
                    DropdownMenuItem(
                      value: CategoryScope.expense,
                      child: Text('Pengeluaran'),
                    ),
                    DropdownMenuItem(
                      value: CategoryScope.income,
                      child: Text('Pemasukan'),
                    ),
                    DropdownMenuItem(
                      value: CategoryScope.both,
                      child: Text('Keduanya'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => scope = value);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () async {
                  await onAdd(name: controller.text, scope: scope);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
}
