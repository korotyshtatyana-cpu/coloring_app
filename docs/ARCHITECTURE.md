# Архитектура приложения

## Общая архитектура (Clean Architecture)

### Слои
- **Presentation:** BLoC для управления состоянием, экраны и виджеты. BLoC создаются на уровне экрана через `BlocProvider`.
- **Domain:** Чистая бизнес-логика. UseCases возвращают данные или выбрасывают исключения.
- **Data:** Репозитории управляют логикой синхронизации. Состояние рисунка хранится локально в Drift для мгновенного отклика. Синхронизация с Supabase (весь JSON проекта) происходит при закрытии экрана или сворачивании приложения (AppLifecycleState.paused/inactive).


## Модули и их ответственность

### core
**Назначение:** Ядро приложения
**Содержит:**
- Локализация (easy_localization + генерация ключей)
- Темы (светлая/темная)
- Расширения для Flutter
- Утилиты (константы, логгер)
- Конфигурация (AppConfig, Flavor)
- DI (appLocator, CoreDi)
- Ресурсы: переводы в `resources/lang/`

**Структура:**
```text
core/lib/
├── core.dart # Публичный API
├── src/
│ ├── config/
│ │ └── app_config.dart # AppConfig с Flavor
│ ├── constants/
│ │ └── constants.dart
│ ├── di/
│ │ ├── app_locator.dart # GetIt instance
│ │ └── core_di.dart # Регистрация core зависимостей
│ ├── extensions/
│ │ ├── context_extensions.dart
│ │ └── theme_extensions.dart
│ ├── localization/
│ │ ├── locale_keys.g.dart # Автогенерируемые ключи
│ │ └── app_localization.dart # Обертка для easy_localization
│ ├── theme/
│ │ └── app_theme.dart
│ └── utils/
│ ├── logger.dart # AppLogger
│ └── result.dart # Result тип
```

**Публичный API (core.dart):** экспортирует все публичные компоненты модуля.

**AppConfig:** содержит конфигурацию приложения в зависимости от флейвора. Поля: `flavor`, `supabaseUrl`, `supabaseAnonKey`, `googleWebClientId`, `appsFlyerDevKey`, `appleAppId`. Фабричный метод `fromFlavor(Flavor)`.

**app_locator.dart:** глобальный экземпляр `GetIt` для DI.

**CoreDi:** регистрирует `AppConfig` и `AppLogger` в `appLocator`.

**AppLocalization:** содержит `langFolderPath`, `supportedLocales`, `fallbackLocale`.


### core_ui
**Назначение:** UI компоненты (только виджеты, без DI)
**Содержит:**
- Переиспользуемые виджеты (кнопки, диалоги, поля ввода, карточки)
- Тема и стили
- Ресурсы: шрифты, иконки, изображения

**Структура:**
```text
core_ui/lib/
├── core_ui.dart # Публичный API
├── src/
│ ├── constants/
│ │ └── package_constants.dart
│ ├── theme/
│ │ ├── app_colors.dart
│ │ ├── app_dimens.dart
│ │ ├── app_fonts.dart
│ │ └── app_theme.dart
│ └── widgets/
│ ├── buttons/
│ │ ├── primary_button.dart
│ │ └── icon_button.dart
│ ├── dialogs/
│ │ ├── loading_dialog.dart
│ │ └── error_dialog.dart
│ ├── inputs/
│ │ ├── custom_slider.dart
│ │ └── search_field.dart
│ └── cards/
│ └── contour_card.dart
```


**Публичный API (core_ui.dart):** экспортирует тему и все виджеты.

**Виджеты:**
- `PrimaryButton` — основная кнопка с закругленными углами
- `IconButton` — кнопка с иконкой для тулбаров
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
- DI (DomainDi)

**Структура:**
```text
domain/lib/
├── domain.dart # Публичный API
├── src/
│ ├── di/
│ │ └── domain_di.dart # Регистрация usecases
│ ├── entities/
│ │ ├── contour_entity.dart
│ │ ├── project_entity.dart
│ │ ├── stroke_entity.dart
│ │ ├── user_entity.dart
│ │ └── brush_type.dart
│ ├── repositories/
│ │ ├── auth_repository.dart
│ │ ├── gallery_repository.dart
│ │ └── canvas_repository.dart
│ ├── use_cases/
│ │ ├── auth/
│ │ │ ├── check_auth_use_case.dart
│ │ │ └── sign_in_use_case.dart
│ │ ├── gallery/
│ │ │ ├── get_contours_use_case.dart
│ │ │ ├── toggle_favorite_use_case.dart
│ │ │ └── get_work_in_progress_use_case.dart
│ │ └── canvas/
│ │ ├── add_stroke_use_case.dart
│ │ ├── undo_stroke_use_case.dart
│ │ ├── redo_stroke_use_case.dart
│ │ ├── save_project_use_case.dart
│ │ ├── load_project_use_case.dart
│ │ └── export_image_use_case.dart
│ └── use_case.dart # Базовые классы UseCase
```


