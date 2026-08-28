# Инструкция для генерации кода

## Цель
Сгенерировать полностью работающее Flutter приложение на основе Clean Architecture с использованием BLoC, get_it (appLocator), easy_localization, auto_route и Drift (SQLite).

## Структура генерации

### Этап 1: Core (дополнить существующее)
1. `app_locator.dart` — GetIt instance (вынести из core_di)
2. `constants.dart` — константы приложения (включая `autosaveDebounce`)
3. `logger.dart` — AppLogger с использованием пакета logger
4. `result.dart` — Result/Either тип для обработки ошибок
5. Обновить `core_di.dart` — добавить регистрацию AppLogger
6. Обновить `core.dart` — добавить экспорты утилит и реэкспорт `flutter_dotenv`, `easy_localization`

### Этап 2: Core_UI (создать виджеты)
1. `buttons/primary_button.dart` — основная кнопка
2. `buttons/icon_button.dart` — `AppIconButton`, кнопка с иконкой для тулбаров
3. `dialogs/loading_dialog.dart` — диалог загрузки
4. `dialogs/error_dialog.dart` — диалог ошибки со статическим методом `show`
5. `inputs/custom_slider.dart` — кастомный слайдер
6. `inputs/search_field.dart` — поле поиска
7. `cards/contour_card.dart` — карточка контура
8. Обновить `core_ui.dart` — добавить экспорты

### Этап 3: Domain (создать полностью)
1. **Базовые классы UseCase:** `domain/lib/src/use_cases/use_case.dart`
2. **Entities:**
    - `user_entity.dart`
    - `contour_entity.dart`
    - `project_entity.dart`
    - `stroke_entity.dart`
    - `brush_type.dart`
3. **Repositories (интерфейсы):**
    - `auth_repository.dart`
    - `canvas_repository.dart`
    - `gallery_repository.dart`
    - `settings_repository.dart`
    - `share_repository.dart`
4. **UseCases:**
    - `auth/check_auth_use_case.dart`
    - `auth/sign_in_use_case.dart`
    - `auth/sign_in_silently_use_case.dart`
    - `canvas/add_stroke_use_case.dart`
    - `canvas/export_image_params.dart`
    - `canvas/export_image_use_case.dart`
    - `canvas/load_project_use_case.dart`
    - `canvas/save_project_use_case.dart`
    - `canvas/share_file_use_case.dart`
    - `gallery/get_contour_by_id_use_case.dart`
    - `gallery/get_contours_by_ids_use_case.dart`
    - `gallery/get_contours_use_case.dart`
    - `gallery/get_favorite_ids_use_case.dart`
    - `gallery/get_work_in_progress_use_case.dart`
    - `gallery/toggle_favorite_use_case.dart`
    - `settings/get_settings_use_case.dart`
    - `settings/update_settings_use_case.dart`
5. Обновить `domain_di.dart` — регистрация всех UseCases
6. Обновить `domain.dart` — добавить экспорты

### Этап 4: Data (создать полностью)
1. **Providers:**
    - `supabase_provider.dart` — инициализация Supabase
    - `database_provider.dart` — Drift база данных с таблицами `Projects`, `Strokes`, `Contours`
    - `auth_remote_provider.dart` — включая `currentUserId`
    - `gallery_remote_provider.dart`
    - `gallery_local_provider.dart`
    - `canvas_remote_provider.dart`
    - `canvas_local_provider.dart`
2. **Models (DTO):**
    - `user_model.dart`
    - `contour_model.dart`
    - `project_model.dart`
    - `stroke_model.dart`
3. **Mappers:**
    - `contour_mapper.dart`
    - `project_mapper.dart`
    - `stroke_mapper.dart`
4. **Repositories (реализации):**
    - `auth_repository_impl.dart`
    - `canvas_repository_impl.dart`
    - `gallery_repository_impl.dart`
    - `settings_repository_impl.dart`
5. **Services:**
    - `share_service.dart`
6. Обновить `data_di.dart` — регистрация всех зависимостей
7. Обновить `data.dart` — добавить экспорты

> **Важно:** в `data` модуле нет папки `datasources`; вместо неё используется `providers/`.

