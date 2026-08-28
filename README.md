# Раскраска PRO

Мобильное Flutter-приложение для раскрашивания контуров с расширенными инструментами: кисти, ластик, undo/redo, избранное, экспорт и настройки.

## Архитектура

Проект построен по модульной архитектуре с чётким разделением ответственности:

- **core** — локализация, темы, DI, утилиты и обработка ошибок.
- **core_ui** — общие виджеты, цвета, шрифты и размеры.
- **domain** — бизнес-логика, сущности, use cases и репозитории.
- **data** — реализация репозиториев, провайдеры данных, сервисы.
- **navigation** — централизованная навигация на базе `auto_route`.
- **features** — экраны и BLoC-ы функциональных модулей:
  - `splash` — splash-экран с проверкой авторизации.
  - `gallery` — галерея контуров, избранное, работа в процессе.
  - `canvas` — редактор раскраски.
  - `settings` — настройки приложения.

Подробнее об архитектуре, спецификациях API и UI см. в документации:

- [Архитектура](docs/ARCHITECTURE.md)
- [Обзор проекта](docs/PROJECT_OVERVIEW.md)
- [Чистый код и лучшие практики](docs/GOOD_PRACTICES.md)
- [Дизайн и AI Промпты](docs/UI_DESIGN_PROMPT.md)
- [UI спецификация](docs/UI_SPEC.md)
- [API спецификация](docs/API_SPEC.md)
- [Чеклист](docs/CHECKLIST.md)

## Запуск

Приложение поддерживает две сборки: разработка (`dev`) и production (`prod`). Конфигурация окружения загружается из файлов `.env.dev` и `.env.prod`.

### Dev

```bash
flutter run -t lib/main_dev.dart --flavor dev
```

### Prod

```bash
flutter run -t lib/main_prod.dart --flavor prod
```

> Для запуска prod-сборки может потребоваться настроенное окружение и подпись.

## Генерация кода

Проект использует кодогенерацию для навигации (`auto_route`), локализации (`easy_localization`) и data-слоя (`build_runner`).

Запустить генерацию для всех модулей можно одной командой:

```bash
./fast_prebuild_script.sh
```

Или по отдельности для каждого модуля:

```bash
./core/prebuild_script_core.sh
./core_ui/prebuild_script_core_ui.sh
./domain/prebuild_script_domain.sh
./data/prebuild_script_data.sh
./navigation/prebuild_script_navigation.sh
./features/splash/prebuild_script_splash.sh
./features/gallery/prebuild_script_gallery.sh
./features/canvas/prebuild_script_canvas.sh
./features/settings/prebuild_script_settings.sh
```
