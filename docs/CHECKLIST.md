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
- [x] Создана светлая тема (AppTheme, lightTheme)
- [x] Созданы утилиты (constants, logger, result)
- [x] Добавлен `autosaveDebounce`
- [x] Создан app_locator.dart (GetIt instance)
- [x] Создан CoreDi (регистрация AppConfig, AppLogger)
- [x] Создан публичный API (core.dart) с экспортом dotenv и easy_localization

## ✅ Core_UI модуль
- [x] Созданы кнопки (PrimaryButton, AppIconButton)
- [x] Созданы диалоги (LoadingDialog, ErrorDialog со статическим show)
- [x] Созданы поля ввода (CustomSlider, SearchField)
- [x] Созданы карточки (ContourCard)
- [x] Создан публичный API (core_ui.dart)
- [x] `ThemeSwitch` и тёмная тема удалены

## ✅ Domain модуль
- [x] Создан `domain/lib/src/use_cases/use_case.dart`
- [x] Созданы модели (UserEntity, ContourEntity, ProjectEntity, StrokeEntity, BrushType)
- [x] Созданы интерфейсы репозиториев (AuthRepository, GalleryRepository, CanvasRepository, SettingsRepository, ShareRepository)
- [x] Созданы UseCases:
    - [x] auth/check_auth_use_case.dart
    - [x] auth/sign_in_use_case.dart
    - [x] auth/sign_in_silently_use_case.dart
    - [x] gallery/get_contours_use_case.dart
    - [x] gallery/get_contours_by_ids_use_case.dart
    - [x] gallery/get_favorite_ids_use_case.dart
    - [x] gallery/toggle_favorite_use_case.dart
    - [x] gallery/get_work_in_progress_use_case.dart
    - [x] gallery/get_contour_by_id_use_case.dart
    - [x] canvas/add_stroke_use_case.dart
    - [x] canvas/save_project_use_case.dart
    - [x] canvas/load_project_use_case.dart
    - [x] canvas/export_image_use_case.dart
    - [x] canvas/export_image_params.dart
    - [x] canvas/share_file_use_case.dart
    - [x] settings/get_settings_use_case.dart
    - [x] settings/update_settings_use_case.dart
- [x] Создан DomainDI (регистрация всех UseCases)
- [x] Создан публичный API (domain.dart)

## ✅ Data модуль
- [x] Созданы провайдеры (SupabaseProvider, AppDatabase/Drift, AuthRemoteProvider с currentUserId, GalleryRemoteProvider, GalleryLocalProvider, CanvasRemoteProvider, CanvasLocalProvider)
- [x] В `data` нет папки `datasources`; используется `providers/`
- [x] Созданы мапперы (ContourMapper, ProjectMapper, StrokeMapper)
- [x] Созданы модели (UserModel, ContourModel, ProjectModel, StrokeModel)
- [x] Созданы репозитории (AuthRepositoryImpl, GalleryRepositoryImpl, CanvasRepositoryImpl, SettingsRepositoryImpl, ShareRepositoryImpl)
- [x] Создан ShareService (static)
- [x] Создан GallerySaverService (static)
- [x] Создан DataDI (регистрация всех зависимостей)
- [x] Создан публичный API (data.dart)
- [x] Drift: таблицы `Projects`, `Strokes`, `Contours`, `schemaVersion = 1`

## ✅ Navigation модуль
- [x] Создан AppRouter с auto_route в `navigation/lib/src/app_router/`
- [x] Маршруты в порядке: Splash, Canvas, Gallery, Settings
- [x] Создан NavigationDI (регистрация AppRouter) в `navigation/lib/src/di/`
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
- [x] Созданы виджеты (ContourCard, FilterChips, EmptyState)
- [x] FilterChips содержит All, Favorites, In Progress + категории
- [x] Пагинация по `Constants.pageSize` для всех фильтров через `GetContoursByIdsUseCase`
- [x] Ошибка отображается через `ErrorDialog`
- [x] Создан публичный API (`gallery.dart`) — только `GalleryRouter` и `GalleryRoute`

## ✅ Canvas Feature
- [x] Создан CanvasBloc (события, состояния)
- [x] `CanvasState` содержит статусы initial, loading, ready, drawing, saving, exporting, error
- [x] Создан CanvasScreen (Screen + Content)
- [x] Создан CanvasPainter — рисует белый фон и мазки (полная история точек)
- [x] Контур отображается через `SvgPicture.string` (с применением толщины)
- [x] Реализовано сглаживание контура (Smooth Contour)
- [x] Реализована поддержка поворота холста
- [x] Обработка касаний через `Listener` с `event.pressure` и коррекцией масштаба
- [x] Автосохранение с `autosaveDebounce` и при сворачивании (включая настройки контура)
- [x] Интеллектуальный Undo/redo через `undoStack`/`redoStack`
- [x] Экспорт: `ExportImageUseCase` + `ShareFileUseCase` / `SaveImageToGalleryUseCase` через `CanvasBloc`
- [x] Созданы виджеты:
    - [x] Стандартизированный `AppIconButton` (24/18px)
    - [x] ColorPicker (Overlay + Hue slider + Black-fix)
    - [x] ContourSettings (Overlay + Gradient Opacity Slider)
- [x] Создан публичный API (`canvas.dart`) — только `CanvasRouter` и `CanvasRoute`

## ✅ Settings Feature
- [x] Создан SettingsBloc (события, состояния)
- [x] Создан SettingsScreen (Screen + Content)
- [x] Создан LanguagePicker
- [x] Удалён ThemeSwitch / тёмная тема
- [x] Создан публичный API (`settings.dart`) — только `SettingsRouter` и `SettingsRoute`

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
- [x] `fast_prebuild_script.sh`

## ✅ Тестирование (опционально)
- [ ] Unit тесты для UseCases
- [ ] Unit тесты для BLoC

## ✅ Документация
- [x] Добавлены dartdoc комментарии
- [x] Создан README.md (обновляется отдельно)

## ✅ Деплой
- [ ] Настроена сборка для dev
- [ ] Настроена сборка для prod
- [ ] Созданы иконки
- [ ] Создан Splash Screen
- [ ] Настроена публикация в магазины
