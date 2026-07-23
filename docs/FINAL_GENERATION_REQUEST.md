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
- `core/lib/core.dart` — публичный API (экспортирует AppConfig, CoreDi, AppLocalization)
- `core/lib/src/config/app_config.dart` — AppConfig с Flavor, fromFlavor
- `core/lib/src/di/core_di.dart` — регистрация AppConfig (appLocator внутри)
- `core/lib/src/localization/app_localization.dart` — настройки локализации

**Core_UI:**
- `core_ui/lib/core_ui.dart` — публичный API
- `core_ui/lib/src/theme/` — app_colors.dart, app_dimens.dart, app_fonts.dart, app_theme.dart
- `core_ui/lib/src/widgets/` — **ПУСТО**

**Domain:**
- `domain/lib/domain.dart` — публичный API
- `domain/lib/src/di/domain_di.dart` — пустой DI
- `domain/lib/src/entities/` — **ПУСТО**
- `domain/lib/src/repositories/` — **ПУСТО**
- `domain/lib/src/use_cases/` — **ПУСТО**
- `domain/lib/src/use_case.dart` — **НУЖНО ДОБАВИТЬ** (базовые классы UseCase)

**Data:**
- `data/lib/data.dart` — публичный API
- `data/lib/src/di/data_di.dart` — пустой DI
- `data/lib/src/datasources/` — **ПУСТО**
- `data/lib/src/models/` — **ПУСТО**
- `data/lib/src/providers/` — **ПУСТО**
- `data/lib/src/repositories/` — **ПУСТО**

**Navigation:**
- `navigation/lib/navigation.dart` — публичный API
- `navigation/lib/src/app_router/app_router.dart` — AppRouter с маршрутами
- `navigation/lib/src/di/navigation_di.dart` — регистрация AppRouter
- `navigation/lib/src/guards/` — **ПУСТО**

**Features:**
- `features/auth/` — структура создана, экран-заглушка, BLoC пустые
- `features/gallery/` — структура создана, экран-заглушка, BLoC пустые
- `features/canvas/` — структура создана, экран-заглушка, BLoC пустые
- `features/settings/` — структура создана, экран-заглушка, BLoC пустые

**Main:**
- `lib/main_common.dart` — главный файл запуска
- `lib/main_dev.dart` — точка входа для dev
- `lib/main_prod.dart` — точка входа для prod
- `lib/app.dart` — App виджет
- `lib/error_handler/` — ErrorHandler, ErrorMessages, ErrorReporting, AppErrorHandlerProvider

**Скрипты:**
- `prebuild_script_*.sh` — для каждого модуля
- `fast_prebuild_script.sh` — общий скрипт сборки


## ЧТО НУЖНО СГЕНЕРИРОВАТЬ

### 1. Core (дополнить)

**Создать файлы:**
```text
core/lib/src/di/app_locator.dart
```
GetIt instance — глобальный экземпляр для DI.

```text
core/lib/src/utils/constants.dart
```
Константы приложения:
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

```text
core/lib/src/utils/logger.dart
```
AppLogger с использованием пакета `logger`. Методы:
- `debug(message, [error, stackTrace])`
- `info(message, [error, stackTrace])`
- `warning(message, [error, stackTrace])`
- `error(message, [error, stackTrace])`
- `verbose(message, [error, stackTrace])`
- `wtf(message, [error, stackTrace])`

