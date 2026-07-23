# Инструкция для генерации кода

## Цель
Сгенерировать полностью работающее Flutter приложение на основе Clean Architecture с использованием BLoC, get_it (appLocator), easy_localization, auto_route и Drift (SQLite).

## Структура генерации

### Этап 1: Core (дополнить существующее)
1. `app_locator.dart` — GetIt instance (вынести из core_di)
2. `constants.dart` — константы приложения
3. `logger.dart` — AppLogger с использованием пакета logger
4. `result.dart` — Result/Either тип для обработки ошибок
5. Обновить `core_di.dart` — добавить регистрацию AppLogger
6. Обновить `core.dart` — добавить экспорты

### Этап 2: Core_UI (создать виджеты)
1. `buttons/primary_button.dart` — основная кнопка
2. `buttons/icon_button.dart` — кнопка с иконкой
3. `dialogs/loading_dialog.dart` — диалог загрузки
4. `dialogs/error_dialog.dart` — диалог ошибки
5. `inputs/custom_slider.dart` — кастомный слайдер
6. `inputs/search_field.dart` — поле поиска
7. `cards/contour_card.dart` — карточка контура
8. Обновить `core_ui.dart` — добавить экспорты

### Этап 3: Domain (создать полностью)
1. **Entities:**
    - `user_entity.dart` — пользователь
    - `contour_entity.dart` — контур
    - `project_entity.dart` — проект
    - `stroke_entity.dart` — мазок
    - `brush_type.dart` — enum типов кистей
2. **Repositories (интерфейсы):**
    - `auth_repository.dart`
    - `gallery_repository.dart`
    - `canvas_repository.dart`
3. **UseCases:**
    - `auth/check_auth_use_case.dart`
    - `auth/sign_in_use_case.dart`
    - `gallery/get_contours_use_case.dart`
    - `gallery/toggle_favorite_use_case.dart`
    - `gallery/get_work_in_progress_use_case.dart`
    - `canvas/add_stroke_use_case.dart`
    - `canvas/undo_stroke_use_case.dart`
    - `canvas/redo_stroke_use_case.dart`
    - `canvas/save_project_use_case.dart`
    - `canvas/load_project_use_case.dart`
    - `canvas/export_image_use_case.dart`
4. Обновить `domain_di.dart` — регистрация всех UseCases
5. Обновить `domain.dart` — добавить экспорты

### Этап 4: Data (создать полностью)
1. **Providers:**
    - `supabase_provider.dart` — инициализация Supabase
    - `database_provider.dart` — Drift база данных
2. **DataSources:**
    - `auth_remote_datasource.dart`
    - `gallery_remote_datasource.dart`
    - `gallery_local_datasource.dart`
    - `canvas_remote_datasource.dart`
    - `canvas_local_datasource.dart`
3. **Models (DTO):**
    - `user_model.dart`
    - `contour_model.dart`
    - `project_model.dart`
    - `stroke_model.dart`
4. **Mappers:**
    - `contour_mapper.dart`
    - `project_mapper.dart`
    - `stroke_mapper.dart`
5. **Repositories (реализации):**
    - `auth_repository_impl.dart`
    - `gallery_repository_impl.dart`
    - `canvas_repository_impl.dart`
6. Обновить `data_di.dart` — регистрация всех зависимостей
7. Обновить `data.dart` — добавить экспорты

### Этап 5: Auth Feature (создать полностью)
1. **BLoC:**
    - `auth_bloc.dart`
    - `auth_event.dart`
    - `auth_state.dart`
2. **Экраны:**
    - `splash_screen.dart`
3. **Виджеты:**
    - `login_button.dart`
4. Обновить `auth.dart` — добавить экспорты

### Этап 6: Gallery Feature (создать полностью)
1. **BLoC:**
    - `gallery_bloc.dart`
    - `gallery_event.dart`
    - `gallery_state.dart`
2. **Экраны:**
    - `gallery_screen.dart`
3. **Виджеты:**
    - `contour_card.dart`
    - `filter_chips.dart`
    - `empty_state.dart`
4. Обновить `gallery.dart` — добавить экспорты

### Этап 7: Canvas Feature (создать полностью)
1. **BLoC:**
    - `canvas_bloc.dart`
    - `canvas_event.dart`
    - `canvas_state.dart`
2. **Экраны:**
    - `canvas_screen.dart`
3. **Painter:**
    - `canvas_painter.dart`
4. **Виджеты:**
    - `brush_picker.dart`
    - `color_picker.dart`
    - `contour_settings.dart`
    - `eyedropper_overlay.dart`
    - `toolbars/top_toolbar.dart`
    - `toolbars/bottom_toolbar.dart`
    - `toolbars/left_controls.dart`
