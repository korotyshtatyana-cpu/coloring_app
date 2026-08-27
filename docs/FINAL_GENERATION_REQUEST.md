# ЗАПРОС НА ГЕНЕРАЦИЮ ПРОЕКТА "РАСКРАСКА PRO"

## ЦЕЛЬ
Сгенерировать полный код Flutter-приложения "Раскраска PRO" на основе архитектуры, описанной в документации проекта.

## ИСХОДНЫЕ ДАННЫЕ
Проект уже имеет настроенную структуру папок и базовые файлы. Документация находится в папке `docs/`:
- `PROJECT_OVERVIEW.md` — общее описание проекта
- `ARCHITECTURE.md` — архитектура и структура
- `GENERATION_INSTRUCTIONS.md` — инструкция для генерации
- `API_SPEC.md` — спецификация API (Supabase)
- `UI_SPEC.md` — спецификация UI экранов и виджетов
- `CHECKLIST.md` — чек-лист разработки

## ТЕКУЩЕЕ СОСТОЯНИЕ ПРОЕКТА

### ✅ Уже готово (создано вручную)

**Core:**
- `core/lib/core.dart` — публичный API (экспортирует AppConfig, CoreDi, AppLocalization, dotenv, easy_localization, locale keys, utils)
- `core/lib/src/config/app_config.dart` — AppConfig с Flavor, fromFlavor
- `core/lib/src/di/core_di.dart` — регистрация AppConfig, AppLogger
- `core/lib/src/di/app_locator.dart` — глобальный GetIt
- `core/lib/src/utils/constants.dart` — константы, включая `autosaveDebounce`
- `core/lib/src/utils/logger.dart` — AppLogger
- `core/lib/src/utils/result.dart` — Result
- `core/lib/src/localization/app_localization.dart` — настройки локализации
- `core/lib/src/localization/generated/locale_keys.g.dart` — сгенерированные ключи
- `core/lib/src/error_handler/error_handler.dart` — базовый обработчик

**Core_UI:**
- `core_ui/lib/core_ui.dart` — публичный API
- `core_ui/lib/src/theme/` — app_colors.dart, app_dimens.dart, app_fonts.dart, app_theme.dart (только `lightTheme`)
- `core_ui/lib/src/widgets/` — PrimaryButton, AppIconButton, LoadingDialog, ErrorDialog, CustomSlider, SearchField, ContourCard

**Domain:**
- `domain/lib/domain.dart` — публичный API
- `domain/lib/src/di/domain_di.dart` — регистрация UseCases
- `domain/lib/src/entities/` — UserEntity, ContourEntity, ProjectEntity, StrokeEntity, BrushType
- `domain/lib/src/repositories/` — AuthRepository, GalleryRepository, CanvasRepository, SettingsRepository, ShareRepository
- `domain/lib/src/use_cases/` — все use cases
- `domain/lib/src/use_cases/use_case.dart` — базовые классы UseCase
- `domain/lib/src/use_cases/canvas/export_image_params.dart` — параметры экспорта

**Data:**
- `data/lib/data.dart` — публичный API
- `data/lib/src/di/data_di.dart` — регистрация провайдеров, сервисов, репозиториев
- `data/lib/src/providers/` — SupabaseProvider, AppDatabase (Drift), AuthRemoteProvider, GalleryRemoteProvider, GalleryLocalProvider, CanvasRemoteProvider, CanvasLocalProvider
- `data/lib/src/models/` — UserModel, ContourModel, ProjectModel, StrokeModel
- `data/lib/src/mappers/` — ContourMapper, ProjectMapper, StrokeMapper
- `data/lib/src/repositories/` — AuthRepositoryImpl, GalleryRepositoryImpl, CanvasRepositoryImpl, SettingsRepositoryImpl
- `data/lib/src/services/` — ShareService
- `data/lib/src/constants/request_constants.dart` — константы Supabase
- Drift: таблицы `Projects`, `Strokes`, `Contours`; `schemaVersion = 1`

