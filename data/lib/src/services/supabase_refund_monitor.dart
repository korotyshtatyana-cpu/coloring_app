import 'dart:async';

import 'package:core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/request_constants.dart';
import '../models/purchase_refund_model.dart';
import 'refund_monitor.dart';

/// Supabase Realtime implementation of [RefundMonitor].
///
/// Subscribes to inserts on the `purchase_refunds` table filtered by user.
/// The webhook only ever inserts unacknowledged rows, and the channel
/// re-subscribes automatically when the connection drops.
class SupabaseRefundMonitor implements RefundMonitor {
  final SupabaseClient _client;
  final AppLogger _logger;

  final StreamController<PurchaseRefundModel> _refunds =
      StreamController<PurchaseRefundModel>.broadcast();
  final Set<String> _emittedIds = <String>{};

  RealtimeChannel? _channel;
  String? _watchedUserId;
  Timer? _reconnectTimer;

  /// Creates a monitor over the given [_client] with the given [_logger].
  SupabaseRefundMonitor({
    required this._client,
    required this._logger,
  });

  @override
  Stream<PurchaseRefundModel> watchRefunds(String userId) {
    if (_watchedUserId != userId) {
      _watchedUserId = userId;
      unawaited(_resubscribe());
    }
    return _refunds.stream;
  }

  @override
  void emitFetched(List<PurchaseRefundModel> refunds) {
    for (final PurchaseRefundModel refund in refunds) {
      _emit(refund);
    }
  }

  @override
  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    final RealtimeChannel? channel = _channel;
    _channel = null;
    if (channel != null) {
      await _client.removeChannel(channel);
    }
    await _refunds.close();
  }

  Future<void> _resubscribe() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final RealtimeChannel? previous = _channel;
    _channel = null;
    if (previous != null) {
      await _client.removeChannel(previous);
    }

    final String? userId = _watchedUserId;
    if (userId == null) {
      return;
    }

    final RealtimeChannel channel = _client.channel(
      'purchase-refunds-$userId',
    );
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: RequestConstants.publicSchema,
          table: RequestConstants.purchaseRefundsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: RequestConstants.userIdColumn,
            value: userId,
          ),
          callback: (PostgresChangePayload payload) =>
              _onInsert(payload.newRecord),
        )
        .subscribe((RealtimeSubscribeStatus status, [Object? error]) {
      if (status == RealtimeSubscribeStatus.closed ||
          status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        _logger.warning(
          '[Monetization] realtime refund channel disconnected, will retry',
        );
        _scheduleReconnect();
      }
    });
    _channel = channel;
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null || _watchedUserId == null) {
      return;
    }
    _reconnectTimer = Timer(Constants.refundChannelReconnectDelay, () {
      unawaited(_resubscribe());
    });
  }

  void _onInsert(Map<String, dynamic> row) {
    try {
      _emit(PurchaseRefundModel.fromJson(row));
    } catch (error, stackTrace) {
      ErrorHandler.report(error, stackTrace);
    }
  }

  void _emit(PurchaseRefundModel refund) {
    if (refund.acknowledgedAt != null) {
      return;
    }
    if (!_emittedIds.add(refund.id)) {
      return;
    }
    if (!_refunds.isClosed) {
      _refunds.add(refund);
    }
  }
}
