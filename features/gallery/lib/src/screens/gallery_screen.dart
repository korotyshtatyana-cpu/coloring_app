import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../bloc/gallery_bloc.dart';
import 'gallery_content.dart';

/// Gallery screen displaying available contours and filters.
@RoutePage()
class GalleryScreen extends StatefulWidget {
  /// Creates a [GalleryScreen].
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> with AutoRouteAware {
  AutoRouteObserver? _observer;

  /// The bloc is owned by this state (not created inside [build]) so that
  /// route-aware callbacks like [didPopNext] can access it without a
  /// [BuildContext] — the screen's own context is an ancestor of the
  /// [BlocProvider] and therefore cannot look it up.
  late final GalleryBloc _bloc = _createBloc();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer = appLocator<AutoRouteObserver>();
    _observer?.subscribe(this, context.routeData);
  }

  @override
  void dispose() {
    _observer?.unsubscribe(this);
    // BlocProvider.value doesn't close the bloc, so we do it ourselves.
    _bloc.close();
    super.dispose();
  }

  @override
  void didPopNext() {
    // This is called when we return to this screen from another screen (like Canvas).
    // Wait a short time to allow background save and thumbnail generation to finish.
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_bloc.isClosed) {
        _bloc.add(const LoadContours(reset: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GalleryBloc>.value(
      value: _bloc,
      child: const GalleryContent(),
    );
  }

  GalleryBloc _createBloc() {
    return GalleryBloc(
      getContoursUseCase: appLocator<GetContoursUseCase>(),
      getContoursByIdsUseCase: appLocator<GetContoursByIdsUseCase>(),
      toggleFavoriteUseCase: appLocator<ToggleFavoriteUseCase>(),
      getFavoriteIdsUseCase: appLocator<GetFavoriteIdsUseCase>(),
      getWorkInProgressUseCase: appLocator<GetWorkInProgressUseCase>(),
    )..add(const LoadContours(reset: true));
  }
}
