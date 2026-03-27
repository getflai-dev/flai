import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../config.dart';

/// Hidden command that connects FlAI to a specific backend.
///
/// Currently supports:
/// - `cmmd` -- CMMD API backend (https://cmmd.ai)
class ConnectCommand extends Command<int> {
  @override
  String get name => 'connect';

  @override
  String get description => 'Connect FlAI to a backend (hidden)';

  @override
  bool get hidden => true;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: flai connect <backend>');
      stderr.writeln('Available backends: cmmd');
      return 1;
    }

    final backend = args.first;

    switch (backend) {
      case 'cmmd':
        return _connectCmmd();
      default:
        stderr.writeln('Unknown backend: $backend');
        stderr.writeln('Available backends: cmmd');
        return 1;
    }
  }

  Future<int> _connectCmmd() async {
    final cwd = Directory.current.path;

    stdout.writeln('\u{1f517} Connecting FlAI to CMMD backend...');
    stdout.writeln('');

    // Read flai.yaml for output_dir and app settings.
    final configManager = FlaiConfigManager(projectRoot: cwd);
    FlaiConfig flaiConfig;
    String outputDir;

    if (!configManager.exists) {
      stderr.writeln(
        '\u{26a0}\u{fe0f}  No flai.yaml found. Run "flai init" first.',
      );
      flaiConfig = const FlaiConfig();
      outputDir = 'flai';
    } else {
      flaiConfig = configManager.read();
      outputDir = flaiConfig.outputDir.startsWith('lib/')
          ? flaiConfig.outputDir.substring(4)
          : flaiConfig.outputDir;
    }

    stdout.writeln('\u{1f4e6} Generating CMMD provider implementations...');

    // Find the cmmd_providers brick
    final brickPath = _findBrickPath();

    try {
      final generator = await MasonGenerator.fromBrick(Brick.path(brickPath));
      final target = DirectoryGeneratorTarget(Directory(cwd));
      final files = await generator.generate(
        target,
        vars: {'output_dir': outputDir},
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      for (final file in files) {
        stdout.writeln('  \x1B[32m\u2713\x1B[0m ${file.path}');
      }
    } on Exception catch (e) {
      stderr.writeln('\u{274c} Failed to generate CMMD providers: $e');
      return 1;
    }

    // Add dependencies to pubspec.yaml.
    stdout.writeln('\u{1f4e6} Adding dependencies...');
    for (final dep in [
      'http',
      'sign_in_with_apple',
      'google_sign_in',
      'url_launcher',
      'speech_to_text',
    ]) {
      _addPubDependency(cwd, dep);
    }

    // Rewrite main.dart to use CMMD providers instead of mocks.
    stdout.writeln('');
    stdout.writeln('\x1B[36m>\x1B[0m Wiring CMMD providers into main.dart...');
    _rewriteMainDart(cwd, outputDir, flaiConfig);

    stdout.writeln('');
    stdout.writeln('\u{2705} CMMD backend connected!');
    stdout.writeln('');
    stdout.writeln(
      'Your app is now wired to \x1B[36mcmmd.ai\x1B[0m with:',
    );
    stdout.writeln('  \x1B[32m\u2713\x1B[0m Authentication (email, Apple, Google)');
    stdout.writeln('  \x1B[32m\u2713\x1B[0m AI chat streaming');
    stdout.writeln('  \x1B[32m\u2713\x1B[0m Conversation persistence');
    stdout.writeln('  \x1B[32m\u2713\x1B[0m Voice (on-device STT + CMMD TTS)');
    stdout.writeln('');
    stdout.writeln('Run \x1B[36mflutter pub get\x1B[0m then \x1B[36mflutter run\x1B[0m.');

    return 0;
  }

  /// Rewrites main.dart to use CMMD providers instead of MockAuthProvider.
  void _rewriteMainDart(String projectRoot, String outputDir, FlaiConfig config) {
    final mainPath = p.join(projectRoot, 'lib', 'main.dart');
    final themeConstructor = switch (config.theme) {
      'light' => 'FlaiThemeData.light()',
      'ios' => 'FlaiThemeData.ios()',
      'premium' => 'FlaiThemeData.premium()',
      _ => 'FlaiThemeData.dark()',
    };

    final appName = config.appName;
    final assistantName = config.assistantName;

    final content = '''import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '$outputDir/app_scaffold.dart';
import '$outputDir/core/theme/flai_theme.dart';
import '$outputDir/flows/chat/chat_experience_config.dart';
import '$outputDir/flows/sidebar/settings_config.dart';
import '$outputDir/providers/cmmd_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress _dependents.isEmpty debug assertion (Flutter bug #106549).
  if (kDebugMode) {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('_dependents.isEmpty')) return;
      originalOnError?.call(details);
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
        appTitle: '$appName',
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
        theme: $themeConstructor,
        chatExperienceConfig: ChatExperienceConfig(
          assistantName: '$assistantName',
          availableModels: [
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
          ],
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
    ),
  );
}
''';

    File(mainPath).writeAsStringSync(content);
    stdout.writeln(
      '  \x1B[32m\u2713\x1B[0m Rewrote \x1B[36mlib/main.dart\x1B[0m with CMMD providers',
    );
  }

  String _findBrickPath() {
    // 1. Relative to the CLI package: ../../bricks/cmmd_providers/
    final cliPackageDir = p.dirname(p.dirname(Platform.script.toFilePath()));
    final fromCli = p.normalize(
      p.join(cliPackageDir, '..', '..', 'bricks', 'cmmd_providers'),
    );
    if (Directory(fromCli).existsSync()) return fromCli;

    // 2. From current working directory (monorepo dev).
    final fromCwd = p.normalize(
      p.join(Directory.current.path, 'bricks', 'cmmd_providers'),
    );
    if (Directory(fromCwd).existsSync()) return fromCwd;

    // 3. Walk up from CWD looking for bricks/ directory.
    var dir = Directory.current;
    for (var i = 0; i < 5; i++) {
      final candidate = p.join(dir.path, 'bricks', 'cmmd_providers');
      if (Directory(candidate).existsSync()) return candidate;
      dir = dir.parent;
    }

    // Fallback -- assume monorepo root
    return 'bricks/cmmd_providers';
  }

  /// Adds [package] to the project's `pubspec.yaml` under `dependencies`.
  void _addPubDependency(String projectRoot, String package) {
    final pubspecPath = p.join(projectRoot, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) return;

    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content) as Map?;
    if (yaml == null) return;

    final existingDeps =
        (yaml['dependencies'] as Map?)?.keys.cast<String>().toSet() ?? {};

    if (existingDeps.contains(package)) {
      stdout.writeln(
        '  \x1B[32m\u2713\x1B[0m $package already in pubspec.yaml',
      );
      return;
    }

    final editor = YamlEditor(content);
    editor.update(['dependencies', package], 'any');
    pubspecFile.writeAsStringSync(editor.toString());
    stdout.writeln(
      '  \x1B[32m\u2713\x1B[0m Added \x1B[36m$package\x1B[0m to pubspec.yaml',
    );
  }
}
