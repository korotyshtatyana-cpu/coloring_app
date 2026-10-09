import 'package:core/core.dart';

import '../../domain.dart';

/// Domain dependency injection setup.
abstract class DomainDI {
  /// Registers all domain use cases in the global [appLocator].
  static void initDependencies() {
    _initUseCases();
  }

  static void _initUseCases() {
    appLocator.registerLazySingleton<CheckAuthUseCase>(
      () => CheckAuthUseCase(repository: appLocator<AuthRepository>()),
    );

    appLocator.registerLazySingleton<SignInUseCase>(
      () => SignInUseCase(repository: appLocator<AuthRepository>()),
    );

    appLocator.registerLazySingleton<SignInSilentlyUseCase>(
      () => SignInSilentlyUseCase(repository: appLocator<AuthRepository>()),
    );

    appLocator.registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(repository: appLocator<AuthRepository>()),
    );

    appLocator.registerLazySingleton<DeleteAccountUseCase>(
      () => DeleteAccountUseCase(repository: appLocator<AuthRepository>()),
    );

    appLocator.registerLazySingleton<GetContoursUseCase>(
      () => GetContoursUseCase(repository: appLocator<GalleryRepository>()),
    );

    appLocator.registerLazySingleton<GetUsedCategoriesUseCase>(
      () => GetUsedCategoriesUseCase(repository: appLocator<GalleryRepository>()),
    );

    appLocator.registerLazySingleton<GetContoursByIdsUseCase>(
      () => GetContoursByIdsUseCase(repository: appLocator<GalleryRepository>()),
    );

    appLocator.registerLazySingleton<GetFavoriteIdsUseCase>(
      () => GetFavoriteIdsUseCase(repository: appLocator<GalleryRepository>()),
    );

    appLocator.registerLazySingleton<ToggleFavoriteUseCase>(
      () => ToggleFavoriteUseCase(repository: appLocator<GalleryRepository>()),
    );

    appLocator.registerLazySingleton<GetWorkInProgressUseCase>(
      () => GetWorkInProgressUseCase(repository: appLocator<GalleryRepository>()),
    );

    appLocator.registerLazySingleton<GetContourByIdUseCase>(
      () => GetContourByIdUseCase(repository: appLocator<GalleryRepository>()),
    );

    appLocator.registerLazySingleton<GetAvailableToolsUseCase>(
      () => GetAvailableToolsUseCase(repository: appLocator<CanvasRepository>()),
    );

    appLocator.registerLazySingleton<AddStrokeUseCase>(
      () => AddStrokeUseCase(repository: appLocator<CanvasRepository>()),
    );

    appLocator.registerLazySingleton<SaveProjectUseCase>(
      () => SaveProjectUseCase(repository: appLocator<CanvasRepository>()),
    );

    appLocator.registerLazySingleton<LoadProjectUseCase>(
      () => LoadProjectUseCase(repository: appLocator<CanvasRepository>()),
    );

    appLocator.registerLazySingleton<ExportImageUseCase>(
      () => ExportImageUseCase(repository: appLocator<CanvasRepository>()),
    );

    appLocator.registerLazySingleton<RenderProjectThumbnailUseCase>(
      () => RenderProjectThumbnailUseCase(repository: appLocator<CanvasRepository>()),
    );

    appLocator.registerLazySingleton<ShareFileUseCase>(
      () => ShareFileUseCase(repository: appLocator<ShareRepository>()),
    );

    appLocator.registerLazySingleton<SaveImageToGalleryUseCase>(
      () => SaveImageToGalleryUseCase(repository: appLocator<CanvasRepository>()),
    );

    appLocator.registerLazySingleton<GetSettingsUseCase>(
      () => GetSettingsUseCase(repository: appLocator<SettingsRepository>()),
    );

    appLocator.registerLazySingleton<UpdateSettingsUseCase>(
      () => UpdateSettingsUseCase(repository: appLocator<SettingsRepository>()),
    );

    appLocator.registerLazySingleton<CheckCanvasOnboardingShownUseCase>(
      () => CheckCanvasOnboardingShownUseCase(repository: appLocator<SettingsRepository>()),
    );

    appLocator.registerLazySingleton<SetCanvasOnboardingShownUseCase>(
      () => SetCanvasOnboardingShownUseCase(repository: appLocator<SettingsRepository>()),
    );

    appLocator.registerLazySingleton<SubmitFeedbackUseCase>(
      () => SubmitFeedbackUseCase(repository: appLocator<FeedbackRepository>()),
    );

    appLocator.registerLazySingleton<GetActiveSubscriptionUseCase>(
      () => GetActiveSubscriptionUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<IsNoAdsPurchasedUseCase>(
      () => IsNoAdsPurchasedUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<GetEntitlementUseCase>(
      () => GetEntitlementUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<GrantRewardedUnlockUseCase>(
      () => GrantRewardedUnlockUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<RecordPurchaseUseCase>(
      () => RecordPurchaseUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<EnqueuePendingPurchaseUseCase>(
      () => EnqueuePendingPurchaseUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<GetPendingPurchasesUseCase>(
      () => GetPendingPurchasesUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<GetPurchaseHistoryUseCase>(
      () => GetPurchaseHistoryUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<GetSubscriptionPlanTypeUseCase>(
      () => const GetSubscriptionPlanTypeUseCase(),
    );

    appLocator.registerLazySingleton<GetGalleryItemsUseCase>(
      () => GetGalleryItemsUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<GetBillingProductsUseCase>(
      () => GetBillingProductsUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<BuySubscriptionUseCase>(
      () => BuySubscriptionUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<BuyProjectUseCase>(
      () => BuyProjectUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<RestorePurchasesUseCase>(
      () => RestorePurchasesUseCase(repository: appLocator<MonetizationRepository>()),
    );

    appLocator.registerLazySingleton<WatchPurchaseUpdatesUseCase>(
      () => WatchPurchaseUpdatesUseCase(repository: appLocator<MonetizationRepository>()),
    );
  }
}
