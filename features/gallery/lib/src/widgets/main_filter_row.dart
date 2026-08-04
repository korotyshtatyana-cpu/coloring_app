import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../bloc/gallery_bloc.dart';
import 'gallery_filter_chip.dart';

/// Main filters for gallery (All, Favorites, In Progress).
class MainFilterRow extends StatelessWidget {
  /// Creates [MainFilterRow].
  const MainFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    final FilterType activeFilter = context.select(
      (GalleryBloc bloc) => bloc.state.activeFilter,
    );

    const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 16);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: <Widget>[
          GalleryFilterChip(
            label: LocaleKeys.all.tr(),
            isActive: activeFilter == FilterType.all,
            onTap: () => _onFilterChanged(context, FilterType.all),
          ),
          const SizedBox(width: 8),
          GalleryFilterChip(
            label: LocaleKeys.favorites.tr(),
            isActive: activeFilter == FilterType.favorites,
            onTap: () => _onFilterChanged(context, FilterType.favorites),
          ),
          const SizedBox(width: 8),
          GalleryFilterChip(
            label: LocaleKeys.work_in_progress.tr(),
            isActive: activeFilter == FilterType.inProgress,
            onTap: () => _onFilterChanged(context, FilterType.inProgress),
          ),
        ],
      ),
    );
  }

  void _onFilterChanged(BuildContext context, FilterType filter) {
    context.read<GalleryBloc>().add(ChangeFilter(filter));
  }
}
