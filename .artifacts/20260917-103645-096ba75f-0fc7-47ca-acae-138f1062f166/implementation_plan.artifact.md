# Gallery Improvements: Remove Stroke Width Adjustments and Filter Empty Categories

This plan covers two main requests:
1. **Remove Dynamic Contour Stroke Width Adjustment:** Simplifying the code and removing the fragile regex-based SVG modification.
2. **Filter Empty Categories in Gallery:** Ensuring the category filter row only displays categories that contain at least one image.

## Proposed Changes

### 1. Remove Dynamic Contour Stroke Width Adjustment

#### [svg_utils.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/core/lib/src/utils/svg_utils.dart)
- Remove `applyStrokeWidth` method.

#### [constants.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/core/lib/src/utils/constants.dart)
- Remove `contourDefaultWidth`, `minContourWidth`, and `maxContourWidth`.

#### [export_image_params.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/domain/lib/src/use_cases/canvas/export_image_params.dart)
- Remove `contourWidth` field and update constructor.

#### [canvas_rendering_service.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/data/lib/src/services/canvas_rendering_service.dart)
- Update `renderCanvasPng` and `_drawContour` to remove `contourWidth` parameters and calls to `applyStrokeWidth`.

#### [canvas_repository_impl.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/data/lib/src/repositories/canvas_repository_impl.dart)
- Stop passing `contourWidth` in `_renderCanvasPng`.

#### [canvas_state.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/features/canvas/lib/src/bloc/canvas_state.dart)
- Remove `contourWidth` from `CanvasState`, `copyWith`, and `props`.

#### [canvas_event.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/features/canvas/lib/src/bloc/canvas_event.dart)
- Remove `width` from `ChangeContourSettings` event.

#### [canvas_bloc.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/features/canvas/lib/src/bloc/canvas_bloc.dart)
- Update `_onChangeContourSettings`, `saveProject`, and `_onExportImage` to remove `contourWidth` logic.

#### [contour_layer.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/features/canvas/lib/src/widgets/canvas/contour_layer.dart)
- Update caching key logic and stop calling `applyStrokeWidth`.

---

### 2. Filter Empty Categories in Gallery

#### [gallery_repository.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/domain/lib/src/repositories/gallery_repository.dart)
- Add `Future<List<ContourCategory>> getUsedCategories()` method.

#### [gallery_remote_provider.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/data/lib/src/providers/gallery_remote_provider.dart)
- Implement `getUsedCategories()` using a distinct query on the `contours` table:
```dart
Future<List<ContourCategory>> getUsedCategories() async {
  final List<Map<String, dynamic>> response = await _client
      .from(RequestConstants.contoursTable)
      .select(RequestConstants.categoryColumn);

  return response
      .map((row) => row[RequestConstants.categoryColumn] as String)
      .toSet()
      .map((name) => ContourCategory.values.byName(name))
      .toList();
}
```

#### [gallery_repository_impl.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/data/lib/src/repositories/gallery_repository_impl.dart)
- Implement `getUsedCategories()` calling the remote provider with a fallback to local data if needed.

#### [gallery_state.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/features/gallery/lib/src/bloc/gallery_state.dart)
- Add `final List<ContourCategory> availableCategories` field.

#### [gallery_bloc.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/features/gallery/lib/src/bloc/gallery_bloc.dart)
- In `_onLoadContours`, if `event.reset` is true, fetch available categories and update the state.

#### [category_filter_row.dart](file:///Users/tatyana/projects/Flutter/coloring_pro/coloring_app/features/gallery/lib/src/widgets/category_filter_row.dart)
- Remove the hardcoded `_categories` list.
- Select `availableCategories` from the `GalleryBloc` state and use them to render the filter chips.

## Verification Plan

### Automated Tests
- `flutter analyze` to check for compilation errors.

### Manual Verification
1. **Contour Rendering:** Verify SVG contours display correctly in the canvas.
2. **Export:** Verify PNG export still contains the contour.
3. **Gallery Categories:**
   - Verify that the category row only shows categories that actually have images in the database.
   - Verify that clicking "All" still shows everything.
   - Verify that filtering by an available category works correctly.
   - (If possible/testable) Add an image to a new category in the database and verify it appears in the gallery after refresh.
