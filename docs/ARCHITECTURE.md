# Архитектура приложения

## Общие принципы

Приложение следует принципам **Clean Architecture** и **SOLID**. Все технические решения и стандарты написания кода подробно описаны в документе **[Flutter Good Practices](GOOD_PRACTICES.md)**.

## Общая архитектура (Clean Architecture)

Приложение разделено на Dart/Flutter модули (package), каждый со своим `pubspec.yaml`:
`core`, `core_ui`, `domain`, `data`, `navigation`, `features/*`.

### Слои
- **Presentation:** BLoC для управления состоянием, экраны и виджеты. BLoC создаются на уровне экрана через `BlocProvider`.
- **Domain:** Чистая бизнес-логика. UseCases возвращают данные или выбрасывают исключения.
- **Data:** Репозитории управляют логикой синхронизации. Состояние рисунка хранится локально в Drift для мгновенного отклика. Синхронизация с Supabase (JSON проекта) происходит при сохранении/автосохранении. Профиль пользователя синхронизируется с таблицей `users` автоматически на стороне БД через триггеры Supabase.

### Точки входа
Приложение не использует `lib/main.dart`. Вместо этого запуск выполняется через флейвор-специфичные точки входа:
- `lib/main_dev.dart` — development-конфигурация (`Flavor.dev`).
- `lib/main_prod.dart` — production-конфигурация (`Flavor.prod`).

Обе точки входа делегируют общую инициализацию `main_common.dart`, который настраивает DI, локализацию и роутер.


## Модули и их ответственность

### core
**Назначение:** Ядро приложения
**Содержит:**
- Локализация (`easy_localization` + генерация ключей)
- Утилиты (константы, логгер, `Result`)
- Конфигурация (`AppConfig`, `Flavor`)
- DI (`appLocator`, `CoreDi`)
- Ресурсы: переводы в `resources/lang/`

**Структура:**
```text
core/lib/
├── core.dart                    # Публичный API
└── src/
    ├── config/
    │   └── app_config.dart      # AppConfig с Flavor
    ├── di/
    │   ├── app_locator.dart     # GetIt instance
    │   └── core_di.dart         # Регистрация core зависимостей
    ├── error_handler/
    │   └── error_handler.dart   # Реэкспорт базового ErrorHandler
    ├── localization/
    │   ├── app_localization.dart
    │   ├── localization.dart    # Реэкспорт локализации
    │   └── generated/
    │       └── locale_keys.g.dart   # Автогенерируемые ключи
    ├── services/
    │   ├── analytics_service.dart   # Аналитические события
    │   └── app_version.dart         # Номер сборки для dev-сборок
    └── utils/
        ├── constants.dart       # Константы приложения
        ├── logger.dart          # AppLogger
        ├── result.dart          # Result тип
        ├── svg_utils.dart       # Утилиты для SVG (парсинг viewBox, скачивание XML)
        └── url_utils.dart       # Работа с URL
```

**Публичный API (core.dart):** экспортирует все публичные компоненты модуля, а также:
- `package:flutter_dotenv/flutter_dotenv.dart`
- `package:easy_localization/easy_localization.dart`
- `package:flutter_bloc/flutter_bloc.dart`
- `package:bloc_concurrency/bloc_concurrency.dart`

**AppConfig:** содержит конфигурацию приложения в зависимости от флейвора. Поля: `flavor`, `supabaseUrl`, `supabaseAnonKey`, `googleWebClientId`, `appsFlyerDevKey`, `appleAppId`, `yandexAdsRewardedUnitId`, `yandexAdsBannerUnitId`. Фабричный метод `fromFlavor(Flavor)`.

**app_locator.dart:** глобальный экземпляр `GetIt` для DI.

**CoreDi:** регистрирует `AppConfig`, `AppLogger` и `AnalyticsService` в `appLocator`.

**AppLocalization:** содержит `langFolderPath`, `supportedLocales`, `fallbackLocale`.


