import 'dart:io';
import 'package:args/command_runner.dart';

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
    stdout.writeln('\u{1f517} Connecting FlAI to CMMD backend...');
    stdout.writeln('');

    // Check for flai.yaml to find output_dir
    final flaiYaml = File('flai.yaml');
    final outputDir = 'lib/flai'; // default

    if (!flaiYaml.existsSync()) {
      stderr.writeln(
        '\u{26a0}\u{fe0f}  No flai.yaml found. Run "flai init" first.',
      );
      stderr.writeln('   Generating into default path: $outputDir/providers/');
    }

    // Run the cmmd_providers brick via mason
    // The brick is bundled at ../../bricks/cmmd_providers
    stdout.writeln('\u{1f4e6} Generating CMMD provider implementations...');

    // Use Process.run to invoke mason make
    final result = await Process.run(
      'mason',
      [
        'make',
        'cmmd_providers',
        '--output-dir',
        '.',
        '--output_dir',
        outputDir.replaceAll('lib/', ''),
        '--on-conflict',
        'overwrite',
      ],
      workingDirectory: Directory.current.path,
    );

    if (result.exitCode != 0) {
      // If mason isn't available or the brick isn't registered,
      // fall back to the brick registry path
      stderr.writeln(
        '\u{26a0}\u{fe0f}  Mason brick not found. Trying bundled brick...',
      );

      // Try with the brick path
      final brickResult = await Process.run(
        'mason',
        [
          'make',
          '--source',
          'path',
          '--path',
          _findBrickPath(),
          '--output-dir',
          '.',
          '--output_dir',
          outputDir.replaceAll('lib/', ''),
          '--on-conflict',
          'overwrite',
        ],
        workingDirectory: Directory.current.path,
      );

      if (brickResult.exitCode != 0) {
        stderr.writeln('\u{274c} Failed to generate CMMD providers.');
        stderr.writeln(brickResult.stderr);
        return 1;
      }
    }

    // Also add http dependency
    stdout.writeln('\u{1f4e6} Adding http dependency...');
    final pubResult = await Process.run(
      'flutter',
      ['pub', 'add', 'http'],
      workingDirectory: Directory.current.path,
    );

    if (pubResult.exitCode != 0) {
      stderr.writeln(
        '\u{26a0}\u{fe0f}  Could not add http dependency automatically.',
      );
      stderr.writeln('   Run: flutter pub add http');
    }

    stdout.writeln('');
    stdout.writeln('\u{2705} CMMD providers generated!');
    stdout.writeln('');
    stdout.writeln('Generated files:');
    stdout.writeln('  $outputDir/providers/cmmd_config.dart');
    stdout.writeln('  $outputDir/providers/cmmd_auth_provider.dart');
    stdout.writeln('  $outputDir/providers/cmmd_ai_provider.dart');
    stdout.writeln('  $outputDir/providers/cmmd_storage_provider.dart');
    stdout.writeln('  $outputDir/providers/cmmd_voice_provider.dart');
    stdout.writeln('');
    stdout.writeln('Usage:');
    stdout.writeln(
      "  import 'package:your_app/flai/providers/cmmd_providers.dart';",
    );
    stdout.writeln('');
    stdout.writeln("  final config = CmmdConfig.dev(organizationId: '42');");
    stdout.writeln(
      '  final authProvider = CmmdAuthProvider(config: config);',
    );
    stdout.writeln('  final aiProvider = CmmdAiProvider(');
    stdout.writeln('    config: config,');
    stdout.writeln(
      '    accessTokenProvider: () => authProvider.accessToken,',
    );
    stdout.writeln('  );');
    stdout.writeln('');
    stdout.writeln('  runApp(FlaiApp(');
    stdout.writeln('    config: AppScaffoldConfig(');
    stdout.writeln('      authProvider: authProvider,');
    stdout.writeln('      aiProvider: aiProvider,');
    stdout.writeln('    ),');
    stdout.writeln('  ));');

    return 0;
  }

  String _findBrickPath() {
    // Look for the brick relative to the CLI package location
    // This works when the CLI is run from the monorepo
    final candidates = [
      'bricks/cmmd_providers',
      '../bricks/cmmd_providers',
      '../../bricks/cmmd_providers',
    ];

    for (final path in candidates) {
      if (Directory(path).existsSync()) return path;
    }

    // Fallback -- assume monorepo root
    return 'bricks/cmmd_providers';
  }
}
