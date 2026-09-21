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
    └── utils/
        ├── constants.dart       # Константы приложения
        ├── logger.dart          # AppLogger
        ├── result.dart          # Result тип
        └── svg_utils.dart       # Утилиты для SVG (парсинг viewBox, скачивание XML)
```

**Публичный API (core.dart):** экспортирует все публичные компоненты модуля, а также:
- `package:flutter_dotenv/flutter_dotenv.dart`
- `package:easy_localization/easy_localization.dart`

**AppConfig:** содержит конфигурацию приложения в зависимости от флейвора. Поля: `flavor`, `supabaseUrl`, `supabaseAnonKey`, `googleWebClientId`, `appsFlyerDevKey`, `appleAppId`. Фабричный метод `fromFlavor(Flavor)`.

**app_locator.dart:** глобальный экземпляр `GetIt` для DI.

**CoreDi:** регистрирует `AppConfig` и `AppLogger` в `appLocator`.

**AppLocalization:** содержит `langFolderPath`, `supportedLocales`, `fallbackLocale`.


### core_ui
**Назначение:** UI компоненты (только виджеты, без DI)
**Содержит:**
- Переиспользуемые виджеты (кнопки, диалоги, поля ввода, карточки)
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
    │   └── app_theme.dart        # Только lightTheme
    ├── utils/
    │   └── responsive_helper.dart # Хелпер для определения типа устройства
    └── widgets/
        ├── buttons/
        │   ├── primary_button.dart
        │   └── icon_button.dart   # AppIconButton
        ├── dialogs/
        │   ├── loading_dialog.dart
        │   └── error_dialog.dart
        ├── inputs/
        │   ├── custom_slider.dart
        │   └── search_field.dart
        └── cards/
            └── contour_card.dart
```


**Публичный API (core_ui.dart):** экспортирует тему, все виджеты и `ResponsiveHelper`.

**Виджеты:**
- `PrimaryButton` — основная кнопка с закругленными углами
- `AppIconButton` — универсальная кнопка с иконкой и подписью для тулбаров (поддерживает активное состояние и кастомные размеры)
- `LoadingDialog` — диалог загрузки с индикатором
- `ErrorDialog` — диалог ошибки с кнопкой "Повторить"
- `CustomSlider` — кастомный слайдер (поддерживает градиенты и настройку цветов для разных панелей)
- `SearchField` — поле поиска с иконкой
- `ContourCard` — карточка контура для галереи

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
    │   ├── contour_entity.dart
    │   ├── project_entity.dart
    │   ├── stroke_entity.dart
    │   ├── user_entity.dart
    │   └── brush_type.dart
    ├── repositories/
    │   ├── auth_repository.dart
    │   ├── canvas_repository.dart
    │   ├── gallery_repository.dart
    │   ├── settings_repository.dart
    │   └── share_repository.dart
    └── use_cases/
        ├── auth/
        │   ├── check_auth_use_case.dart
        │   ├── sign_in_use_case.dart
        │   └── sign_in_silently_use_case.dart
        ├── canvas/
        │   ├── add_stroke_use_case.dart
        │   ├── export_image_params.dart
        │   ├── export_image_use_case.dart
        │   ├── load_project_use_case.dart
        │   ├── save_project_use_case.dart
        │   └── share_file_use_case.dart
        ├── gallery/
        │   ├── get_contour_by_id_use_case.dart
        │   ├── get_contours_by_ids_use_case.dart
        │   ├── get_contours_use_case.dart
        │   ├── get_favorite_ids_use_case.dart
        │   ├── get_work_in_progress_use_case.dart
        │   ├── toggle_favorite_use_case.dart
        │   └── get_used_categories_use_case.dart # Список непустых категорий
        ├── settings/
        │   ├── get_settings_use_case.dart
        │   └── update_settings_use_case.dart
        └── use_case.dart     # Базовые классы UseCase
```


**Публичный API (domain.dart):** экспортирует все сущности, репозитории, usecases и DI.

**Базовые классы UseCase:** (`domain/lib/src/use_cases/use_case.dart`)
- `UseCase<Input, Output>` — синхронный UseCase
- `FutureUseCase<Input, Output>` — асинхронный UseCase
- `StreamUseCase<Input, Output>` — стримовый UseCase
- `NoParams` — класс-заглушка для случаев без параметров

**Сущности:**
- `UserEntity` — пользователь (id, email, name, avatarUrl)
- `ContourEntity` — контур (id, title, category, svgUrl, previewUrl)
- `ContourCategory` — enum категорий контура. `all` — UI-значение «Все категории».
- `ProjectEntity` — проект (id, contourId, userId, data, lastOpened, createdAt)
- `StrokeEntity` — мазок (points, color, size, opacity, brushType)
- `BrushType` — enum (circle, square, watercolor, chalk, marker, calligraphy, texture, airbrush)

**Репозитории (интерфейсы):**
- `AuthRepository` — checkAuth(), signIn(), signInSilently()
- `GalleryRepository` — getContours, getContoursByIds, getFavoriteIds, toggleFavorite, getWorkInProgress, getContourById, getUsedCategories
- `CanvasRepository` — addStroke, saveProject, loadProject, exportImage, saveImageToGallery
- `SettingsRepository` — getLanguageCode, saveLanguageCode
- `ShareRepository` — shareFile

**UseCases:**
- `CheckAuthUseCase` — проверяет авторизацию
- `GetUsedCategoriesUseCase` — возвращает список категорий, в которых есть контуры
- `GetContoursUseCase` — получает список контуров с пагинацией
- `AddStrokeUseCase` — добавляет мазок
- `SaveProjectUseCase` — сохраняет проект
- `LoadProjectUseCase` — загружает проект
- `ExportImageUseCase` — экспортирует изображение (использует кэшированный SVG контур)
- `SaveImageToGalleryUseCase` — сохраняет файл в галерею устройства

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
    ├── constants/
    │   └── request_constants.dart
    ├── di/
    │   └── data_di.dart
    ├── mappers/
    │   ├── contour_mapper.dart
    │   ├── project_mapper.dart
    │   └── stroke_mapper.dart
    ├── models/
    │   ├── contour_model.dart
    │   ├── project_model.dart
    │   ├── stroke_model.dart
    │   └── user_model.dart
    ├── providers/
    │   ├── supabase_provider.dart
    │   ├── database_provider.dart     # Drift AppDatabase
    │   ├── auth_remote_provider.dart
    │   ├── gallery_remote_provider.dart
    │   ├── gallery_local_provider.dart
    │   ├── canvas_remote_provider.dart
    │   └── canvas_local_provider.dart
    ├── repositories/
    │   ├── auth_repository_impl.dart
    │   ├── canvas_repository_impl.dart
    │   ├── gallery_repository_impl.dart
    │   ├── settings_repository_impl.dart
    │   └── share_repository_impl.dart
    └── services/
        ├── share_service.dart
        ├── gallery_saver_service.dart
        └── canvas_rendering_service.dart # Рендеринг в PNG
```


