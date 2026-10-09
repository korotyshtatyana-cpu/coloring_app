import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../bloc/subscription_bloc.dart';
import 'subscription_content.dart';

/// Screen showing subscription plans and purchase history.
@RoutePage()
class SubscriptionScreen extends StatelessWidget {
  /// Creates a [SubscriptionScreen].
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionBloc>(
      create: (context) => SubscriptionBloc(
        getCurrentUserUseCase: appLocator<GetCurrentUserUseCase>(),
        getActiveSubscriptionUseCase: appLocator<GetActiveSubscriptionUseCase>(),
        getPurchaseHistoryUseCase: appLocator<GetPurchaseHistoryUseCase>(),
        getPendingPurchasesUseCase: appLocator<GetPendingPurchasesUseCase>(),
        buySubscriptionUseCase: appLocator<BuySubscriptionUseCase>(),
        restorePurchasesUseCase: appLocator<RestorePurchasesUseCase>(),
        watchPurchaseUpdatesUseCase: appLocator<WatchPurchaseUpdatesUseCase>(),
      )..add(const LoadSubscription()),
      child: const SubscriptionContent(),
    );
  }
}
