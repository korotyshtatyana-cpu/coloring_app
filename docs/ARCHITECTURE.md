# Архитектура приложения

## Общая архитектура (Clean Architecture)

Приложение разделено на Dart/Flutter модули (package), каждый со своим `pubspec.yaml`:
`core`, `core_ui`, `domain`, `data`, `navigation`, `features/*`.

### Слои
- **Presentation:** BLoC для управления состоянием, экраны и виджеты. BLoC создаются на уровне экрана через `BlocProvider`.
- **Domain:** Чистая бизнес-логика. UseCases возвращают данные или выбрасывают исключения.
- **Data:** Репозитории управляют логикой синхронизации. Состояние рисунка хранится локально в Drift для мгновенного отклика. Синхронизация с Supabase (JSON проекта) происходит при сохранении/автосохранении.

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
        └── svg_utils.dart       # Утилиты для SVG
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


**Публичный API (core_ui.dart):** экспортирует тему и все виджеты.

**Виджеты:**
- `PrimaryButton` — основная кнопка с закругленными углами
- `AppIconButton` — кнопка с иконкой для тулбаров
- `LoadingDialog` — диалог загрузки с индикатором
- `ErrorDialog` — диалог ошибки с кнопкой "Повторить"
- `CustomSlider` — кастомный слайдер для размера и прозрачности
- `SearchField` — поле поиска с иконкой
- `ContourCard` — карточка контура для галереи


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
        │   └── toggle_favorite_use_case.dart
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
- `ContourEntity` — контур (id, title, category, svgData, previewUrl)
- `ContourCategory` — enum категорий контура (all, animals, nature, fantasy, mandala, transport, cities, people, flowers, patterns, abstract). `all` — UI-значение «Все категории», не хранится в базе; use cases конвертируют его в `null` перед репозиторием
- `ProjectEntity` — проект (id, contourId, userId, data, lastOpened, createdAt)
- `StrokeEntity` — мазок (points, color, size, opacity, brushType)
- `BrushType` — enum (circle, square, watercolor, chalk, marker, calligraphy, texture, airbrush)

**Репозитории (интерфейсы):**
- `AuthRepository` — checkAuth(), signIn(), signInSilently()
- `GalleryRepository` — getContours, getContoursByIds, getFavoriteIds, toggleFavorite, getWorkInProgress, getContourById
- `CanvasRepository` — addStroke, saveProject, loadProject, exportImage, saveImageToGallery
- `SettingsRepository` — getLanguageCode, saveLanguageCode
- `ShareRepository` — shareFile

**UseCases:**
- `CheckAuthUseCase` — проверяет авторизацию
- `SignInUseCase` — выполняет ручной вход
- `SignInSilentlyUseCase` — пытается войти автоматически
- `GetContoursUseCase` — получает список контуров с пагинацией
- `GetContoursByIdsUseCase` — получает контуры по списку id
- `GetFavoriteIdsUseCase` — возвращает id избранных контуров
- `ToggleFavoriteUseCase` — добавляет/удаляет из избранного
- `GetWorkInProgressUseCase` — получает начатые проекты
- `GetContourByIdUseCase` — загружает один контур по id
- `AddStrokeUseCase` — добавляет мазок
- `SaveProjectUseCase` — сохраняет проект
- `LoadProjectUseCase` — загружает проект
- `ExportImageUseCase` — экспортирует изображение
- `ShareFileUseCase` — делится файлом
- `SaveImageToGalleryUseCase` — сохраняет файл в галерею устройства
- `GetSettingsUseCase` — читает настройки
- `UpdateSettingsUseCase` — сохраняет настройки

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
    ├── errors/
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
        └── gallery_saver_service.dart
