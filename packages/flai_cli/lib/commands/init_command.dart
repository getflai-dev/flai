import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../config.dart';

/// `flai init` — initialise FlAI in the current Flutter project.
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
        help: 'Directory for generated components.',
        defaultsTo: 'lib/flai',
      )
      ..addOption(
        'theme',
        abbr: 't',
        help: 'Default theme (dark or light).',
        defaultsTo: 'dark',
        allowed: ['dark', 'light'],
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

    final outputDir = argResults!['output-dir'] as String;
    final theme = argResults!['theme'] as String;

    // 3. Create the config file.
    final config = FlaiConfig(
      outputDir: outputDir,
      theme: theme,
      installed: [],
    );
    configManager.write(config);
    stdout.writeln('\x1B[32m\u2713\x1B[0m Created $kConfigFileName');

    // 4. Create the output directory structure.
    final outputPath = p.join(cwd, outputDir);
    _ensureDirectory(p.join(outputPath, 'core'));
    _ensureDirectory(p.join(outputPath, 'widgets'));
    _ensureDirectory(p.join(outputPath, 'providers'));

    // 5. Generate core scaffold files (placeholder for mason brick).
    _writeCoreFiles(outputPath, theme);

    stdout.writeln('');
    stdout.writeln('\x1B[32m\u2713 FlAI initialised successfully!\x1B[0m');
    stdout.writeln('');
    stdout.writeln('Next steps:');
    stdout.writeln(
      '  \x1B[36mflai add chat_screen\x1B[0m   '
      '— install the full chat screen',
    );
    stdout.writeln(
      '  \x1B[36mflai list\x1B[0m              '
      '— see all available components',
    );
    stdout.writeln(
      '  \x1B[36mflai doctor\x1B[0m            '
      '— check project health',
    );
    stdout.writeln('');

    return 0;
  }

  void _ensureDirectory(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      stdout.writeln(
        '\x1B[32m\u2713\x1B[0m Created directory ${p.relative(path)}',
      );
    }
  }

  /// Writes the core scaffold files that `flai_init` mason brick would
  /// generate. These are minimal stubs so the project compiles.
  void _writeCoreFiles(String outputPath, String theme) {
    // ── flai_theme.dart ────────────────────────────────────────────
    final themeFile = File(p.join(outputPath, 'core', 'flai_theme.dart'));
    if (!themeFile.existsSync()) {
      themeFile.writeAsStringSync('''
import 'package:flutter/material.dart';

/// FlAI theme configuration.
///
/// Customise colors, typography and spacing used by all FlAI components.
class FlaiTheme {
  final Color primaryColor;
  final Color userBubbleColor;
  final Color assistantBubbleColor;
  final Color backgroundColor;
  final TextStyle messageTextStyle;

  const FlaiTheme({
    this.primaryColor = const Color(0xFF6C63FF),
    this.userBubbleColor = const Color(0xFF6C63FF),
    this.assistantBubbleColor = const Color(0xFF2D2D2D),
    this.backgroundColor = const Color(0xFF1A1A1A),
    this.messageTextStyle = const TextStyle(fontSize: 15, height: 1.5),
  });

  static const FlaiTheme dark = FlaiTheme();

  static const FlaiTheme light = FlaiTheme(
    primaryColor: Color(0xFF6C63FF),
    userBubbleColor: Color(0xFF6C63FF),
    assistantBubbleColor: Color(0xFFE8E8E8),
    backgroundColor: Color(0xFFFFFFFF),
    messageTextStyle: TextStyle(
      fontSize: 15,
      height: 1.5,
      color: Color(0xFF1A1A1A),
    ),
  );
}
''');
      stdout.writeln('\x1B[32m\u2713\x1B[0m Generated core/flai_theme.dart');
    }

    // ── chat_message.dart ──────────────────────────────────────────
    final modelFile = File(p.join(outputPath, 'core', 'chat_message.dart'));
    if (!modelFile.existsSync()) {
      modelFile.writeAsStringSync('''
/// The role of a chat message participant.
enum MessageRole { user, assistant, system }

/// A single chat message.
class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}
''');
      stdout.writeln('\x1B[32m\u2713\x1B[0m Generated core/chat_message.dart');
    }

    // ── chat_provider.dart ─────────────────────────────────────────
    final providerFile = File(p.join(outputPath, 'core', 'chat_provider.dart'));
    if (!providerFile.existsSync()) {
      providerFile.writeAsStringSync('''
import 'chat_message.dart';

/// Abstract interface for AI chat providers.
///
/// Implement this to connect FlAI widgets to an LLM backend.
abstract class ChatProvider {
  /// Sends [messages] and returns the assistant's reply.
  Future<ChatMessage> sendMessage(List<ChatMessage> messages);

  /// Sends [messages] and yields partial content as it streams in.
  Stream<String> streamMessage(List<ChatMessage> messages);
}
''');
      stdout.writeln('\x1B[32m\u2713\x1B[0m Generated core/chat_provider.dart');
    }
  }
}
