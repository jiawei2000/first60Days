import 'package:flutter/material.dart';
import 'package:flutter_app/resources/widgets/loader_widget.dart';
import 'package:nylo_framework/nylo_framework.dart';

/// Main entry point for the application
class Main extends StatefulWidget {
  final String? initialRoute;
  final ThemeMode themeMode;
  final List<NavigatorObserver> navigatorObservers;
  final GlobalKey<NavigatorState>? navigatorKey;
  final Route<dynamic>? Function(RouteSettings settings) onGenerateRoute;
  final Route<dynamic>? Function(RouteSettings settings) onUnknownRoute;
  final Nylo? nylo;

  Main(
    Nylo nylo, {
    super.key,
  })  : onGenerateRoute = nylo.router!.generator(),
        onUnknownRoute = nylo.router!.unknownRoute(),
        navigatorKey = NyNavigator.instance.router.navigatorKey,
        initialRoute = nylo.getInitialRoute(),
        navigatorObservers = nylo.getNavigatorObservers(),
        nylo = nylo,
        themeMode = ThemeMode.system;

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends NyPage<Main> {

  @override
  get init => () {

  };

  /// Map of lifecycle actions
  @override
  get lifecycleActions => widget.nylo?.appLifecycleStates ?? {};

  /// Loading style for the page.
  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal(
    child: MaterialApp(
      color: Colors.white,
      debugShowMaterialGrid: false,
      showPerformanceOverlay: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      showSemanticsDebugger: false,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          backgroundColor: Colors.white,
          body: Loader()
      ),
    )
  );

  /// The [view] method displays your page.
  @override
  Widget view(BuildContext context) {
    List<AppTheme> appThemes = Nylo.getAppThemes();
    return Container(
      color: Colors.white,
      child: LocalizedApp(
        child: ThemeProvider(
          themes: appThemes,
          child: ThemeConsumer(
            child: ValueListenableBuilder(
              valueListenable: ValueNotifier(NyLocalization.instance.locale),
              builder: (context, Locale locale, _) => MaterialApp(
                navigatorKey: widget.navigatorKey,
                themeMode: widget.themeMode,
                navigatorObservers: widget.navigatorObservers,
                debugShowMaterialGrid: false,
                showPerformanceOverlay: false,
                checkerboardRasterCacheImages: false,
                checkerboardOffscreenLayers: false,
                showSemanticsDebugger: false,
                debugShowCheckedModeBanner: false,
                darkTheme: appThemes.darkTheme,
                initialRoute: widget.initialRoute,
                onGenerateRoute: widget.onGenerateRoute,
                onUnknownRoute: widget.onUnknownRoute,
                theme: ThemeProvider.themeOf(context).data,
                localeResolutionCallback:
                    (Locale? locale, Iterable<Locale> supportedLocales) {
                  return locale;
                },
                localizationsDelegates: NyLocalization.instance.delegates,
                locale: locale,
                supportedLocales: [Locale('en', 'US')],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
