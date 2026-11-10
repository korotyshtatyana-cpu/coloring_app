import 'package:auto_route/auto_route.dart';
import 'package:canvas/canvas.dart';
import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:settings/settings.dart';

import '../bloc/gallery_bloc.dart';
import '../widgets/ad_loading_overlay.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips.dart';
import '../widgets/gallery_title.dart';
import '../widgets/grid/gallery_grid.dart';
import '../widgets/user_avatar_button.dart';

/// Content of the gallery screen.
class GalleryContent extends StatelessWidget {
  /// Creates [GalleryContent].
  const GalleryContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.primaryBg,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: colors.primaryBg,
        surfaceTintColor: colors.primaryBg,
        title: GalleryTitle(title: context.tr(LocaleKeys.gallery)),
        actions: <Widget>[
          BlocBuilder<GalleryBloc, GalleryState>(
            buildWhen: (GalleryState previous, GalleryState current) =>
                previous.planType != current.planType ||
                previous.noAdsPurchased != current.noAdsPurchased,
            builder: (BuildContext context, GalleryState state) =>
                UserAvatarButton(
                  onPressed: () => _onProfilePressed(context),
                  planType: state.planType,
                  noAdsPurchased: state.noAdsPurchased,
                ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: MultiBlocListener(
        listeners: <BlocListener<GalleryBloc, GalleryState>>[
          BlocListener<GalleryBloc, GalleryState>(
            listenWhen: _shouldListenToAccessRequest,
            listener: _onAccessRequest,
          ),
        ],
        child: BlocBuilder<GalleryBloc, GalleryState>(
          buildWhen: (GalleryState previous, GalleryState current) =>
              previous.isLoadingAd != current.isLoadingAd,
          builder: (BuildContext context, GalleryState state) => Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              child: CircularProgressIndicator(color: colors.accentDark),
                            );
                          }

                          if (state.contours.isEmpty) {
                            return const EmptyState();
                          }

                          return NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification notification) {
                              return _handleScroll(context, notification, state);
                            },
                            child: RefreshIndicator(
                              color: colors.accentDark,
                              backgroundColor: colors.secondaryBg,
                              onRefresh: () async => _onRefresh(context),
                              child: GalleryGrid(state: state),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  BlocBuilder<GalleryBloc, GalleryState>(
                    buildWhen: (GalleryState previous, GalleryState current) =>
                        previous.showAds != current.showAds,
                    builder: _buildBanner,
                  ),
                ],
              ),
              if (state.isLoadingAd) const Positioned.fill(child: AdLoadingOverlay()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, GalleryState state) {
    if (!state.showAds) {
      return const SizedBox.shrink();
    }
    final Widget? banner = appLocator<AdService>().buildBanner();
    if (banner == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: Semantics(
        label: context.tr(LocaleKeys.banner_ad_label),
        child: Padding(padding: const EdgeInsets.only(top: 4), child: banner),
      ),
    );
  }

  bool _shouldListenToAccessRequest(GalleryState previous, GalleryState current) {
    return current.accessRequest != null && current.accessRequest?.id != previous.accessRequest?.id;
  }

  Future<void> _onAccessRequest(BuildContext context, GalleryState state) async {
    final AccessRequest request = state.accessRequest!;
    final GalleryBloc bloc = context.read<GalleryBloc>();
    bloc.add(const AccessRequestHandled());

    if (request.granted) {
      await context.router.push(
        CanvasRoute(
          contourId: request.contourId,
          isViewOnly: request.viewOnly,
        ),
      );
      return;
    }

    if (request.outcome == RewardedAdOutcome.unavailable) {
      ErrorDialog.show(
        context,
        message: context.tr(LocaleKeys.rewarded_ad_unavailable),
        retryLabel: context.tr(LocaleKeys.retry),
        onRetry: () => bloc.add(OpenContour(request.contourId)),
      );
    }
  }

  void _onProfilePressed(BuildContext context) {
    context.router.push(const SettingsRoute());
  }

  bool _shouldListenToFailure(GalleryState previous, GalleryState current) {
    return current.status == GalleryStatus.failure && previous.status != GalleryStatus.failure;
  }

  void _onFailure(BuildContext context, GalleryState state) {
    // The raw exception is logged by the bloc; the user only sees a clear,
    // localized message.
    ErrorDialog.show(
      context,
      message: context.tr(LocaleKeys.something_went_wrong),
      retryLabel: context.tr(LocaleKeys.retry),
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
