import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

class GalleryTitle extends StatelessWidget {
  /// Creates a [GalleryTitle] with the localized [title].
  const GalleryTitle({super.key, required this.title});

  /// Localized gallery name without the build number.
  final String title;

  /// Whether this is a dev build, the only one that shows the build number.
  bool get _isDevBuild => appLocator<AppConfig>().flavor == Flavor.dev;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TextStyle style = AppFonts.appBarTitle.copyWith(
      color: colors.primaryText,
      shadows: <Shadow>[],
    );

    // The build number is developer information, so it is never rendered in
    // release builds. Returning early also skips the platform call that reads
    // the package info.
    if (!_isDevBuild) {
      return Text(title, style: style);
    }

    return FutureBuilder<String>(
      future: AppVersion.buildNumber,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        final String build = snapshot.data ?? '';

        if (build.isEmpty) {
          return Text(title, style: style);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(title, style: style, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            Text(
              build,
              style: style.copyWith(
                color: colors.primaryText.withValues(alpha: 0.5),
              ),
            ),
          ],
        );
      },
    );
  }
}
