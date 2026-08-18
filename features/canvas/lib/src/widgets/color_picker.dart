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

  /// Creates a [ColorPickerDialog].
  const ColorPickerDialog({
    this.onEyedropper,
    super.key,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  ColorLabelType _selectedFormat = ColorLabelType.hex;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

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

  void _onFormatChanged(ColorLabelType format, Color currentColor) {
    setState(() {
      _selectedFormat = format;
      _textController.text = _colorToString(currentColor, format);
    });
  }

  void _onTextChanged(String value, BuildContext context) {
    final Color? color = _parseColor(value, _selectedFormat);
    if (color != null) {
      context.read<CanvasBloc>().add(ChangeColor(color));
    }
  }

  Future<void> _copyValueToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _textController.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Copied to clipboard',
            style: AppFonts.normal16.copyWith(color: Colors.white),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color currentColor = context.select(
      (CanvasBloc bloc) => bloc.state.color,
    );

    _updateTextFromColor(currentColor);

    return AlertDialog(
      backgroundColor: colors.secondaryBg,
      title: Text(
        LocaleKeys.color.tr(),
        style: AppFonts.semiBold20.copyWith(color: Colors.black),
      ),
      content: SingleChildScrollView(
        child: Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.black,
              displayColor: Colors.black,
            ),
          ),
          child: DefaultTextStyle(
            style: AppFonts.normal16.copyWith(color: Colors.black),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ColorPicker(
                  pickerColor: currentColor,
                  enableAlpha: false,
                  labelTypes: const <ColorLabelType>[],
                  onColorChanged: (Color color) {
                    context.read<CanvasBloc>().add(ChangeColor(color));
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    DropdownButton<ColorLabelType>(
                      value: _selectedFormat,
                      dropdownColor: colors.secondaryBg,
                      style: AppFonts.normal16.copyWith(color: Colors.black),
                      underline: Container(
                        height: 1,
                        color: Colors.black,
                      ),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black,
                      ),
                      items: ColorLabelType.values.map((ColorLabelType type) {
                        return DropdownMenuItem<ColorLabelType>(
                          value: type,
                          child: Text(
                            type.name.toUpperCase(),
                            style: AppFonts.normal16
                                .copyWith(color: Colors.black),
                          ),
                        );
                      }).toList(),
                      onChanged: (ColorLabelType? type) {
                        if (type != null) {
                          _onFormatChanged(type, currentColor);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _textFocusNode,
                        cursorColor: Colors.blue,
                        style: AppFonts.normal16.copyWith(color: Colors.black),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: colors.primaryText),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        onChanged: (String value) {
                          _onTextChanged(value, context);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.black),
                      tooltip: 'Copy',
                      onPressed: _copyValueToClipboard,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onEyedropper?.call();
          },
          child: Text(
            LocaleKeys.eyedropper.tr(),
            style: AppFonts.normal16.copyWith(color: Colors.black),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.secondaryBg,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.defaultBorder),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 24,
            ),
          ),
          child: Text(
            LocaleKeys.save.tr(),
            style: AppFonts.semiBold20.copyWith(color: Colors.black),
          ),
        ),
      ],
    );
  }
}
