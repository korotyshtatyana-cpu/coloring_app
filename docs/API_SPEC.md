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
  svg_data TEXT NOT NULL, -- В БД хранится URL на SVG файл в Storage
  preview_url TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Поле category хранит строковое значение enum ContourCategory.

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

## Локальная база Drift (SQLite)

`schemaVersion = 3`.

- `Projects` — id, contourId, userId, data (JSON), lastOpened, createdAt
- `Strokes` — id, projectId, points (JSON), color, size, opacity, brushType, brushId, isPressureSensitive
- `Contours` — id, title, category, svgUrl, previewUrl, createdAt

Таблица `Contours` кэширует данные. Поле `svgUrl` в коде соответствует полю `svg_data` в удаленной БД.

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

## Категории контуров
Приложение динамически получает список непустых категорий через запрос:
`select category from contours group by category`.

## JSON структура проекта:
```json
{
  "strokes": [...],
  "settings": {
    "contourColor": 4278190080,
    "contourOpacity": 0.5
  },
  "thumbnailPath": "..."
}
```
> [!NOTE]
> `contourWidth` удален из настроек проекта.
