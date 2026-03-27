import 'package:flutter/material.dart';

import 'flai/app_scaffold.dart';
import 'flai/flows/sidebar/settings_config.dart';
import 'flai/providers/cmmd_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