**Navigation:**
- `navigation/lib/navigation.dart` — публичный API, экспортирует `auto_route`, `AppRouter`, `NavigationDI`
- `navigation/lib/src/app_router/app_router.dart` — AppRouter с маршрутами: Splash, Canvas, Gallery, Settings
- `navigation/lib/src/app_router/app_router.gr.dart` — генерируется `auto_route`
- `navigation/lib/src/di/navigation_di.dart` — регистрация AppRouter

**Features:**
- `features/splash/` — BLoC, SplashScreen, LoginButton, публичный API `splash.dart`
- `features/gallery/` — BLoC, GalleryScreen, FilterChips, ContourCard, EmptyState, публичный API `gallery.dart`
- `features/canvas/` — BLoC, CanvasScreen, CanvasPainter, инструменты, публичный API `canvas.dart`
- `features/settings/` — BLoC, SettingsScreen, LanguagePicker, публичный API `settings.dart`

**Main:**
- `lib/main_common.dart` — главный файл запуска и `App` виджет
- `lib/main_dev.dart` — точка входа для dev
- `lib/main_prod.dart` — точка входа для prod
- `lib/error_handler/` — ErrorHandler, ErrorMessages, ErrorReporting, AppErrorHandlerProvider

**Скрипты:**
- `prebuild_script_*.sh` — для каждого модуля (выполняют `flutter pub get`, а где нужно — `build_runner`)
- `fast_prebuild_script.sh` — общий скрипт сборки

**Примечание:** `App` виджет находится внутри `lib/main_common.dart`, отдельного `lib/app.dart` нет. Приложение не фиксирует ориентацию только на `portraitUp` — поддерживаются портретная и альбомная ориентации.


## ЧТО НУЖНО ПОДДЕРЖИВАТЬ / РЕАЛИЗОВАТЬ

### 1. Core (поддерживать)
- `core/lib/src/di/app_locator.dart` — GetIt instance
- `core/lib/src/utils/constants.dart` — константы приложения:
  - `maxUndoSteps = 5`
  - `maxStrokePoints = 1000`
  - `pageSize = 20`
  - `defaultBrushSize = 10.0`
  - `minBrushSize = 1.0`
  - `maxBrushSize = 100.0`
  - `defaultOpacity = 1.0`
  - `contourDefaultOpacity = 1.0`
  - `contourDefaultWidth = 2.0`
  - `minContourWidth = 0.5`
  - `maxContourWidth = 10.0`
  - `autosaveDebounce = Duration(milliseconds: 500)`
- `core/lib/src/utils/logger.dart` — AppLogger с методами debug, info, warning, error, verbose, wtf
- `core/lib/src/utils/result.dart` — Result/Either
- `core/lib/src/localization/generated/locale_keys.g.dart` — сгенерированные ключи
- `core/lib/core.dart` — экспортирует `flutter_dotenv`, `easy_localization`, утилиты, локализацию, DI

### 2. Core_UI (поддерживать)
- `core_ui/lib/src/widgets/buttons/primary_button.dart` — PrimaryButton
- `core_ui/lib/src/widgets/buttons/icon_button.dart` — AppIconButton
- `core_ui/lib/src/widgets/dialogs/loading_dialog.dart`
- `core_ui/lib/src/widgets/dialogs/error_dialog.dart` — ErrorDialog со статическим `show`
- `core_ui/lib/src/widgets/inputs/custom_slider.dart`
- `core_ui/lib/src/widgets/inputs/search_field.dart`
- `core_ui/lib/src/widgets/cards/contour_card.dart`
- `core_ui/lib/src/theme/app_theme.dart` — только `lightTheme`

> **Тёмная тема и ThemeSwitch не создаются.**

