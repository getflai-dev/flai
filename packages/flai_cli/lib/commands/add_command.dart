import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../brick_registry.dart';
import '../config.dart';
import '../dependency_resolver.dart';
import '../platform_setup.dart';

/// `flai add <component>` — install a component and its dependencies.
class AddCommand extends Command<int> {
  @override
  String get name => 'add';

  @override
  String get description => 'Add a FlAI component to your project.';

  @override
  String get invocation => 'flai add <component>';

  AddCommand() {
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Show what would be installed without making changes.',
    );
  }

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      stderr.writeln('\x1B[31mError:\x1B[0m Please specify a component name.');
      stderr.writeln('');
      stderr.writeln('Usage: flai add <component>');
      stderr.writeln(
        'Run \x1B[36mflai list\x1B[0m to see available components.',
      );
      return 1;
    }

    final componentName = argResults!.rest.first;
    final dryRun = argResults!['dry-run'] as bool;
    final cwd = Directory.current.path;

    // 1. Check the component exists in the registry.
    final brick = BrickRegistry.lookup(componentName);
    if (brick == null) {
      stderr.writeln(
        '\x1B[31mError:\x1B[0m Unknown component "$componentName".',
      );
      stderr.writeln(
        'Run \x1B[36mflai list\x1B[0m to see available components.',
      );
      return 1;
    }

    // 2. Check that the project is initialised.
    final configManager = FlaiConfigManager(projectRoot: cwd);
    if (!configManager.exists) {
      stderr.writeln(
        '\x1B[31mError:\x1B[0m No flai.yaml found. '
        'Run \x1B[36mflai init\x1B[0m first.',
      );
      return 1;
    }

    final config = configManager.read();
    final alreadyInstalled = config.installed.toSet();

    // 3. Resolve the full dependency graph.
    const resolver = DependencyResolver();
    final installOrder = resolver.resolve(
      componentName,
      alreadyInstalled: alreadyInstalled,
    );

    if (installOrder.isEmpty) {
      stdout.writeln(
        '\x1B[32m\u2713\x1B[0m $componentName is already installed.',
      );
      return 0;
    }

    // 4. Collect pub dependencies.
    final pubDeps = resolver.collectPubDependencies(installOrder);

    // 5. Display the installation plan.
    stdout.writeln('');
    stdout.writeln('\x1B[1mInstallation plan:\x1B[0m');
    for (final name in installOrder) {
      final info = BrickRegistry.lookup(name)!;
      stdout.writeln('  \x1B[36m+\x1B[0m $name — ${info.description}');
    }
    if (pubDeps.isNotEmpty) {
      stdout.writeln('');
      stdout.writeln('\x1B[1mPub dependencies to add:\x1B[0m');
      for (final dep in pubDeps) {
        stdout.writeln('  \x1B[36m+\x1B[0m $dep');
      }
    }
    stdout.writeln('');

    if (dryRun) {
      stdout.writeln('\x1B[33m(dry run — no changes made)\x1B[0m');
      return 0;
    }

    // Derive the output_dir variable from config.
    // config.outputDir is like "lib/flai" — the brick var is just "flai".
    final outputDirVar =
        config.outputDir.startsWith('lib/')
            ? config.outputDir.substring(4)
            : config.outputDir;

    // 6. Install each component using Mason.
    for (final name in installOrder) {
      final brickPath = _resolveBrickPath(name);
      if (brickPath == null) {
        stderr.writeln(
          '\x1B[33m!\x1B[0m Brick not found for $name — skipping.',
        );
        continue;
      }

      stdout.writeln('\x1B[36m>\x1B[0m Installing $name...');

      try {
        final generator = await MasonGenerator.fromBrick(Brick.path(brickPath));
        final target = DirectoryGeneratorTarget(Directory(cwd));
        final files = await generator.generate(
          target,
          vars: {'output_dir': outputDirVar},
          fileConflictResolution: FileConflictResolution.overwrite,
        );

        for (final file in files) {
          stdout.writeln('  \x1B[32m\u2713\x1B[0m ${file.path}');
        }
      } on Exception catch (e) {
        stderr.writeln('\x1B[31mError:\x1B[0m Failed to install $name: $e');
        continue;
      }
    }

    // 7. Add pub.dev dependencies to the project pubspec.yaml.
    if (pubDeps.isNotEmpty) {
      _addPubDependencies(cwd, pubDeps);
    }

    // 8. Configure platform permissions if needed.
    final needsPermissions = installOrder.any(
      (name) => const {'chat_experience', 'app_scaffold'}.contains(name),
    );
    if (needsPermissions) {
      final platformActions = PlatformSetup(projectRoot: cwd).run();
      for (final action in platformActions) {
        stdout.writeln(
          '  \x1B[32m\u2713\x1B[0m $action',
        );
      }
    }

    // 9. Generate main.dart if installing app_scaffold.
    if (installOrder.contains('app_scaffold')) {
      _generateMainDart(cwd, config, outputDirVar);
    }

    // 10. Update flai.yaml.
    configManager.markInstalled(installOrder);

    stdout.writeln('');
    stdout.writeln(
      '\x1B[32m\u2713 Successfully installed $componentName!\x1B[0m',
    );

    if (pubDeps.isNotEmpty) {
      stdout.writeln('');
      stdout.writeln(
        'Run \x1B[36mflutter pub get\x1B[0m to fetch new dependencies.',
      );
    }
    stdout.writeln('');

    return 0;
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

  /// Generates a ready-to-run `main.dart` using values from `flai.yaml`.
  void _generateMainDart(String projectRoot, FlaiConfig config, String outputDir) {
    final mainPath = p.join(projectRoot, 'lib', 'main.dart');
    final themeConstructor = switch (config.theme) {
      'light' => 'FlaiThemeData.light()',
      'ios' => 'FlaiThemeData.ios()',
      'premium' => 'FlaiThemeData.premium()',
      _ => 'FlaiThemeData.dark()',
    };

    final appName = config.appName;
    final assistantName = config.assistantName;

    final content = '''import 'package:flutter/material.dart';

import '$outputDir/app_scaffold.dart';
import '$outputDir/core/theme/flai_theme.dart';
import '$outputDir/flows/auth/mock_auth_provider.dart';
import '$outputDir/flows/chat/chat_experience_config.dart';
import '$outputDir/flows/sidebar/settings_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FlaiApp(
      config: AppScaffoldConfig(
        appTitle: '$appName',
        authProvider: MockAuthProvider(),
        theme: $themeConstructor,
        chatExperienceConfig: ChatExperienceConfig(
          assistantName: '$assistantName',
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
      '  \x1B[32m\u2713\x1B[0m Generated \x1B[36mlib/main.dart\x1B[0m '
      '(theme: ${config.theme}, app: $appName)',
    );
  }

  /// Adds [packages] to the project's `pubspec.yaml` under `dependencies`.
  void _addPubDependencies(String projectRoot, List<String> packages) {
    final pubspecPath = p.join(projectRoot, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) return;

    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content) as Map?;
    if (yaml == null) return;

    final existingDeps =
        (yaml['dependencies'] as Map?)?.keys.cast<String>().toSet() ?? {};

    final toAdd = packages.where((p) => !existingDeps.contains(p)).toList();
    if (toAdd.isEmpty) return;

    final editor = YamlEditor(content);
    for (final pkg in toAdd) {
      editor.update(['dependencies', pkg], 'any');
      stdout.writeln(
        '  \x1B[32m\u2713\x1B[0m Added \x1B[36m$pkg\x1B[0m to pubspec.yaml',
      );
    }

    pubspecFile.writeAsStringSync(editor.toString());
  }
}
