import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../brick_registry.dart';
import '../config.dart';

/// `flai doctor` — check project health and configuration.
class DoctorCommand extends Command<int> {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Check FlAI project health and configuration.';

  @override
  Future<int> run() async {
    final cwd = Directory.current.path;
    var hasErrors = false;

    stdout.writeln('');
    stdout.writeln('\x1B[1mFlAI Doctor\x1B[0m');
    stdout.writeln('');

    // ── 1. Flutter project check ─────────────────────────────────
    final isFlutter = isFlutterProject(cwd);
    if (isFlutter) {
      _pass('Flutter project detected');
    } else {
      _fail('Not a Flutter project (no pubspec.yaml with Flutter dependency)');
      hasErrors = true;
    }

    // ── 2. flai.yaml check ───────────────────────────────────────
    final configManager = FlaiConfigManager(projectRoot: cwd);
    FlaiConfig? config;
    if (configManager.exists) {
      try {
        config = configManager.read();
        _pass('flai.yaml is valid');
      } catch (e) {
        _fail('flai.yaml exists but is invalid: $e');
        hasErrors = true;
      }
    } else {
      _fail('flai.yaml not found — run "flai init"');
      hasErrors = true;
    }

    // ── 3. Core files check ──────────────────────────────────────
    if (config != null) {
      final corePath = p.join(cwd, config.outputDir, 'core');
      final expectedCoreFiles = [
        'flai_theme.dart',
        'chat_message.dart',
        'chat_provider.dart',
      ];

      var allCorePresent = true;
      for (final fileName in expectedCoreFiles) {
        final file = File(p.join(corePath, fileName));
        if (file.existsSync()) {
          _pass('Core file exists: ${config.outputDir}/core/$fileName');
        } else {
          _warn('Missing core file: ${config.outputDir}/core/$fileName');
          allCorePresent = false;
        }
      }
      if (!allCorePresent) {
        stdout.writeln(
          '  \x1B[33m  Tip: Run "flai init" to regenerate core files.\x1B[0m',
        );
      }

      // ── 4. Installed component checks ────────────────────────────
      if (config.installed.isNotEmpty) {
        stdout.writeln('');
        stdout.writeln('\x1B[1mInstalled components:\x1B[0m');
        for (final name in config.installed) {
          final info = BrickRegistry.lookup(name);
          if (info == null) {
            _warn('$name is listed but not in the registry');
          } else {
            _pass(name);
          }
        }
      }

      // ── 5. Pub dependency checks ─────────────────────────────────
      final pubspecFile = File(p.join(cwd, 'pubspec.yaml'));
      if (pubspecFile.existsSync() && config.installed.isNotEmpty) {
        final pubspecContent = pubspecFile.readAsStringSync();
        final pubspecYaml = loadYaml(pubspecContent);
        final projectDeps =
            (pubspecYaml is Map && pubspecYaml['dependencies'] is Map)
                ? (pubspecYaml['dependencies'] as Map).keys
                    .cast<String>()
                    .toSet()
                : <String>{};

        final missingPubDeps = <String>[];
        for (final componentName in config.installed) {
          final info = BrickRegistry.lookup(componentName);
          if (info == null) continue;
          for (final pubDep in info.pubDependencies) {
            if (!projectDeps.contains(pubDep)) {
              missingPubDeps.add(pubDep);
            }
          }
        }

        if (missingPubDeps.isNotEmpty) {
          stdout.writeln('');
          stdout.writeln('\x1B[1mMissing pub dependencies:\x1B[0m');
          for (final dep in missingPubDeps.toSet()) {
            _warn('$dep is required but not in pubspec.yaml');
          }
          hasErrors = true;
        } else if (config.installed.isNotEmpty) {
          stdout.writeln('');
          _pass('All pub dependencies are declared');
        }
      }
    }

    // ── Summary ──────────────────────────────────────────────────
    stdout.writeln('');
    if (hasErrors) {
      stdout.writeln(
        '\x1B[33mSome issues were found. See above for details.\x1B[0m',
      );
    } else {
      stdout.writeln('\x1B[32mNo issues found!\x1B[0m');
    }
    stdout.writeln('');

    return hasErrors ? 1 : 0;
  }

  void _pass(String message) {
    stdout.writeln('  \x1B[32m\u2713\x1B[0m $message');
  }

  void _fail(String message) {
    stdout.writeln('  \x1B[31m\u2717\x1B[0m $message');
  }

  void _warn(String message) {
    stdout.writeln('  \x1B[33m!\x1B[0m $message');
  }
}
