import 'package:flutter/material.dart';

import 'avatar_config.dart';

/// An item in an attachment picker (e.g. Camera, Photos, Files).
class AttachItem {
  /// The icon to display for this item.
  final IconData icon;

  /// The label to display for this item.
  final String label;

  /// The callback invoked when the user taps this item.
  final VoidCallback? onTap;

  /// Creates an [AttachItem].
  const AttachItem({required this.icon, required this.label, this.onTap});

  /// Preset for opening the device camera.
  const AttachItem.camera({this.onTap})
    : icon = Icons.camera_alt_rounded,
      label = 'Camera';

  /// Preset for opening the photo library.
  const AttachItem.photos({this.onTap})
    : icon = Icons.photo_library_rounded,
      label = 'Photos';

  /// Preset for attaching a file.
  const AttachItem.files({this.onTap})
    : icon = Icons.upload_file_rounded,
      label = 'Files';
}

/// A suggestion chip shown to the user.
class ChipItem {
  /// The label displayed on the chip.
  final String label;

  /// An optional icon for the chip.
  final IconData? icon;

  /// Whether this chip is selected by default.
  final bool isDefault;

  /// Creates a [ChipItem].
  const ChipItem({required this.label, this.icon, this.isDefault = false});
}

/// A section of items shown in the attachment picker.
sealed class AttachmentSection {
  const AttachmentSection();
}

/// A standard attachment section with a flat list of items.
class AttachSection extends AttachmentSection {
  /// The attachment items in this section.
  final List<AttachItem> items;

  /// Creates an [AttachSection].
  const AttachSection({required this.items});
}

/// A custom-titled attachment section with a flat list of items.
class CustomSection extends AttachmentSection {
  /// The section title.
  final String title;

  /// The attachment items in this section.
  final List<AttachItem> items;

  /// Creates a [CustomSection].
  const CustomSection({required this.title, required this.items});
}

/// An attachment section that displays its items as chips.
class ChipsSection extends AttachmentSection {
  /// The section title.
  final String title;

  /// The chip items in this section.
  final List<ChipItem> items;

  /// Creates a [ChipsSection].
  const ChipsSection({required this.title, required this.items});
}

/// Describes an AI model available for selection.
class ModelOption {
  /// The unique identifier of the model.
  final String id;

  /// The display name of the model.
  final String name;

  /// A short description of the model's capabilities.
  final String? description;

  /// An optional icon representing the model.
  final IconData? icon;

  /// Creates a [ModelOption].
  const ModelOption({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });
}

/// Configuration for the message composer.
class ComposerConfig {
  /// The sections shown in the attachment picker.
  ///
  /// Defaults to [defaultAttachmentSections] which includes Camera, Photos,
  /// and Files — the standard iOS upload options. Override to customise.
  final List<AttachmentSection> attachmentSections;

  /// Creates a [ComposerConfig].
  const ComposerConfig({this.attachmentSections = defaultAttachmentSections});

  /// The standard iOS attachment options: Camera, Photos, Files.
  ///
  /// Shown as rounded-rectangle cards at the top of the attachment sheet.
  /// Developers can replace or extend these with additional sections.
  static const defaultAttachmentSections = <AttachmentSection>[
    AttachSection(
      items: [AttachItem.camera(), AttachItem.photos(), AttachItem.files()],
    ),
  ];
}

/// Top-level configuration for the chat experience.
class ChatExperienceConfig {
  /// The display name of the assistant.
  final String assistantName;

  /// Avatar configuration for the assistant.
  final AvatarConfig? assistantAvatar;

  /// Override for the greeting text. If null, a default is derived from
  /// [assistantName].
  final String? greeting;

  /// Override for the greeting subtitle. If null, a default is used.
  final String? greetingSubtitle;

  /// Override for the composer placeholder text. If null, a default is derived
  /// from [assistantName].
  final String? composerPlaceholder;

  /// Configuration for the message composer.
  final ComposerConfig composerConfig;

  /// The list of AI models available in the model selector.
  final List<ModelOption> availableModels;

  /// Whether voice input/output is enabled in the composer.
  ///
  /// When true, a microphone button appears in the composer. When tapped,
  /// it replaces the text field with the [VoiceRecorder] widget.
  /// Requires a [VoiceProvider] to be configured in [AppScaffoldConfig].
  final bool enableVoice;

  /// Whether ghost mode (temporary, unsaved chats) is enabled.
  final bool enableGhostMode;

  /// Whether users can switch models per-message.
  final bool enablePerMessageModelSwitch;

  /// Creates a [ChatExperienceConfig].
  const ChatExperienceConfig({
    this.assistantName = 'Assistant',
    this.assistantAvatar,
    this.greeting,
    this.greetingSubtitle,
    this.composerPlaceholder,
    this.composerConfig = const ComposerConfig(),
    this.availableModels = const [],
    this.enableVoice = false,
    this.enableGhostMode = false,
    this.enablePerMessageModelSwitch = false,
  });

  /// The resolved greeting text shown in the empty state.
  String get resolvedGreeting => greeting ?? 'Hi, I\'m $assistantName';

  /// The resolved subtitle shown beneath the greeting in the empty state.
  String get resolvedGreetingSubtitle =>
      greetingSubtitle ?? 'How can I help you today?';

  /// The resolved placeholder text for the composer input field.
  String get resolvedPlaceholder =>
      composerPlaceholder ?? 'Ask $assistantName anything...';
}
