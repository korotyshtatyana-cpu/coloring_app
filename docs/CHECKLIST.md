# Чек-лист разработки

## ✅ Настройка проекта
- [x] Создан pubspec.yaml в корне
- [x] Созданы pubspec.yaml для каждого модуля
- [x] Создана структура папок
- [x] Созданы файлы переводов в core/resources/lang/
- [x] Созданы .env.dev и .env.prod
- [x] Созданы скрипты (prebuild_script_*.sh)
- [x] Создан fast_prebuild_script.sh

## ✅ Core модуль
- [x] Настроена локализация (easy_localization)
- [x] Сгенерирован locale_keys.g.dart в `core/lib/src/localization/generated/`
- [x] Созданы утилиты (constants, logger, result, svg_utils, url_utils)
- [x] Добавлены `autosaveDebounce`, `stalePendingPurchaseThreshold`, `refundDialogMergeWindow`
- [x] Создан app_locator.dart (GetIt instance)
- [x] Создан CoreDi (регистрация AppConfig, AppLogger, AnalyticsService)
- [x] Создан публичный API (core.dart) с экспортом dotenv, easy_localization, flutter_bloc и bloc_concurrency

## ✅ Core_UI модуль
- [x] Создана светлая тема (AppTheme, lightTheme) — тема находится в `core_ui`, а не в `core`
- [x] Созданы кнопки (PrimaryButton, AppButton, AppIconButton)
- [x] Созданы контейнеры панелей (ToolbarContainer)
- [x] Созданы диалоги (LoadingDialog, ErrorDialog, RefundDialog)
- [x] Созданы поля ввода (GradientSlider, AppDropdown, SearchField)
- [x] Создан публичный API (core_ui.dart)
- [x] `ThemeSwitch` и тёмная тема удалены
- [x] `ContourCard` перенесена в `features/gallery`

## ✅ Domain модуль
- [x] Создан `domain/lib/src/use_cases/use_case.dart`
- [x] Созданы модели (UserEntity, ContourEntity, ProjectEntity, StrokeEntity, ToolEntity, BrushType, SubscriptionEntity, UserEntitlementEntity, PendingPurchaseEntity, PurchaseRefundEntity, FeedbackEntity и др.)
- [x] Создана доменная логика (`ProjectAccessCalculator`, `StaleSubscriptionPending`)
- [x] Созданы интерфейсы репозиториев (AuthRepository, GalleryRepository, CanvasRepository, MonetizationRepository, SettingsRepository, ShareRepository, FeedbackRepository)
- [x] Созданы UseCases:
    - [x] auth: CheckAuth, SignIn, SignInSilently, GetCurrentUser, DeleteAccount
    - [x] gallery: GetContours, GetContoursByIds, GetFavoriteIds, ToggleFavorite, GetWorkInProgress, GetContourById, GetUsedCategories
    - [x] canvas: AddStroke, SaveProject, LoadProject, ExportImage, RenderProjectThumbnail, GetAvailableTools, SaveImageToGallery, ShareFile, canvas onboarding
    - [x] settings: GetSettings, UpdateSettings
    - [x] feedback: SubmitFeedback
    - [x] monetization: подписки, покупки проекта/кредита, restore, pending, история, refunds, rewarded unlock
- [x] Создан DomainDI (регистрация всех UseCases)
- [x] Создан публичный API (domain.dart)