### core_ui
**Назначение:** UI компоненты (только виджеты, без DI)
**Содержит:**
- Переиспользуемые виджеты (кнопки, контейнеры, диалоги, поля ввода)
- Тема и стили (только светлая тема)
- Ресурсы: шрифты, иконки, изображения
- Адаптивность (`ResponsiveHelper`)

**Структура:**
```text
core_ui/lib/
├── core_ui.dart # Публичный API
└── src/
    ├── constants/
    │   └── package_constants.dart
    ├── theme/
    │   ├── app_colors.dart
    │   ├── app_dimens.dart
    │   ├── app_fonts.dart
    │   ├── app_icons.dart
    │   ├── app_images.dart
    │   └── app_theme.dart        # Только lightTheme
    ├── utils/
    │   └── responsive_helper.dart # Хелпер для определения типа устройства
    └── widgets/
        ├── buttons/
        │   ├── app_button.dart
        │   ├── primary_button.dart
        │   └── icon_button.dart   # AppIconButton
        ├── containers/
        │   └── toolbar_container.dart
        ├── dialogs/
        │   ├── loading_dialog.dart
        │   ├── error_dialog.dart
        │   └── refund_dialog.dart
        └── inputs/
            ├── app_dropdown.dart
            ├── gradient_slider.dart
            └── search_field.dart
```


**Публичный API (core_ui.dart):** экспортирует тему, все виджеты и `ResponsiveHelper`.

**Виджеты:**
- `PrimaryButton` — основная кнопка с закругленными углами
- `AppButton` — кнопка с настраиваемым цветом, заливкой и компактным режимом
- `AppIconButton` — универсальная кнопка с иконкой и подписью для тулбаров (поддерживает активное состояние и кастомные размеры)
- `ToolbarContainer` — общий контейнер плавающих панелей холста
- `LoadingDialog` — диалог загрузки с индикатором
- `ErrorDialog` — диалог ошибки с кнопкой "Повторить"
- `RefundDialog` — модальный диалог уведомления о возврате покупки
- `GradientSlider` — кастомный слайдер (поддерживает градиенты и настройку цветов для разных панелей)
- `AppDropdown<T>` — выпадающий список
- `SearchField` — поле поиска с иконкой

Карточка контура (`ContourCard`) находится в модуле `features/gallery`, а не в `core_ui`.

**ResponsiveHelper:** предоставляет метод `isTablet(context)` (порог 600dp) для адаптивной верстки (например, изменение количества колонок в галерее).


### domain
**Назначение:** Бизнес-логика
**Содержит:**
- Интерфейсы репозиториев
- UseCases
- Доменные модели
- Базовые классы UseCase
- DI (`DomainDI`)

**Структура:**
```text
domain/lib/
├── domain.dart # Публичный API
└── src/
    ├── di/
    │   └── domain_di.dart
    ├── entities/
    │   ├── billing_product_entity.dart
    │   ├── brush_type.dart
    │   ├── contour_access_type.dart
    │   ├── contour_category.dart
    │   ├── contour_entity.dart
    │   ├── entitlement_type.dart
    │   ├── feedback_entity.dart
    │   ├── gallery_item_entity.dart
    │   ├── pending_purchase_entity.dart
    │   ├── project_access.dart
    │   ├── project_entity.dart
    │   ├── purchase_refund_entity.dart
    │   ├── purchase_update_entity.dart
    │   ├── stroke_entity.dart
    │   ├── subscription_entity.dart
    │   ├── subscription_interval.dart
    │   ├── subscription_plan_type.dart
    │   ├── subscription_price_entity.dart
    │   ├── tool_entity.dart
    │   ├── user_entitlement_entity.dart
    │   ├── user_entity.dart
    │   └── work_in_progress_entity.dart
    ├── logic/
    │   ├── project_access_calculator.dart
    │   └── stale_subscription_pending.dart
    ├── repositories/
    │   ├── auth_repository.dart
    │   ├── canvas_repository.dart
    │   ├── feedback_repository.dart
    │   ├── gallery_repository.dart
    │   ├── monetization_repository.dart
    │   ├── settings_repository.dart
    │   └── share_repository.dart
    └── use_cases/
        ├── auth/          # CheckAuth, SignIn, SignInSilently, GetCurrentUser, DeleteAccount
        ├── canvas/        # AddStroke, Load/SaveProject, ExportImage, RenderProjectThumbnail,
        │                  # GetAvailableTools, SaveImageToGallery, ShareFile, canvas onboarding
        ├── feedback/      # SubmitFeedback
        ├── gallery/       # GetContours, GetContoursByIds, GetContourById, GetFavoriteIds,
        │                  # ToggleFavorite, GetWorkInProgress, GetUsedCategories
        ├── monetization/  # подписки, покупки, история, pending, refunds, rewarded unlock
        ├── settings/      # GetSettings, UpdateSettings
        └── use_case.dart  # Базовые классы UseCase
```


