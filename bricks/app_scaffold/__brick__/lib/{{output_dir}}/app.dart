import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/flai_theme.dart';
import 'providers/storage_provider.dart';
import 'app_config.dart';
import 'providers.dart';
import 'routing/app_router.dart';

/// Root widget for the FlAI app scaffold.
///
/// Accepts an [AppScaffoldConfig] and wires together the theme, provider tree,
/// and router. Creates the [GoRouter] once in [initState] so navigation state
/// is preserved across rebuilds.
///
/// ```dart
/// runApp(
///   FlaiApp(
///     config: AppScaffoldConfig(
///       authProvider: myAuthProvider,
///       aiProvider: myAiProvider,
///     ),
///   ),
/// );
/// ```
class FlaiApp extends StatefulWidget {
  /// The scaffold configuration containing providers, theme, and flow configs.
  final AppScaffoldConfig config;

  /// Creates a [FlaiApp].
  const FlaiApp({
    super.key,
    required this.config,
  });

  @override
  State<FlaiApp> createState() => _FlaiAppState();
}

class _FlaiAppState extends State<FlaiApp> {
  late final StorageProvider _storageProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _storageProvider =
        widget.config.storageProvider ?? InMemoryStorageProvider();
    _router = createAppRouter(config: widget.config);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  /// Infer brightness from the background luminance to set correct status
  /// bar icon color.
  Brightness get _brightness =>
      _resolvedTheme.colors.background.computeLuminance() > 0.5
          ? Brightness.light
          : Brightness.dark;

  FlaiThemeData get _resolvedTheme =>
      widget.config.theme ?? FlaiThemeData.dark();

  @override
  Widget build(BuildContext context) {
    final theme = _resolvedTheme;

    return FlaiTheme(
      data: theme,
      child: FlaiProviders(
        authProvider: widget.config.authProvider,
        storageProvider: _storageProvider,
        aiProvider: widget.config.aiProvider,
        voiceProvider: widget.config.voiceProvider,
        child: MaterialApp.router(
          routerConfig: _router,
          title: widget.config.appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: _brightness,
            scaffoldBackgroundColor: theme.colors.background,
            colorScheme: ColorScheme(
              brightness: _brightness,
              primary: theme.colors.primary,
              onPrimary: theme.colors.primaryForeground,
              secondary: theme.colors.secondary,
              onSecondary: theme.colors.secondaryForeground,
              error: theme.colors.destructive,
              onError: theme.colors.destructiveForeground,
              surface: theme.colors.card,
              onSurface: theme.colors.cardForeground,
            ),
          ),
        ),
      ),
    );
  }
}