5. Обновить `canvas.dart` — добавить экспорты

### Этап 8: Settings Feature (создать полностью)
1. **BLoC:**
    - `settings_bloc.dart`
    - `settings_event.dart`
    - `settings_state.dart`
2. **Экраны:**
    - `settings_screen.dart`
3. **Виджеты:**
    - `theme_switch.dart`
    - `language_picker.dart`
4. Обновить `settings.dart` — добавить экспорты

### Этап 9: Обновить pubspec.yaml
1. Добавить все необходимые зависимости в корневой pubspec.yaml
2. Добавить зависимости для каждого модуля
3. Добавить dev зависимости

### Этап 10: Создать build.yaml
1. Настроить auto_route генератор
2. Настроить drift генератор

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
1. Использовать `Paint.imageFilter` и `MaskFilter` для реализации сложных кистей (акварель, аэрограф).
2. Оптимизировать отрисовку через `PictureRecorder` или `RepaintBoundary` при большом количестве мазков.

### Каждый Repository должен:
1. Иметь интерфейс в domain
2. Иметь реализацию в data
3. Работать с data sources

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
import '../use_case.dart';

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
1. Используют интерфейсы FutureUseCase<Input, Output> или UseCase<Input, Output>
2. execute принимает [Input? params] (опциональный параметр)
3. Возвращают Future<Output> или Output напрямую 
4. Зависимости передаются через конструктор с required 
5. Не используют Result — ошибки пробрасываются наружу

### Базовые классы UseCase:
```dart
// domain/lib/src/use_case.dart
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
```dart
// features/gallery/lib/src/screens/gallery_screen.dart
@RoutePage()
class GalleryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<GalleryBloc>(
      create: (context) => GalleryBloc(
        getContoursUseCase: appLocator<GetContoursUseCase>(),
        toggleFavoriteUseCase: appLocator<ToggleFavoriteUseCase>(),
        getWorkInProgressUseCase: appLocator<GetWorkInProgressUseCase>(),
      ),
      child: const GalleryContent(),
    );
  }
}

// features/gallery/lib/src/bloc/gallery_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:navigation/navigation.dart';
import 'package:flutter/widgets.dart';

part 'gallery_event.dart';
part 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final GetContoursUseCase _getContoursUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;
  final GetWorkInProgressUseCase _getWorkInProgressUseCase;

  GalleryBloc({
    required GetContoursUseCase getContoursUseCase,
    required ToggleFavoriteUseCase toggleFavoriteUseCase,
    required GetWorkInProgressUseCase getWorkInProgressUseCase,
  })  : _getContoursUseCase = getContoursUseCase,
        _toggleFavoriteUseCase = toggleFavoriteUseCase,
        _getWorkInProgressUseCase = getWorkInProgressUseCase,
        super(const GalleryState()) {
    on<LoadContours>(_onLoadContours);
    on<ChangeFilter>(_onChangeFilter);
    on<ToggleFavorite>(_onToggleFavorite);
    on<SelectCategory>(_onSelectCategory);
  }

  Future<void> _onLoadContours(
    LoadContours event,
    Emitter<GalleryState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: GalleryStatus.loading,
        error: null,
      ));

      final contours = await _getContoursUseCase.execute(
        limit: Constants.pageSize,
        offset: state.currentPage * Constants.pageSize,
        category: state.selectedCategory,
      );

      final newContours = event.reset
          ? contours
          : [...state.contours, ...contours];

      emit(state.copyWith(
        status: GalleryStatus.success,
        contours: newContours,
        currentPage: state.currentPage + 1,
        hasReachedMax: contours.length < Constants.pageSize,
        error: null,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      emit(state.copyWith(
        status: GalleryStatus.failure,
        error: e.toString(),
      ));
    }
  }

  // ... другие обработчики

  @override
  Future<void> close() {
    // отписки если есть
    return super.close();
  }
}
```

## Формат State
```dart
// features/gallery/lib/src/bloc/gallery_state.dart
part of 'gallery_bloc.dart';

enum GalleryStatus {
  initial,
  loading,
  success,
  failure,
}

class GalleryState extends Equatable {
  final GalleryStatus status;
  final List<ContourEntity> contours;
  final String? error;
  final FilterType activeFilter;
  final String? selectedCategory;
  final int currentPage;
  final bool hasReachedMax;

