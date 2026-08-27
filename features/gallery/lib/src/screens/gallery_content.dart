import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:settings/settings.dart';

import '../bloc/gallery_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips.dart';
import '../widgets/gallery_grid.dart';

/// Content of the gallery screen.
class GalleryContent extends StatelessWidget {
  /// Creates [GalleryContent].
  const GalleryContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TextStyle titleStyle = AppFonts.semiBold20.copyWith(color: colors.primaryText);

    return Scaffold(
      backgroundColor: colors.primaryBg,
      appBar: AppBar(
        backgroundColor: colors.primaryBg,
        title: Text(
          LocaleKeys.gallery.tr(),
          style: titleStyle,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings, color: colors.primaryText),
            onPressed: () => _onSettingsPressed(context),
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
              listenWhen: _shouldListenToFailure,
              listener: _onFailure,
              child: BlocBuilder<GalleryBloc, GalleryState>(
                builder: (BuildContext context, GalleryState state) {
                  if (state.status == GalleryStatus.loading && state.contours.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(color: colors.secondaryBg),
                    );
                  }

                  if (state.contours.isEmpty) {
                    return const EmptyState();
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) =>
                        _handleScroll(context, notification, state),
                    child: RefreshIndicator(
                      color: colors.secondaryBg,
                      onRefresh: () async => _onRefresh(context),
                      child: GalleryGrid(state: state),
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

  void _onSettingsPressed(BuildContext context) {
    context.router.push(const SettingsRoute());
  }

  bool _shouldListenToFailure(GalleryState previous, GalleryState current) {
    return current.status == GalleryStatus.failure && previous.status != GalleryStatus.failure;
  }

  void _onFailure(BuildContext context, GalleryState state) {
    ErrorDialog.show(
      context,
      message: state.error ?? LocaleKeys.something_went_wrong.tr(),
      retryLabel: LocaleKeys.retry.tr(),
      onRetry: () => _onRefresh(context),
    );
  }

  void _onRefresh(BuildContext context) {
    context.read<GalleryBloc>().add(const LoadContours(reset: true));
  }

  void _onLoadMore(BuildContext context) {
    context.read<GalleryBloc>().add(const LoadContours());
  }

  bool _handleScroll(BuildContext context, ScrollNotification notification, GalleryState state) {
    final bool isNearBottom =
        notification.metrics.pixels >= notification.metrics.maxScrollExtent * 0.9;
    if (isNearBottom && !state.hasReachedMax && state.status != GalleryStatus.loading) {
      _onLoadMore(context);
    }
    return false;
  }
}
