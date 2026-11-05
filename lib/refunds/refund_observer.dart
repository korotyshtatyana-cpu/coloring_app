import 'dart:async';

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';

/// Session-scoped watcher that shows the refund dialog above any screen.
///
/// Sits above the feature blocs: the realtime refund stream is owned by the
/// data layer, while this widget owns the single dialog every refund path
/// (realtime event, resume fallback, gallery pull-to-refresh) funnels into.
/// Gallery and canvas react to the same stream themselves and update their
/// access state in parallel.
class RefundObserver extends StatefulWidget {
  /// The application subtree, typically `MaterialApp.router`.
  final Widget child;

  /// Creates a [RefundObserver].
  const RefundObserver({required this.child, super.key});

  @override
  State<RefundObserver> createState() => _RefundObserverState();
}

class _RefundObserverState extends State<RefundObserver>
    with WidgetsBindingObserver {
  StreamSubscription<PurchaseRefundEntity>? _refundsSubscription;
  String? _watchedUserId;

  final List<PurchaseRefundEntity> _pending = <PurchaseRefundEntity>[];
  final Set<String> _pendingIds = <String>{};
  Timer? _mergeTimer;
  Timer? _userRetryTimer;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_ensureWatching());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mergeTimer?.cancel();
    _userRetryTimer?.cancel();
    unawaited(_refundsSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    // Resume re-resolves the user and runs the polling fallback, so refunds
    // recorded while realtime was unavailable still reach the dialog.
    unawaited(_ensureWatching());
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<void> _ensureWatching() async {
    try {
      final UserEntity? user = await appLocator<GetCurrentUserUseCase>()
          .execute();
      if (!mounted) {
        return;
      }
      final String? userId = user?.id;
      if (userId == null) {
        // Sign-in may still be in flight on a cold start; retry until the
        // account is known so no refund is missed.
        _userRetryTimer ??= Timer(
          Constants.refundChannelReconnectDelay,
          () {
            _userRetryTimer = null;
            unawaited(_ensureWatching());
          },
        );
        return;
      }
      _userRetryTimer?.cancel();
      _userRetryTimer = null;
      if (userId == _watchedUserId) {
        return;
      }
      _watchedUserId = userId;
      await _refundsSubscription?.cancel();
      _refundsSubscription = appLocator<WatchRefundsUseCase>()
          .execute(userId)
          .listen(_onRefund);
      // Fallback for the time before the channel was up: unacknowledged
      // refunds discovered here are emitted into the same stream.
      unawaited(_fetchUnacknowledged(userId));
    } catch (error, stackTrace) {
      ErrorHandler.report(error, stackTrace);
    }
  }

  Future<void> _fetchUnacknowledged(String userId) async {
    try {
      await appLocator<GetPurchaseRefundsUseCase>().execute(userId);
    } catch (error, stackTrace) {
      ErrorHandler.report(error, stackTrace);
    }
  }

  void _onRefund(PurchaseRefundEntity refund) {
    if (_pendingIds.add(refund.id)) {
      _pending.add(refund);
    }
    _mergeTimer?.cancel();
    _mergeTimer = Timer(Constants.refundDialogMergeWindow, _flushPending);
  }

  void _flushPending() {
    if (_dialogShowing || _pending.isEmpty) {
      return;
    }
    final List<PurchaseRefundEntity> batch =
        List<PurchaseRefundEntity>.of(_pending);
    _pending.clear();
    _pendingIds.clear();
    unawaited(_showDialog(batch));
  }

  Future<void> _showDialog(List<PurchaseRefundEntity> batch) async {
    final List<RefundDialogEntry> entries = await Future.wait(
      batch.map(_toEntry),
    );
    if (!mounted) {
      return;
    }
    final BuildContext? dialogContext =
        appLocator<AppRouter>().navigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted) {
      _requeue(batch);
      return;
    }

    _dialogShowing = true;
    appLocator<AppLogger>().debug(
      '[Monetization] refund dialog shown: count=${batch.length}',
    );
    try {
      await RefundDialog.show(dialogContext, entries: entries);
    } finally {
      _dialogShowing = false;
    }

    for (final PurchaseRefundEntity refund in batch) {
      try {
        await appLocator<AcknowledgePurchaseRefundUseCase>().execute(refund.id);
        appLocator<AppLogger>().debug(
          '[Monetization] refund acknowledged: '
          'token=${_lastTokenChars(refund.purchaseToken)}',
        );
      } catch (error, stackTrace) {
        ErrorHandler.report(error, stackTrace);
      }
    }

    // Refunds that arrived while the dialog was up are shown next.
    _flushPending();
  }

  void _requeue(List<PurchaseRefundEntity> batch) {
    for (final PurchaseRefundEntity refund in batch) {
      if (_pendingIds.add(refund.id)) {
        _pending.add(refund);
      }
    }
    _mergeTimer?.cancel();
    _mergeTimer = Timer(Constants.refundDialogMergeWindow, _flushPending);
  }

  Future<RefundDialogEntry> _toEntry(PurchaseRefundEntity refund) async {
    final String message = refund.isSubscriptionRefund
        ? LocaleKeys.refund_dialog_body_subscription.tr()
        : LocaleKeys.refund_dialog_body_credit.tr();
    return RefundDialogEntry(
      message: message,
      previewUrl: await _previewUrlOf(refund),
    );
  }

  Future<String?> _previewUrlOf(PurchaseRefundEntity refund) async {
    final String? contourId = refund.affectedContourId;
    if (contourId == null) {
      return null;
    }
    try {
      final ContourEntity? contour =
          await appLocator<GetContourByIdUseCase>().execute(contourId);
      return contour?.previewUrl;
    } catch (error, stackTrace) {
      ErrorHandler.report(error, stackTrace);
      return null;
    }
  }

  String _lastTokenChars(String token) {
    return token.length <= 8 ? token : token.substring(token.length - 8);
  }
}