**Публичный API (domain.dart):** экспортирует все сущности, репозитории, usecases и DI.

**Базовые классы UseCase:**
- `UseCase<Input, Output>` — синхронный UseCase
- `FutureUseCase<Input, Output>` — асинхронный UseCase
- `StreamUseCase<Input, Output>` — стримовый UseCase
- `NoParams` — класс-заглушка для случаев без параметров

**Сущности:**
- `UserEntity` — пользователь (id, email, name, avatarUrl)
- `ContourEntity` — контур (id, title, category, svgData, previewUrl)
- `ProjectEntity` — проект (id, contourId, userId, data, lastOpened, createdAt)
- `StrokeEntity` — мазок (points, color, size, opacity, brushType)
- `BrushType` — enum (circle, square, watercolor, chalk, marker, calligraphy, texture, airbrush)

**Репозитории (интерфейсы):**
- `AuthRepository` — checkAuth(), signIn()
- `GalleryRepository` — getContours(limit, offset, category), toggleFavorite(contourId), getWorkInProgress()
- `CanvasRepository` — addStroke(projectId, stroke), undoStroke(projectId), redoStroke(projectId), saveProject(project), loadProject(contourId), exportImage(projectId)

**UseCases:**
- `CheckAuthUseCase` — проверяет авторизацию
- `SignInUseCase` — выполняет вход
- `GetContoursUseCase` — получает список контуров с пагинацией
- `ToggleFavoriteUseCase` — добавляет/удаляет из избранного
- `GetWorkInProgressUseCase` — получает начатые проекты
- `AddStrokeUseCase` — добавляет мазок
- `UndoStrokeUseCase` — отменяет последний мазок
- `RedoStrokeUseCase` — возвращает отмененный мазок
- `SaveProjectUseCase` — сохраняет проект
- `LoadProjectUseCase` — загружает проект
- `ExportImageUseCase` — экспортирует изображение

**DomainDi:** регистрирует все UseCase в `appLocator` с использованием `registerLazySingleton`.


### data
**Назначение:** Реализация репозиториев
**Содержит:**
- Реализации репозиториев
- DataSources (Supabase, Drift/SQLite)
- Data модели (DTO)
- Мапперы (модель ↔ сущность)
- Провайдеры (Supabase, Drift)
- DI (DataDi)

**Структура:**
```text
data/lib/
├── data.dart # Публичный API
├── src/
│ ├── constants/
│ ├── di/
│ │ └── data_di.dart # Регистрация репозиториев
│ ├── errors/
│ ├── mappers/
│ │ ├── contour_mapper.dart
│ │ ├── project_mapper.dart
│ │ └── stroke_mapper.dart
│ ├── models/
│ │ ├── contour_model.dart
│ │ ├── project_model.dart
│ │ └── stroke_model.dart
│ ├── providers/
│ │ ├── supabase_provider.dart
│ │ └── database_provider.dart
│ ├── repositories/
│ │ ├── auth_repository_impl.dart
│ │ ├── gallery_repository_impl.dart
│ │ └── canvas_repository_impl.dart
│ └── datasources/
│ ├── auth_remote_datasource.dart
│ ├── gallery_remote_datasource.dart
│ ├── gallery_local_datasource.dart
│ ├── canvas_remote_datasource.dart
│ └── canvas_local_datasource.dart
```


**Публичный API (data.dart):** экспортирует все реализации репозиториев, провайдеры и DI.

**Провайдеры:**
- `SupabaseProvider` — инициализация Supabase с конфигом
- `AppDatabase` (Drift) — база данных SQLite с таблицами Projects и Strokes

**DataSources:**
- `AuthRemoteDataSource` — работа с Supabase Auth
- `GalleryRemoteDataSource` — получение контуров и избранного из Supabase
- `GalleryLocalDataSource` — кэширование контуров в Drift
- `CanvasRemoteDataSource` — сохранение проектов в Supabase
- `CanvasLocalDataSource` — сохранение проектов в Drift

**Models (DTO):** `UserModel`, `ContourModel`, `ProjectModel`, `StrokeModel`

**Mappers:** преобразуют Models ↔ Entities

**Реализации репозиториев:** `AuthRepositoryImpl`, `GalleryRepositoryImpl`, `CanvasRepositoryImpl`

**DataDi:** регистрирует провайдеры, datasources и репозитории в правильном порядке.


