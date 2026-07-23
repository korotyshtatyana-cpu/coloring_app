import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:navigation/navigation.dart';

import 'error_handler/error_handler.dart';

Future<void> mainCommon(Flavor flavor) async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await EasyLocalization.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      <DeviceOrientation>[DeviceOrientation.portraitUp]);

  await _setupDI(flavor);

  runApp(const App());

  FlutterNativeSplash.remove();
}

Future<void> _setupDI(Flavor flavor) async {
  await dotenv.load(
    fileName: switch (flavor) {
      Flavor.prod => '.env.prod',
      Flavor.dev => '.env.dev',
    },
  );

  CoreDi.init(flavor);
  await DataDI.initDependencies();
  DomainDI.initDependencies();
  NavigationDI.initDependencies();

  await appLocator.allReady();
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<App> {
  final AppRouter _appRouter = appLocator<AppRouter>();

  late final RouterConfig<Object> _routerConfig;

  @override
  void initState() {
    super.initState();

    _routerConfig = _appRouter.config();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ErrorHandler.init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      path: AppLocalization.langFolderPath,
      supportedLocales: AppLocalization.supportedLocales,
      fallbackLocale: AppLocalization.fallbackLocale,
      child: Builder(
        builder: (BuildContext context) {
          return AppErrorHandlerProvider(
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: _routerConfig,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: lightTheme,
            ),
          );
        },
      ),
    );
  }
}