**Публичный API (domain.dart):** экспортирует все сущности, репозитории, usecases и DI.

**Базовые классы UseCase:** (`domain/lib/src/use_cases/use_case.dart`)
- `UseCase<Input, Output>` — синхронный UseCase
- `FutureUseCase<Input, Output>` — асинхронный UseCase
- `StreamUseCase<Input, Output>` — стримовый UseCase
- `NoParams` — класс-заглушка для случаев без параметров

**Сущности:**
- `UserEntity` — пользователь (id, email, name, avatarUrl)
- `ContourEntity` — контур (id, title, category, svgUrl, previewUrl, createdAt, accessType, price, productId)
- `ContourCategory` — enum категорий контура. `all` — UI-значение «Все категории».
- `ContourAccessType` — enum доступа: `free`, `rewarded`, `paid`
- `ProjectEntity` — проект (id, contourId, userId, data, lastOpened, createdAt)
- `StrokeEntity` — мазок (`List<StrokePoint>`, color, size, opacity, brushType, brushId, isPressureSensitive); `StrokePoint` хранит offset и pressure
- `ToolEntity` — доступный инструмент (id, nameKey, previewPath, isPressureSensitive)
- `BrushType` — enum (circle, square, watercolor, chalk, marker, calligraphy, texture, airbrush)
- `SubscriptionEntity`, `SubscriptionPlanType`, `SubscriptionInterval`, `SubscriptionPriceEntity` — подписка, план, период и цена
- `UserEntitlementEntity`, `EntitlementType` — право доступа к проекту
- `ProjectAccess`, `GalleryItemEntity` — вычисленный уровень доступа и элемент галереи
- `PendingPurchaseEntity`, `PurchaseUpdateEntity`, `BillingProductEntity` — состояние покупок
- `PurchaseRefundEntity` — возврат покупки
- `FeedbackEntity`, `FeedbackType` — обратная связь и её тип
- `WorkInProgressEntity` — начатый проект для фильтра «В работе»

**Логика:**
- `ProjectAccessCalculator` — чистая функция расчёта доступа к проекту
- `stale_subscription_pending.dart` — определяет устаревшую pending-подписку

**Репозитории (интерфейсы):**
- `AuthRepository` — checkAuth(), getCurrentUser(), signIn(), signInSilently(), deleteAccount()
- `GalleryRepository` — getContours, getContoursByIds, getFavoriteIds, toggleFavorite, getWorkInProgress, getContourById, getUsedCategories
- `CanvasRepository` — getAvailableTools, addStroke, saveProject, deleteProject, loadProject, exportImage, renderProjectThumbnail, saveImageToGallery
- `MonetizationRepository` — подписки, покупки проектов/кредитов, restore, pending, refunds, `watchRefunds`, `purchaseUpdates`
- `SettingsRepository` — getLanguageCode, saveLanguageCode, canvas onboarding
- `ShareRepository` — shareFile
- `FeedbackRepository` — submitFeedback

