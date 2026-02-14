import 'package:app_2/core/constants/app_spacing.dart';
import 'package:app_2/features/finance/domain/entities/finance_account.dart';
import 'package:app_2/features/finance/domain/entities/finance_category.dart';
import 'package:app_2/features/finance/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MasterDataPage extends ConsumerWidget {
  const MasterDataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Master Data'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dompet/Rekening'),
              Tab(text: 'Kategori'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AccountsTab(
              asyncValue: accountsAsync,
              onAdd: (name) async {
                await ref.read(accountsControllerProvider.notifier).add(name);
              },
              onDelete: (id) async {
                await ref.read(accountsControllerProvider.notifier).delete(id);
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
                await ref.read(categoriesControllerProvider.notifier).delete(id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsTab extends StatelessWidget {
  const _AccountsTab({
    required this.asyncValue,
    required this.onAdd,
    required this.onDelete,
  });

  final AsyncValue<List<FinanceAccount>> asyncValue;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Terjadi error: $error')),
      data: (items) {
        return Padding(
          padding: AppSpacing.p16,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _showAddAccountDialog(context, onAdd),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah dompet/rekening'),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Belum ada dompet/rekening'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.s8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            tileColor: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: const Icon(Icons.account_balance_wallet),
                            title: Text(item.name),
                            trailing: IconButton(
                              tooltip: 'Hapus dompet/rekening',
                              onPressed: () =>
                                  _confirmDeleteAccount(context, item, onDelete),
                              icon: const Icon(Icons.delete_outline_rounded),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
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
  }) onAdd;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Terjadi error: $error')),
      data: (items) {
        return Padding(
          padding: AppSpacing.p16,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _showAddCategoryDialog(context, onAdd),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah kategori'),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Belum ada kategori'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.s8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            tileColor: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: const Icon(Icons.label_outline_rounded),
                            title: Text(item.name),
                            subtitle: Text(_labelForScope(item.scope)),
                            trailing: IconButton(
                              tooltip: 'Hapus kategori',
                              onPressed: () =>
                                  _confirmDeleteCategory(context, item, onDelete),
                              icon: const Icon(Icons.delete_outline_rounded),
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

  Future<void> _showAddCategoryDialog(
    BuildContext context,
    Future<void> Function({
      required String name,
      required CategoryScope scope,
    }) onAdd,
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

  String _labelForScope(CategoryScope scope) {
    return switch (scope) {
      CategoryScope.income => 'Pemasukan',
      CategoryScope.expense => 'Pengeluaran',
      CategoryScope.both => 'Pemasukan & Pengeluaran',
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
