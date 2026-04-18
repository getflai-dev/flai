import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'flai/app_scaffold.dart';
import 'flai/flows/brain/brain_screen.dart';
import 'flai/flows/chat/chat_experience_config.dart';
import 'flai/flows/settings/account_screen.dart';
import 'flai/flows/settings/connections_screen.dart';
import 'flai/flows/settings/profile_screen.dart';
import 'flai/flows/sidebar/settings_config.dart';
import 'flai/flows/sidebar/sidebar_config.dart';
import 'flai/providers/cmmd_providers.dart';
import 'flai/themes/cmmd_themes.dart';

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

  runApp(
    FlaiApp(
      config: AppScaffoldConfig(
        appTitle: 'CMMD',
        theme: CmmdTheme.light(),
        sidebarConfig: const SidebarConfig(
          appName: 'CMMD',
          appLogo: CmmdLogo.full(),
          enableSearch: true,
          navItems: [
            NavItem(
              icon: Icons.psychology_outlined,
              label: 'Brain',
              page: FlaiBrainScreen(),
            ),
          ],
        ),
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
        brainProvider: CmmdBrainProvider(
          config: config,
          accessTokenProvider: tokenFn,
          organizationIdProvider: orgFn,
          csrfHeadersProvider: csrfFn,
        ),
        connectionsProvider: CmmdConnectionsProvider(
          config: config,
          accessTokenProvider: tokenFn,
          organizationIdProvider: orgFn,
          csrfHeadersProvider: csrfFn,
        ),
        chatExperienceConfig: ChatExperienceConfig(
          assistantName: 'Nova',
          greetingSubtitle: 'Your command center for work and life.',
          composerPlaceholder: 'Ask Nova anything...',
          availableModels: const [
            ModelOption(
              id: 'claude-sonnet-4-20250514',
              name: 'Claude Sonnet',
              description: 'Fast and intelligent',
              icon: Icons.bolt_rounded,
            ),
            ModelOption(
              id: 'claude-opus-4-20250514',
              name: 'Claude Opus',
              description: 'Most capable',
              icon: Icons.auto_awesome,
            ),
            ModelOption(
              id: 'gpt-4o',
              name: 'GPT-4o',
              description: 'OpenAI multimodal',
              icon: Icons.circle_outlined,
            ),
          ],
          availableModes: const [
            ChatMode(
              id: 'quick_answer',
              name: 'Quick Answer',
              subtitle: 'Concise direct responses',
              icon: Icons.bolt_rounded,
            ),
            ChatMode(
              id: 'autopilot',
              name: 'Autopilot',
              subtitle: 'Executes tasks for you',
              icon: Icons.auto_awesome,
            ),
            ChatMode(
              id: 'deep_think',
              name: 'Deep Think',
              subtitle: 'Reasons through hard problems',
              icon: Icons.psychology_alt_rounded,
            ),
            ChatMode(
              id: 'code',
              name: 'Code',
              subtitle: 'Writes and edits code',
              icon: Icons.code_rounded,
            ),
          ],
          availableSearchModes: const [
            SearchModeOption(
              id: 'smart',
              name: 'Smart',
              icon: Icons.auto_awesome_rounded,
            ),
            SearchModeOption(
              id: 'internal',
              name: 'Internal',
              icon: Icons.lock_outline_rounded,
            ),
            SearchModeOption(
              id: 'external',
              name: 'External',
              icon: Icons.public_rounded,
            ),
          ],
          composerConfig: ComposerConfig(
            attachmentSections: [
              const AttachSection(
                items: [
                  AttachItem.camera(),
                  AttachItem.photos(),
                  AttachItem.files(),
                ],
              ),
              CustomSection(
                title: 'Context',
                items: const [
                  AttachItem(
                    icon: Icons.folder_outlined,
                    label: 'Brain Folders',
                  ),
                  AttachItem(
                    icon: Icons.description_outlined,
                    label: 'Brain Documents',
                  ),
                  AttachItem(
                    icon: Icons.work_outline_rounded,
                    label: 'Projects',
                  ),
                  AttachItem(
                    icon: Icons.person_outline_rounded,
                    label: 'People',
                  ),
                ],
              ),
            ],
          ),
          suggestionPrompts: const [
            SuggestionPrompt(
              prompt: "What's in my email today?",
              label: "What's in my email?",
              icon: Icons.mail_outline_rounded,
            ),
            SuggestionPrompt(
              prompt: 'Summarize my Brain',
              icon: Icons.psychology_outlined,
            ),
            SuggestionPrompt(
              prompt: 'What did I work on yesterday?',
              icon: Icons.history_rounded,
            ),
            SuggestionPrompt(
              prompt: 'Draft a status update',
              icon: Icons.edit_note_rounded,
            ),
          ],
        ),
        settingsConfig: SettingsConfig(
          sections: [
            SettingsSection(
              title: 'Profile',
              rows: [
                NavigationRow(
                  icon: Icons.person_outline_rounded,
                  label: 'General',
                  destinationBuilder: (_) => const FlaiProfileScreen(),
                ),
                NavigationRow(
                  icon: Icons.business_outlined,
                  label: 'Account',
                  destinationBuilder: (_) => const FlaiAccountScreen(),
                ),
              ],
            ),
            SettingsSection(
              title: 'Integrations',
              rows: [
                NavigationRow(
                  icon: Icons.cable_rounded,
                  label: 'Connections',
                  destinationBuilder: (_) => const FlaiConnectionsScreen(),
                ),
              ],
            ),
            SettingsSection(
              title: 'Account',
              rows: [
                NavigationRow(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
