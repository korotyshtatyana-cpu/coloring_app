import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../bloc/canvas_bloc.dart';

/// Color picker dialog with color wheel, format selector, and input field.
class ColorPickerDialog extends StatefulWidget {
  /// Callback invoked when the eyedropper mode is requested.
  final VoidCallback? onEyedropper;

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

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  final ColorLabelType _selectedFormat = ColorLabelType.hex;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  HSVColor? _hsvColor;

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  String _colorToString(Color color, ColorLabelType format) {
    switch (format) {
      case ColorLabelType.hex:
        final String hex = color
            .toARGB32()
            .toRadixString(16)
            .padLeft(8, '0')
            .substring(2)
            .toUpperCase();
        return '#$hex';
      case ColorLabelType.rgb:
        return '${(color.r * 255).round()}, ${(color.g * 255).round()}, '
            '${(color.b * 255).round()}';
      case ColorLabelType.hsv:
        final HSVColor hsv = HSVColor.fromColor(color);
        return '${hsv.hue.round()}, ${(hsv.saturation * 100).round()}, '
            '${(hsv.value * 100).round()}';
      case ColorLabelType.hsl:
        final HSLColor hsl = HSLColor.fromColor(color);
        return '${hsl.hue.round()}, ${(hsl.saturation * 100).round()}, '
            '${(hsl.lightness * 100).round()}';
    }
  }

  List<num?> _extractNumbers(String value) {
    return RegExp(r'[\d.]+')
        .allMatches(value)
        .map((RegExpMatch match) => num.tryParse(match.group(0)!))
        .toList();
  }

  Color? _parseColor(String value, ColorLabelType format) {
    switch (format) {
      case ColorLabelType.hex:
        String hex = value.trim();
        if (hex.startsWith('#')) {
          hex = hex.substring(1);
        }
        if (hex.length == 6) {
          final int? colorValue = int.tryParse(hex, radix: 16);
          if (colorValue != null) {
            return Color(0xFF000000 | colorValue);
          }
        }
        return null;
      case ColorLabelType.rgb:
        final List<num?> numbers = _extractNumbers(value);
        if (numbers.length >= 3) {
          return Color.fromARGB(
            255,
            numbers[0]!.toInt().clamp(0, 255),
            numbers[1]!.toInt().clamp(0, 255),
            numbers[2]!.toInt().clamp(0, 255),
          );
        }
        return null;
      case ColorLabelType.hsv:
        final List<num?> numbers = _extractNumbers(value);
        if (numbers.length >= 3) {
          return HSVColor.fromAHSV(
            1.0,
            numbers[0]!.toDouble().clamp(0, 360),
            numbers[1]!.toDouble().clamp(0, 100) / 100,
            numbers[2]!.toDouble().clamp(0, 100) / 100,
          ).toColor();
        }
        return null;
      case ColorLabelType.hsl:
        final List<num?> numbers = _extractNumbers(value);
        if (numbers.length >= 3) {
          return HSLColor.fromAHSL(
            1.0,
            numbers[0]!.toDouble().clamp(0, 360),
            numbers[1]!.toDouble().clamp(0, 100) / 100,
            numbers[2]!.toDouble().clamp(0, 100) / 100,
          ).toColor();
        }
        return null;
    }
  }

  void _updateTextFromColor(Color color) {
    if (_textFocusNode.hasFocus) {
      return;
    }
    _textController.text = _colorToString(color, _selectedFormat);
  }

  void _onTextChanged(String value, BuildContext context) {
    final Color? color = _parseColor(value, _selectedFormat);
    if (color != null) {
      final bloc = context.read<CanvasBloc>();
      if (widget.isContour) {
        bloc.add(ChangeContourSettings(color: color));
      } else {
        bloc.add(ChangeColor(color));
      }
    }
  }

  Future<void> _copyValueToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _textController.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'copied_to_clipboard'.tr(),
            style: AppFonts.normal16.copyWith(color: Colors.white),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _onColorChanged(HSVColor color) {
    setState(() => _hsvColor = color);
    final bloc = context.read<CanvasBloc>();
    if (widget.isContour) {
      bloc.add(ChangeContourSettings(color: color.toColor()));
    } else {
      bloc.add(ChangeColor(color.toColor()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color currentColor = context.select((CanvasBloc bloc) =>
    widget.isContour ? bloc.state.contourColor : bloc.state.color);

    if (_hsvColor == null ||
        (_hsvColor!.toColor().toARGB32() != currentColor.toARGB32() &&
            currentColor.toARGB32() != 0xFF000000)) {
      _hsvColor = HSVColor.fromColor(currentColor);
    } else if (currentColor.toARGB32() == 0xFF000000 && _hsvColor != null) {
      _hsvColor = _hsvColor!.withValue(0);
    }

    _updateTextFromColor(currentColor);

    return IntrinsicWidth(
      child: IntrinsicHeight(
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                LocaleKeys.color.tr(),
                style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
              ),
              const SizedBox(height: 12),
              Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: colors.primaryText,
                    displayColor: colors.primaryText,
                  ),
                ),
                child: DefaultTextStyle(
                  style: AppFonts.normal16.copyWith(color: colors.primaryText),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Color picker area (color wheel)
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: ColorPickerArea(
                          _hsvColor!,
                          _onColorChanged,
                          PaletteType.hsv,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Hue slider
                      SizedBox(
                        height: 32,
                        width: 200,
                        child: ColorPickerSlider(
                          TrackType.hue,
                          _hsvColor!,
                          _onColorChanged,
                          displayThumbColor: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Saturation slider
                      SizedBox(
                        height: 32,
                        width: 200,
                        child: ColorPickerSlider(
                          TrackType.saturation,
                          _hsvColor!,
                          _onColorChanged,
                          displayThumbColor: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Value/Brightness slider
                      SizedBox(
                        height: 32,
                        width: 200,
                        child: ColorPickerSlider(
                          TrackType.value,
                          _hsvColor!,
                          _onColorChanged,
                          displayThumbColor: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Row with eyedropper, text input, and copy button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.colorize,
                              color: colors.primaryText,
                              size: 20,
                            ),
                            tooltip: 'eyedropper'.tr(),
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onEyedropper?.call();
                            },
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: _textController,
                              focusNode: _textFocusNode,
                              cursorColor: colors.green,
                              style: AppFonts.normal16.copyWith(
                                color: colors.primaryText,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                isDense: true,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: colors.secondaryText,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: colors.primaryText,
                                  ),
                                ),
                              ),
                              onChanged: (String value) {
                                _onTextChanged(value, context);
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy,
                              color: colors.primaryText,
                              size: 20,
                            ),
                            tooltip: 'copy'.tr(),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}