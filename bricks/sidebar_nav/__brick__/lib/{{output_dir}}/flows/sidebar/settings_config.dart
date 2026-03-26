import 'package:flutter/widgets.dart';

/// A single informational item (e.g. Privacy Policy, Terms of Service).
class InfoItem {
  /// The display label for this item.
  final String label;

  /// An optional URL associated with this item.
  final String? url;

  /// An optional tap callback.
  final VoidCallback? onTap;

  /// Creates an [InfoItem].
  const InfoItem({
    required this.label,
    this.url,
    this.onTap,
  });
}

/// A row displayed inside a [SettingsSection].
///
/// Use one of the subtypes to describe the row's behavior:
/// - [NavigationRow] — tappable row that navigates to another screen
/// - [DropdownRow] — row with a dropdown selector
/// - [ToggleRow] — row with a boolean toggle switch
/// - [InfoRow] — read-only row displaying a value
/// - [CustomRow] — fully custom widget row
sealed class SettingsRow {
  /// The icon displayed at the start of the row.
  final IconData? icon;

  /// The primary label for this row.
  final String label;

  const SettingsRow({this.icon, required this.label});
}

/// A tappable row that triggers navigation to another screen or flow.
class NavigationRow extends SettingsRow {
  /// Called when the user taps this row.
  final VoidCallback? onTap;

  /// Creates a [NavigationRow].
  const NavigationRow({
    super.icon,
    required super.label,
    this.onTap,
  });
}

/// A row with a dropdown selector for choosing from a list of string options.
class DropdownRow extends SettingsRow {
  /// The currently selected value.
  final String value;

  /// The available options to choose from.
  final List<String> options;

  /// Called when the user selects a new value.
  final void Function(String)? onChanged;

  /// Creates a [DropdownRow].
  const DropdownRow({
    super.icon,
    required super.label,
    required this.value,
    required this.options,
    this.onChanged,
  });
}

/// A row with a boolean toggle switch.
class ToggleRow extends SettingsRow {
  /// The current toggle state.
  final bool value;

  /// Called when the toggle value changes.
  final ValueChanged<bool>? onChanged;

  /// Creates a [ToggleRow].
  const ToggleRow({
    super.icon,
    required super.label,
    required this.value,
    this.onChanged,
  });
}

/// A read-only row displaying a static value string.
class InfoRow extends SettingsRow {
  /// The value text displayed at the trailing end of the row.
  final String value;

  /// Creates an [InfoRow].
  const InfoRow({
    super.icon,
    required super.label,
    required this.value,
  });
}

/// A row with a fully custom widget built by [builder].
class CustomRow extends SettingsRow {
  /// Builds the custom widget for this row.
  final WidgetBuilder builder;

  /// Creates a [CustomRow].
  const CustomRow({
    super.icon,
    required super.label,
    required this.builder,
  });
}

/// A titled group of [SettingsRow] items.
class SettingsSection {
  /// The section heading text.
  final String title;

  /// The rows contained in this section.
  final List<SettingsRow> rows;

  /// Creates a [SettingsSection].
  const SettingsSection({
    required this.title,
    required this.rows,
  });
}

/// Top-level configuration for the settings sheet or screen.
class SettingsConfig {
  /// The fractional height of the settings bottom sheet (0.0 – 1.0).
  final double drawerHeightRatio;

  /// Whether to show a workspace switcher at the top of settings.
  final bool showWorkspaceSwitcher;

  /// The list of settings sections to display.
  final List<SettingsSection> sections;

  /// Informational link items shown at the bottom (e.g. Privacy Policy).
  final List<InfoItem> infoItems;

  /// The application version string displayed in settings.
  final String? appVersion;

  /// Creates a [SettingsConfig].
  const SettingsConfig({
    this.drawerHeightRatio = 0.7,
    this.showWorkspaceSwitcher = false,
    this.sections = const [],
    this.infoItems = const [],
    this.appVersion,
  });
}
