import 'package:flutter/material.dart';

class PaymentModeBadge extends StatelessWidget {
  const PaymentModeBadge({
    super.key,
    required this.isNonCash,
    this.compact = false,
  });

  final bool isNonCash;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = isNonCash ? 'Non-tunai' : 'Tunai';
    final bgColor = isNonCash ? const Color(0xFFFDE8E8) : const Color(0xFFE8F5E9);
    final textColor = isNonCash ? const Color(0xFFB91C1C) : const Color(0xFF1B5E20);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: (compact
                ? Theme.of(context).textTheme.labelSmall
                : Theme.of(context).textTheme.labelMedium)
            ?.copyWith(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
