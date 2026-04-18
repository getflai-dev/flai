import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/secure_auth_storage.dart';
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
/// On first launch, attempts to restore a persisted auth session from secure
/// storage so the user stays logged in between app restarts. While restoring,
/// a loading indicator is shown.
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
  const FlaiApp({super.key, required this.config});

  @override
  State<FlaiApp> createState() => _FlaiAppState();
}

class _FlaiAppState extends State<FlaiApp> {
  late final StorageProvider _storageProvider;
  late final GoRouter _router;
  late final SecureAuthStorage _authStorage;

  bool _isRestoringSession = true;
  StreamSubscription<({String? accessToken, String? refreshToken})>? _tokenSub;

  @override
  void initState() {
    super.initState();
    _storageProvider =
        widget.config.storageProvider ?? InMemoryStorageProvider();
    _router = createAppRouter(config: widget.config);
    _authStorage = SecureAuthStorage();

    _listenToTokenChanges();
    _tryRestoreSession();
  }

  @override
  void dispose() {
    _tokenSub?.cancel();
    _router.dispose();
    super.dispose();
  }

  /// Subscribe to the auth provider's token stream to persist changes.
  void _listenToTokenChanges() {
    _tokenSub = widget.config.authProvider.tokenChanges.listen((tokens) async {
      if (tokens.accessToken != null) {
        await _authStorage.saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
        final user = widget.config.authProvider.currentUser;
        if (user != null) {
          await _authStorage.saveUser(user);
        }
      } else {
        // Null access token indicates sign-out — clear persisted session.
        await _authStorage.clear();
      }
    });
  }

  /// Attempt to restore a previously persisted session from secure storage.
  Future<void> _tryRestoreSession() async {
    try {
      final stored = await _authStorage.readTokens();
      if (stored != null) {
        final restored = await widget.config.authProvider.tryRestoreSession(
          stored.accessToken,
          stored.refreshToken,
        );
        if (!restored) {
          // Validation failed (expired, revoked, etc.) — clear stale tokens
          // so the next launch doesn't retry with the same dead credentials.
          await _authStorage.clear();
        }
      }
    } catch (_) {
      // Restoration failed — user will see the login screen.
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringSession = false;
        });
      }
    }
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

    if (_isRestoringSession) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: theme.colors.background,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return FlaiTheme(
      data: theme,
      child: FlaiProviders(
        authProvider: widget.config.authProvider,
        storageProvider: _storageProvider,
        aiProvider: widget.config.aiProvider,
        voiceProvider: widget.config.voiceProvider,
        brainProvider: widget.config.brainProvider,
        connectionsProvider: widget.config.connectionsProvider,
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
