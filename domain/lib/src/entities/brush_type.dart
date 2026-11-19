/// Available brush types for drawing on the canvas.
///
/// Standard brushes paint a hard edge. Soft brushes ([softLiner] and
/// [softRoundBasic]) use the same stroke data as their standard counterparts,
/// but their edge is rendered with a blur whose radius is proportional to the
/// brush size. The blur is applied by the painters, so the rest of the app only
/// deals with the brush type.
enum BrushType {
  /// Round brush tip.
  circle,

  /// Square brush tip.
  square,

  /// Watercolor-like soft brush.
  watercolor,

  /// Chalk-like textured brush.
  chalk,

  /// Marker-like semi-transparent brush.
  marker,

  /// Calligraphy brush that reacts to direction.
  calligraphy,

  /// Textured brush (cloud, grass, etc.).
  texture,

  /// Airbrush with scattered spray effect.
  airbrush,

  /// Pressure-sensitive liner with a soft, blurred edge.
  ///
  /// Functionally the same as the standard fine liner, but the painters
  /// render its silhouette with a size-proportional blur.
  softLiner,

  /// Constant-width round brush with a soft, blurred edge.
  ///
  /// Functionally the same as the standard round brush, but the painters
  /// render its edge with a size-proportional blur.
  softRoundBasic;

  /// Whether this brush is rendered with a soft, blurred edge.
  ///
  /// Soft brushes use a blur radius proportional to the brush size, so a
  /// thicker stroke also gets a wider soft falloff. Standard brushes return
  /// `false` and keep their hard edges.
  bool get isSoft => this == softLiner || this == softRoundBasic;
}
