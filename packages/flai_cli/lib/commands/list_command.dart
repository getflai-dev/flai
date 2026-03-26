import 'dart:io';

import 'package:args/command_runner.dart';

import '../brick_registry.dart';
import '../config.dart';

/// `flai list` — list all available components with install status.
class ListCommand extends Command<int> {
  @override
  String get name => 'list';

  @override
  String get description =>
      'List all available FlAI components grouped by category.';

  @override
  Future<int> run() async {
    final cwd = Directory.current.path;
    final configManager = FlaiConfigManager(projectRoot: cwd);

    // Determine installed components (empty set if project not initialised).
    final Set<String> installed;
    if (configManager.exists) {
      installed = configManager.read().installed.toSet();
    } else {
      installed = {};
    }

    stdout.writeln('');
    stdout.writeln('\x1B[1mFlAI Components\x1B[0m');
    stdout.writeln('');

    for (final category in BrickRegistry.categories) {
      stdout.writeln('\x1B[1;4m$category\x1B[0m');
      final bricks = BrickRegistry.byCategory(category);
      for (final brick in bricks) {
        final status =
            installed.contains(brick.name)
                ? '\x1B[32m[installed]\x1B[0m'
                : '\x1B[90m[not installed]\x1B[0m';
        stdout.writeln(
          '  \x1B[36m${brick.name.padRight(22)}\x1B[0m '
          '${brick.description.padRight(55)} $status',
        );
      }
      stdout.writeln('');
    }

    if (!configManager.exists) {
      stdout.writeln(
        '\x1B[33mHint:\x1B[0m Run \x1B[36mflai init\x1B[0m to get started.',
      );
      stdout.writeln('');
    }

    return 0;
  }
}
