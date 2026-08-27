import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../bloc/gallery_bloc.dart';
import 'gallery_content.dart';

/// Gallery screen displaying available contours and filters.
@RoutePage()
class GalleryScreen extends StatelessWidget {
  /// Creates a [GalleryScreen].
  const GalleryScreen({super.key});

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