## ✅ Data модуль
- [x] Созданы провайдеры (SupabaseProvider, AppDatabase/Drift, AuthRemoteProvider, GalleryRemoteProvider, GalleryLocalProvider, CanvasRemoteProvider, CanvasLocalProvider, FeedbackRemoteProvider, MonetizationRemoteProvider)
- [x] В `data` нет папки `datasources`; используется `providers/`
- [x] Созданы мапперы (Contour, Project, Stroke, Subscription, UserEntitlement, PendingPurchase, PurchaseRefund)
- [x] Созданы модели (UserModel, ContourModel, ProjectModel, StrokeModel, SubscriptionModel, SubscriptionPurchaseModel, UserEntitlementModel, PendingPurchaseModel, PurchaseRefundModel)
- [x] Созданы репозитории (AuthRepositoryImpl, GalleryRepositoryImpl, CanvasRepositoryImpl, MonetizationRepositoryImpl, SettingsRepositoryImpl, ShareRepositoryImpl, FeedbackRepositoryImpl)
- [x] Создан ShareService (static)
- [x] Создан GallerySaverService (static)
- [x] Созданы сервисы биллинга (`BillingPlatform`, `GooglePlayBillingPlatform`), рекламы (`AdService`, `YandexAdService`) и возвратов (`RefundMonitor`, `SupabaseRefundMonitor`)
- [x] Создан `SubscriptionCache` (in-memory + SharedPreferences, TTL)
- [x] Создан DataDI (регистрация всех зависимостей)
- [x] Создан публичный API (data.dart)
- [x] Drift: таблицы `Projects`, `Strokes`, `Brushes`, `Contours`, `schemaVersion = 5`

## ✅ Navigation модуль
- [x] Создан AppRouter с auto_route в `navigation/lib/src/app_router/`
- [x] Маршруты в порядке: Splash, Canvas, Gallery, Settings, Subscription
- [x] Все маршруты, кроме Splash, защищены `AuthGuard`
- [x] Создан NavigationDI (регистрация AuthGuard, AppRouter, AutoRouteObserver) в `navigation/lib/src/di/`
- [x] Сгенерирован `app_router.gr.dart`
- [x] Создан публичный API (`navigation.dart`) — экспортирует `auto_route`, `AppRouter`, `NavigationDI`

## ✅ Splash Feature
- [x] Создан AuthBloc (события, состояния)
- [x] Добавлен `SignInSilentlyUseCase`
- [x] Создан SplashScreen (Screen + Content)
- [x] Реализована автоматическая авторизация с fallback на ручной вход
- [x] `LoginButton` показывается только при `AuthStatus.failure`
- [x] Создан публичный API (`splash.dart`) — только `SplashRouter` и `SplashRoute`

## ✅ Gallery Feature
- [x] Создан GalleryBloc (события, состояния)
- [x] Создан GalleryScreen (Screen + Content)
- [x] Созданы виджеты (GalleryContourCard/ContourCard, FilterChips, EmptyState, UserAvatarButton, ProjectAccessBadge, AdLoadingOverlay)
- [x] Кнопка-аватар в AppBar открывает `SettingsRoute`
- [x] FilterChips содержит All, Favorites, In Progress + категории
- [x] Пагинация по `Constants.pageSize` для всех фильтров через `GetContoursByIdsUseCase`
- [x] Ошибка отображается через `ErrorDialog`
- [x] Обрабатываются rewarded-видео, покупка paid-проекта и баннер рекламы
- [x] Создан публичный API (`gallery.dart`) — только `GalleryRouter` и `GalleryRoute`

## ✅ Canvas Feature
- [x] Создан CanvasBloc (события, состояния)
- [x] `CanvasState` содержит статусы initial, loading, ready, drawing, saving, exporting, error
- [x] Создан CanvasScreen (Screen + Content)
- [x] Отрисовка мазков через `RasterCanvasBuffer` (завершённые) и `ActiveStrokePainter` (текущий); `CanvasPainter` существует, но в текущем стеке холста не используется
- [x] Контур отображается через `ContourLayer`/`SvgPicture.string` без изменения оригинальной толщины
- [x] Реализовано сглаживание контура (Smooth Contour)
- [x] Реализована поддержка поворота холста
- [x] Обработка касаний через `Listener` с `event.pressure` и коррекцией масштаба
- [x] Автосохранение с `autosaveDebounce` и при сворачивании (включая настройки контура)
- [x] Интеллектуальный Undo/redo через `undoStack`/`redoStack` (до 5 шагов)
- [x] Экспорт: `ExportImageUseCase` + `ShareFileUseCase` / `SaveImageToGalleryUseCase` через `CanvasBloc`
- [x] Режим только просмотра (`isViewOnly`) с баннером причины и разблокировкой
- [x] Onboarding холста и кнопка информации
- [x] Созданы виджеты:
    - [x] Стандартизированный `AppIconButton` (24/18px)
    - [x] ColorPicker (Overlay + Hue slider + Black-fix)
    - [x] Палитра контура (цвет и прозрачность)
    - [x] Toolbar-панели (`TopToolbar`, `BottomToolbar`, `LeftControls`)
