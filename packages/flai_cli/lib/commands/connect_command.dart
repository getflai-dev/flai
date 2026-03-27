import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

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

    // Check for flai.yaml to find output_dir
    final flaiYaml = File(p.join(cwd, 'flai.yaml'));
    var outputDir = 'flai'; // default (without lib/ prefix)

    if (!flaiYaml.existsSync()) {
      stderr.writeln(
        '\u{26a0}\u{fe0f}  No flai.yaml found. Run "flai init" first.',
      );
      stderr.writeln('   Generating into default path: lib/$outputDir/providers/');
    } else {
      try {
        final yaml = loadYaml(flaiYaml.readAsStringSync()) as Map?;
        final configOutputDir = yaml?['output_dir'] as String?;
        if (configOutputDir != null) {
          outputDir = configOutputDir.startsWith('lib/')
              ? configOutputDir.substring(4)
              : configOutputDir;
        }
      } catch (_) {
        // Use default if yaml parsing fails
      }
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
    for (final dep in ['http', 'record', 'path_provider']) {
      _addPubDependency(cwd, dep);
    }

    stdout.writeln('');
    stdout.writeln('\u{2705} CMMD providers generated!');
    stdout.writeln('');
    stdout.writeln('Generated files:');
    stdout.writeln('  lib/$outputDir/providers/cmmd_config.dart');
    stdout.writeln('  lib/$outputDir/providers/cmmd_auth_provider.dart');
    stdout.writeln('  lib/$outputDir/providers/cmmd_ai_provider.dart');
    stdout.writeln('  lib/$outputDir/providers/cmmd_storage_provider.dart');
    stdout.writeln('  lib/$outputDir/providers/cmmd_voice_provider.dart');
    stdout.writeln('');
    stdout.writeln('Usage:');
    stdout.writeln(
      "  import 'package:your_app/$outputDir/providers/cmmd_providers.dart';",
    );
    stdout.writeln('');
    stdout.writeln("  final config = CmmdConfig(organizationId: '42');");
    stdout.writeln(
      '  final authProvider = CmmdAuthProvider(config: config);',
    );
    stdout.writeln(
      "  final tokenFn = () => authProvider.accessToken ?? '';",
    );
    stdout.writeln('');
    stdout.writeln('  runApp(FlaiApp(');
    stdout.writeln('    config: AppScaffoldConfig(');
    stdout.writeln('      authProvider: authProvider,');
    stdout.writeln(
      '      aiProvider: CmmdAiProvider(config: config, accessTokenProvider: tokenFn),',
    );
    stdout.writeln(
      '      storageProvider: CmmdStorageProvider(config: config, accessTokenProvider: tokenFn),',
    );
    stdout.writeln(
      '      voiceProvider: CmmdVoiceProvider(config: config, accessTokenProvider: tokenFn),',
    );
    stdout.writeln('    ),');
    stdout.writeln('  ));');
    stdout.writeln('');
    stdout.writeln(
      'Voice is auto-enabled when voiceProvider is configured.',
    );
    stdout.writeln('Run \x1B[36mflutter pub get\x1B[0m to fetch dependencies.');

    return 0;
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