### 3. Domain (поддерживать)
- **Базовые классы UseCase:** `domain/lib/src/use_cases/use_case.dart`
- **Entities:**
  - `UserEntity` — id, email, name, avatarUrl
  - `ContourEntity` — id, title, category, svgData, previewUrl
  - `ProjectEntity` — id, contourId, userId, data (JSON), lastOpened, createdAt
  - `StrokeEntity` — points, color, size, opacity, brushType
  - `BrushType` — circle, square, watercolor, chalk, marker, calligraphy, texture, airbrush
- **Repositories:**
  - `AuthRepository` — checkAuth, signIn, signInSilently
  - `GalleryRepository` — getContours, getContoursByIds, toggleFavorite, getFavoriteIds, getWorkInProgress, getContourById
  - `CanvasRepository` — addStroke, saveProject, loadProject, exportImage
  - `SettingsRepository` — getLanguageCode, saveLanguageCode
  - `ShareRepository` — shareFile
- **UseCases:**
  - Auth: `CheckAuthUseCase`, `SignInUseCase`, `SignInSilentlyUseCase`
  - Gallery: `GetContoursUseCase`, `GetContoursByIdsUseCase`, `GetFavoriteIdsUseCase`, `ToggleFavoriteUseCase`, `GetWorkInProgressUseCase`, `GetContourByIdUseCase`
   - Canvas: `AddStrokeUseCase`, `SaveProjectUseCase`, `LoadProjectUseCase`, `ExportImageUseCase`, `ShareFileUseCase` (с `ExportImageParams`), `SaveImageToGalleryUseCase`
  - Settings: `GetSettingsUseCase`, `UpdateSettingsUseCase`
- **DomainDI** — регистрирует все UseCases через `registerLazySingleton`
- **domain.dart** — экспортирует всё публичное

### 4. Data (поддерживать)
- **Providers:**
  - `SupabaseProvider` — инициализация Supabase
  - `AppDatabase` (Drift) — таблицы `Projects`, `Strokes`, `Contours`; `schemaVersion = 1`
  - `AuthRemoteProvider` — auth, включая `currentUserId`
  - `GalleryRemoteProvider` — контуры и избранное
  - `GalleryLocalProvider` — кэширование контуров
  - `CanvasRemoteProvider` — проекты в Supabase
  - `CanvasLocalProvider` — проекты в Drift
- **Models:** `UserModel`, `ContourModel`, `ProjectModel`, `StrokeModel`
- **Mappers:** `ContourMapper`, `ProjectMapper`, `StrokeMapper`
- **Repositories:** `AuthRepositoryImpl`, `GalleryRepositoryImpl`, `CanvasRepositoryImpl`, `SettingsRepositoryImpl`
- **Services:** `ShareService` (static), `GallerySaverService` (static), `ShareRepositoryImpl`
- **DataDI** — регистрирует провайдеры, сервисы, репозитории
- **data.dart** — экспортирует всё публичное

> **В `data` нет папки `datasources`; используется `providers/`.**

### 5. Features (поддерживать)

#### Splash (ранее auth)
- **BLoC:** `auth_bloc.dart`, `auth_event.dart`, `auth_state.dart`
- **События:** `CheckAuth`, `SignIn`, `SignInSilently`
- **Состояние:** `status`, `isAuthenticated`, `user`, `error`
- **События/UseCases:** `CheckAuthUseCase`, `SignInUseCase`, `SignInSilentlyUseCase`
- **Экраны:** `splash_screen.dart` — SplashScreen + SplashContent
- **Виджеты:** `login_button.dart`
- **Публичный API:** `features/splash/lib/splash.dart` — `SplashRouter`, `SplashRoute`
- **Логика:**
  1. `CheckAuth`
  2. Если авторизован → `GalleryRoute`
  3. Если нет → `SignInSilently`
  4. Если не удалось → показать `LoginButton` (ручной `SignIn`)