**UseCases:** сгруппированы по папкам `auth`, `canvas`, `feedback`, `gallery`, `monetization`, `settings`. Помимо базовых сценариев (CheckAuth, GetContours, AddStroke, SaveProject, ExportImage, SaveImageToGallery), есть монетизация: получение подписки/ entitlements, покупка подписки, проекта и кредита, восстановление, очередь pending-покупок, история и возвраты.

**DomainDI:** регистрирует все UseCase в `appLocator` с использованием `registerLazySingleton`.


### data
**Назначение:** Реализация репозиториев и работа с внешними источниками данных
**Содержит:**
- Реализации репозиториев
- Провайдеры (`Provider`) — источники данных: Supabase, Drift/SQLite
- Сервисы (`Service`) — переиспользуемые платформенные операции (шаринг, пермишены и т.д.)
- Data модели (DTO)
- Мапперы (модель ↔ сущность)
- Константы запросов (`RequestConstants`)
- DI (`DataDI`)

В модуле `data` нет папки `datasources`; вместо неё используется `providers/`.

**Структура:**
```text
data/lib/
├── data.dart # Публичный API
└── src/
    ├── cache/
    │   └── subscription_cache.dart   # In-memory + SharedPreferences, TTL
    ├── constants/
    │   ├── ad_constants.dart
    │   ├── analytics_events.dart
    │   └── request_constants.dart
    ├── di/
    │   └── data_di.dart
    ├── mappers/
    │   ├── contour_mapper.dart
    │   ├── pending_purchase_mapper.dart
    │   ├── project_mapper.dart
    │   ├── purchase_refund_mapper.dart
    │   ├── stroke_mapper.dart
    │   ├── subscription_mapper.dart
    │   └── user_entitlement_mapper.dart
    ├── models/
    │   ├── contour_model.dart
    │   ├── pending_purchase_model.dart
    │   ├── project_model.dart
    │   ├── purchase_refund_model.dart
    │   ├── stroke_model.dart
    │   ├── subscription_model.dart
    │   ├── subscription_purchase_model.dart
    │   ├── user_entitlement_model.dart
    │   └── user_model.dart
    ├── providers/
    │   ├── supabase_provider.dart
    │   ├── database_provider.dart     # Drift AppDatabase
    │   ├── auth_remote_provider.dart
    │   ├── gallery_remote_provider.dart
    │   ├── gallery_local_provider.dart
    │   ├── canvas_remote_provider.dart
    │   ├── canvas_local_provider.dart
    │   ├── feedback_remote_provider.dart
    │   └── monetization_remote_provider.dart
    ├── repositories/
    │   ├── auth_repository_impl.dart
    │   ├── canvas_repository_impl.dart
    │   ├── feedback_repository_impl.dart
    │   ├── gallery_repository_impl.dart
    │   ├── monetization_repository_impl.dart
    │   ├── settings_repository_impl.dart
    │   └── share_repository_impl.dart
    ├── services/
    │   ├── ad_service.dart / ad_service_factory.dart / yandex_ad_service.dart
    │   ├── yandex_banner_ad_view.dart
    │   ├── billing_platform.dart / google_play_billing_platform.dart
    │   ├── apple_billing_platform.dart / billing_platform_factory.dart
    │   ├── refund_monitor.dart / supabase_refund_monitor.dart
    │   ├── rewarded_ad_outcome.dart / stub_ad_service.dart
    │   ├── share_service.dart
    │   ├── gallery_saver_service.dart
    │   └── canvas_rendering_service.dart # Рендеринг в PNG
    └── utils/
        └── server_time.dart          # Парсинг UTC-времени с сервера
```


**Публичный API (data.dart):** экспортирует все реализации репозиториев, провайдеры, сервисы, модели, мапперы и DI.

**Провайдеры:**
- `SupabaseProvider` — инициализация Supabase с конфигом
- `AppDatabase` (Drift) — база данных SQLite с таблицами `Projects`, `Strokes`, `Brushes` и `Contours`. Текущая схема — v5.
- `GalleryRemoteProvider` — получение контуров и избранного из Supabase. Метод `getUsedCategories` выбирает `category` из всех строк, а уникальность обеспечивает на клиенте через `Set`.
- `MonetizationRemoteProvider` — подписки, покупки, entitlements, pending-покупки и возвраты.
- `FeedbackRemoteProvider` — загрузка вложений в Storage и запись обратной связи.
- `CanvasRenderingService` — рендеринг холста в PNG. Использует raw XML контура.

