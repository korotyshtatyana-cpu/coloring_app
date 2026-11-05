import '../models/purchase_refund_model.dart';

/// Abstraction over the realtime refund delivery channel.
///
/// The application always talks to this interface, so the transport (Supabase
/// Realtime today) stays behind it. Emitted refunds are deduplicated by id:
/// a refund discovered through both the realtime channel and the unacknowledged
/// read fallback is delivered exactly once per session.
abstract class RefundMonitor {
  /// Emits refunds recorded for [userId] as soon as the server writes them.
  ///
  /// Only unacknowledged refunds are emitted. Calling again with a different
  /// user re-targets the underlying channel; every listener shares the same
  /// broadcast stream.
  Stream<PurchaseRefundModel> watchRefunds(String userId);

  /// Emits [refunds] that were discovered by polling instead of the realtime
  /// channel, so both delivery paths feed the same stream.
  void emitFetched(List<PurchaseRefundModel> refunds);

  /// Releases the channel and the refund stream.
  Future<void> dispose();
}
