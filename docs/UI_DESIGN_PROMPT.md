# UI Design Specification & AI Prompts

Этот документ содержит концепцию дизайна приложения "Coloring PRO" и готовые инструкции (промпты) для генерации визуальных интерфейсов с помощью AI (Midjourney, DALL-E, Claude и др.).

## 1. Концепция Дизайна (Design Concept)

### Общая идея
*   **Стиль:** Минимализм с элементами цифрового экспрессионизма (Digital Expressionism).
*   **Аудитория:** Девушки и женщины 16+.
*   **Вайб:** Легкость, чистота, отсутствие "давления", вдохновение. Приложение должно ощущаться как современное арт-пространство.
*   **Референс функционала:** GoPaint (удобство, чистота, фокус на творчестве).

### Визуальный язык
*   **Формы:** Максимально скругленные углы (Pill-shaped). Большие радиусы скругления для всех кнопок и панелей.
*   **Иконки:** Тонкие контурные линии (Thin Line Icons). Минималистичный и элегантный стиль.
*   **Цвета:** 
    *   Фон: Мягкий белый (Off-white) или очень светло-серый.
    *   Акценты: Пастельные тона, мягкие градиенты. Цвет иконок меняется в зависимости от активности.
    *   Текст: Глубокий графитовый (избегаем жесткого черного).

## 2. Описание экранов

### Галерея (Gallery)
*   Просторная сетка с большими отступами.
*   Карточки с сильным скруглением углов.
*   Мягкие "островки" (chips) для категорий.
*   Возможны абстрактные "мазки краски" на фоне экрана для поддержки стиля экспрессионизма.

### Редактор (Canvas Editor)
*   Холст занимает 90%+ экрана.
*   Парящие (floating) панели управления с мягкими тенями.
*   Слайдеры в виде изящных полосок с градиентами (особенно для прозрачности).
*   Компактные кнопки (24x24) с центрированными иконками (18x18).

### Оверлеи (Settings & Color Picker)
*   Полностью прозрачные фоны (без затемнения остального экрана).
*   Стиль "Glassmorphism" или плотные белые "карточки" с закруглением 24px+.
*   Плавные переходы цветов в палитре.

---

## 3. Промпты для AI (AI Generation Prompts)

### Основной интерфейс (UI Layout)
> **Prompt:** Mobile app UI design, Coloring book for women 16+, minimalist aesthetic, Digital Expressionism style accents, very rounded corners, pill-shaped buttons, thin line icons, soft pastel color palette, off-white background, airy and light feel, inspired by GoPaint, high resolution, clean layout, functional yet artistic.

### Набор иконок (Icon Set)
> **Prompt:** Minimalist thin line icon set for a drawing app: brush, eraser, undo, redo, color wheel, settings. Vector style, elegant, feminine, clean lines, consistent weight, isolated on white background.

### Цветовая палитра и текстуры (Atmosphere)
> **Prompt:** Abstract digital expressionism background for mobile app, soft pastel brush strokes on off-white canvas, minimalist, artistic, calming, light and airy, high resolution.

---

## 4. Инструкции по реализации
При применении дизайна в коде Flutter следует придерживаться правил из **[GOOD_PRACTICES.md](GOOD_PRACTICES.md)**:
1. Использовать `AppIconButton` для всех кнопок тулбара.
2. Использовать `CustomSlider` с поддержкой градиентов.
3. Реализовывать окна настроек через `showGeneralDialog` с прозрачным фоном.
