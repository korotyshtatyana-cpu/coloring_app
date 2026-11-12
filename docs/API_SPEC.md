# API спецификация (Supabase)

## Таблицы Supabase

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE contours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  category TEXT NOT NULL,       -- Депрекейтед (сохранено для обратной совместимости)
  categories text[] NOT NULL DEFAULT '{}', -- Массив категорий контура
  svg_data TEXT NOT NULL,       -- В БД хранится URL на SVG-файл в Storage
  preview_url TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  access_type contour_access_type NOT NULL DEFAULT 'free', -- free / rewarded / paid
  price INTEGER,                -- цена в центах, только для paid
  product_id TEXT               -- явный Google Play product id для paid
);

-- Поле categories хранит массив строк enum ContourCategory (например, ['fantasy', 'goth']).
-- Поле category хранит первичную (legacy) категорию для старых версий клиента.
-- Поле access_type хранит строковое значение enum ContourAccessType.

-- Миграция 20261112000000_contour_multi_categories.sql (Expand-фаза):
--   * добавляет categories text[] NOT NULL DEFAULT '{}';
--   * заполняет массив из category для существующих строк;
--   * создаёт GIN-индекс для фильтрации через оператор `@>`;
--   * добавляет триггер, который заполняет categories при записи только category
--     старым клиентом.
-- Колонка category остаётся до завершения Contract-фазы, когда все клиенты
-- будут читать только categories.
--
-- Порядок выката: сначала применить эту миграцию к Supabase, затем выпускать
-- клиент, который читает categories и фильтрует через contains.

CREATE TABLE favorites (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  contour_id UUID REFERENCES contours(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, contour_id)
);

CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  contour_id UUID REFERENCES contours(id) ON DELETE CASCADE,
  data JSONB NOT NULL, -- strokes и настройки контура
  thumbnail_url TEXT,
  last_opened TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, contour_id)
);
```

Монетизационные таблицы (`subscriptions`, `subscription_purchases`,
`user_entitlements`, `pending_purchases`, `purchase_refunds`,
`processed_purchases`), RPC-функции и Edge Functions описаны в
[MONETIZATION.md](MONETIZATION.md).

## Локальная база Drift (SQLite)

`schemaVersion = 6`.

- `Projects` — id, contourId, userId, data (JSON), lastOpened, createdAt
- `Strokes` — id, projectId, points (JSON), color, size, opacity, brushType, brushId, isPressureSensitive
- `Brushes` — id, nameKey, previewPath, isPressureSensitive
- `Contours` — id, title, category, categories (JSON list), svgUrl, previewUrl, createdAt, accessType, price, productId

Таблица `Contours` кэширует данные. Поле `categories` хранит список категорий как JSON-массив строк. Поле `svgUrl` в коде соответствует полю `svg_data` в удалённой БД.

## Supabase Storage

### Бакет: countours_svgs
Хранит SVG-файлы контуров.
```text
countours_svgs/
├── animals/
│   ├── wolf.svg
│   └── ...
└── nature/
    └── ...
```

### Бакет: project_thumbnails
Миниатюры проектов пользователей (PNG).
```text
project_thumbnails/
├── {user_id}/
│   └── {contour_id}.png
```

### Бакет: feedback_attachments
Вложения обратной связи.
```text
feedback_attachments/
├── {user_id}/
│   └── {file_name}
└── anonymous/
    └── {file_name}
```

## Категории контуров
Контур может принадлежать нескольким категориям. Источником истины является
массив `categories`; колонка `category` — legacy-поле Expand-фазы, которое
сохраняется для обратной совместимости и используется как fallback, если массив
пуст или отсутствует.

- Приложение получает категории запросом `select categories, category from contours`.
- DTO (`ContourModel`) сначала читает `categories`, затем `category`, а при
  отсутствии обоих значений использует `ContourCategory.all`.
- Неизвестные строки игнорируются (`ContourCategory.tryParse`), поэтому новая
  категория на сервере не ломает старые версии приложения.
- `GetUsedCategoriesUseCase` возвращает плоский уникальный список всех
  категорий, встречающихся в контурах (`Set`), и он питает чипы фильтра.
- Фильтрация по категории выполняется на сервере через оператор contains:
  `.contains('categories', [category_name])`, поэтому контур с
  `["fantasy", "goth"]` находится и по `fantasy`, и по `goth`.
- При офлайн-фолбеке та же проверка выполняется локально:
  `contour.categories.contains(category)`.
- Пустые категории в UI не попадают.

## JSON структура контура (Supabase)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Dragon",
  "category": "fantasy",
  "categories": ["fantasy", "animals"],
  "svg_data": "https://<project>.supabase.co/storage/v1/object/public/countours_svgs/dragon.svg",
  "preview_url": "https://<project>.supabase.co/storage/v1/object/public/contours_previews/dragon.png",
  "access_type": "free",
  "price": null,
  "product_id": null,
  "created_at": "2026-11-12T10:00:00Z"
}
```
> `category` дублирует первую категорию из `categories` для старых клиентов.
> Новые записи должны заполнять оба поля; триггер БД дополнительно синхронизирует
> `categories`, если запись пришла только с `category`.

## JSON структура проекта:
```json
{
  "strokes": [
    {
      "id": "contourId_0",
      "project_id": "contourId",
      "points": [[10.0, 20.0, 1.0]],
      "color": 4278190080,
      "size": 10.0,
      "opacity": 1.0,
      "brushType": "circle",
      "brushId": "brush_id",
      "isPressureSensitive": true
    }
  ],
  "settings": {
    "contourColor": 4278190080,
    "contourOpacity": 0.5
  },
  "thumbnailPath": "..."
}
```
> [!NOTE]
> `contourWidth` удален из настроек проекта.
