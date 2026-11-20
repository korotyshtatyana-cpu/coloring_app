import 'dart:async';

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../bloc/canvas_bloc.dart';
import '../utils/color_format.dart';
import 'color_picker/library_tab.dart';
import 'color_picker/palette_tab.dart';
import 'color_picker/recent_colors_row.dart';

/// Dialog with a palette tab, a marker library and persistent recent colors.
///
/// The canvas BLoC remains the single source of truth for the selected color;
/// both tabs read it with `context.select` and update it through the same
/// callbacks.
class ColorPickerDialog extends StatefulWidget {
  /// Callback invoked when the eyedropper mode is requested.
  /// Pass [isContour] to let the caller know which layer to update.
  final void Function({required bool isContour})? onEyedropper;

  /// Whether the picker is being used for contour color.
  final bool isContour;

  /// Creates a [ColorPickerDialog].
  const ColorPickerDialog({
    this.isContour = false,
    this.onEyedropper,
    super.key,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog>
    with SingleTickerProviderStateMixin {
  late final RecentColorsService _recentColorsService;
  late final TabController _tabController;
  List<String> _recentColors = const <String>[];
  String? _lastSelectedHex;

  @override
  void initState() {
    super.initState();
    _recentColorsService = context.read<RecentColorsService>();
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_loadRecentColors());
  }

  @override
  void dispose() {
    _tabController.dispose();
    final String? hex = _lastSelectedHex;
    if (hex != null) {
      unawaited(_recentColorsService.remember(hex));
    }
    super.dispose();
  }

  Future<void> _loadRecentColors() async {
    final List<String> colors = await _recentColorsService.load();
    if (mounted) setState(() => _recentColors = colors);
  }

  void _dispatchColor(Color color) {
    final CanvasBloc bloc = context.read<CanvasBloc>();
    if (widget.isContour) {
      bloc.add(ChangeContourSettings(color: color));
    } else {
      bloc.add(ChangeColor(color));
    }
  }

  void _onColorChanged(Color color) => _dispatchColor(color);

  void _onColorSelected(Color color) {
    _dispatchColor(color);
    _lastSelectedHex = ColorFormat.toHex(color);
  }

  void _onEyedropper() {
    Navigator.of(context).pop();
    widget.onEyedropper?.call(isContour: widget.isContour);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors palette = AppColors.of(context);
    final String title = widget.isContour
        ? LocaleKeys.contour.tr()
        : LocaleKeys.color.tr();

    return SizedBox(
      width: 320,
      height: 590,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: palette.primaryText,
              displayColor: palette.primaryText,
            ),
          ),
          child: DefaultTextStyle(
            style: AppFonts.normal16.copyWith(color: palette.primaryText),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        title,
                        style: AppFonts.semiBold20.copyWith(
                          color: palette.primaryText,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: palette.iconPrimary,
                        size: 20,
                      ),
                      tooltip: LocaleKeys.close.tr(),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TabBar(
                  labelStyle: AppFonts.normal14,
                  controller: _tabController,
                  labelColor: palette.iconActive,
                  unselectedLabelColor: palette.primaryText,
                  indicatorColor: palette.iconActive,
                  indicatorPadding: const EdgeInsets.only(bottom: 8),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: <Widget>[
                    Tab(text: LocaleKeys.palette.tr()),
                    Tab(text: LocaleKeys.library.tr()),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _tabController,
                    children: <Widget>[
                      PaletteTab(
                        isContour: widget.isContour,
                        onColorChanged: _onColorChanged,
                        onColorSelected: _onColorSelected,
                      ),
                      LibraryTab(
                        isContour: widget.isContour,
                        onColorSelected: _onColorSelected,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                RecentColorsRow(
                  colors: _recentColors,
                  onSelected: (String hex) {
                    final Color? color = ColorFormat.tryParseHex(hex);
                    if (color != null) _onColorSelected(color);
                  },
                  onEyedropper: _onEyedropper,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
