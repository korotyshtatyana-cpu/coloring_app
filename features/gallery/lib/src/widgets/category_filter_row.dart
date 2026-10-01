import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../bloc/gallery_bloc.dart';
import '../extensions/contour_category_extension.dart';
import 'gallery_filter_chip.dart';

/// Row of category filter chips.
class CategoryFilterRow extends StatelessWidget {
  /// Creates [CategoryFilterRow].
  const CategoryFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GalleryBloc>().state;
    final ContourCategory selectedCategory = state.selectedCategory;
    final List<ContourCategory> availableCategories = state.availableCategories;

    const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 16);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: <Widget>[
          GalleryFilterChip(
            label: context.tr(LocaleKeys.all),
            isActive: selectedCategory == ContourCategory.all,
            onTap: () => _onCategoryChanged(context, ContourCategory.all),
          ),
          const SizedBox(width: 8),
          ...availableCategories.map((ContourCategory category) {
            final bool isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GalleryFilterChip(
                label: category.localized(context),
                isActive: isSelected,
                onTap: () => _onCategoryChanged(
                  context,
                  isSelected ? ContourCategory.all : category,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _onCategoryChanged(BuildContext context, ContourCategory category) {
    context.read<GalleryBloc>().add(SelectCategory(category));
  }
}