### navigation
**Назначение:** Навигация
**Содержит:**
- Определение маршрутов (auto_route)
- Генерируемый роутер
- DI (NavigationDi)

**Структура:**
```text
navigation/lib/
├── navigation.dart # Публичный API
├── src/
│ ├── app_router/
│ │ ├── app_router.dart # Определение маршрутов
│ │ └── app_router.gr.dart # Генерируется auto_route
│ └── di/
│ └── navigation_di.dart
```

**Публичный API (navigation.dart):** экспортирует AutoRoute, AppRouter и DI.

**AppRouter:** определяет маршруты: Auth → Gallery → Canvas → Settings. Использует `@AutoRouterConfig` с `replaceInRouteName: 'Screen|Page,Route'`.

**NavigationDi:** регистрирует `AppRouter` в `appLocator`.


### features
**Назначение:** Фичи приложения
**Структура каждой фичи:**
```text
features/auth/
├── lib/
│ ├── auth.dart # Публичный API
│ ├── src/
│ │ ├── bloc/
│ │ │ ├── auth_bloc.dart
│ │ │ ├── auth_event.dart
│ │ │ └── auth_state.dart
│ │ ├── screens/
│ │ │ └── auth_screen.dart
│ │ └── widgets/
│ │ └── login_button.dart
│ └── pubspec.yaml
```


**Каждая фича содержит:**
- BLoC (события, состояния)
- Экраны (Screens)
- Виджеты (Widgets)
- Публичный API (auth.dart, gallery.dart, canvas.dart, settings.dart)

**Предоставление BLoC:** происходит на уровне экранов (Screens) через `BlocProvider`. Зависимости (UseCases, Router) внедряются в конструктор BLoC из `appLocator`.

Пример:
```dart
@RoutePage()
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<MainBloc>(
      create: (context) => MainBloc(
        appRouter: appLocator<AppRouter>(),
        getStoryByIdUseCase: appLocator<GetStoryByIdUseCase>(),
      ),
      child: const MainContent(),
    );
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

### Регистрация UseCase (в DomainDi)
```dart
appLocator.registerLazySingleton<SomeUseCase>(
  () => SomeUseCase(
    repository: appLocator<SomeRepository>(),
  ),
);
```

### Порядок инициализации в main_common
1. CoreDi.init(flavor) — AppConfig, AppLogger 
2. DataDi.initDependencies() — провайдеры, datasources, репозитории 
3. DomainDi.initDependencies() — usecases 
4. NavigationDi.initDependencies() — AppRouter 
5. appLocator.allReady()

## Локализация (easy_localization)
### Файлы переводов
```text
core/resources/lang/
├── en-US.json
└── ru-RU.json
```

### Генерация ключей
```text
flutter pub run easy_localization:generate \
  -f json \
  -O lib/src/localization \
  -o locale_keys.g.dart \
  -i resources/lang
```

### Использование в коде
```dart
Text(LocaleKeys.gallery).tr();
```

## Обработка ошибок
### Структура error_handler
```text
lib/error_handler/
├── error_handler.dart
├── error_messages.dart
├── error_reporting.dart
└── provider/
    └── app_error_handler_provider.dart
```

### ErrorHandler
- init(BuildContext context) — инициализация 
- handleError(Object error, StackTrace stackTrace, [String? customMessage]) — обработка ошибки 
- Логирование через AppLogger 
- Отображение диалога ошибки 
- Опциональный репортинг

### AppErrorHandlerProvider
- Оборачивает все приложение 
- Перехватывает ошибки через FlutterError.onError 
- Перехватывает ошибки в BLoC через Bloc.observer 
- Показывает диалог ошибки через ErrorHandler

## Drift (SQLite) база данных
### Таблицы
- Projects — id, contourId, userId, data (JSON), lastOpened, createdAt 
- Strokes — id, projectId, points (JSON), color, size, opacity, brushType

### Настройка
- Использовать @DriftDatabase с таблицами 
- AppDatabase extends _$AppDatabase 
- schemaVersion = 1
- _openConnection() — открытие SQLite файла

### Генерация кода
```bash
flutter pub run build_runner build
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

### CanvasPainter
- Отрисовка нижнего слоя (мазки пользователя)
- Отрисовка верхнего слоя (контур с прозрачностью)
- Поддержка трансформации (масштаб, поворот, смещение)

### Обработка жестов
- `onPanStart` — начало мазка
- `onPanUpdate` — добавление точек (с учетом давления)
- `onPanEnd` — завершение мазка
- `onScaleStart/Update/End` — зум и панорамирование

### Давление стилуса
- Использовать `event.pressure` (0.0-1.0)
- Динамический размер: `baseSize * pressure`
- Fallback для устройств без поддержки: `baseSize`