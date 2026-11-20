import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../bloc/canvas_bloc.dart';
import '../../utils/color_format.dart';

/// Palette tab with the saturation square, hue/value sliders and hex input.
class PaletteTab extends StatefulWidget {
  /// Creates the palette tab.
  const PaletteTab({
    required this.isContour,
    required this.onColorChanged,
    required this.onColorSelected,
    super.key,
  });

  /// Whether the picker edits the contour color instead of the brush color.
  final bool isContour;

  /// Called while a color is being changed, before it is committed.
  final ValueChanged<Color> onColorChanged;

  /// Called when the user finishes choosing a color.
  final ValueChanged<Color> onColorSelected;

  @override
  State<PaletteTab> createState() => _PaletteTabState();
}

class _PaletteTabState extends State<PaletteTab> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  HSVColor? _hsvColor;

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _syncFromColor(Color color) {
    if (_hsvColor == null ||
        (_hsvColor!.toColor().toARGB32() != color.toARGB32() &&
            color.toARGB32() != 0xFF000000)) {
      _hsvColor = HSVColor.fromColor(color);
    } else if (color.toARGB32() == 0xFF000000) {
      _hsvColor = _hsvColor!.withValue(0);
    }
    if (!_textFocusNode.hasFocus) {
      _textController.text = ColorFormat.toHex(color);
    }
  }

  void _onHsvChanged(HSVColor color) {
    setState(() => _hsvColor = color);
    widget.onColorChanged(color.toColor());
  }

  void _commitHsv() {
    final HSVColor? hsv = _hsvColor;
    if (hsv != null) widget.onColorSelected(hsv.toColor());
  }

  void _onTextChanged(String value) {
    final Color? color = ColorFormat.tryParseHex(value);
    if (color != null) widget.onColorChanged(color);
  }

  void _onTextSubmitted(String value) {
    final Color? color = ColorFormat.tryParseHex(value);
    if (color != null) widget.onColorSelected(color);
  }

  Future<void> _copyValueToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _textController.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleKeys.copied_to_clipboard.tr(),
            style: AppFonts.normal16.copyWith(color: Colors.white),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color currentColor = context.select(
      (CanvasBloc bloc) =>
          widget.isContour ? bloc.state.contourColor : bloc.state.color,
    );
    final double contourOpacity = widget.isContour
        ? context.select((CanvasBloc bloc) => bloc.state.contourOpacity)
        : 1.0;
    _syncFromColor(currentColor);
    final HSVColor hsv = _hsvColor!;
    final AppColors palette = AppColors.of(context);

    return Theme(
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
            Listener(
              onPointerUp: (_) => _commitHsv(),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: ColorPickerArea(hsv, _onHsvChanged, PaletteType.hsv),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 32,
                    width: 250,
                    child: ColorPickerSlider(
                      TrackType.hue,
                      hsv,
                      _onHsvChanged,
                      displayThumbColor: false,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 32,
                    width: 250,
                    child: ColorPickerSlider(
                      TrackType.saturation,
                      hsv,
                      _onHsvChanged,
                      displayThumbColor: false,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 32,
                    width: 250,
                    child: ColorPickerSlider(
                      TrackType.value,
                      hsv,
                      _onHsvChanged,
                      displayThumbColor: false,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isContour) ...<Widget>[
              const SizedBox(height: 10),
              SizedBox(
                width: 200,
                height: 40,
                child: GradientSlider(
                  value: contourOpacity,
                  thumbColor: palette.white,
                  onChanged: (double value) {
                    context.read<CanvasBloc>().add(
                      ChangeContourSettings(opacity: value),
                    );
                  },
                  gradient: LinearGradient(
                    colors: <Color>[
                      currentColor.withValues(alpha: 0),
                      currentColor.withValues(alpha: 1),
                    ],
                  ),
                ),
              ),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: SizedBox(
                    width: 196,
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      cursorColor: palette.iconActive,
                      style: AppFonts.normal16.copyWith(
                        color: palette.primaryText,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        isDense: true,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: palette.secondaryText),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: palette.primaryText),
                        ),
                      ),
                      onChanged: _onTextChanged,
                      onSubmitted: _onTextSubmitted,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: palette.iconPrimary, size: 20),
                  tooltip: LocaleKeys.copy.tr(),
                  onPressed: _copyValueToClipboard,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
