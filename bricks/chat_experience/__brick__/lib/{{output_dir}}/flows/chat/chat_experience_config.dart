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
  const AttachItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

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
  const ChipItem({
    required this.label,
    this.icon,
    this.isDefault = false,
  });
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

/// Describes a chat mode available in the composer (e.g. Quick Answer,
/// Autopilot, Deep Think, Code).
///
/// Modes are presented in a "mode pill" inside the composer that mirrors
/// the CMMD web "Autopilot" picker. Each mode bundles routing decisions
/// such as which model to use, whether to allow tool calls, etc — those
/// translations are made by the consumer's [AiProvider].
class ChatMode {
  /// Unique identifier (e.g. `autopilot`, `quick_answer`).
  final String id;

  /// Short display name (e.g. `Autopilot`).
  final String name;

  /// Tagline / subtitle shown in the picker (e.g.
  /// `Executes tasks for you`).
  final String? subtitle;

  /// Icon shown in the pill and the picker row.
  final IconData icon;

  /// Optional accent color override for the pill icon. When null, the
  /// theme's primary color is used.
  final Color? accent;

  /// Creates a [ChatMode].
  const ChatMode({
    required this.id,
    required this.name,
    required this.icon,
    this.subtitle,
    this.accent,
  });
}

/// Describes a search-mode option (e.g. Smart, Internal, External) used to
/// scope what the assistant can pull into context per chat.
class SearchModeOption {
  /// Unique identifier (e.g. `smart`, `internal`, `external`).
  final String id;

  /// Short display name (e.g. `Smart`).
  final String name;

  /// Optional icon shown alongside the label.
  final IconData? icon;

  /// Creates a [SearchModeOption].
  const SearchModeOption({required this.id, required this.name, this.icon});
}

/// A short suggestion prompt rendered above the composer when the chat
/// is empty.
class SuggestionPrompt {
  /// The text inserted into the composer when tapped (also shown on the
  /// chip itself if [label] is null).
  final String prompt;

  /// Optional shorter label rendered on the chip. Defaults to [prompt].
  final String? label;

  /// Optional leading icon.
  final IconData? icon;

  /// Creates a [SuggestionPrompt].
  const SuggestionPrompt({required this.prompt, this.label, this.icon});

  /// The text rendered on the chip itself.
  String get displayLabel => label ?? prompt;
}

/// Configuration for the message composer.
class ComposerConfig {
  /// The sections shown in the attachment picker.
  ///
  /// Defaults to [defaultAttachmentSections] which includes Camera, Photos,
  /// and Files — the standard iOS upload options. Override to customise.
  final List<AttachmentSection> attachmentSections;

  /// Creates a [ComposerConfig].
  const ComposerConfig({
    this.attachmentSections = defaultAttachmentSections,
  });

  /// The standard iOS attachment options: Camera, Photos, Files.
  ///
  /// Shown as rounded-rectangle cards at the top of the attachment sheet.
  /// Developers can replace or extend these with additional sections.
  static const defaultAttachmentSections = <AttachmentSection>[
    AttachSection(items: [
      AttachItem.camera(),
      AttachItem.photos(),
      AttachItem.files(),
    ]),
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
  ///
  /// When [availableModes] is non-empty, the composer renders a "mode pill"
  /// (Autopilot/Quick Answer/etc.) instead of the plain model picker, and
  /// this list is treated as the underlying model registry that modes
  /// route to.
  final List<ModelOption> availableModels;

  /// The list of chat modes shown in the composer's mode pill.
  ///
  /// When empty (default), the composer falls back to the plain model
  /// picker behavior driven by [availableModels]. When non-empty, the
  /// composer shows a single pill (e.g. `✦ Autopilot ▾`) that opens a
  /// CMMD-style mode picker sheet.
  final List<ChatMode> availableModes;

  /// The list of search-mode options shown in the "+" sheet's
  /// `Search Mode` section.
  ///
  /// Defaults to an empty list, in which case no Search Mode section is
  /// rendered. Provide e.g. `[smart, internal, external]` to enable the
  /// segmented control.
  final List<SearchModeOption> availableSearchModes;

  /// Suggestion prompts rendered above the composer when the chat is
  /// empty (e.g. `What's in my email?`, `Summarize my Brain`).
  ///
  /// Tapping a chip inserts the prompt into the composer and sends it.
  /// Defaults to an empty list (no chips shown).
  final List<SuggestionPrompt> suggestionPrompts;

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
    this.availableModes = const [],
    this.availableSearchModes = const [],
    this.suggestionPrompts = const [],
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
