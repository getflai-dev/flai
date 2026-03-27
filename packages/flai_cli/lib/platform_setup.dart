import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// Configures iOS and Android platform files for FlAI features.
///
/// Adds required privacy permission descriptions to iOS Info.plist and
/// required permissions to Android AndroidManifest.xml. These are needed
/// for camera, photo library, microphone, and file picker features that
/// ship with the chat_experience brick.
class PlatformSetup {
  final String projectRoot;

  PlatformSetup({required this.projectRoot});

  /// Run all platform setup steps. Returns a list of actions taken.
  List<String> run() {
    final actions = <String>[];
    actions.addAll(_setupIos());
    actions.addAll(_setupAndroid());
    return actions;
  }

  // ── iOS ──────────────────────────────────────────────────────────────

  /// Required iOS Info.plist entries for FlAI features.
  static const _iosPermissions = {
    'NSMicrophoneUsageDescription':
        'This app uses the microphone for voice messages.',
    'NSCameraUsageDescription':
        'This app uses the camera to capture photos for chat.',
    'NSPhotoLibraryUsageDescription':
        'This app accesses your photo library to attach images.',
  };

  List<String> _setupIos() {
    final actions = <String>[];
    final plistPath = p.join(projectRoot, 'ios', 'Runner', 'Info.plist');
    final plistFile = File(plistPath);

    if (!plistFile.existsSync()) return actions;

    var content = plistFile.readAsStringSync();
    var modified = false;

    for (final entry in _iosPermissions.entries) {
      if (!content.contains(entry.key)) {
        // Insert before the closing </dict> tag.
        final insertion = '\t<key>${entry.key}</key>\n'
            '\t<string>${entry.value}</string>\n';
        content = content.replaceFirst(
          '</dict>\n</plist>',
          '$insertion</dict>\n</plist>',
        );
        modified = true;
        actions.add('iOS: Added ${entry.key}');
      }
    }

    if (modified) {
      plistFile.writeAsStringSync(content);
    }

    return actions;
  }

  // ── Android ──────────────────────────────────────────────────────────

  /// Required Android permissions for FlAI features.
  static const _androidPermissions = [
    'android.permission.RECORD_AUDIO',
    'android.permission.CAMERA',
  ];

  List<String> _setupAndroid() {
    final actions = <String>[];
    final manifestPath = p.join(
      projectRoot,
      'android',
      'app',
      'src',
      'main',
      'AndroidManifest.xml',
    );
    final manifestFile = File(manifestPath);

    if (!manifestFile.existsSync()) return actions;

    final content = manifestFile.readAsStringSync();

    try {
      final document = XmlDocument.parse(content);
      final manifest = document.rootElement;
      var modified = false;

      for (final permission in _androidPermissions) {
        final fullName = permission;
        final alreadyPresent = manifest.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'uses-permission')
            .any(
              (e) =>
                  e.getAttribute('android:name') == fullName,
            );

        if (!alreadyPresent) {
          // Insert before the first <application> element.
          final applicationIndex = manifest.children.indexWhere(
            (n) => n is XmlElement && n.name.local == 'application',
          );

          final element = XmlElement(
            XmlName('uses-permission'),
            [XmlAttribute(XmlName('android:name'), fullName)],
          );

          if (applicationIndex >= 0) {
            manifest.children.insert(applicationIndex, element);
            // Add newline for formatting.
            manifest.children.insert(
              applicationIndex + 1,
              XmlText('\n    '),
            );
          } else {
            manifest.children.add(element);
          }

          modified = true;
          actions.add('Android: Added $permission');
        }
      }

      if (modified) {
        manifestFile.writeAsStringSync(document.toXmlString(pretty: true));
      }
    } catch (_) {
      // If XML parsing fails, skip Android setup gracefully.
    }

    return actions;
  }
}
