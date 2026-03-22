import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ContextMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDivider;

  const ContextMenuItem({
    this.label = '',
    this.icon,
    this.onTap,
    this.enabled = true,
    this.isDivider = false,
  });

  const ContextMenuItem.divider()
      : label = '',
        icon = null,
        onTap = null,
        enabled = false,
        isDivider = true;
}

class ContextMenuRegion extends StatelessWidget {
  const ContextMenuRegion({
    super.key,
    required this.child,
    required this.menuItems,
  });

  final Widget child;
  final List<ContextMenuItem> menuItems;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details) =>
          _showContextMenu(context, details.globalPosition),
      child: child,
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final items = <PopupMenuEntry<int>>[];
    for (var i = 0; i < menuItems.length; i++) {
      final item = menuItems[i];
      if (item.isDivider) {
        items.add(const PopupMenuDivider());
      } else {
        items.add(PopupMenuItem<int>(
          value: i,
          enabled: item.enabled,
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
              ],
              Text(item.label),
            ],
          ),
        ));
      }
    }

    showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx, position.dy,
      ),
      items: items,
    ).then((index) {
      if (index != null && menuItems[index].onTap != null) {
        menuItems[index].onTap!();
      }
    });
  }
}
