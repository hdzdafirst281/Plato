import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_tour_target.dart';

class GymTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Color? backgroundColor;
  final IconData navIcon;
  final VoidCallback? onBackClick;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  // THÊM: Các thuộc tính để bọc Guide Tour cho nút Back
  final GlobalKey? navTourKey;
  final String? navTourTitle;
  final String? navTourDesc;

  const GymTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.backgroundColor,
    this.navIcon = Symbols.arrow_back,
    this.onBackClick,
    this.actions,
    this.bottom,
    this.navTourKey,
    this.navTourTitle,
    this.navTourDesc,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Build nút Back
    Widget? leadingWidget;
    if (onBackClick != null) {
      final iconBtn = IconButton(
        icon: Icon(navIcon, color: colorScheme.onSurface),
        onPressed: onBackClick,
      );

      // Bọc TourTarget nếu có truyền Key (Sử dụng bo góc mặc định 8.0 tạo ô vuông mềm)
      if (navTourKey != null && navTourTitle != null && navTourDesc != null) {
        leadingWidget = GymTourTarget(
          tourKey: navTourKey!,
          title: navTourTitle!,
          description: navTourDesc!,
          targetPadding: EdgeInsets.zero,
          child: iconBtn,
        );
      } else {
        leadingWidget = iconBtn;
      }
    }

    return AppBar(
      backgroundColor: backgroundColor ?? colorScheme.surfaceContainerHighest,
      scrolledUnderElevation: 0, 
      centerTitle: true,
      elevation: 0,
      leading: leadingWidget,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}