# Инструкция для генерации кода

## Цель
Сгенерировать полностью работающее Flutter приложение на основе Clean Architecture с использованием BLoC, get_it (appLocator), easy_localization, auto_route и Drift (SQLite).

## Структура генерации

### Этап 1: Core (дополнить существующее)
1. `app_locator.dart` — GetIt instance.
2. `constants.dart` — константы приложения (включая `minPointDistance` и `autosaveDebounce`).
3. `svg_utils.dart` — утилиты для парсинга `viewBox` и скачивания XML из URL.
4. Обновить `core.dart` — добавить экспорты утилит и реэкспорт `flutter_dotenv`, `easy_localization`.

### Этап 2: Core_UI (создать виджеты)
1. `responsive_helper.dart` — хелпер для определения планшетов (600dp).
2. `buttons/primary_button.dart` — основная кнопка.
3. `buttons/icon_button.dart` — `AppIconButton` (24px, иконка 18px).
4. `dialogs/error_dialog.dart` — диалог ошибки со статическим методом `show`.
5. `inputs/gradient_slider.dart` — слайдер с поддержкой градиентов.
6. `cards/contour_card.dart` — карточка контура.
7. Обновить `core_ui.dart` — добавить экспорты.

### Этап 3: Domain (создать полностью)
1. **Entities:**
    - `contour_entity.dart` (содержит `svgUrl`).
    - `project_entity.dart` (хранит `strokes` и настройки контура в `data`).
    - `stroke_entity.dart` (points, color, size, opacity, brushType, brushId, isPressureSensitive).
2. **Repositories (интерфейсы):**
    - `gallery_repository.dart` — методы `getContours`, `getUsedCategories`, `toggleFavorite`.
    - `canvas_repository.dart` — методы `saveProject`, `loadProject`, `exportImage`.
3. **UseCases:**
    - `gallery/get_used_categories_use_case.dart` — для фильтрации пустых категорий.
    - `canvas/export_image_params.dart` — принимает raw XML контура.
    - `canvas/export_image_use_case.dart`.

### Этап 4: Data (создать полностью)
1. **Providers:**
    - `database_provider.dart` — Drift БД. Таблица `Contours` с полем `svgUrl`. Схема v3.
    - `gallery_remote_provider.dart` — методы для получения контуров и списка категорий.
2. **Models (DTO):**
    - `contour_model.dart` (мапинг `svg_data` из БД в `svgUrl`).
3. **Mappers:** `contour_mapper.dart`, `stroke_mapper.dart`.
4. **Services:**
    - `canvas_rendering_service.dart` — склейка битмапа мазков и SVG контура в PNG.

### Этап 5: Gallery Feature
1. **BLoC:** `gallery_bloc.dart`. При сбросе (`reset: true`) запрашивает список активных категорий.
2. **Widgets:**
    - `gallery_grid.dart` — использует `ResponsiveHelper` (2 или 3 колонки).
    - `category_filter_row.dart` — отображает только активные категории из состояния BLoC.

### Этап 6: Canvas Feature (Bitmap Baking)
1. **BLoC:** `canvas_bloc.dart`. 
    - При загрузке скачивает XML контура через `SvgUtils.fetchSvgContent`.
    - Не обновляет список `strokes` на каждую точку, только `currentStroke`.
    - Событие `ContourCompiled` переводит экран в состояние `ready`.
2. **Painters:**
    - `CanvasPainter` — предоставляет `StrokeRenderer` для отрисовки мазков. Оптимизирован через `drawPath`.
    - `BitmapPainter` — ультра-быстрая отрисовка `ui.Image`.
    - `ActiveStrokePainter` — векторная отрисовка одной линии.
3. **Widgets:**
    - `raster_canvas_buffer.dart` — хранит `ui.Image` всех завершенных мазков. Поддерживает инкрементальное запекание.
    - `canvas_stack.dart` — разделяет отрисовку на `RasterCanvasBuffer`, векторный активный мазок и `ContourLayer`.
    - `contour_layer.dart` — компилирует SVG XML в `Picture` и уведомляет BLoC о готовности.
4. **Screens:** `canvas_screen.dart`. Лоадер скрывается только когда `status == ready` и `isContourReady == true`.

## Критерии качества

### Производительность:
1. Использование **Bitmap Baking** для фоновых мазков.
2. Изоляция слоев через `RepaintBoundary` и независимые `BlocBuilder`.
3. Фильтрация точек по расстоянию (`minPointDistance`).
4. Отрисовка линий через `drawPath`.

### Надежность:
1. Обработка ошибок сети при загрузке SVG — автоматическая разблокировка интерфейса.
2. Обработка ошибок Supabase (например, 521) — скрытие лоадера и показ диалога ошибки.

### Архитектура:
1. Репозитории возвращают доменные сущности.
2. BLoC не зависят от Flutter виджетов.
3. Весь UI декларативен и разбит на мелкие файлы.

## Drift (SQLite)
Генерация через `drift_dev`. Схема v3 (svg_url в контурах).

## Запуск приложения
Через точки входа `main_dev.dart` и `main_prod.dart`.
