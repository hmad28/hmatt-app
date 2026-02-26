import 'package:app_2/core/constants/app_spacing.dart';
import 'package:app_2/core/utils/currency_formatter.dart';
import 'package:app_2/core/utils/local_image_preview.dart';
import 'package:app_2/features/finance/domain/entities/transaction_item.dart';
import 'package:app_2/features/finance/presentation/widgets/payment_mode_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.planHints = const <String>[],
  });

  final TransactionItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final List<String> planHints;

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == TransactionType.income;
    final isTransfer = item.type == TransactionType.transfer;
    final isNonCash = isTransfer || !_isCashAccount(item.account);
    final color = isTransfer
        ? const Color(0xFF334155)
        : isIncome
        ? const Color(0xFF197B4B)
        : const Color(0xFFB23A48);
    final dateText = _formatDate(item.createdAt);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(width: 4, height: 138, color: color.withValues(alpha: 0.9)),
          Expanded(
            child: Padding(
              padding: AppSpacing.p12,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(
                      isTransfer
                          ? Icons.swap_horiz_rounded
                          : isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTransfer
                              ? '${item.account ?? 'Tanpa akun'} -> ${item.transferToAccount ?? 'Tanpa akun tujuan'}'
                              : item.account == null
                              ? (item.category ?? 'Tanpa kategori')
                              : '${item.account} • ${item.category ?? 'Tanpa kategori'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        PaymentModeBadge(isNonCash: isNonCash, compact: true),
                        if (item.proofImagePath != null &&
                            item.proofImagePath!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: InkWell(
                              onTap: () => showLocalImageViewer(
                                context,
                                path: item.proofImagePath!,
                                title: item.title,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  buildLocalImageThumbnail(
                                    path: item.proofImagePath!,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Bukti: ${item.proofImagePath!.split('\\').last}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (planHints.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ...planHints
                                  .take(2)
                                  .map(
                                    (name) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6F3EC),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        'Plan: $name',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: const Color(0xFF1F6F43),
                                            ),
                                      ),
                                    ),
                                  ),
                              if (planHints.length > 2)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '+${planHints.length - 2} plan',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          dateText,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isTransfer
                            ? ''
                            : isIncome
                            ? '+'
                            : '-'}${CurrencyFormatter.idr(item.amount)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Edit transaksi',
                            onPressed: onEdit,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Hapus transaksi',
                            onPressed: onDelete,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(value);
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm').format(value);
    }
  }

  bool _isCashAccount(String? account) {
    if (account == null || account.trim().isEmpty) {
      return true;
    }
    final lower = account.toLowerCase();
    return lower.contains('cash') || lower.contains('kas');
  }
}
