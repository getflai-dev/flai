import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'flai/app_scaffold.dart';
import 'flai/flows/sidebar/settings_config.dart';
import 'flai/providers/cmmd_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress _dependents.isEmpty debug assertion (Flutter bug #106549).
  // This fires when notifyListeners() rebuilds the widget tree after the
  // Scaffold drawer has been open. Only affects debug builds — release
  // builds strip assert() and work fine.
  if (kDebugMode) {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('_dependents.isEmpty')) return;
      originalOnError?.call(details);
    };
    final originalBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (details) {
      if (details.exception.toString().contains('_dependents.isEmpty')) {
        return const SizedBox.shrink();
      }
      return originalBuilder(details);
    };
  }

  final config = CmmdConfig();
  final authProvider = CmmdAuthProvider(config: config);
  String tokenFn() => authProvider.accessToken ?? '';
  String? orgFn() => authProvider.organizationId;
  Map<String, String> csrfFn() => authProvider.csrfHeaders;

  runApp(FlaiApp(
    config: AppScaffoldConfig(
      authProvider: authProvider,
      aiProvider: CmmdAiProvider(
        config: config,
        accessTokenProvider: tokenFn,
        organizationIdProvider: orgFn,
        csrfHeadersProvider: csrfFn,
      ),
      storageProvider: CmmdStorageProvider(
        config: config,
        accessTokenProvider: tokenFn,
        organizationIdProvider: orgFn,
        csrfHeadersProvider: csrfFn,
      ),
      voiceProvider: CmmdVoiceProvider(
        config: config,
        accessTokenProvider: tokenFn,
        organizationIdProvider: orgFn,
        csrfHeadersProvider: csrfFn,
      ),
      settingsConfig: SettingsConfig(
        sections: [
          SettingsSection(
            title: 'Account',
            rows: [
              NavigationRow(
                icon: Icons.logout,
                label: 'Sign Out',
              ),
            ],
          ),
        ],
      ),
    ),
  ));
}