```


**Публичный API (data.dart):** экспортирует все реализации репозиториев, провайдеры, сервисы и DI.

**Провайдеры:**
- `SupabaseProvider` — инициализация Supabase с конфигом
- `AppDatabase` (Drift) — база данных SQLite с таблицами `Projects`, `Strokes` и `Contours`
- `AuthRemoteProvider` — работа с Supabase Auth; содержит `currentUserId`
- `GalleryRemoteProvider` — получение контуров и избранного из Supabase
- `GalleryLocalProvider` — кэширование контуров в Drift
- `CanvasRemoteProvider` — сохранение проектов в Supabase
- `CanvasLocalProvider` — сохранение проектов в Drift

**Models (DTO):** `UserModel`, `ContourModel`, `ProjectModel`, `StrokeModel`

**Mappers:** преобразуют Models ↔ Entities

**Реализации репозиториев:** `AuthRepositoryImpl`, `GalleryRepositoryImpl`, `CanvasRepositoryImpl`, `SettingsRepositoryImpl`, `ShareRepositoryImpl`

**Сервисы:**
- `ShareService` — статический сервис-обертка над `share_plus` для шаринга файлов/изображений.
- `GallerySaverService` — статический сервис-обертка над `saver_gallery` для сохранения изображений в галерею устройства.
- Платформенные операции (шаринг, запрос пермишенов, работа с файлами) оформляются как сервисы, а не размазываются по провайдерам/репозиториям.

**DataDI:** регистрирует провайдеры, сервисы и репозитории в правильном порядке.

**Реализация `ShareRepository`:** `ShareRepositoryImpl` использует статический `ShareService`.


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
- `navigation/lib/src/app_router/app_router.gr.dart` — генерируется `auto_route` (минимальный/заглушка, `part-of`).

Использует `@AutoRouterConfig` с `replaceInRouteName: 'Screen|Page,Route'`.

**NavigationDI:** регистрирует `AppRouter` в `appLocator`.


### features
**Назначение:** Фичи приложения

**Фича авторизации/загрузки называется `splash`:**
```text
features/splash/
├── lib/
│   ├── splash.dart               # Публичный API: SplashRoute
│   ├── splash.gr.dart              # Генерируется auto_route
│   └── src/
│       ├── bloc/
│       │   ├── auth_bloc.dart
│       │   ├── auth_event.dart
│       │   └── auth_state.dart
│       ├── screens/
│       │   └── splash_screen.dart
│       └── widgets/
│           └── login_button.dart
└── pubspec.yaml
```

**Каждая фича содержит:**
- BLoC (события, состояния)
- Экраны (Screens)
- Виджеты (Widgets)
- Публичный API (`splash.dart`, `gallery.dart`, `canvas.dart`, `settings.dart`)

**Публичный API фичи:**
- Фичи не экспортируют BLoC, виджеты и экраны напрямую.
- Публичный файл объявляет `@AutoRouterConfig` и импортирует реальный экран, чтобы `auto_route` сгенерировал `*Route` класс.
- Через фичу доступен только сгенерированный класс маршрута (`SplashRoute`, `GalleryRoute`, `CanvasRoute`, `SettingsRoute`).

**Предоставление BLoC:** происходит на уровне экранов (Screens) через `BlocProvider`. Зависимости (UseCases, Router) внедряются в конструктор BLoC из `appLocator`.

**Структура экрана:**
```dart
@RoutePage()
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(
        checkAuthUseCase: appLocator<CheckAuthUseCase>(),
        signInUseCase: appLocator<SignInUseCase>(),
        signInSilentlyUseCase: appLocator<SignInSilentlyUseCase>(),
      )..add(const CheckAuth()),
      child: const SplashContent(),
    );
  }
}

class SplashContent extends StatelessWidget {
  const SplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    // ... UI
  }
}
```


## State Management (BLoC)

### Принципы BLoC
1. Единый класс состояния (extends Equatable)
2. Абстрактные события (extends Equatable)
3. Все зависимости через конструктор с `required`
4. Обработчики событий — приватные методы `_on...`
5. Использование `copyWith` для обновления состояния
6. `enum` для статусов (initial, loading, success, failure)
7. Обработка ошибок через ErrorHandler
8. `close()` для отписок от стримов и таймеров
9. Опционально: `with WidgetsBindingObserver` для отслеживания жизненного цикла

### Формат State
```dart
enum SomeStatus { initial, loading, success, failure }

