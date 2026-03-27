/// FlAI Sidebar Nav flow — barrel export.
///
/// Import this single file to access all sidebar navigation components,
/// configuration types, and sub-page templates.
///
/// ```dart
/// import 'flai/flows/sidebar/sidebar_nav.dart';
/// ```
library;

// ── Config ──────────────────────────────────────────────────────────────────
export 'sidebar_config.dart';
export 'settings_config.dart';

// ── Screens ─────────────────────────────────────────────────────────────────
export 'screens/sidebar_drawer.dart';
export 'screens/settings_drawer.dart';

// ── Settings sub-pages ───────────────────────────────────────────────────────
export 'screens/settings_sub_pages/billing_page.dart';
export 'screens/settings_sub_pages/connectors_page.dart';
export 'screens/settings_sub_pages/notifications_page.dart';
export 'screens/settings_sub_pages/privacy_page.dart';
export 'screens/settings_sub_pages/profile_page.dart';
export 'screens/settings_sub_pages/usage_page.dart';

// ── Widgets ──────────────────────────────────────────────────────────────────
export 'widgets/chat_list_item.dart';
export 'widgets/settings_row_widget.dart';
export 'widgets/top_nav_bar.dart';
export 'widgets/workspace_switcher.dart';