```text
core/lib/src/utils/result.dart
```
Result/Either тип для обработки ошибок:
```dart
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

**Обновить `core/lib/core.dart`:**
Добавить экспорты:
- `src/di/app_locator.dart`
- `src/utils/constants.dart`
- `src/utils/logger.dart`
- `src/utils/result.dart`

**Обновить `core/lib/src/di/core_di.dart`:**
Добавить регистрацию AppLogger:
```dart
appLocator.registerLazySingleton<AppLogger>(AppLogger.new);
```


### 2. Core_UI (виджеты)

**Создать все виджеты в `core_ui/lib/src/widgets/`:**

```text
core_ui/lib/src/widgets/buttons/primary_button.dart
```
PrimaryButton — основная кнопка приложения с закругленными углами.

```text
core_ui/lib/src/widgets/buttons/icon_button.dart
```
IconButton — кнопка с иконкой для тулбаров.

```text
core_ui/lib/src/widgets/dialogs/loading_dialog.dart
```
LoadingDialog — диалог загрузки с индикатором.

```text
core_ui/lib/src/widgets/dialogs/error_dialog.dart
```
ErrorDialog — диалог ошибки с кнопкой "Повторить".

```text
core_ui/lib/src/widgets/inputs/custom_slider.dart
```
CustomSlider — кастомный слайдер для размера и прозрачности кисти.

```text
core_ui/lib/src/widgets/inputs/search_field.dart
```
SearchField — поле поиска с иконкой.

```text
core_ui/lib/src/widgets/cards/contour_card.dart
```
ContourCard — карточка контура для галереи (превью, название, звезда избранного).

**Обновить `core_ui/lib/core_ui.dart`:**
Добавить экспорты всех виджетов.


### 3. Domain (полностью)

**Базовые классы UseCase в `domain/lib/src/use_case.dart`:**
```dart
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

**Entities в `domain/lib/src/entities/`:**

```text
domain/lib/src/entities/user_entity.dart
```
Поля: `id`, `email`, `name`, `avatarUrl`.

```text
domain/lib/src/entities/contour_entity.dart
```
Поля: `id`, `title`, `category`, `svgData`, `previewUrl`.

```text
domain/lib/src/entities/project_entity.dart
```
Поля: `id`, `contourId`, `userId`, `data` (JSON), `lastOpened`, `createdAt`.

```text
domain/lib/src/entities/stroke_entity.dart
```
Поля: `points` (List<Offset>), `color` (int), `size` (double), `opacity` (double), `brushType` (BrushType).

```text
domain/lib/src/entities/brush_type.dart
```
Enum: `circle`, `square`, `watercolor`, `chalk`, `marker`, `calligraphy`, `texture`, `airbrush`.

**Repositories (интерфейсы) в `domain/lib/src/repositories/`:**

```text
domain/lib/src/repositories/auth_repository.dart
```
Методы: `checkAuth()`, `signIn()`.

```text
domain/lib/src/repositories/gallery_repository.dart
```
Методы: `getContours(limit, offset, category)`, `toggleFavorite(contourId)`, `getWorkInProgress()`.

```text
domain/lib/src/repositories/canvas_repository.dart
```
Методы: `addStroke(projectId, stroke)`, `undoStroke(projectId)`, `redoStroke(projectId)`, `saveProject(project)`, `loadProject(contourId)`, `exportImage(projectId)`.

**UseCases в `domain/lib/src/use_cases/`:**

```text
domain/lib/src/use_cases/auth/check_auth_use_case.dart
```
Проверяет авторизацию пользователя.

```text
domain/lib/src/use_cases/auth/sign_in_use_case.dart
```
Выполняет вход через Google/Apple.

```text
domain/lib/src/use_cases/gallery/get_contours_use_case.dart
```
Получает список контуров с пагинацией.

```text
domain/lib/src/use_cases/gallery/toggle_favorite_use_case.dart
```
Добавляет/удаляет контур из избранного.

```text
domain/lib/src/use_cases/gallery/get_work_in_progress_use_case.dart
```
Получает список начатых проектов.

```text
domain/lib/src/use_cases/canvas/add_stroke_use_case.dart
```
Добавляет мазок в проект.

```text
domain/lib/src/use_cases/canvas/undo_stroke_use_case.dart
```
Отменяет последний мазок.

```text
domain/lib/src/use_cases/canvas/redo_stroke_use_case.dart
```
Возвращает отмененный мазок.

```text
domain/lib/src/use_cases/canvas/save_project_use_case.dart
```
Сохраняет проект.

```text
domain/lib/src/use_cases/canvas/load_project_use_case.dart
```
Загружает проект.