#### Gallery
- **BLoC:** gallery_bloc, gallery_event, gallery_state
- **События:** `LoadContours`, `ChangeFilter`, `SelectCategory`, `ToggleFavorite`
- **Состояние:** `status`, `contours`, `error`, `activeFilter`, `selectedCategory`, `currentPage`, `hasReachedMax`, `favoriteIds`, `workInProgressIds`
- **UseCases:** `GetContoursUseCase`, `GetContoursByIdsUseCase`, `GetFavoriteIdsUseCase`, `GetWorkInProgressUseCase`, `ToggleFavoriteUseCase`
- **Экраны:** `gallery_screen.dart`
- **Виджеты:** `contour_card.dart`, `filter_chips.dart`, `empty_state.dart`
- **Фильтры:** All, Favorites, In Progress + категории из `API_SPEC.md`
- **Пагинация:** `Constants.pageSize` для всех фильтров, включая Favorites/InProgress через `GetContoursByIdsUseCase`
- **Ошибка:** отображается через `ErrorDialog.show`

#### Canvas
- **BLoC:** canvas_bloc, canvas_event, canvas_state
- **События:** `LoadProject`, `StartDrawing`, `AddPoint`, `EndDrawing`, `Undo`, `Redo`, `SaveProject`, `ExportImage`, `ExportImageFinished`, `ChangeBrushSize`, `ChangeOpacity`, `ChangeColor`, `ChangeBrushType`, `ChangeContourSettings`, `ResetView`, `UpdateTransform`, `ToggleEraser`
- **Состояние:** `status`, `strokes`, `currentStroke`, `contour`, `undoStack`, `redoStack`, `brushSize`, `opacity`, `color`, `brushType`, `isEraser`, `contourColor`, `contourOpacity`, `contourWidth`, `transform`, `error`
- **Статусы:** `initial`, `loading`, `ready`, `drawing`, `saving`, `exporting`, `error`
- **UseCases:** `AddStrokeUseCase`, `SaveProjectUseCase`, `LoadProjectUseCase`, `GetContourByIdUseCase`, `ExportImageUseCase`, `ShareFileUseCase`
- **Экран:** `canvas_screen.dart`
- **Painter:** `canvas_painter.dart` — только мазки; контур через `SvgPicture.string`
- **Обработка касаний:** `Listener` с `onPointerDown/Move/Up/Cancel`, передача `event.pressure`
- **Автосохранение:** после каждого мазка (с `autosaveDebounce`) и при сворачивании (`WidgetsBindingObserver`)
- **Undo/redo:** через `undoStack`/`redoStack`, ограничены `maxUndoSteps`
- **Экспорт:** `ExportImageUseCase` → PNG; BLoC событие `ExportImage(ExportType)` выбирает "Поделиться" (`ShareFileUseCase`) или "Сохранить в галерею" (`SaveImageToGalleryUseCase`)
- **Виджеты:**
  - `color_picker.dart` — `ColorPickerDialog` на `flutter_colorpicker` + кнопка пипетки
  - `brush_picker.dart` — иконки-заглушки
  - `contour_settings.dart` — цвет, прозрачность, толщина контура
  - `eyedropper_overlay.dart`
  - `export_menu.dart`
  - `toolbars/top_toolbar.dart`, `bottom_toolbar.dart`, `left_controls.dart`

#### Settings
- **BLoC:** settings_bloc, settings_event, settings_state
- **События:** `LoadSettings`, `ChangeLanguage`
- **Состояние:** `status`, `locale`, `error`
- **UseCases:** `GetSettingsUseCase`, `UpdateSettingsUseCase`
- **Экран:** `settings_screen.dart`
- **Виджет:** `language_picker.dart`
- **Публичный API:** `settings.dart` — `SettingsRoute`

> **ThemeSwitch не создаётся.**

### 6. Обновить pubspec.yaml

**Корневой pubspec.yaml** — в `dependencies` только `flutter`, `core`, `flutter_native_splash` и внешние зависимости, нужные напрямую. Все модули (`core_ui`, `domain`, `data`, `navigation`, `splash`, `gallery`, `canvas`, `settings`) подключаются через `dependency_overrides`.