class SomeState extends Equatable {
  final SomeStatus status;
  final Data? data;
  final String? error;

  const SomeState({
    this.status = SomeStatus.initial,
    this.data,
    this.error,
  });

  @override
  List<Object?> get props => [status, data, error];

  SomeState copyWith({...});
}
```
### Формат Event
```dart
abstract class SomeEvent extends Equatable {
  const SomeEvent();
  @override List<Object?> get props => [];
}

class LoadData extends SomeEvent {
  final bool reset;
  const LoadData({this.reset = false});
  @override List<Object?> get props => [reset];
}
```

### Формат BLoC
```dart
class SomeBloc extends Bloc<SomeEvent, SomeState> {
  final SomeUseCase _someUseCase;

  SomeBloc({required SomeUseCase someUseCase})
      : _someUseCase = someUseCase,
        super(const SomeState()) {
    on<LoadData>(_onLoadData);
  }

  Future<void> _onLoadData(LoadData event, Emitter<SomeState> emit) async {
    try {
      emit(state.copyWith(status: SomeStatus.loading));
      final data = await _someUseCase.execute();
      emit(state.copyWith(status: SomeStatus.success, data: data));
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      emit(state.copyWith(status: SomeStatus.failure, error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    // отписки
    return super.close();
  }
}
```

## Dependency Injection (appLocator)
### Глобальный экземпляр
```dart
// core/lib/src/di/app_locator.dart
final GetIt appLocator = GetIt.instance;
```

### Порядок инициализации в main_common
1. `CoreDi.init(flavor)` — AppConfig, AppLogger
2. `DataDI.initDependencies()` — провайдеры, сервисы, репозитории
3. `DomainDI.initDependencies()` — usecases
4. `NavigationDI.initDependencies()` — AppRouter
5. `appLocator.allReady()`

## Локализация (easy_localization)
### Файлы переводов
```text
core/resources/lang/
├── en-US.json
└── ru-RU.json
```

### Генерация ключей
```bash
flutter pub run easy_localization:generate \
  -f json \
  -O lib/src/localization/generated \
  -o locale_keys.g.dart \
  -i resources/lang
```

Сгенерированные ключи живут в `core/lib/src/localization/generated/locale_keys.g.dart`.

### Использование в коде
```dart
Text(LocaleKeys.gallery).tr();
```

## Обработка ошибок
### Глобальный ErrorHandler
`lib/error_handler/error_handler.dart` инициализируется с `GlobalKey<NavigatorState>`, получает контекст из `navigatorKey.currentState?.overlay?.context` и показывает `ErrorDialog` через `ErrorDialog.show`.

### AppErrorHandlerProvider
- Оборачивает приложение в `main_common.dart`
- Перехватывает ошибки через `FlutterError.onError`
- Перехватывает ошибки в BLoC через `Bloc.observer`
- Логирует ошибки через `AppLogger`

### ErrorDialog
- Универсальный виджет в `core_ui`
- Статический метод `show` для отображения диалога
- Используется в галерее как отдельный диалог, а не как виджет внутри списка

## Drift (SQLite) база данных
### Таблицы
- `Projects` — id, contourId, userId, data (JSON), lastOpened, createdAt
- `Strokes` — id, projectId, points (JSON), color, size, opacity, brushType
- `Contours` — id, title, category, svgData, previewUrl, createdAt

### Настройка
- Использовать `@DriftDatabase` с таблицами
- `AppDatabase extends _$AppDatabase`
- `schemaVersion = 1`
- `_openConnection()` — открытие SQLite файла

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
| `contourDefaultWidth` | 2.0 |
| `minContourWidth` | 0.5 |
| `maxContourWidth` | 10.0 |
| `autosaveDebounce` | 500ms |

---

## Типы кистей (enum)
| Значение | Описание |
|----------|----------|
| `circle` | Круглая |
| `square` | Квадратная |
| `watercolor` | Акварель |
| `chalk` | Мелок |
| `marker` | Маркер |
| `calligraphy` | Каллиграфическая |
| `texture` | Текстурная |
| `airbrush` | Аэрограф |

---

## Константы вместо строк
Все идентификаторы таблиц, колонок, параметров запросов и сообщения об ошибках централизованы в `RequestConstants` (`data/lib/src/constants/request_constants.dart`).

Примеры:
- Имена таблиц: `usersTable`, `contoursTable`, `favoritesTable`, `projectsTable`
- Колонки: `createdAtColumn`, `userIdColumn`, `contourIdColumn`
- Параметры: `limitParam`, `offsetParam`, `orderParam`
- Сообщения: `userNotAuthenticated`, `googleSignInFailed`

Провайдеры не используют «магические строки» при построении запросов Supabase.

## Сервисы для переиспользуемых платформенных операций
Платформенно-зависимые и часто повторяющиеся операции оформляются как сервисы в `data/lib/src/services/`:
- `ShareService` — шаринг файлов/изображений через `share_plus`.

К сервисам относятся также пермишены, экспорт файлов, работа с галереей устройства. Сервисы регистрируются в `DataDI` и внедряются в репозитории/провайдеры, избегая дублирования кода.

## Версии пакетов
Предпочтение отдается последним стабильным версиям пакетов (`google_sign_in ^7.2.0`, `share_plus`, `flutter_colorpicker`, `image_gallery_saver` и т.д.).
Зависимости обновляются через `flutter pub outdated` и тестируются с `flutter analyze` / `flutter build apk --debug`.

---

## Best Practices

1. **Разделение UI и логики** — вся бизнес-логика в BLoC и UseCases
2. **Переиспользование виджетов** — выносить в core_ui
3. **Обработка ошибок** — UseCase выбрасывают исключения, BLoC перехватывают и передают в ErrorHandler
4. **Работа с Drift** — использовать генерацию кода, миграции, транзакции
5. **Производительность** — const конструкторы, ListView.builder, избегать rebuild
6. **Экспорт модулей** — только то, что используется другими модулями
7. **Состояния загрузки** — initial, loading, success, failure
8. **Доступность** — Semantics, тап-области ≥ 44pt
9. **Жизненный цикл BLoC** — отписки в `close()`
10. **Тема** — используется только светлая тема; переключатель темы удалён

### CanvasPainter
- Отрисовка нижнего слоя: белый фон + мазки пользователя
- Контур отрисовывается отдельно через `SvgPicture.string` с прозрачностью, цветом и толщиной (`SvgUtils.applyStrokeWidth`)
- Поддержка трансформации (масштаб, поворот, смещение) передаётся в CustomPainter

### Обработка касаний
- Используется `Listener` (`onPointerDown`, `onPointerMove`, `onPointerUp`, `onPointerCancel`)
- Координаты и `event.pressure` передаются в BLoC
- Мультитач — зум и панорамирование через `InteractiveViewer`

### Давление стилуса
- Использовать `event.pressure` (0.0-1.0)
- Динамический размер: `max(minBrushSize, baseSize * pressure)`
- Fallback для устройств без поддержки: `baseSize`

### Автосохранение
- Дебаунс `Constants.autosaveDebounce` после каждого завершённого мазка
- Сохранение при сворачивании/фоне через `WidgetsBindingObserver` (`AppLifecycleState.paused/inactive`)

### Экспорт
- Экспорт обрабатывается в `CanvasBloc`: событие `ExportImage(ExportType)` запускает `ExportImageUseCase`, а затем `ShareFileUseCase` (для `ExportType.share`) или `SaveImageToGalleryUseCase` (для `ExportType.gallery`)
- `CanvasRepository.exportImage` склеивает белый фон, мазки и контур (с применённой толщиной), сохраняет в PNG
- `CanvasRepository.saveImageToGallery` сохраняет готовый файл в галерею устройства через `GallerySaverService`
