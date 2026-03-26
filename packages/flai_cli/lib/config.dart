import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// The default name of the FlAI configuration file.
const String kConfigFileName = 'flai.yaml';

/// Represents the contents of a project's `flai.yaml`.
class FlaiConfig {
  /// Directory (relative to project root) where generated components are placed.
  final String outputDir;

  /// Active theme name.
  final String theme;

  /// Names of components already installed in this project.
  final List<String> installed;

  const FlaiConfig({
    this.outputDir = 'lib/flai',
    this.theme = 'dark',
    this.installed = const [],
  });

  /// Creates a [FlaiConfig] from a parsed YAML map.
  factory FlaiConfig.fromYaml(Map yaml) {
    return FlaiConfig(
      outputDir: yaml['output_dir'] as String? ?? 'lib/flai',
      theme: yaml['theme'] as String? ?? 'dark',
      installed:
          (yaml['installed'] as YamlList?)?.cast<String>().toList(
            growable: true,
          ) ??
          <String>[],
    );
  }

  /// Serialises this config to a YAML string.
  String toYamlString() {
    final editor = YamlEditor('');
    editor.update([], {
      'output_dir': outputDir,
      'theme': theme,
      'installed': installed,
    });
    return editor.toString();
  }
}

/// Utilities for reading and writing the `flai.yaml` configuration file.
class FlaiConfigManager {
  final String projectRoot;

  FlaiConfigManager({required this.projectRoot});

  /// Absolute path to the config file.
  String get configPath => p.join(projectRoot, kConfigFileName);

  /// Whether the config file exists.
  bool get exists => File(configPath).existsSync();

  /// Reads and parses the config file.
  ///
  /// Throws a [FileSystemException] if the file does not exist.
  FlaiConfig read() {
    final file = File(configPath);
    if (!file.existsSync()) {
      throw FileSystemException(
        'Config file not found. Run "flai init" first.',
        configPath,
      );
    }
    final content = file.readAsStringSync();
    final yaml = loadYaml(content);
    if (yaml is! Map) {
      throw FormatException('Invalid flai.yaml: expected a YAML mapping.');
    }
    return FlaiConfig.fromYaml(yaml);
  }

  /// Writes a [FlaiConfig] to disk.
  void write(FlaiConfig config) {
    File(configPath).writeAsStringSync(config.toYamlString());
  }

  /// Creates the initial config file with default values.
  ///
  /// Returns the newly created [FlaiConfig].
  FlaiConfig createDefault() {
    const config = FlaiConfig();
    write(config);
    return config;
  }

  /// Adds [componentNames] to the installed list and persists the change.
  void markInstalled(List<String> componentNames) {
    final config = read();
    final updated = {...config.installed, ...componentNames}.toList()..sort();
    write(
      FlaiConfig(
        outputDir: config.outputDir,
        theme: config.theme,
        installed: updated,
      ),
    );
  }
}

/// Checks whether [directory] looks like a Flutter project.
///
/// Returns `true` if a `pubspec.yaml` exists and contains a `flutter`
/// dependency (either under `dependencies` or as an SDK reference).
bool isFlutterProject(String directory) {
  final pubspecFile = File(p.join(directory, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) return false;

  final content = pubspecFile.readAsStringSync();
  final yaml = loadYaml(content);
  if (yaml is! Map) return false;

  // Check for `dependencies.flutter` (standard Flutter project).
  final deps = yaml['dependencies'];
  if (deps is Map && deps.containsKey('flutter')) return true;

  // Also accept an `environment.flutter` constraint.
  final env = yaml['environment'];
  if (env is Map && env.containsKey('flutter')) return true;

  return false;
}