**Models (DTO):** `UserModel`, `ContourModel` (удалённое поле `svg_data` мапится в `svgUrl`), `ProjectModel`, `StrokeModel`, `SubscriptionModel`, `SubscriptionPurchaseModel`, `UserEntitlementModel`, `PendingPurchaseModel`, `PurchaseRefundModel`.

**Mappers:** преобразуют Models ↔ Entities.

**Реализации репозиториев:** `AuthRepositoryImpl`, `GalleryRepositoryImpl`, `CanvasRepositoryImpl`, `MonetizationRepositoryImpl`, `SettingsRepositoryImpl`, `ShareRepositoryImpl`, `FeedbackRepositoryImpl`.

**Сервисы:**
- `ShareService` — статический сервис-обертка над `share_plus`.
- `GallerySaverService` — статический сервис-обертка над `saver_gallery`.
- `BillingPlatform` / `GooglePlayBillingPlatform` — покупки через `in_app_purchase`.
- `AdService` / `YandexAdService` — Rewarded Video и баннер.
- `RefundMonitor` / `SupabaseRefundMonitor` — realtime-уведомления о возвратах.
- `SubscriptionCache` — кэш состояния подписки с TTL.

**DataDI:** регистрирует провайдеры, сервисы и репозитории в правильном порядке, включая инициализацию биллинга и рекламы.


### navigation
**Назначение:** Навигация
**Содержит:**
- Реэкспорт `auto_route` (публичный API для навигации)
- Корневой роутер приложения (`AppRouter`)
- DI-регистрация роутера (`NavigationDI`)

**Структура:**
```text
navigation/lib/
├── navigation.dart
└── src/
    ├── app_router/
    │   ├── app_router.dart       # Маршруты: Splash, Canvas, Gallery, Settings, Subscription
    │   └── app_router.gr.dart    # Сгенерированный код auto_route
    ├── di/
    │   └── navigation_di.dart
    └── guards/
        └── auth_guard.dart       # Проверка авторизации перед защищёнными маршрутами
```

**Публичный API (navigation.dart):** экспортирует классы `auto_route`, а также `AppRouter` и `NavigationDI`.

**AppRouter:** корневой роутер приложения находится в модуле `navigation`:
- `navigation/lib/src/app_router/app_router.dart` — определение маршрутов в порядке: Splash, Canvas, Gallery, Settings, Subscription. `SplashRoute` — initial.
- Все маршруты, кроме `SplashRoute`, подключены с `AuthGuard`.

Использует `@AutoRouterConfig` с `replaceInRouteName: 'Screen|Page,Route'`.

**AuthGuard:** проверяет текущую авторизацию, затем пытается выполнить silent sign-in и интерактивный вход. Если все попытки неуспешны, выполняется переход на `SplashRoute`.

**NavigationDI:** регистрирует `AuthGuard`, `AppRouter` и `AutoRouteObserver` в `appLocator`.


### features
**Назначение:** Фичи приложения

**Каждая фича содержит:**
- BLoC (события, состояния) либо набор виджетов/логики; `feedback` содержит `FeedbackBloc` без отдельного экрана
- Экраны (Screens)
- Виджеты (Widgets)
- Публичный API (`splash.dart`, `gallery.dart`, `canvas.dart`, `settings.dart`, `subscription.dart`, `feedback.dart`)

**Предоставление BLoC:** происходит на уровне экранов (Screens) через `BlocProvider`. Зависимости (UseCases, Router) внедряются в конструктор BLoC из `appLocator`.