### Этап 5: Splash Feature (создать полностью)
1. **BLoC:**
    - `src/bloc/auth_bloc.dart`
    - `src/bloc/auth_event.dart`
    - `src/bloc/auth_state.dart`
2. **Экраны:**
    - `src/screens/splash_screen.dart` — `@RoutePage() class SplashScreen` + `SplashContent`
3. **Виджеты:**
    - `src/widgets/login_button.dart`
4. Обновить `splash.dart` — объявить `SplashRouter` с `@AutoRouterConfig`, импортировать `splash_screen.dart` (без `export`), добавить `part 'splash.gr.dart'`

### Этап 6: Gallery Feature (создать полностью)
1. **BLoC:**
    - `src/bloc/gallery_bloc.dart`
    - `src/bloc/gallery_event.dart`
    - `src/bloc/gallery_state.dart`
2. **Экраны:**
    - `src/screens/gallery_screen.dart` — `@RoutePage() class GalleryScreen` + `GalleryContent`
3. **Виджеты:**
    - `src/widgets/contour_card.dart`
    - `src/widgets/filter_chips.dart` — фильтры All/Favorites/In Progress + категории
    - `src/widgets/empty_state.dart`
4. Обновить `gallery.dart` — объявить `GalleryRouter`, импортировать `gallery_screen.dart`, добавить `part 'gallery.gr.dart'`

### Этап 7: Canvas Feature (создать полностью)
1. **BLoC:**
    - `src/bloc/canvas_bloc.dart`
    - `src/bloc/canvas_event.dart`
    - `src/bloc/canvas_state.dart`
2. **Экраны:**
    - `src/screens/canvas_screen.dart` — `@RoutePage() class CanvasScreen` + `CanvasContent` (Stateful)
3. **Painter:**
    - `src/painters/canvas_painter.dart` — только мазки
4. **Виджеты:**
    - `src/widgets/brush_picker.dart` — иконки-заглушки
    - `src/widgets/color_picker.dart` — `ColorPickerDialog` на базе `flutter_colorpicker` с кнопкой пипетки
    - `src/widgets/contour_settings.dart` — цвет, прозрачность, толщина контура
    - `src/widgets/eyedropper_overlay.dart`
    - `src/widgets/export_menu.dart`
    - `src/widgets/toolbars/top_toolbar.dart`
    - `src/widgets/toolbars/bottom_toolbar.dart`
    - `src/widgets/toolbars/left_controls.dart`
5. Обновить `canvas.dart` — объявить `CanvasRouter`, импортировать `canvas_screen.dart`, добавить `part 'canvas.gr.dart'`

### Этап 8: Settings Feature (создать полностью)
1. **BLoC:**
    - `src/bloc/settings_bloc.dart`
    - `src/bloc/settings_event.dart`
    - `src/bloc/settings_state.dart`
2. **Экраны:**
    - `src/screens/settings_screen.dart` — `@RoutePage() class SettingsScreen` + `SettingsContent`
3. **Виджеты:**
    - `src/widgets/language_picker.dart`
4. Обновить `settings.dart` — объявить `SettingsRouter`, импортировать `settings_screen.dart`, добавить `part 'settings.gr.dart'`

> **Переключатель темы (`ThemeSwitch`) не создаётся — тёмная тема удалена из проекта.**

### Этап 9: Обновить pubspec.yaml
1. В корневом `pubspec.yaml` оставить в `dependencies` только `flutter`, `core` и внешние зависимости, нужные напрямую на уровне приложения.
2. Все модули подключить через `dependency_overrides`.
3. Зависимости для каждого модуля добавить в его собственный `pubspec.yaml`.
4. Генераторы кода (`build_runner`, `auto_route_generator`, `drift_dev`) подключать в тех модулях, где они реально используются.

### Этап 10: Создать build.yaml
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

## Критерии качества

### Каждый сгенерированный файл должен:
1. Иметь валидный импорт всех зависимостей
2. Не иметь синтаксических ошибок
3. Следовать Dart Style Guide
4. Иметь комментарии для публичных методов
5. Иметь правильные типы и null-safety

