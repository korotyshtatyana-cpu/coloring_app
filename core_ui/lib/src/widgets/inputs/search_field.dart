import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Search input field with a search icon, clear button and debounced changes.
class SearchField extends StatefulWidget {
  /// Initial text value.
  final String? value;

  /// Hint text shown when empty.
  final String hintText;

  /// Callback invoked after the user stops typing for [debounce] duration.
  final ValueChanged<String>? onChanged;

  /// Callback when the user submits the query.
  final ValueChanged<String>? onSubmitted;

  /// Debounce duration for [onChanged].
  final Duration debounce;

  /// Creates a [SearchField].
  const SearchField({
    this.value,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.debounce = const Duration(milliseconds: 300),
    super.key,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value &&
        widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    _debounceTimer?.cancel();
    if (widget.onChanged == null) return;
    _debounceTimer = Timer(widget.debounce, () {
      widget.onChanged!(_controller.text);
    });
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool hasText = _controller.text.isNotEmpty;

    return TextField(
      controller: _controller,
      onSubmitted: widget.onSubmitted,
      style: AppFonts.normal16.copyWith(color: colors.primaryText),
      cursorColor: colors.green,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppFonts.normal16.copyWith(color: colors.secondaryText),
        prefixIcon: Icon(Icons.search, color: colors.secondaryText),
        suffixIcon: hasText
            ? IconButton(
                icon: Icon(Icons.clear, color: colors.secondaryText),
                onPressed: _clear,
              )
            : null,
        filled: true,
        fillColor: colors.secondaryBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide(color: colors.green.withValues(alpha: 0.5)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
