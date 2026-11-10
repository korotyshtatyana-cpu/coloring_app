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
  category TEXT NOT NULL,
  svg_data TEXT NOT NULL, -- В БД хранится URL на SVG-файл в Storage
  preview_url TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  access_type contour_access_type NOT NULL DEFAULT 'free', -- free / rewarded / paid
  price INTEGER,          -- цена в центах, только для paid
  product_id TEXT         -- явный Google Play product id для paid
);

-- Поле category хранит строковое значение enum ContourCategory.
-- Поле access_type хранит строковое значение enum ContourAccessType.

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

`schemaVersion = 5`.

- `Projects` — id, contourId, userId, data (JSON), lastOpened, createdAt
- `Strokes` — id, projectId, points (JSON), color, size, opacity, brushType, brushId, isPressureSensitive
- `Brushes` — id, nameKey, previewPath, isPressureSensitive
- `Contours` — id, title, category, svgUrl, previewUrl, createdAt, accessType, price, productId

Таблица `Contours` кэширует данные. Поле `svgUrl` в коде соответствует полю `svg_data` в удалённой БД.

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
Приложение получает категории всех контуров запросом
`select category from contours` и убирает дубликаты на клиенте через `Set`.
Пустые категории в UI не попадают.

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
