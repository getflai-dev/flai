import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../brick_registry.dart';
import '../config.dart';
import '../dependency_resolver.dart';

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

    // 6. Install each component.
    final outputDir = p.join(cwd, config.outputDir, 'widgets');
    _ensureDirectory(outputDir);

    for (final name in installOrder) {
      final info = BrickRegistry.lookup(name)!;

      // Attempt to use a local mason brick; fall back to generating a stub.
      final brickDir = _resolveBrickPath(name);
      if (brickDir != null && Directory(brickDir).existsSync()) {
        stdout.writeln('\x1B[36m>\x1B[0m Installing $name from brick...');
        _copyBrickOutput(brickDir, outputDir, name);
      } else {
        stdout.writeln(
          '\x1B[36m>\x1B[0m Generating $name stub (brick not found locally)...',
        );
        _generateStub(outputDir, info);
      }
    }

    // 7. Add pub.dev dependencies to the project pubspec.yaml.
    if (pubDeps.isNotEmpty) {
      _addPubDependencies(cwd, pubDeps);
    }

    // 8. Update flai.yaml.
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

  /// Tries to locate a mason brick at the conventional path relative to the
  /// CLI package or project root.
  String? _resolveBrickPath(String brickName) {
    // Resolve relative to the CLI package: ../../bricks/<name>/
    final cliPackageDir = p.dirname(p.dirname(Platform.script.toFilePath()));
    final relativePath = p.join(cliPackageDir, '..', '..', 'bricks', brickName);
    final resolved = p.normalize(relativePath);
    if (Directory(resolved).existsSync()) return resolved;

    // Also check from the current working directory.
    final fromCwd = p.normalize(
      p.join(Directory.current.path, 'bricks', brickName),
    );
    if (Directory(fromCwd).existsSync()) return fromCwd;

    return null;
  }

  /// Copies the brick's `__brick__` template output into [outputDir].
  ///
  /// This is a simplified approach: it copies Dart files from the brick's
  /// `__brick__` directory as-is. A full implementation would use Mason's
  /// generator to process Mustache templates.
  void _copyBrickOutput(String brickDir, String outputDir, String name) {
    final brickTemplate = Directory(p.join(brickDir, '__brick__'));
    if (!brickTemplate.existsSync()) {
      stdout.writeln(
        '  \x1B[33m!\x1B[0m No __brick__ template found; generating stub instead.',
      );
      final info = BrickRegistry.lookup(name);
      if (info != null) _generateStub(outputDir, info);
      return;
    }

    for (final entity in brickTemplate.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = p.relative(entity.path, from: brickTemplate.path);
        final destPath = p.join(outputDir, relativePath);
        _ensureDirectory(p.dirname(destPath));
        entity.copySync(destPath);
        stdout.writeln('  \x1B[32m\u2713\x1B[0m ${p.relative(destPath)}');
      }
    }
  }

  /// Generates a minimal stub file for a component when no brick is available.
  void _generateStub(String outputDir, BrickInfo info) {
    final className = _toPascalCase(info.name);
    final fileName = '${info.name}.dart';
    final filePath = p.join(outputDir, fileName);

    if (File(filePath).existsSync()) {
      stdout.writeln('  \x1B[33m!\x1B[0m $fileName already exists, skipping.');
      return;
    }

    final content =
        StringBuffer()
          ..writeln("import 'package:flutter/material.dart';")
          ..writeln()
          ..writeln('/// ${info.description}')
          ..writeln('///')
          ..writeln('/// Generated by FlAI CLI. Customise freely.')
          ..writeln('class $className extends StatelessWidget {')
          ..writeln('  const $className({super.key});')
          ..writeln()
          ..writeln('  @override')
          ..writeln('  Widget build(BuildContext context) {')
          ..writeln(
            "    return const Placeholder(); // TODO: implement $className",
          )
          ..writeln('  }')
          ..writeln('}');

    File(filePath).writeAsStringSync(content.toString());
    stdout.writeln('  \x1B[32m\u2713\x1B[0m ${p.relative(filePath)}');
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
      // Use 'any' version constraint; the developer can pin later.
      editor.update(['dependencies', pkg], 'any');
      stdout.writeln(
        '  \x1B[32m\u2713\x1B[0m Added \x1B[36m$pkg\x1B[0m to pubspec.yaml',
      );
    }

    pubspecFile.writeAsStringSync(editor.toString());
  }

  void _ensureDirectory(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  String _toPascalCase(String snake) {
    return snake
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join();
  }
}