- [x] Создан публичный API (`canvas.dart`) — только `CanvasRouter` и `CanvasRoute`

## ✅ Settings Feature
- [x] Создан SettingsBloc (события, состояния)
- [x] Создан SettingsScreen (Screen + Content) — экран профиля
- [x] Создан ProfileUserHeader с рамкой аватара по плану подписки
- [x] Создан ProfileSubscriptionStatus и переход на `SubscriptionRoute`
- [x] Создан LanguagePicker для 7 локалей
- [x] Добавлены FeedbackActions/FeedbackButton
- [x] Добавлено удаление аккаунта с подтверждением
- [x] Удалён ThemeSwitch / тёмная тема
- [x] Создан публичный API (`settings.dart`) — только `SettingsRouter` и `SettingsRoute`

## ✅ Subscription Feature
- [x] Создан SubscriptionBloc (события, состояния)
- [x] Создан SubscriptionScreen (Screen + Content)
- [x] Создан SubscriptionStatusBlock с датой окончания и бейджем отключённого автообновления
- [x] Созданы SubscriptionPlanCard и PlanPeriodSelector для No Ads / Premium
- [x] Создан PurchaseHistorySection (максимальная высота 200 px, внутренний скролл)
- [x] Созданы PurchaseDialog и обработка результата покупки
- [x] Фоновое обновление показывает `LinearProgressIndicator`, не скрывая контент
- [x] Нет кнопки отмены подписки — отмена выполняется в Google Play
- [x] Создан публичный API (`subscription.dart`) — `SubscriptionRoute`

## ✅ Feedback Feature
- [x] Создан FeedbackBloc (события, состояния)
- [x] Созданы форма, вложения и `showFeedbackForm`
- [x] Создан публичный API (`feedback.dart`)

## ✅ Error Handler
- [x] Создан глобальный ErrorHandler с `GlobalKey<NavigatorState>`
- [x] Создан ErrorMessages
- [x] Создан ErrorReporting
- [x] Создан AppErrorHandlerProvider
- [x] ErrorDialog.show вызывается из `overlay?.context`

## ✅ Main Entry Point
- [x] Создан `main_common.dart` (содержит `App` виджет)
- [x] Создан `main_dev.dart`
- [x] Создан `main_prod.dart`
- [x] Приложение не фиксирует ориентацию только на `portraitUp`

## ✅ Интеграция
- [x] Корневой `pubspec.yaml` содержит модули через `dependency_overrides`
- [x] Все DI зарегистрированы
- [x] Все маршруты работают
- [x] Приложение запускается

## ✅ Скрипты
- [x] `prebuild_script_core.sh` (flutter pub get + easy_localization generate)
- [x] `prebuild_script_core_ui.sh` (flutter pub get)
- [x] `prebuild_script_domain.sh` (flutter pub get)
- [x] `prebuild_script_data.sh` (flutter pub get + build_runner)
- [x] `prebuild_script_navigation.sh` (flutter pub get + build_runner)
- [x] `prebuild_script_splash.sh` (flutter pub get + build_runner)
- [x] `prebuild_script_gallery.sh` (flutter pub get + build_runner)
- [x] `prebuild_script_canvas.sh` (flutter pub get + build_runner)
- [x] `prebuild_script_settings.sh` (flutter pub get + build_runner)
- [x] `prebuild_script_subscription.sh` (flutter pub get + build_runner)
- [x] `fast_prebuild_script.sh`
- [x] У `features/feedback` нет prebuild-скрипта, потому что модуль не использует кодогенерацию