**Публичный API (data.dart):** экспортирует все реализации репозиториев, провайдеры, сервисы и DI.

**Провайдеры:**
- `SupabaseProvider` — инициализация Supabase с конфигом
- `AppDatabase` (Drift) — база данных SQLite с таблицами `Projects`, `Strokes` и `Contours`. Схема v3 (svg_url вместо svg_data).
- `GalleryRemoteProvider` — получение контуров и избранного из Supabase. Метод `getUsedCategories` через `select(category)`.
- `CanvasRenderingService` — рендеринг холста в PNG. Использует raw XML контура.

**Models (DTO):** `UserModel`, `ContourModel` (svg_data из БД мапится в svgUrl), `ProjectModel`, `StrokeModel`

**Mappers:** преобразуют Models ↔ Entities

**Реализации репозиториев:** `AuthRepositoryImpl`, `GalleryRepositoryImpl`, `CanvasRepositoryImpl`, `SettingsRepositoryImpl`, `ShareRepositoryImpl`

**Сервисы:**
- `ShareService` — статический сервис-обертка над `share_plus`.
- `GallerySaverService` — статический сервис-обертка над `saver_gallery`.

**DataDI:** регистрирует провайдеры, сервисы и репозитории в правильном порядке.


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
    │   ├── app_router.dart       # Определение маршрутов: Splash, Canvas, Gallery, Settings
    │   └── app_router.gr.dart    # Минимальная заглушка (part-of)
    └── di/
        └── navigation_di.dart
```

**Публичный API (navigation.dart):** экспортирует классы `auto_route`, а также `AppRouter` и `NavigationDI`.

**AppRouter:** корневой роутер приложения находится в модуле `navigation`:
- `navigation/lib/src/app_router/app_router.dart` — определение маршрутов в порядке: Splash, Canvas, Gallery, Settings. `SplashRoute` — initial.

Использует `@AutoRouterConfig` с `replaceInRouteName: 'Screen|Page,Route'`.

**NavigationDI:** регистрирует `AppRouter` в `appLocator`.


### features
**Назначение:** Фичи приложения

**Каждая фича содержит:**
- BLoC (события, состояния)
- Экраны (Screens)
- Виджеты (Widgets)
- Публичный API (`splash.dart`, `gallery.dart`, `canvas.dart`, `settings.dart`)

**Предоставление BLoC:** происходит на уровне экранов (Screens) через `BlocProvider`. Зависимости (UseCases, Router) внедряются в конструктор BLoC из `appLocator`.

**Галерея (gallery):**
- Поддерживает адаптивную сетку (2 или 3 колонки через `ResponsiveHelper`).
- Фильтрует пустые категории, запрашивая список используемых через `GetUsedCategoriesUseCase`.

**Холст (canvas):**
- Синхронизированная загрузка: лоадер висит до полной подготовки мазков и SVG-контура.
- **Bitmap Baking:** высокая производительность за счет «запекания» завершенных мазков в растровый буфер.


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

### Оптимизации отрисовки (CanvasPainter)
- **drawPath:** Для кистей с постоянной шириной используется `canvas.drawPath` вместо сотен `canvas.drawLine`, что значительно быстрее.
- **Filtering:** В `CanvasBloc` игнорируются точки, расстояние до которых меньше `Constants.minPointDistance` (1.5px).


## Dependency Injection (appLocator)
### Глобальный экземпляр
```dart
// core/lib/src/di/app_locator.dart
final GetIt appLocator = GetIt.instance;
```


## Локализация (easy_localization)
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
- `Strokes` — мазки (теперь включают `brushId` и `isPressureSensitive`).
- `Contours` — кэш метаданных контура (с полем `svg_url`).

### Генерация кода
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Ключевые константы
| Константа | Значение |
|-----------|----------|
| `maxUndoSteps` | 5 |
| `pageSize` | 20 |
| `minPointDistance` | 1.5 |
| `contourDefaultOpacity` | 1.0 |
| `autosaveDebounce` | 500ms |

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