**Галерея (gallery):**
- Поддерживает адаптивную сетку (2 или 3 колонки в портрете, 4 в ландшафте).
- Фильтрует пустые категории, запрашивая список используемых через `GetUsedCategoriesUseCase`.
- Показывает бейджи доступа, баннер рекламы и обрабатывает покупку/просмотр rewarded-видео.
- Реагирует на возвраты и обновляет доступ без полной перезагрузки экрана.

**Холст (canvas):**
- Синхронизированная загрузка: лоадер висит до полной подготовки мазков и SVG-контура.
- **Bitmap Baking:** высокая производительность за счет «запекания» завершенных мазков в растровый буфер.
- Поддерживает режим только просмотра (`isViewOnly`) с баннером причины и кнопкой разблокировки.

**Подписка (subscription):**
- Экран статуса, тарифов No Ads / Premium, восстановления покупок и истории.
- Фоновая проверка статуса показывает тонкий `LinearProgressIndicator`, не скрывая контент.
- Не содержит кнопки отмены подписки: отмена выполняется в Google Play.

**Обратная связь (feedback):**
- Форма с типом обращения, email и вложениями.
- Используется в настройках и в уведомлении об устаревшей pending-покупке.


## State Management (BLoC)

### Принципы BLoC
1. Единый класс состояния (extends Equatable)
2. Абстрактные события (extends Equatable)
3. Обработчики событий — приватные методы `_on...`
4. Использование `copyWith` для обновления состояния
5. Обработка ошибок через ErrorHandler и ErrorDialog.

### Формат State
```dart
enum SomeStatus { initial, loading, success, failure }

class SomeState extends Equatable {
  final SomeStatus status;
  final Data? data;
  final String? error;

  // ... copyWith, props
}
```


## Rendering & Performance (Bitmap Baking)

### Архитектура холста
Для обеспечения плавности 60/120 FPS на холстах с тысячами мазков используется гибридная архитектура:

1. **_FinishedStrokesLayer (RasterCanvasBuffer):** 
   - Все завершенные мазки «запекаются» в один объект `ui.Image` (битмап) в памяти.
   - Использует `RepaintBoundary` для кэширования картинки в GPU.
   - Перерисовывается **только** при завершении нового мазка (инкрементально) или при Undo/Redo (полный пересчет).
   - Это обеспечивает O(1) производительность при панорамировании и зуме.

2. **_ActiveStrokeLayer:** 
   - Рисует только ту линию, которую пользователь ведет пальцем в данный момент.
   - Использует векторную отрисовку для максимальной точности.
   - Частота обновления — каждый кадр, но нагрузка минимальна, так как мазок всего один.

3. **_ContourLayerWrapper:**
   - Рисует SVG-контур поверх всего.
   - Изолирован через `RepaintBoundary`.

### Оптимизации отрисовки (StrokeRenderer / ActiveStrokePainter)
- **drawPath:** Для кистей с постоянной шириной `StrokeRenderer.drawStroke` и `ActiveStrokePainter` используют `canvas.drawPath` вместо сотен `canvas.drawLine`, что значительно быстрее. Для pressure-sensitive мазков ширина меняется посегментно через `drawLine`.
- **Filtering:** В `CanvasBloc` игнорируются точки, расстояние до которых меньше `Constants.minPointDistance` (1.5px).
- **CanvasPainter** (`features/canvas/lib/src/painters/canvas_painter.dart`) содержит базовую реализацию рисования списка мазков, но в текущем `CanvasStack` не инстанцируется.

### Рисование за границами страницы
Мазок не прерывается на краях страницы: пока палец (или указатель мыши) не отпущен, точки продолжают
добавляться в тот же мазок, даже если указатель ушел за пределы страницы и вернулся обратно.

- **Ввод:** `Listener` в `CanvasScreen` перехватывает указатель на весь жест (`_activeDrawPointer`).
  Проверка «указатель на странице» выполняется только в начале жеста; выход за край больше не завершает мазок.
- **Видимая область:** `CanvasStack` — это и есть страница, а `ClipRect` обрезает краску за её пределами.
  Экспорт и превью рендерят те же прямоугольники страницы, поэтому за край ничего не попадает.