### Каждый BLoC должен:
1. Иметь единый класс состояния (extends Equatable)
2. Иметь абстрактные события (extends Equatable)
3. Обрабатывать загрузку, ошибки, успех
4. Не иметь зависимостей от UI
5. Использовать ErrorHandler для обработки ошибок

### Каждый UseCase должен:
1. Иметь только одну ответственность
2. Вызывать репозиторий
3. Возвращать данные напрямую или выбрасывать исключения

### Слой рисования (CanvasPainter):
1. Рисовать белый фон и мазки пользователя (полная история точек)
2. Контур отображается отдельно через `SvgPicture.string` с применением настройки толщины (`SvgUtils.applyStrokeWidth`)
3. Поддерживать трансформацию (масштаб, поворот до 360°, смещение)
4. Реализовать сглаживание контура (Smooth Contour)
5. Оптимизировать отрисовку через `RepaintBoundary`

### Каждый Repository должен:
1. Иметь интерфейс в domain
2. Иметь реализацию в data
3. Работать с провайдерами

## Формат Result
```dart
// core/lib/src/utils/result.dart
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final String message;
  final dynamic error;
  const Failure(this.message, {this.error});
}
```

## Формат UseCase
```dart
// domain/lib/src/use_cases/auth/check_auth_use_case.dart
import '../../../../domain.dart';

class CheckAuthUseCase implements FutureUseCase<NoParams, bool> {
  final AuthRepository _repository;

  CheckAuthUseCase({required AuthRepository repository}) : _repository = repository;

  @override
  Future<bool> execute([NoParams? params]) {
    return _repository.checkAuth();
  }
}
```

Правила для UseCase:
1. Используют интерфейсы `FutureUseCase<Input, Output>` или `UseCase<Input, Output>`
2. `execute` принимает `[Input? params]` (опциональный параметр)
3. Возвращают `Future<Output>` или `Output` напрямую
4. Зависимости передаются через конструктор с `required`
5. Не используют `Result` — ошибки пробрасываются наружу

### Базовые классы UseCase:
```dart
// domain/lib/src/use_cases/use_case.dart
abstract class UseCase<Input, Output> {
  Output execute([Input? params]);
}

abstract class FutureUseCase<Input, Output> {
  Future<Output> execute([Input? params]);
}

abstract class StreamUseCase<Input, Output> {
  Stream<Output> execute([Input? params]);
}

class NoParams {
  const NoParams();
}
```

## Формат BLoC и его использование

### SplashScreen
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
```

### GalleryBloc
```dart
class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final GetContoursUseCase _getContoursUseCase;
  final GetContoursByIdsUseCase _getContoursByIdsUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;
  final GetFavoriteIdsUseCase _getFavoriteIdsUseCase;
  final GetWorkInProgressUseCase _getWorkInProgressUseCase;

  GalleryBloc({
    required GetContoursUseCase getContoursUseCase,
    required GetContoursByIdsUseCase getContoursByIdsUseCase,
    required ToggleFavoriteUseCase toggleFavoriteUseCase,
    required GetFavoriteIdsUseCase getFavoriteIdsUseCase,
    required GetWorkInProgressUseCase getWorkInProgressUseCase,
  })  : _getContoursUseCase = getContoursUseCase,
        _getContoursByIdsUseCase = getContoursByIdsUseCase,
        _toggleFavoriteUseCase = toggleFavoriteUseCase,
        _getFavoriteIdsUseCase = getFavoriteIdsUseCase,
        _getWorkInProgressUseCase = getWorkInProgressUseCase,
        super(const GalleryState()) {
    on<LoadContours>(_onLoadContours);
    on<ChangeFilter>(_onChangeFilter);
    on<SelectCategory>(_onSelectCategory);
    on<ToggleFavorite>(_onToggleFavorite);
  }

  // ...
}
```

### CanvasScreen
```dart
@RoutePage()
class CanvasScreen extends StatelessWidget {
  final String contourId;

