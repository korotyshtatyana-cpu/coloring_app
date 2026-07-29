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
  svg_data TEXT NOT NULL,
  preview_url TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

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
  data JSONB NOT NULL,
  last_opened TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, contour_id)
);
```

## Локальная база Drift (SQLite)

`schemaVersion = 1`. В локальной базе три таблицы:

- `Projects` — id, contourId, userId, data (JSON), lastOpened, createdAt
- `Strokes` — id, projectId, points (JSON), color, size, opacity, brushType
- `Contours` — id, title, category, svgData, previewUrl, createdAt

Таблица `Contours` используется для кэширования контуров.

## Supabase API Endpoints
### Получение контуров
```text
GET /rest/v1/contours
Query params:
- select: *
- limit: 20
- offset: 0
- order: created_at.desc
- category: eq.'animals' (опционально)
```

### Получение избранного
```text
GET /rest/v1/favorites
Query params:
- select: contour_id
- user_id: eq.'USER_ID'
```

### Добавление/удаление из избранного
```text
POST /rest/v1/favorites
Body: {"user_id": "USER_ID", "contour_id": "CONTOUR_ID"}

DELETE /rest/v1/favorites
Query params:
- user_id: eq.'USER_ID'
- contour_id: eq.'CONTOUR_ID'
```

### Получение проектов пользователя
```text
GET /rest/v1/projects
Query params:
- select: contour_id, data, last_opened
- user_id: eq.'USER_ID'
```

### Сохранение проекта
```text
UPSERT /rest/v1/projects
Body: {
  "user_id": "USER_ID",
  "contour_id": "CONTOUR_ID",
  "data": {"strokes": [...]}
}
Использовать on_conflict: (user_id, contour_id) DO UPDATE
```

## Supabase Storage
### Бакет: contours
```text
contours/
├── previews/
│   ├── contour_1.jpg
│   ├── contour_2.jpg
│   └── ...
└── svg/
    ├── contour_1.svg
    ├── contour_2.svg
    └── ...
```

### URL для preview
```text
https://PROJECT_ID.supabase.co/storage/v1/object/public/contours/previews/contour_1.jpg
```

## .env файлы
Файлы содержат только те ключи, которые используются в `AppConfig`.

### .env.dev
```text
SUPABASE_URL=https://your-project-dev.supabase.co
SUPABASE_ANON_KEY=your-dev-anon-key
GOOGLE_WEB_CLIENT_ID=your-dev-client-id
APPSFLYER_DEV_KEY=your-appsflyer-dev-key
APPSFLYER_IOS_APP_ID=your-ios-app-id
APPSFLYER_ANDROID_APP_ID=your-android-app-id
```

### .env.prod
```text
SUPABASE_URL=https://your-project-prod.supabase.co
SUPABASE_ANON_KEY=your-prod-anon-key
GOOGLE_WEB_CLIENT_ID=your-prod-client-id
APPSFLYER_DEV_KEY=your-appsflyer-prod-key
APPSFLYER_IOS_APP_ID=your-ios-app-id
APPSFLYER_ANDROID_APP_ID=your-android-app-id
```

## Категории контуров
| Категория | Описание | Ключ локализации |
|-----------|----------|------------------|
| `animals` | Животные | `LocaleKeys.animals` |
| `nature` | Природа | `LocaleKeys.nature` |
| `fantasy` | Фэнтези | `LocaleKeys.fantasy` |
| `mandala` | Мандалы | `LocaleKeys.mandala` |
| `transport` | Транспорт | `LocaleKeys.transport` |
| `cities` | Города | `LocaleKeys.cities` |
| `people` | Люди | `LocaleKeys.people` |
| `flowers` | Цветы | `LocaleKeys.flowers` |
| `patterns` | Узоры | `LocaleKeys.patterns` |
| `abstract` | Абстракция | `LocaleKeys.abstract` |

## JSON структура для хранения проектов:
```json
{
  "strokes": [
    {
      "points": [[12.5, 34.2], [13.1, 35.0], ...],
      "color": 4294967295,
      "size": 5.0,
      "opacity": 0.8,
      "brushType": "watercolor"
    }
  ],
  "settings": {
    "contourColor": 4278190080,
    "contourOpacity": 0.5,
    "contourWidth": 2.0
  }
}
```