```text
domain/lib/src/use_cases/canvas/export_image_use_case.dart
```
Экспортирует изображение.

**Формат UseCase:**
```dart
import '../../../../domain.dart';
import '../../use_case.dart';

class CheckAuthUseCase implements FutureUseCase<NoParams, bool> {
final AuthRepository _repository;

CheckAuthUseCase({required AuthRepository repository}) : _repository = repository;

@override
Future<bool> execute([NoParams? params]) {
return _repository.checkAuth();
}
}
```

**Обновить `domain/lib/src/di/domain_di.dart`:**
Заполнить регистрацию всех UseCases.

**Обновить `domain/lib/domain.dart`:**
Добавить экспорты:
- `src/use_case.dart`
- `src/entities/` (все)
- `src/repositories/` (все)
- `src/use_cases/` (все)
- `src/di/domain_di.dart`


### 4. Data (полностью)

**Providers в `data/lib/src/providers/`:**

```text
data/lib/src/providers/supabase_provider.dart
```
Инициализация Supabase с конфигом.

```text
data/lib/src/providers/database_provider.dart
```
Drift база данных с таблицами Projects и Strokes.

**DataSources в `data/lib/src/datasources/`:**

```text
data/lib/src/datasources/auth_remote_datasource.dart
```
Методы для работы с Supabase Auth.

```text
data/lib/src/datasources/gallery_remote_datasource.dart
```
Методы для получения контуров и избранного из Supabase.

```text
data/lib/src/datasources/gallery_local_datasource.dart
```
Методы для кэширования контуров в Drift.

```text
data/lib/src/datasources/canvas_remote_datasource.dart
```
Методы для сохранения проектов в Supabase.

```text
data/lib/src/datasources/canvas_local_datasource.dart
```
Методы для сохранения проектов в Drift.

**Models (DTO) в `data/lib/src/models/`:**

```text
data/lib/src/models/user_model.dart
```
```text
data/lib/src/models/contour_model.dart
```
```text
data/lib/src/models/project_model.dart
```
```text
data/lib/src/models/stroke_model.dart
```

**Mappers в `data/lib/src/mappers/`:**

```text
data/lib/src/mappers/contour_mapper.dart
```
```text
data/lib/src/mappers/project_mapper.dart
```
```text
data/lib/src/mappers/stroke_mapper.dart
```

**Repositories (реализации) в `data/lib/src/repositories/`:**

```text
data/lib/src/repositories/auth_repository_impl.dart
```
```text
data/lib/src/repositories/gallery_repository_impl.dart
```
```text
data/lib/src/repositories/canvas_repository_impl.dart
```

**Обновить `data/lib/src/di/data_di.dart`:**
Заполнить регистрацию всех провайдеров, datasources, репозиториев.

**Обновить `data/lib/data.dart`:**
Добавить экспорты.


### 5. Features (полностью)

#### Auth

**BLoC:**
```text
features/auth/lib/src/bloc/auth_bloc.dart
```
```text
features/auth/lib/src/bloc/auth_event.dart
```
```text
features/auth/lib/src/bloc/auth_state.dart
```

**События:** `CheckAuth`, `SignIn`, `SignOut`

**Состояние:** `status` (initial, loading, success, failure), `isAuthenticated`, `user`, `error`

**Экраны:**
```text
features/auth/lib/src/screens/splash_screen.dart
```
Экран загрузки с проверкой авторизации.

