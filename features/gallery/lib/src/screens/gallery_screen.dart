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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer = appLocator<AutoRouteObserver>();
    _observer?.subscribe(this, context.routeData);
  }

  @override
  void dispose() {
    _observer?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // This is called when we return to this screen from another screen (like Canvas).
    // Wait a short time to allow background save and thumbnail generation to finish.
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<GalleryBloc>().add(const LoadContours(reset: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GalleryBloc>(
      create: (BuildContext context) => _createBloc(context),
      child: const GalleryContent(),
    );
  }

  GalleryBloc _createBloc(BuildContext context) {
    return GalleryBloc(
      getContoursUseCase: appLocator<GetContoursUseCase>(),
      getContoursByIdsUseCase: appLocator<GetContoursByIdsUseCase>(),
      toggleFavoriteUseCase: appLocator<ToggleFavoriteUseCase>(),
      getFavoriteIdsUseCase: appLocator<GetFavoriteIdsUseCase>(),
      getWorkInProgressUseCase: appLocator<GetWorkInProgressUseCase>(),
    )..add(const LoadContours(reset: true));
  }
}
