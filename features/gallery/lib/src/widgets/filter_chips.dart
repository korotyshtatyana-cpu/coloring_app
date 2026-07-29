import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/gallery_bloc.dart';

/// Filter chips for switching gallery filters and categories.
class FilterChips extends StatelessWidget {
  /// Creates [FilterChips].
  const FilterChips({super.key});

  static const List<String> _categories = <String>[
    'animals',
    'nature',
    'fantasy',
    'mandala',
    'transport',
    'cities',
    'people',
    'flowers',
    'patterns',
    'abstract',
  ];

  static const Map<String, String> _categoryKeys = <String, String>{
    'animals': LocaleKeys.animals,
    'nature': LocaleKeys.nature,
    'fantasy': LocaleKeys.fantasy,
    'mandala': LocaleKeys.mandala,
    'transport': LocaleKeys.transport,
    'cities': LocaleKeys.cities,
    'people': LocaleKeys.people,
    'flowers': LocaleKeys.flowers,
    'patterns': LocaleKeys.patterns,
    'abstract': LocaleKeys.abstract,
  };

  @override
  Widget build(BuildContext context) {
    final FilterType activeFilter = context.select(
      (GalleryBloc bloc) => bloc.state.activeFilter,
    );
    final String? selectedCategory = context.select(
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
            children: _categories.map((String category) {
              final bool isSelected = selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: _categoryKeys[category]!.tr(),
                  isActive: isSelected,
                  onTap: () => context.read<GalleryBloc>().add(
                        SelectCategory(isSelected ? '' : category),
                      ),
                ),
              );
            }).toList(),
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
