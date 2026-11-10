import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:settings/src/screens/settings_content.dart';

import '../bloc/settings_bloc.dart';

/// Settings screen for application preferences.
@RoutePage()
class SettingsScreen extends StatefulWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutoRouteAware {
  AutoRouteObserver? _observer;
  StreamSubscription<PurchaseUpdateEntity>? _purchaseUpdatesSubscription;
  bool _didRequestInitialLoad = false;

  /// The bloc is owned by this state (not created inside [build]) so that
  /// route-aware callbacks like [didPopNext] can access it without a
  /// [BuildContext] — the screen's own context is an ancestor of the
  /// [BlocProvider] and therefore cannot look it up.
  late final SettingsBloc _bloc = SettingsBloc(
    getSettingsUseCase: appLocator<GetSettingsUseCase>(),
    updateSettingsUseCase: appLocator<UpdateSettingsUseCase>(),
    getCurrentUserUseCase: appLocator<GetCurrentUserUseCase>(),
    deleteAccountUseCase: appLocator<DeleteAccountUseCase>(),
    getActiveSubscriptionUseCase: appLocator<GetActiveSubscriptionUseCase>(),
    isNoAdsPurchasedUseCase: appLocator<IsNoAdsPurchasedUseCase>(),
    getSubscriptionPlanTypeUseCase:
        appLocator<GetSubscriptionPlanTypeUseCase>(),
  );

  @override
  void initState() {
    super.initState();
    // A confirmed purchase (including one completed while the subscription
    // screen is still open) changes the plan that drives the avatar frame.
    _purchaseUpdatesSubscription = appLocator<WatchPurchaseUpdatesUseCase>()
        .execute()
        .listen(_onPurchaseUpdate);
  }

  void _onPurchaseUpdate(PurchaseUpdateEntity update) {
    if (!mounted || update.status != PurchaseUpdateStatus.success) {
      return;
    }
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer = appLocator<AutoRouteObserver>();
    _observer?.subscribe(this, context.routeData);

    // The locale is only available once dependencies are resolved, so the
    // initial load cannot run from [initState].
    if (!_didRequestInitialLoad) {
      _didRequestInitialLoad = true;
      _reload();
    }
  }

  @override
  void didPopNext() {
    // Returning from the subscription screen may have changed the active plan,
    // which drives the avatar frame and the status row.
    _reload();
  }

  void _reload() {
    if (!mounted || _bloc.isClosed) {
      return;
    }
    _bloc.add(LoadSettings(currentLocale: context.locale.toString()));
  }

  @override
  void dispose() {
    _purchaseUpdatesSubscription?.cancel();
    _observer?.unsubscribe(this);
    // BlocProvider.value doesn't close the bloc, so we do it ourselves.
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsBloc>.value(
      value: _bloc,
      child: const SettingsContent(),
    );
  }
}
