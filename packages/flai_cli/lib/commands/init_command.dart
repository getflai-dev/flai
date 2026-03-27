import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

import '../config.dart';
import '../platform_setup.dart';

/// `flai init` — initialise FlAI in the current Flutter project.
///
/// Runs an interactive setup when no flags are passed, asking for:
/// - App name
/// - AI assistant name
/// - Theme preset
///
/// All prompts have sensible defaults so the user can press Enter through
/// everything for a working setup in seconds.
class InitCommand extends Command<int> {
  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize FlAI in a Flutter project (creates flai.yaml and core files).';

  InitCommand() {
    argParser
      ..addOption(
        'output-dir',
        abbr: 'o',
        help: 'Subdirectory inside lib/ for generated components.',
        defaultsTo: 'flai',
      )
      ..addOption(
        'theme',
        abbr: 't',
        help: 'Theme preset.',
        allowed: ['dark', 'light', 'ios', 'premium'],
      )
      ..addOption(
        'app-name',
        help: 'Application display name.',
      )
      ..addOption(
        'assistant-name',
        help: 'AI assistant display name.',
      )
      ..addFlag(
        'no-interactive',
        negatable: false,
        help: 'Skip interactive prompts and use defaults.',
      );
  }

  @override
  Future<int> run() async {
    final cwd = Directory.current.path;

    // 1. Verify this is a Flutter project.
    if (!isFlutterProject(cwd)) {
      stderr.writeln(
        '\x1B[31mError:\x1B[0m The current directory is not a Flutter project.',
      );
      stderr.writeln(
        'Make sure you are in a directory with a pubspec.yaml '
        'that declares a Flutter dependency.',
      );
      return 1;
    }

    final configManager = FlaiConfigManager(projectRoot: cwd);

    // 2. Warn if already initialised.
    if (configManager.exists) {
      stderr.writeln(
        '\x1B[33mWarning:\x1B[0m flai.yaml already exists. '
        'Re-initialising will overwrite the config.',
      );
    }

    final noInteractive = argResults!['no-interactive'] as bool;
    final outputDir = argResults!['output-dir'] as String;

    // 3. Collect configuration — interactive prompts with defaults.
    String appName;
    String assistantName;
    String theme;

    if (noInteractive) {
      appName = (argResults!['app-name'] as String?) ?? 'FlAI Chat';
      assistantName = (argResults!['assistant-name'] as String?) ?? 'Assistant';
      theme = (argResults!['theme'] as String?) ?? 'dark';
    } else {
      stdout.writeln('');
      stdout.writeln(
        '\x1B[1m\x1B[36m  FlAI\x1B[0m — AI Chat Components for Flutter',
      );
      stdout.writeln('');

      appName = (argResults!['app-name'] as String?) ??
          _prompt('  App name', defaultValue: 'FlAI Chat');

      assistantName = (argResults!['assistant-name'] as String?) ??
          _prompt('  Assistant name', defaultValue: 'Assistant');

      theme = (argResults!['theme'] as String?) ??
          _promptChoice(
            '  Theme',
            choices: ['dark', 'light', 'ios', 'premium'],
            defaultValue: 'dark',
          );

      stdout.writeln('');
    }

    // 4. Create the config file.
    final config = FlaiConfig(
      outputDir: 'lib/$outputDir',
      theme: theme,
      appName: appName,
      assistantName: assistantName,
      installed: ['flai_init'],
    );
    configManager.write(config);
    stdout.writeln('\x1B[32m\u2713\x1B[0m Created $kConfigFileName');

    // 5. Generate core files using the flai_init Mason brick.
    final brickPath = _resolveBrickPath('flai_init');
    if (brickPath == null) {
      stderr.writeln(
        '\x1B[31mError:\x1B[0m Could not locate the flai_init brick.',
      );
      stderr.writeln(
        'Ensure you have the FlAI bricks available. '
        'If installed via pub, bricks should be bundled with the CLI.',
      );
      return 1;
    }

    stdout.writeln('\x1B[36m>\x1B[0m Generating core files...');

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
      stderr.writeln('\x1B[31mError:\x1B[0m Failed to generate files: $e');
      return 1;
    }

    // 6. Configure iOS and Android platform permissions.
    stdout.writeln('\x1B[36m>\x1B[0m Configuring platform permissions...');
    final platformActions = PlatformSetup(projectRoot: cwd).run();
    for (final action in platformActions) {
      stdout.writeln('  \x1B[32m\u2713\x1B[0m $action');
    }
    if (platformActions.isEmpty) {
      stdout.writeln('  \x1B[32m\u2713\x1B[0m Permissions already configured');
    }

    stdout.writeln('');
    stdout.writeln('\x1B[32m\u2713 FlAI initialised!\x1B[0m');
    stdout.writeln('');
    stdout.writeln('  App name:       \x1B[36m$appName\x1B[0m');
    stdout.writeln('  Assistant:      \x1B[36m$assistantName\x1B[0m');
    stdout.writeln('  Theme:          \x1B[36m$theme\x1B[0m');
    stdout.writeln('');
    stdout.writeln('Next steps:');
    stdout.writeln(
      '  \x1B[36mflai add app_scaffold\x1B[0m   '
      '— install the complete app shell',
    );
    stdout.writeln(
      '  \x1B[36mflai list\x1B[0m              '
      '— see all available components',
    );
    stdout.writeln('');

    return 0;
  }

  /// Prompt the user for a string value with a default.
  String _prompt(String label, {required String defaultValue}) {
    stdout.write('$label \x1B[2m($defaultValue)\x1B[0m: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    return input.isEmpty ? defaultValue : input;
  }

  /// Prompt the user to pick from a list of choices.
  String _promptChoice(
    String label, {
    required List<String> choices,
    required String defaultValue,
  }) {
    final choiceStr = choices.map((c) {
      return c == defaultValue ? '\x1B[1m$c\x1B[0m' : c;
    }).join(' / ');
    stdout.write('$label [$choiceStr]: ');
    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (input.isEmpty) return defaultValue;
    if (choices.contains(input)) return input;
    stdout.writeln('  \x1B[33mInvalid choice, using $defaultValue\x1B[0m');
    return defaultValue;
  }

  /// Tries to find the brick directory by checking common locations.
  String? _resolveBrickPath(String brickName) {
    // 1. Relative to the CLI package: ../../bricks/<name>/
    final cliPackageDir = p.dirname(p.dirname(Platform.script.toFilePath()));
    final fromCli = p.normalize(
      p.join(cliPackageDir, '..', '..', 'bricks', brickName),
    );
    if (Directory(fromCli).existsSync()) return fromCli;

    // 2. From current working directory (monorepo dev).
    final fromCwd = p.normalize(
      p.join(Directory.current.path, 'bricks', brickName),
    );
    if (Directory(fromCwd).existsSync()) return fromCwd;

    // 3. Walk up from CWD looking for bricks/ directory.
    var dir = Directory.current;
    for (var i = 0; i < 5; i++) {
      final candidate = p.join(dir.path, 'bricks', brickName);
      if (Directory(candidate).existsSync()) return candidate;
      dir = dir.parent;
    }

    return null;
  }
}
