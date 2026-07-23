# Чек-лист разработки

## ✅ Настройка проекта
- [ ] Создан pubspec.yaml в корне
- [ ] Созданы pubspec.yaml для каждого модуля
- [ ] Создана структура папок
- [ ] Созданы файлы переводов в core/resources/lang/
- [ ] Созданы .env.dev и .env.prod
- [ ] Созданы скрипты (prebuild_script_*.sh)
- [ ] Создан fast_prebuild_script.sh

## ✅ Core модуль
- [ ] Настроена локализация (easy_localization)
- [ ] Сгенерирован locale_keys.g.dart
- [ ] Создана тема (AppTheme)
- [ ] Созданы расширения
- [ ] Созданы утилиты (constants, logger, result)
- [ ] Создан app_locator.dart (GetIt instance)
- [ ] Создан CoreDi (регистрация AppConfig, AppLogger)
- [ ] Создан публичный API (core.dart)

## ✅ Core_UI модуль
- [ ] Созданы кнопки (PrimaryButton, IconButton)
- [ ] Созданы диалоги (LoadingDialog, ErrorDialog)
- [ ] Созданы поля ввода (CustomSlider, SearchField)
- [ ] Созданы карточки (ContourCard)
- [ ] Создан публичный API (core_ui.dart)

## ✅ Domain модуль
- [ ] Создан use_case.dart (UseCase, FutureUseCase, StreamUseCase, NoParams)
- [ ] Созданы модели (UserEntity, ContourEntity, ProjectEntity, StrokeEntity, BrushType)
- [ ] Созданы интерфейсы репозиториев (AuthRepository, GalleryRepository, CanvasRepository)
- [ ] Созданы UseCases:
    - [ ] auth/check_auth_use_case.dart
    - [ ] auth/sign_in_use_case.dart
    - [ ] gallery/get_contours_use_case.dart
    - [ ] gallery/toggle_favorite_use_case.dart
    - [ ] gallery/get_work_in_progress_use_case.dart
    - [ ] canvas/add_stroke_use_case.dart
    - [ ] canvas/undo_stroke_use_case.dart
    - [ ] canvas/redo_stroke_use_case.dart
    - [ ] canvas/save_project_use_case.dart
    - [ ] canvas/load_project_use_case.dart
    - [ ] canvas/export_image_use_case.dart
- [ ] Создан DomainDi (регистрация всех UseCases)
- [ ] Создан публичный API (domain.dart)

## ✅ Data модуль
- [ ] Созданы провайдеры (SupabaseProvider, DatabaseProvider - Drift)
- [ ] Созданы мапперы (ContourMapper, ProjectMapper, StrokeMapper)
- [ ] Созданы DataSources:
    - [ ] auth_remote_datasource.dart
    - [ ] gallery_remote_datasource.dart
    - [ ] gallery_local_datasource.dart
    - [ ] canvas_remote_datasource.dart
    - [ ] canvas_local_datasource.dart
- [ ] Созданы модели (UserModel, ContourModel, ProjectModel, StrokeModel)
- [ ] Созданы репозитории (AuthRepositoryImpl, GalleryRepositoryImpl, CanvasRepositoryImpl)
- [ ] Создан DataDi (регистрация всех зависимостей)
- [ ] Создан публичный API (data.dart)

## ✅ Navigation модуль
- [ ] Создан AppRouter с auto_route
- [ ] Созданы Guards (если нужны)
- [ ] Создан NavigationDi (регистрация AppRouter)
- [ ] Сгенерирован app_router.gr.dart
- [ ] Создан публичный API (navigation.dart)

## ✅ Auth Feature
- [ ] Создан AuthBloc (события, состояния)
- [ ] Создан SplashScreen
- [ ] Создан LoginButton
- [ ] Создан публичный API (auth.dart)

## ✅ Gallery Feature
- [ ] Создан GalleryBloc (события, состояния)
- [ ] Создан GalleryScreen
- [ ] Созданы виджеты (ContourCard, FilterChips, EmptyState)
- [ ] Создан публичный API (gallery.dart)

## ✅ Canvas Feature
- [ ] Создан CanvasBloc (события, состояния)
- [ ] Создан CanvasScreen
- [ ] Создан CanvasPainter
- [ ] Созданы виджеты:
    - [ ] BrushPicker
    - [ ] ColorPicker
    - [ ] ContourSettings
    - [ ] EyedropperOverlay
    - [ ] TopToolbar
    - [ ] BottomToolbar
    - [ ] LeftControls
- [ ] Создан публичный API (canvas.dart)

## ✅ Settings Feature
- [ ] Создан SettingsBloc (события, состояния)
- [ ] Создан SettingsScreen
- [ ] Созданы виджеты (ThemeSwitch, LanguagePicker)
- [ ] Создан публичный API (settings.dart)

## ✅ Error Handler
- [ ] Создан ErrorHandler
- [ ] Создан ErrorMessages
- [ ] Создан ErrorReporting
- [ ] Создан AppErrorHandlerProvider

## ✅ Main Entry Point
- [ ] Создан main_common.dart
- [ ] Создан main_dev.dart
- [ ] Создан main_prod.dart
- [ ] Создан app.dart

## ✅ Интеграция
- [ ] Все модули подключены в корневом pubspec.yaml
- [ ] Все DI зарегистрированы
- [ ] Все маршруты работают
- [ ] Приложение запускается

## ✅ Скрипты
- [ ] prebuild_script_core.sh
- [ ] prebuild_script_core_ui.sh
- [ ] prebuild_script_domain.sh
- [ ] prebuild_script_data.sh
- [ ] prebuild_script_navigation.sh
- [ ] prebuild_script_auth.sh
- [ ] prebuild_script_gallery.sh
- [ ] prebuild_script_canvas.sh
- [ ] prebuild_script_settings.sh
- [ ] fast_prebuild_script.sh

## ✅ Тестирование (опционально)
- [ ] Unit тесты для UseCases
- [ ] Unit тесты для BLoC

## ✅ Документация
- [ ] Добавлены dartdoc комментарии
- [ ] Создан README.md

## ✅ Деплой
- [ ] Настроена сборка для dev
- [ ] Настроена сборка для prod
- [ ] Созданы иконки
- [ ] Создан Splash Screen
- [ ] Настроена публикация в магазины