## ✅ Монетизация
- [x] Доменные сущности: `ContourAccessType`, `SubscriptionPlanType`, `EntitlementType`, `SubscriptionEntity`, `UserEntitlementEntity`, `ProjectAccess`
- [x] `ProjectAccessCalculator` — чистая логика доступа (`domain/lib/src/logic/`)
- [x] UseCases монетизации (`get_active_subscription`, `is_no_ads_purchased`, `get_entitlement`, `grant_rewarded_unlock`, `buy_subscription`, `buy_project`, `restore_purchases`, `record_purchase`, `get_pending_purchases`, `watch_purchase_updates` и др.)
- [x] `MonetizationRepository` + `MonetizationRepositoryImpl`
- [x] Google Play Billing (`BillingPlatform`, `in_app_purchase`) — Stage 6
- [x] Подписки (No Ads / Premium) и индивидуальные покупки проектов
- [x] Модель Google Play: 2 продукта (`no_ads`, `premium`) × 3 base plan (`week` / `month` / `year`), `offerToken` резолвится из `subscriptionOfferDetails`
- [x] Смена плана с активной подписки через `ChangeSubscriptionParam` / `ReplacementMode.withTimeProration` (No Ads → Premium и смена base plan)
- [x] Защита от дублей `pending_purchases` для одного purchase token
- [x] Восстановление покупок (restore) с таймаутом `restoreResultTimeout`
- [x] История покупок: подписки с интервалом (неделя/месяц/год), пометка «Автообновление», разовые покупки с превью
- [x] `subscription_purchases` — отдельная запись на каждый оплаченный период, идемпотентность по `(purchase_token, expires_at)`
- [x] Очередь `pending_purchases` и её разрешение
- [x] Экран подписки (`SubscriptionBloc`, `SubscriptionScreen`, `PurchaseDialog`)
- [x] Rewarded-видео (Yandex Mobile Ads) и баннер в галерее — Stage 7
- [x] Supabase Edge Functions (`verify-purchase`, `google-play-webhook`) + миграция
- [x] Настройка `.env.sample` (ключи рекламы) и `AppConfig`
- [x] Кэш состояния подписки (`SubscriptionCache`, in-memory + SharedPreferences, TTL)
- [x] Аналитические события монетизации (`AnalyticsEvents`, `AnalyticsService`)
- [x] Локализованные сообщения об ошибках монетизации
- [x] Realtime-уведомления о возвратах (`RefundMonitor` на Supabase Realtime, `MonetizationRepository.watchRefunds`)
- [x] `RefundObserver` — единый модальный диалог возврата над любым экраном, merge, acknowledge
- [x] Перевод открытого холста в view-only при возврате (`MarkCurrentContourAsViewOnly`, `ViewOnlyReason`, баннер с причиной)
- [x] Реакция галереи на возврат в реальном времени (перезагрузка доступа по событию) + fallback на resume/pull-to-refresh
- [x] Фикс JWT clock skew в Edge Functions (`iat` со сдвигом −60с)
- [x] `docs/MONETIZATION.md` с разделами настройки и testing checklist

## ✅ Тестирование (опционально)
- [x] Unit тесты для `ProjectAccessCalculator` (все сценарии из `MONETIZATION.md` §3)
- [ ] Unit тесты для UseCases
- [ ] Unit тесты для BLoC

## ✅ Документация
- [x] Добавлены dartdoc комментарии
- [x] Создан README.md (обновляется отдельно)

## ✅ Деплой
- [ ] Настроена сборка для dev
- [ ] Настроена сборка для prod
- [x] Созданы иконки (`flutter_launcher_icons`, Android/iOS ресурсы)
- [x] Создан Splash Screen (`features/splash` + `flutter_native_splash`)
- [ ] Настроена публикация в магазины