  const GalleryState({
    this.status = GalleryStatus.initial,
    this.contours = const [],
    this.error,
    this.activeFilter = FilterType.all,
    this.selectedCategory,
    this.currentPage = 0,
    this.hasReachedMax = false,
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
  ];

  GalleryState copyWith({
    GalleryStatus? status,
    List<ContourEntity>? contours,
    String? error,
    FilterType? activeFilter,
    String? selectedCategory,
    int? currentPage,
    bool? hasReachedMax,
  }) {
    return GalleryState(
      status: status ?? this.status,
      contours: contours ?? this.contours,
      error: error ?? this.error,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}
```

## Формат Event
```dart
// features/gallery/lib/src/bloc/gallery_event.dart
part of 'gallery_bloc.dart';

abstract class GalleryEvent {
  const GalleryEvent();
}

class LoadContours extends GalleryEvent {
  final bool reset;

  const LoadContours({this.reset = false});
}

class ChangeFilter extends GalleryEvent {
  final FilterType filter;

  const ChangeFilter(this.filter);
}

class SelectCategory extends GalleryEvent {
  final String category;

  const SelectCategory(this.category);
}

class ToggleFavorite extends GalleryEvent {
  final String contourId;

  const ToggleFavorite(this.contourId);
}
```

### Пример экспорта модуля
```dart
// core/lib/core.dart
export 'src/config/app_config.dart';
export 'src/constants/constants.dart';
export 'src/di/app_locator.dart';
export 'src/di/core_di.dart';
export 'src/localization/app_localization.dart';
export 'src/localization/locale_keys.g.dart';
export 'src/theme/app_theme.dart';
export 'src/utils/logger.dart';
export 'src/utils/result.dart';
export 'src/extensions/context_extensions.dart';
```

### CanvasPainter пример:
```dart
class CanvasPainter extends CustomPainter {
  final List<StrokeEntity> strokes;
  final ContourEntity contour;
  final double contourOpacity;
  final Color contourColor;
  final double contourWidth;
  final Matrix4 transform;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(transform.storage);

    // 1. Нижний слой (мазки)
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // 2. Верхний слой (контур)
    _drawContour(canvas, contour, contourOpacity, contourColor, contourWidth);

    canvas.restore();
  }

  void _drawStroke(Canvas canvas, StrokeEntity stroke) {
    // Рисование мазка с учетом типа кисти
  }

  void _drawContour(Canvas canvas, ContourEntity contour, ...) {
    // Рендеринг SVG контура с настройками
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
           oldDelegate.contourOpacity != contourOpacity ||
           oldDelegate.contourColor != contourColor ||
           oldDelegate.transform != transform;
  }
}
```

## Drift (SQLite) настройка
### pubspec.yaml зависимости
```yaml
dependencies:
  drift: ^2.34.2
  sqlite3_flutter_libs: ^0.6.0+eol
  path_provider: ^2.1.6
  path: ^1.9.1

dev_dependencies:
  drift_dev: ^2.34.4
  build_runner: ^2.15.2
```

### Генерация кода Drift
```bash
flutter pub run build_runner build
```

## Скрипты для генерации

### prebuild_script_core.sh
```bash
#!/bin/bash
flutter pub run easy_localization:generate \
  -f json \
  -O lib/src/localization \
  -o locale_keys.g.dart \
  -i resources/lang

echo "Core localization generated successfully!"
```

### prebuild_script_navigation.sh
```bash
#!/bin/bash
flutter pub run build_runner build \
  --delete-conflicting-outputs

echo "Navigation router generated successfully!"
```

### fast_prebuild_script.sh (корневой)
```bash
#!/bin/bash
echo "Running all prebuild scripts..."

./core/prebuild_script_core.sh
./core_ui/prebuild_script_core_ui.sh
./domain/prebuild_script_domain.sh
./data/prebuild_script_data.sh
./navigation/prebuild_script_navigation.sh

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
1. Все строковые литералы использовать через LocaleKeys 
2. Все стили выносить в тему 
3. Все навигационные маршруты - через auto_route 
4. Все зависимости регистрировать в appLocator 
5. Использовать Equatable для состояний и сущностей 
6. Для работы с Supabase использовать supabase_flutter 
7. Для локального хранения использовать Drift (SQLite)
8. Обработку ошибок через ErrorHandler 
9. Каждый модуль имеет публичный API файл 
10. Из модулей экспортировать только то, что используется другими модулями 
11. AppConfig передается в DI при инициализации 
12. BLoC создаются через BlocProvider непосредственно на экранах, используя appLocator для получения зависимостей (UseCase и др.)
13. Для Drift использовать генерацию кода через drift_dev
