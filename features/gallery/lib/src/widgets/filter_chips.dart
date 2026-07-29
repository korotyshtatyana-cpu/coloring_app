import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/gallery_bloc.dart';
import '../extensions/contour_category_extension.dart';

/// Filter chips for switching gallery filters and categories.
class FilterChips extends StatelessWidget {
  /// Creates [FilterChips].
  const FilterChips({super.key});

  static final List<ContourCategory> _categories = ContourCategory.values
      .where((ContourCategory c) => c != ContourCategory.all)
      .toList();

  @override
  Widget build(BuildContext context) {
    final FilterType activeFilter = context.select(
      (GalleryBloc bloc) => bloc.state.activeFilter,
    );
    final ContourCategory selectedCategory = context.select(
      (GalleryBloc bloc) => bloc.state.selectedCategory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              _FilterChip(
                label: LocaleKeys.all.tr(),
                isActive: activeFilter == FilterType.all,
                onTap: () => context.read<GalleryBloc>().add(
                      const ChangeFilter(FilterType.all),
                    ),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: LocaleKeys.favorites.tr(),
                isActive: activeFilter == FilterType.favorites,
                onTap: () => context.read<GalleryBloc>().add(
                      const ChangeFilter(FilterType.favorites),
                    ),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: LocaleKeys.work_in_progress.tr(),
                isActive: activeFilter == FilterType.inProgress,
                onTap: () => context.read<GalleryBloc>().add(
                      const ChangeFilter(FilterType.inProgress),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              _FilterChip(
                label: LocaleKeys.all.tr(),
                isActive: selectedCategory == ContourCategory.all,
                onTap: () => context.read<GalleryBloc>().add(
                      const SelectCategory(ContourCategory.all),
                    ),
              ),
              const SizedBox(width: 8),
              ..._categories.map((ContourCategory category) {
                final bool isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: category.localized(),
                    isActive: isSelected,
                    onTap: () => context.read<GalleryBloc>().add(
                          SelectCategory(
                            isSelected ? ContourCategory.all : category,
                          ),
                        ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap(),
      selectedColor: colors.secondaryBg,
      labelStyle: AppFonts.normal14.copyWith(
        color: isActive ? colors.gainsboro : colors.primaryBg,
      ),
    );
  }
}