**Для каждого модуля** — необходимые зависимости в его собственном `pubspec.yaml`. Генераторы (`build_runner`, `auto_route_generator`, `drift_dev`, `easy_localization` и т.д.) подключаются в модулях, где они нужны.

**Пример корневого pubspec.yaml:**
```yaml
name: coloring_app

environment:
  sdk: ">=3.12.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  core:
    path: ./core
  flutter_native_splash: ^2.4.0

dependency_overrides:
  core:
    path: ./core
  core_ui:
    path: ./core_ui
  domain:
    path: ./domain
  data:
    path: ./data
  navigation:
    path: ./navigation
  splash:
    path: ./features/splash
  gallery:
    path: ./features/gallery
  canvas:
    path: ./features/canvas
  settings:
    path: ./features/settings

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.2
```

### 7. Создать / поддерживать build.yaml

В корне проекта:
```yaml
targets:
  $default:
    builders:
      auto_route_generator:
        options:
          enable_generators:
            - auto_route
          include_imports: true
      drift_dev:
        options:
          store_date_time_values_as_text: true
```


## ПОРЯДОК ГЕНЕРАЦИИ / СБОРКИ

1. **Core** — `app_locator.dart`, `constants.dart`, `logger.dart`, `result.dart`, локализация
2. **Core_UI** — все виджеты и тема
3. **Domain** — `use_case.dart` → entities → repositories → usecases → `domain_di.dart`
4. **Data** — providers → models → mappers → repositories → services → `data_di.dart`
5. **Navigation** — `AppRouter` с маршрутами Splash, Canvas, Gallery, Settings
6. **Features** — Splash → Gallery → Canvas → Settings
7. **Обновить pubspec.yaml** и **build.yaml**
8. **Запустить** `./fast_prebuild_script.sh`


## ТРЕБОВАНИЯ К КОДУ

1. **Длина строки:** 100 символов
2. **Каждый класс в отдельном файле**
3. **Все публичные методы должны иметь dartdoc комментарии**
4. **BLoC** — единый класс состояния (extends Equatable), создается через `BlocProvider` в экране
5. **BLoC НЕ регистрируется в DI** — зависимости передаются через конструктор с `appLocator`
6. **UseCase** — используют интерфейсы `FutureUseCase`/`UseCase`
7. **UseCase** — возвращают `Future`/значение напрямую (не `Result`)
8. **Ошибки** — UseCase выбрасывают исключения, BLoC перехватывает и вызывает `ErrorHandler`
9. **Clean Architecture** — Presentation → Domain → Data
10. **Именование:** папки — snake_case, файлы — snake_case, классы — PascalCase, переменные — camelCase
11. **Drift** — `Projects`, `Strokes`, `Contours`; `schemaVersion = 1`
12. **Контур** — отображается `SvgPicture.string` (с применённой толщиной), не рисуется в `CanvasPainter`
13. **Касания** — `Listener`, давление `event.pressure`
14. **Локализация** — ключи в `core/lib/src/localization/generated/locale_keys.g.dart`
15. **Тема** — только светлая; `ThemeSwitch` не реализовывать


## ИНСТРУКЦИЯ ПО ЗАПУСКУ ПОСЛЕ ГЕНЕРАЦИИ

```bash
# 1. Получить зависимости
flutter pub get

# 2. Запустить скрипты генерации
./fast_prebuild_script.sh

# 3. Запустить приложение
flutter run -t lib/main_dev.dart
```


## ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ

Вся архитектура, структура и API описаны в файлах папки `docs/`. Используйте их как основной источник информации.

- **PROJECT_OVERVIEW.md** — общее описание и ключевые особенности
- **ARCHITECTURE.md** — детальная архитектура всех модулей
- **GENERATION_INSTRUCTIONS.md** — инструкция с примерами кода
- **API_SPEC.md** — спецификация Supabase и локальная Drift-схема
- **UI_SPEC.md** — спецификация UI экранов и виджетов
- **CHECKLIST.md** — чек-лист всех задач
