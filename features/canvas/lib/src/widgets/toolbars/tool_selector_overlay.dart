import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Overlay for selecting a specific tool within a category (Brush or Eraser).
class ToolSelectorOverlay extends StatelessWidget {
  /// List of available tools to display.
  final List<ToolEntity> tools;

  /// Currently active tool ID.
  final String? activeToolId;

  /// Callback when a tool is selected.
  final ValueChanged<String> onToolSelected;

  /// Creates a [ToolSelectorOverlay].
  const ToolSelectorOverlay({
    required this.tools,
    required this.activeToolId,
    required this.onToolSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return IntrinsicWidth(
      child: Material(
        color: colors.primaryBg,
        elevation: 4,
        shadowColor: colors.accentDark.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tools.map((tool) {
              final bool isActive = tool.id == activeToolId;

              return InkWell(
                splashColor: colors.accentLight,
                onTap: () {
                  onToolSelected(tool.id);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.accentLight.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.nameKey.tr(),
                        style: AppFonts.normal10.copyWith(
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 160,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.secondaryBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.secondaryText.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: tool.previewPath.isNotEmpty
                              ? Image.asset(
                                  tool.previewPath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.gesture,
                                    size: 16,
                                    color: colors.secondaryText,
                                  ),
                                )
                              : Icon(
                                  Icons.gesture,
                                  size: 16,
                                  color: colors.secondaryText,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
