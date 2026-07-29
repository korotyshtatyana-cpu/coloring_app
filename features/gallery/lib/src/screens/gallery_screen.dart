import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:settings/settings.dart';

import '../bloc/gallery_bloc.dart';
import '../widgets/contour_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips.dart';

/// Gallery screen displaying available contours and filters.
@RoutePage()
class GalleryScreen extends StatelessWidget {
  /// Creates a [GalleryScreen].
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GalleryBloc>(
      create: (context) => GalleryBloc(
        getContoursUseCase: appLocator<GetContoursUseCase>(),
        getContoursByIdsUseCase: appLocator<GetContoursByIdsUseCase>(),
        toggleFavoriteUseCase: appLocator<ToggleFavoriteUseCase>(),
        getFavoriteIdsUseCase: appLocator<GetFavoriteIdsUseCase>(),
        getWorkInProgressUseCase: appLocator<GetWorkInProgressUseCase>(),
      )..add(const LoadContours()),

      child: const GalleryContent(),
    );
  }
}

class GalleryContent extends StatelessWidget {
  /// Creates [GalleryContent].
  const GalleryContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.primaryBg,
      appBar: AppBar(
        backgroundColor: colors.primaryBg,
        title: Text(
          LocaleKeys.gallery.tr(),
          style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings, color: colors.primaryText),
            onPressed: () => context.router.push(const SettingsRoute()),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          const FilterChips(),
          const SizedBox(height: 8),
          Expanded(
            child: BlocListener<GalleryBloc, GalleryState>(
              listenWhen: (GalleryState previous, GalleryState current) =>
                  current.status == GalleryStatus.failure &&
                  previous.status != GalleryStatus.failure,
              listener: (BuildContext context, GalleryState state) {
                ErrorDialog.show(
                  context,
                  message: state.error ?? LocaleKeys.something_went_wrong.tr(),
                  retryLabel: LocaleKeys.retry.tr(),
                  onRetry: () => context.read<GalleryBloc>().add(
                        const LoadContours(reset: true),
                      ),
                );
              },
              child: BlocBuilder<GalleryBloc, GalleryState>(
                builder: (context, state) {
                  if (state.status == GalleryStatus.loading &&
                      state.contours.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(color: colors.secondaryBg),
                    );
                  }

                  if (state.status == GalleryStatus.failure &&
                      state.contours.isEmpty) {
                    return const EmptyState();
                  }

                  if (state.contours.isEmpty) {
                    return const EmptyState();
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent * 0.9 &&
                          !state.hasReachedMax &&
                          state.status != GalleryStatus.loading) {
                        context.read<GalleryBloc>().add(const LoadContours());
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      color: colors.secondaryBg,
                      onRefresh: () async {
                        context.read<GalleryBloc>().add(
                              const LoadContours(reset: true),
                            );
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).orientation ==
                                  Orientation.portrait
                              ? 2
                              : 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: state.contours.length,
                        itemBuilder: (context, index) {
                          final contour = state.contours[index];
                          final isFavorite =
                              state.favoriteIds.contains(contour.id);
                          final isInProgress =
                              state.workInProgressIds.contains(contour.id);

                          return GalleryContourCard(
                            contour: contour,
                            isFavorite: isFavorite,
                            isInProgress: isInProgress,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
