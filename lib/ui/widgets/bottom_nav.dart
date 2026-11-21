import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

@immutable
class NavItem {
  const NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Bottom navigation: the selected item pops (scale bounce) and turns green.
class OobliBottomNav extends StatelessWidget {
  const OobliBottomNav({super.key, required this.items, required this.currentIndex, required this.onTap});

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.onTap});

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final color = selected ? c.primary : c.secondaryText;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1,
              duration: Motion.medium,
              curve: Motion.emphasized,
              child: Icon(item.icon, color: color, size: 26),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: Motion.fast,
              style: selected
                  ? t.titleSmall.copyWith(color: color, fontWeight: FontWeight.w800)
                  : t.labelMedium.copyWith(color: color),
              child: Text(item.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
