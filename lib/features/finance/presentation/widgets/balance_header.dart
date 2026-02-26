import 'package:app_2/core/constants/app_spacing.dart';
import 'package:app_2/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

class BalanceHeader extends StatelessWidget {
  const BalanceHeader({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.isBalanceVisible,
    required this.onToggleVisibility,
  });

  final double totalIncome;
  final double totalExpense;
  final bool isBalanceVisible;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final net = totalIncome - totalExpense;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F766E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                'Tersimpan lokal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Total Saldo',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isBalanceVisible ? CurrencyFormatter.idr(net) : '***',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: TextButton.icon(
              onPressed: onToggleVisibility,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(
                isBalanceVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
              ),
              label: Text(
                isBalanceVisible ? 'Sembunyikan saldo' : 'Tampilkan saldo',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pemasukan',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFB6F5D8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBalanceVisible
                            ? CurrencyFormatter.idr(totalIncome)
                            : '***',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengeluaran',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFFECACA),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBalanceVisible
                            ? CurrencyFormatter.idr(totalExpense)
                            : '***',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
