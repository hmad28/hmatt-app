import 'package:app_2/core/constants/app_spacing.dart';
import 'package:app_2/core/utils/currency_formatter.dart';
import 'package:app_2/core/utils/idr_currency_input_formatter.dart';
import 'package:app_2/features/finance/domain/entities/financial_plan.dart';
import 'package:app_2/features/finance/presentation/providers/financial_plan_providers.dart';
import 'package:app_2/features/finance/presentation/widgets/mobile_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PlanStatusFilter { all, active, completed }

class FinancialPlanPage extends ConsumerStatefulWidget {
  const FinancialPlanPage({super.key});

  @override
  ConsumerState<FinancialPlanPage> createState() => _FinancialPlanPageState();
}

class _FinancialPlanPageState extends ConsumerState<FinancialPlanPage> {
  var _statusFilter = PlanStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final isMobile = MobileBottomNav.isEnabledFor(context);
    final asyncPlans = ref.watch(financialPlansControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: isMobile ? null : AppBar(title: const Text('Rencana Keuangan')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FBFC), Color(0xFFEFF3FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: asyncPlans.when(
            data: (plans) {
              final visiblePlans = _applyStatusFilter(plans);
              final totalAllPlans = plans.fold<double>(
                0,
                (sum, item) => sum + item.targetAmount,
              );

              return Column(
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
                        'Perencanaan Keuangan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  if (isMobile) const SizedBox(height: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          _PlanTotalCard(total: totalAllPlans, count: plans.length),
                          const SizedBox(height: AppSpacing.s12),
                          _PlanStatusFilterBar(
                            filter: _statusFilter,
                            onChanged: (value) =>
                                setState(() => _statusFilter = value),
                          ),
                          const SizedBox(height: AppSpacing.s12),
                          Expanded(
                            child: visiblePlans.isEmpty
                                ? const _EmptyPlanState()
                                : ListView.separated(
                                    itemCount: visiblePlans.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: AppSpacing.s12),
                                    itemBuilder: (context, index) {
                                      final item = visiblePlans[index];
                                      return _PlanCard(
                                        plan: item,
                                        onToggleCompleted: () async {
                                          final nextStatus = item.status ==
                                                  FinancialPlanStatus.completed
                                              ? FinancialPlanStatus.active
                                              : FinancialPlanStatus.completed;
                                          await ref
                                              .read(
                                                financialPlansControllerProvider
                                                    .notifier,
                                              )
                                              .updatePlan(
                                                item.copyWith(status: nextStatus),
                                              );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            error: (error, stackTrace) =>
                Center(child: Text('Terjadi error: $error')),
            loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
      floatingActionButton: isMobile
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showPlanDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Plan'),
            ),
      bottomNavigationBar: isMobile
          ? MobileBottomNav(
              selectedIndex: 2,
              addTooltip: 'Tambah plan',
              onAddPressed: () => _showPlanDialog(context),
            )
          : null,
    );
  }

  List<FinancialPlan> _applyStatusFilter(List<FinancialPlan> plans) {
    return plans.where((item) {
      return switch (_statusFilter) {
        PlanStatusFilter.all => true,
        PlanStatusFilter.active => item.status == FinancialPlanStatus.active,
        PlanStatusFilter.completed =>
          item.status == FinancialPlanStatus.completed,
      };
    }).toList();
  }

  Future<void> _showPlanDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    var priority = PlanPriority.medium;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Tambah Plan Keuangan'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Apa rencana ini untuk?',
                          hintText: 'Contoh: Beli laptop baru',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          IdrCurrencyInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Harga',
                          prefixText: 'Rp ',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      DropdownButtonFormField<PlanPriority>(
                        initialValue: priority,
                        decoration: const InputDecoration(
                          labelText: 'Prioritas',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: PlanPriority.low,
                            child: Text('Rendah'),
                          ),
                          DropdownMenuItem(
                            value: PlanPriority.medium,
                            child: Text('Sedang'),
                          ),
                          DropdownMenuItem(
                            value: PlanPriority.high,
                            child: Text('Tinggi'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setLocalState(() => priority = value);
                        },
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
                    final amount = IdrCurrencyInputFormatter.parseToInt(
                      amountController.text,
                    );
                    if (title.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lengkapi nama rencana dan harga.'),
                        ),
                      );
                      return;
                    }

                    await ref
                        .read(financialPlansControllerProvider.notifier)
                        .addPlan(
                          title: title,
                          targetAmount: amount.toDouble(),
                          priority: priority,
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

class _PlanTotalCard extends StatelessWidget {
  const _PlanTotalCard({required this.total, required this.count});

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total dana yang dibutuhkan',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.idr(total),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 4),
          Text('$count rencana tersimpan'),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onToggleCompleted,
  });

  final FinancialPlan plan;
  final Future<void> Function() onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final isCompleted = plan.status == FinancialPlanStatus.completed;
    final (priorityLabel, priorityColor) = switch (plan.priority) {
      PlanPriority.low => ('Rendah', const Color(0xFF475569)),
      PlanPriority.medium => ('Sedang', const Color(0xFF0F766E)),
      PlanPriority.high => ('Tinggi', const Color(0xFFB91C1C)),
    };

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
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Prioritas $priorityLabel',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: priorityColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.idr(plan.targetAmount),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF0F766E),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await onToggleCompleted();
                },
                icon: Icon(
                  isCompleted
                      ? Icons.radio_button_unchecked_rounded
                      : Icons.check_circle_rounded,
                ),
                label: Text(isCompleted ? 'Tandai belum selesai' : 'Tandai selesai'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanStatusFilterBar extends StatelessWidget {
  const _PlanStatusFilterBar({required this.filter, required this.onChanged});

  final PlanStatusFilter filter;
  final ValueChanged<PlanStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SegmentedButton<PlanStatusFilter>(
        segments: const [
          ButtonSegment(value: PlanStatusFilter.all, label: Text('Semua')),
          ButtonSegment(value: PlanStatusFilter.active, label: Text('Aktif')),
          ButtonSegment(
            value: PlanStatusFilter.completed,
            label: Text('Selesai'),
          ),
        ],
        selected: {filter},
        onSelectionChanged: (value) => onChanged(value.first),
      ),
    );
  }
}

class _EmptyPlanState extends StatelessWidget {
  const _EmptyPlanState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Belum ada plan. Tekan tombol tambah untuk membuat plan.'),
    );
  }
}