- **Bleed-зона:** координаты точек ограничиваются прямоугольником «страница + 1.5 от большей стороны»
  (`_strokeBounds`). Палец может уйти дальше, чем на весь экран (на минимальном зуме), но такие выходы
  за пределы bleed невозможны, поэтому точность линии у края не страдает, а координаты остаются конечными.
- **Слой прозрачности:** `StrokeRenderer.drawStroke` и `ActiveStrokePainter` ограничивают `saveLayer`
  страницей (`visibleArea`), иначе полупрозрачный мазок, ушедший за край, раздувал бы offscreen-буфер.
- **Пустые мазки:** жест, не оставивший ни одной точки на странице (в т.ч. обычный тап), не сохраняется:
  отправляется `CancelDrawing`.


## Dependency Injection (appLocator)
### Глобальный экземпляр
```dart
// core/lib/src/di/app_locator.dart
final GetIt appLocator = GetIt.instance;
```


## Локализация (easy_localization)
### Поддерживаемые языки
`en-US`, `ru-RU`, `es-ES`, `pt-BR`, `be-BY`, `de-DE`, `fr-FR`
(`AppLocalization.supportedLocales`). Файлы переводов лежат в
`core/resources/lang/`, ключи генерируются через `prebuild_script_core.sh`.

Сохранённый код языка нормализуется в `SettingsBloc`: `_` заменяется на `-`,
регистр приводится к нижнему, поддерживается код без региона (например, `ru`),
а неизвестный код откатывается к `en-US` (`AppLocalization.fallbackLocale`).

### Использование в коде
```dart
Text(LocaleKeys.gallery).tr();
```


## Обработка ошибок
### Глобальный ErrorHandler
Централизованный перехват ошибок. Показывает `ErrorDialog` через контекст навигатора.
В `CanvasScreen` лоадер автоматически скрывается при ошибке (`status == CanvasStatus.error`), позволяя пользователю увидеть сообщение об ошибке.


## Drift (SQLite) база данных
### Таблицы
- `Projects` — данные проекта и настройки контура (цвет, прозрачность).
- `Strokes` — мазки (включают `brushId` и `isPressureSensitive`).
- `Brushes` — доступные инструменты (`id`, `nameKey`, `previewPath`, `isPressureSensitive`).
- `Contours` — кэш метаданных контура (`svg_url`, а также `access_type`, `price`, `product_id`).

Текущая версия схемы — `schemaVersion = 5`. Миграции добавляют `Brushes` и поля мазков (v2), переименовывают `svg_data` → `svg_url` (v3), добавляют поля монетизации (v4) и `product_id` (v5).

### Генерация кода
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Ключевые константы
| Константа | Значение |
|-----------|----------|
| `maxUndoSteps` | 5 |
| `maxStrokePoints` | 1000 |
| `pageSize` | 20 |
| `defaultBrushSize` | 10.0 |
| `minBrushSize` | 1.0 |
| `maxBrushSize` | 100.0 |
| `defaultOpacity` | 1.0 |
| `contourDefaultOpacity` | 1.0 |
| `minPointDistance` | 1.5 |
| `autosaveDebounce` | 500ms |
| `stalePendingPurchaseThreshold` | 24h |
| `refundChannelReconnectDelay` | 2s |
| `refundDialogMergeWindow` | 400ms |

---

## Типы кистей (enum)
`circle`, `square`, `watercolor`, `chalk`, `marker`, `calligraphy`, `texture`, `airbrush`.

---

## Константы вместо строк
Все ключи БД и параметры API живут в `RequestConstants`.

## Сервисы
Платформенные операции (шаринг, сохранение в галерею) вынесены в статические сервисы в модуле `data`.

---

## Best Practices

1. **Разделение UI и логики.**
2. **Изоляция рендеринга.** Разделение на растровые и векторные слои.
3. **Адаптивность.** Использование `ResponsiveHelper` для планшетов.
4. **Загрузка данных.** SVG контуры загружаются из Supabase Storage по URL.
5. **Тема.** Только светлая тема.
