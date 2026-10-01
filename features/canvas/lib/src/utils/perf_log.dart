import 'package:flutter/foundation.dart';

/// Enables canvas performance logging.
///
/// On in every non-release build, so it does not depend on the runner passing
/// `--dart-define` (an IDE launch silently omits it). Use `--profile`: raster
/// timings from a debug build are not representative. Silently compiled out of
/// release builds.
const bool kCanvasPerfLog = !kReleaseMode;

/// Painter invocations since the last report, keyed by layer.
///
/// The counts answer "what was actually rasterized for this frame", which is
/// what separates a genuinely expensive layer from an empty frame that is
/// slow for another reason.
final Map<String, int> _paintCounts = <String, int>{};

/// Records that [layer] painted once. Include the properties that drive the
/// cost, so a slow frame can be attributed without guessing.
void perfCountPaint(String layer) {
  if (!kCanvasPerfLog) return;
  _paintCounts.update(layer, (int value) => value + 1, ifAbsent: () => 1);
}

/// Prints and clears the painter counters for this frame.
void perfReportPaints(String prefix) {
  if (!kCanvasPerfLog || _paintCounts.isEmpty) return;
  debugPrint('$prefix $_paintCounts');
  _paintCounts.clear();
}

/// Prints a one-off environment report, e.g. which renderer is in use.
void perfLogOnce(String key, String value) {
  if (!kCanvasPerfLog) return;
  debugPrint('[$key] $value');
}

/// Prints a tagged line, for one-off diagnostics such as raster timings.
void perfLog(String key, String value) {
  if (!kCanvasPerfLog) return;
  debugPrint('[$key] $value');
}