  const CanvasScreen({super.key, required this.contourId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CanvasBloc>(
      create: (context) => CanvasBloc(
        contourId: contourId,
        addStrokeUseCase: appLocator<AddStrokeUseCase>(),
        saveProjectUseCase: appLocator<SaveProjectUseCase>(),
        loadProjectUseCase: appLocator<LoadProjectUseCase>(),
        getContourByIdUseCase: appLocator<GetContourByIdUseCase>(),
      )..add(const LoadProject()),
      child: const CanvasContent(),
    );
  }
}
```

## Формат State
```dart
// features/gallery/lib/src/bloc/gallery_state.dart
part of 'gallery_bloc.dart';

enum GalleryStatus { initial, loading, success, failure }

class GalleryState extends Equatable {
  final GalleryStatus status;
  final List<ContourEntity> contours;
  final String? error;
  final FilterType activeFilter;
  final String? selectedCategory;
  final int currentPage;
  final bool hasReachedMax;
  final List<String> favoriteIds;
  final List<String> workInProgressIds;

  const GalleryState({
    this.status = GalleryStatus.initial,
    this.contours = const [],
    this.error,
    this.activeFilter = FilterType.all,
    this.selectedCategory,
    this.currentPage = 0,
    this.hasReachedMax = false,
    this.favoriteIds = const [],
    this.workInProgressIds = const [],
  });

  @override
  List<Object?> get props => [
    status,
    contours,
    error,
    activeFilter,
    selectedCategory,
    currentPage,
    hasReachedMax,
    favoriteIds,
    workInProgressIds,
  ];

  GalleryState copyWith({...});
}
```

## Формат Event
```dart
part of 'gallery_bloc.dart';

abstract class GalleryEvent extends Equatable {
  const GalleryEvent();
}

class LoadContours extends GalleryEvent {
  final bool reset;
  const LoadContours({this.reset = false});
  @override List<Object?> get props => [reset];
}

class ChangeFilter extends GalleryEvent {
  final FilterType filter;
  const ChangeFilter(this.filter);
  @override List<Object?> get props => [filter];
}

class SelectCategory extends GalleryEvent {
  final ContourCategory? category;
  const SelectCategory(this.category);
  @override List<Object?> get props => [category];
}

class ToggleFavorite extends GalleryEvent {
  final String contourId;
  const ToggleFavorite(this.contourId);
  @override List<Object?> get props => [contourId];
}
```

### Пример экспорта модуля
```dart
// core/lib/core.dart
export 'package:flutter_dotenv/flutter_dotenv.dart';
export 'package:easy_localization/easy_localization.dart';

export 'src/config/app_config.dart';
export 'src/constants/constants.dart';
export 'src/di/app_locator.dart';
export 'src/di/core_di.dart';
export 'src/error_handler/error_handler.dart';
export 'src/localization/app_localization.dart';
export 'src/localization/generated/locale_keys.g.dart';
export 'src/utils/logger.dart';
export 'src/utils/result.dart';
```

### Пример публичного API фичи
```dart
// features/splash/lib/splash.dart
import 'package:auto_route/auto_route.dart';

import 'src/screens/splash_screen.dart';

part 'splash.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class SplashRouter {}
```

Фичи не экспортируют BLoC, виджеты и экраны. Внешние модули используют только `SplashRoute`, `GalleryRoute`, `CanvasRoute`, `SettingsRoute`.

### CanvasPainter пример:
```dart
class CanvasPainter extends CustomPainter {
  final List<StrokeEntity> strokes;
  final StrokeEntity? currentStroke;
  final Matrix4 transform;

  CanvasPainter({
    required this.strokes,
    this.currentStroke,
    Matrix4? transform,
  }) : transform = transform ?? Matrix4.identity();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(transform.storage);

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }

    canvas.restore();
  }

  void _drawStroke(Canvas canvas, StrokeEntity stroke) {
    // Рисование мазка
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
           oldDelegate.currentStroke != currentStroke ||
           oldDelegate.transform != transform;
  }
}
```

## Drift (SQLite) настройка
### pubspec.yaml зависимости
```yaml
dependencies:
  drift: ^2.34.2
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.3
  path: ^1.9.0

dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.8
```

### Таблицы
- `Projects`
- `Strokes`
- `Contours` — кэширование контуров

### Генерация кода Drift
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Скрипты для генерации

### prebuild_script_core.sh
```bash
#!/bin/bash
set -e

flutter pub get
flutter pub run easy_localization:generate \
  -f json \
  -O lib/src/localization/generated \
  -o locale_keys.g.dart \
  -i resources/lang

echo "Core prebuild completed!"
```

### prebuild_script_navigation.sh
```bash
#!/bin/bash
set -e

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

echo "Navigation router generated successfully!"
```

### prebuild_script_data.sh
```bash
#!/bin/bash
set -e

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

echo "Data prebuild completed!"
```

### fast_prebuild_script.sh (корневой)
```bash
#!/bin/bash
set -e

echo "Running all prebuild scripts..."

./core/prebuild_script_core.sh
./core_ui/prebuild_script_core_ui.sh
./domain/prebuild_script_domain.sh
./data/prebuild_script_data.sh
./navigation/prebuild_script_navigation.sh
./features/splash/prebuild_script_splash.sh
./features/gallery/prebuild_script_gallery.sh
./features/canvas/prebuild_script_canvas.sh
./features/settings/prebuild_script_settings.sh

echo "All prebuild scripts completed!"
```

## Запуск приложения
```bash
# Dev
flutter run -t lib/main_dev.dart

# Prod
flutter run -t lib/main_prod.dart

# Сборка APK dev
flutter build apk -t lib/main_dev.dart

# Сборка APK prod
flutter build apk -t lib/main_prod.dart
```

## Примечания по генерации
1. Все строковые литералы использовать через `LocaleKeys`
2. Стили выносить в тему `core_ui`
3. Все навигационные маршруты — через `auto_route`
4. Все зависимости регистрировать в `appLocator`
5. Использовать `Equatable` для состояний и сущностей
6. Для работы с Supabase использовать `supabase_flutter`
7. Для локального хранения использовать Drift (SQLite)
8. Обработку ошибок через `ErrorHandler`
9. Каждый модуль имеет публичный API файл
10. Из модулей экспортировать только то, что используется другими модулями
11. `AppConfig` передаётся в DI при инициализации
12. BLoC создаются через `BlocProvider` непосредственно на экранах, используя `appLocator`
13. Экран фичи состоит из двух классов: `*Screen` (создаёт BLoC, `@RoutePage`) и `*Content` (вся UI-реализация). Логика обработки событий выносится в именованные методы класса `*Content`.
14. Публичный API фичи (`splash.dart`, `gallery.dart`, `canvas.dart`, `settings.dart`) экспортирует только сгенерированный `*Route`.
15. Корневой `AppRouter` находится в модуле `navigation`; маршруты: Splash, Canvas, Gallery, Settings.
16. `App` виджет находится в `lib/main_common.dart`, отдельного `lib/app.dart` нет.
17. Приложение не фиксирует ориентацию только на `portraitUp`.
18. Для Drift использовать генерацию кода через `drift_dev`.
19. Контур на холсте рисуется через отдельный виджет `ContourLayer` (использует `SvgPicture.string` с применённой толщиной).
20. Обработка касаний холста — через `Listener` с передачей `event.pressure` и коррекцией координат под текущий масштаб/трансформацию.
21. Тёмная тема и `ThemeSwitch` не генерируются.
22. **Важно:** Следовать всем правилам чистого кода, описанным в **[GOOD_PRACTICES.md](GOOD_PRACTICES.md)**:
    - Запрет на методы `_build...()` (использовать композицию виджетов).
    - Оптимизация перерисовок через `context.select`.
    - Использование `const` конструкторов везде, где возможно.
    - Вынос повторяющихся значений (отступы, цвета) в локальные переменные внутри `build`.
    - 1 класс — 1 файл (за исключением `StatefulWidget` + `State`).
    - Использование `AppIconButton` с размером 24px и иконкой 18px для тулбаров.
    - Реализация настроек и выбора цвета в виде оверлеев (`showGeneralDialog` с прозрачным фоном).
    - Сохранение настроек контура (цвет, прозрачность, толщина) в базу данных вместе с проектом.
