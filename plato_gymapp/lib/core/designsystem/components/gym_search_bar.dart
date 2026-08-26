import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/shapes.dart';
export '../../../../core/utils/search_utils.dart';

class GymSearchBar extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChange;
  final String placeholderText;

  const GymSearchBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChange,
    this.placeholderText = "Tìm kiếm...",
  });

  @override
  State<GymSearchBar> createState() => _GymSearchBarState();
}

class _GymSearchBarState extends State<GymSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant GymSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Đồng bộ controller nếu text bị thay đổi từ bên ngoài (State của parent)
    if (oldWidget.searchQuery != widget.searchQuery && _controller.text != widget.searchQuery) {
      _controller.text = widget.searchQuery;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      onChanged: widget.onSearchChange,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: widget.placeholderText,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Symbols.search, color: colorScheme.primary),
        // Chỉ hiện nút X khi có text
        suffixIcon: widget.searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Symbols.clear, color: colorScheme.onSurfaceVariant),
                onPressed: () {
                  widget.onSearchChange('');
                  _controller.clear();
                },
              )
            : null,
        filled: true,
        fillColor: colorScheme.surface, // Container Color
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        // Tái sử dụng bo góc Medium từ hệ thống Shape
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent),
          borderRadius: AppShapes.medium.borderRadius.resolve(Directionality.of(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          borderRadius: AppShapes.medium.borderRadius.resolve(Directionality.of(context)),
        ),
      ),
      textInputAction: TextInputAction.search,
    );
  }
}