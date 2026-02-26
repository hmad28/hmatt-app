import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onAddPressed,
    this.addTooltip = 'Tambah',
    this.hideWhenKeyboardOpen = true,
  });

  final int selectedIndex;
  final VoidCallback onAddPressed;
  final String addTooltip;
  final bool hideWhenKeyboardOpen;

  static bool isEnabledFor(BuildContext context) {
    if (kIsWeb) {
      return false;
    }
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isPreviewMobile =
        DevicePreview.isEnabled(context) &&
        MediaQuery.sizeOf(context).width <= 700;
    return isAndroid || isPreviewMobile;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (hideWhenKeyboardOpen && keyboardOpen) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 20,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      selected: selectedIndex == 0,
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'Home',
                      onTap: () => _go(context, 0),
                    ),
                    _NavItem(
                      selected: selectedIndex == 1,
                      icon: Icons.list_alt_outlined,
                      selectedIcon: Icons.list_alt,
                      label: 'Master',
                      onTap: () => _go(context, 1),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -16),
                child: Tooltip(
                  message: addTooltip,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: onAddPressed,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x330F766E),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      selected: selectedIndex == 2,
                      icon: Icons.assignment_outlined,
                      selectedIcon: Icons.assignment,
                      label: 'Plan',
                      onTap: () => _go(context, 2),
                    ),
                    _NavItem(
                      selected: selectedIndex == 3,
                      icon: Icons.bar_chart_outlined,
                      selectedIcon: Icons.bar_chart,
                      label: 'Stats',
                      onTap: () => _go(context, 3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, int index) {
    if (index == selectedIndex) {
      return;
    }
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/masters');
        break;
      case 2:
        context.go('/plans');
        break;
      case 3:
        context.go('/stats');
        break;
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selected ? selectedIcon : icon, color: color, size: 24),
          const SizedBox(height: 1),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