**Формат экрана с BlocProvider:**
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
),
child: const SplashContent(),
);
}
}
```

**Виджеты:**
```text
features/auth/lib/src/widgets/login_button.dart
```
Кнопка входа через Google/Apple.

**Обновить `features/auth/lib/auth.dart`:**
Добавить экспорты.


#### Gallery

**BLoC:**
```text
features/gallery/lib/src/bloc/gallery_bloc.dart
```
```text
features/gallery/lib/src/bloc/gallery_event.dart
```
```text
features/gallery/lib/src/bloc/gallery_state.dart
```

**События:** `LoadContours`, `ChangeFilter`, `ToggleFavorite`, `SelectCategory`

**Состояние:** `status`, `contours`, `error`, `activeFilter`, `selectedCategory`, `currentPage`, `hasReachedMax`

**Экраны:**
```text
features/gallery/lib/src/screens/gallery_screen.dart
```
Главный экран с сеткой контуров и фильтрами.

**Формат экрана с BlocProvider:**
```dart
@RoutePage()
class GalleryScreen extends StatelessWidget {
const GalleryScreen({super.key});

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
```

**Виджеты:**
```text
features/gallery/lib/src/widgets/contour_card.dart
```
```text
features/gallery/lib/src/widgets/filter_chips.dart
```
```text
features/gallery/lib/src/widgets/empty_state.dart
```

**Обновить `features/gallery/lib/gallery.dart`:** Добавить экспорты.


#### Canvas

**BLoC:**
```text
features/canvas/lib/src/bloc/canvas_bloc.dart
```
```text
features/canvas/lib/src/bloc/canvas_event.dart
```
```text
features/canvas/lib/src/bloc/canvas_state.dart
```

**События:** `StartDrawing`, `AddPoint`, `EndDrawing`, `Undo`, `Redo`, `SaveProject`, `LoadProject`, `ExportImage`, `ChangeBrushSize`, `ChangeOpacity`, `ChangeColor`, `ChangeBrushType`, `ChangeContourSettings`, `ResetView`

**Состояние:** `status`, `strokes`, `currentStroke`, `undoStack`, `brushSize`, `opacity`, `color`, `brushType`, `contourColor`, `contourOpacity`, `transform`

**Экраны:**
```text
features/canvas/lib/src/screens/canvas_screen.dart
```
Экран рисования с холстом и инструментами.

**Формат экрана с BlocProvider:**
```dart
@RoutePage()
class CanvasScreen extends StatelessWidget {
final String contourId;

const CanvasScreen({required this.contourId});

@override
Widget build(BuildContext context) {
return BlocProvider<CanvasBloc>(
create: (context) => CanvasBloc(
contourId: contourId,
addStrokeUseCase: appLocator<AddStrokeUseCase>(),
undoStrokeUseCase: appLocator<UndoStrokeUseCase>(),
redoStrokeUseCase: appLocator<RedoStrokeUseCase>(),
saveProjectUseCase: appLocator<SaveProjectUseCase>(),
loadProjectUseCase: appLocator<LoadProjectUseCase>(),
exportImageUseCase: appLocator<ExportImageUseCase>(),
),
child: const CanvasContent(),
);
}
}
```

**Painter:**
```text
features/canvas/lib/src/painters/canvas_painter.dart
```
CustomPainter для отрисовки холста (контур сверху, мазки снизу).

**Виджеты:**
```text
features/canvas/lib/src/widgets/brush_picker.dart
```
Выбор типа кисти.

```text
features/canvas/lib/src/widgets/color_picker.dart
```
Полноценная палитра цветов (цветовой круг + RGB).

```text
features/canvas/lib/src/widgets/contour_settings.dart
```
Настройки контура (цвет, прозрачность, толщина).

```text
features/canvas/lib/src/widgets/eyedropper_overlay.dart
```
Пипетка с лупой для выбора цвета.

```text
features/canvas/lib/src/widgets/toolbars/top_toolbar.dart
```
Верхняя панель (назад, экспорт, индикатор сохранения).

```text
features/canvas/lib/src/widgets/toolbars/bottom_toolbar.dart
```
Нижняя панель инструментов (цвет, кисти, ластик, отмена, повтор, контур).

```text
features/canvas/lib/src/widgets/toolbars/left_controls.dart
```
Левая панель (ползунки размера и прозрачности, кнопка сброса вида).

**Обновить `features/canvas/lib/canvas.dart`:** Добавить экспорты.


#### Settings

**BLoC:**
```text
features/settings/lib/src/bloc/settings_bloc.dart
```
```text
features/settings/lib/src/bloc/settings_event.dart
```
```text
features/settings/lib/src/bloc/settings_state.dart
```

**События:** `LoadSettings`, `ChangeLanguage`

**Состояние:** `status`, `locale`, `error`

**Экраны:**
```text
features/settings/lib/src/screens/settings_screen.dart
```
Экран настроек.

**Формат экрана с BlocProvider:**
```dart
@RoutePage()
class SettingsScreen extends StatelessWidget {
const SettingsScreen({super.key});

@override
Widget build(BuildContext context) {
return BlocProvider<SettingsBloc>(
create: (context) => SettingsBloc(
getSettingsUseCase: appLocator<GetSettingsUseCase>(),
updateSettingsUseCase: appLocator<UpdateSettingsUseCase>(),
),
child: const SettingsContent(),
);
}
}
```

**Виджеты:**
```text
features/settings/lib/src/widgets/language_picker.dart
```
Выбор языка (Dropdown).

**Обновить `features/settings/lib/settings.dart`:** Добавить экспорты.


### 6. ОБНОВИТЬ pubspec.yaml

**Корневой pubspec.yaml** — добавить все модули и зависимости.

**Для каждого модуля** — добавить необходимые зависимости.

**Обязательные зависимости:**
- `flutter_bloc: ^8.1.4`
- `get_it: ^7.6.7`
- `equatable: ^2.0.5`
- `auto_route: ^8.0.0`
- `easy_localization: ^3.0.3`
- `flutter_dotenv: ^5.1.0`
- `supabase_flutter: ^2.5.0`
- `drift: ^2.14.0`
- `sqlite3_flutter_libs: ^0.5.0`
- `path_provider: ^2.1.3`
- `shared_preferences: ^2.2.3`
- `google_sign_in: ^6.2.1`
- `sign_in_with_apple: ^5.0.0`
- `flutter_svg: ^2.0.9`
- `image: ^4.2.0`
- `screenshot: ^2.1.0`
- `share_plus: ^7.2.2`
- `gallery_saver: ^2.3.2`
- `flutter_colorpicker: ^1.0.3`
- `sliding_up_panel: ^2.0.0+1`
- `logger: ^2.0.2+1`
- `flutter_native_splash: ^2.4.0`

**Dev зависимости:**
- `build_runner: ^2.4.8`
- `auto_route_generator: ^8.0.0`
- `drift_dev: ^2.14.0`
- `easy_localization_generator: ^1.0.0`


### 7. Создать build.yaml

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
generate_migrations: true
```


## ПОРЯДОК ГЕНЕРАЦИИ

1. **Core** — `app_locator.dart`, `constants.dart`, `logger.dart`, `result.dart`
2. **Core_UI** — все виджеты
3. **Domain** — use_case.dart → entities → repositories → usecases → domain_di.dart
4. **Data** — providers → datasources → models → mappers → repositories → data_di.dart
5. **Features** — Auth → Gallery → Canvas → Settings
6. **Обновить pubspec.yaml** и создать **build.yaml**


## ТРЕБОВАНИЯ К КОДУ

1. **Длина строки:** 100 символов
2. **Каждый класс в отдельном файле**
3. **Все публичные методы должны иметь dartdoc комментарии**
4. **BLoC** — единый класс состояния (extends Equatable), создается через `BlocProvider` в экране
5. **BLoC НЕ регистрируется в DI** — зависимости передаются через конструктор с использованием `appLocator`
6. **UseCase** — используют интерфейсы FutureUseCase/UseCase
7. **UseCase** — возвращают Future/значение напрямую (не Result)
8. **Ошибки** — UseCase выбрасывают исключения, BLoC перехватывают
9. **Следовать Clean Architecture** (Presentation → Domain → Data)
10. **Именование:** папки — snake_case, файлы — snake_case, классы — PascalCase, переменные — camelCase


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
- **API_SPEC.md** — спецификация Supabase
- **UI_SPEC.md** — спецификация UI экранов и виджетов
- **CHECKLIST.md** — чек-лист всех задач