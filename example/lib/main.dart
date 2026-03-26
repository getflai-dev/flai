import 'package:flutter/material.dart';
import 'flai/flai.dart';
import 'screens/chat_demo_screen.dart';
import 'screens/component_gallery_screen.dart';

void main() {
  runApp(const FlaiShowcaseApp());
}

class FlaiShowcaseApp extends StatefulWidget {
  const FlaiShowcaseApp({super.key});

  @override
  State<FlaiShowcaseApp> createState() => _FlaiShowcaseAppState();
}

class _FlaiShowcaseAppState extends State<FlaiShowcaseApp> {
  FlaiThemeData _themeData = FlaiThemeData.light();
  String _currentThemeName = 'light';

  void _setTheme(String name) {
    setState(() {
      _currentThemeName = name;
      _themeData = switch (name) {
        'light' => FlaiThemeData.light(),
        'dark' => FlaiThemeData.dark(),
        'ios' => FlaiThemeData.ios(),
        'premium' => FlaiThemeData.premium(),
        _ => FlaiThemeData.dark(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        _currentThemeName == 'dark' || _currentThemeName == 'premium';

    return FlaiTheme(
      data: _themeData,
      child: MaterialApp(
        title: 'FlAI Showcase',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _themeData.colors.primary,
            brightness: isDark ? Brightness.dark : Brightness.light,
          ),
          scaffoldBackgroundColor: _themeData.colors.background,
        ),
        home: MainScreen(
          currentTheme: _currentThemeName,
          onThemeChanged: _setTheme,
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String currentTheme;
  final ValueChanged<String> onThemeChanged;

  const MainScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ChatDemoScreen(
            currentTheme: widget.currentTheme,
            onThemeChanged: widget.onThemeChanged,
          ),
          ComponentGalleryScreen(
            currentTheme: widget.currentTheme,
            onThemeChanged: widget.onThemeChanged,
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: theme.colors.card),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: theme.colors.card,
          selectedItemColor: theme.colors.primary,
          unselectedItemColor: theme.colors.mutedForeground,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat Demo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.widgets_outlined),
              activeIcon: Icon(Icons.widgets),
              label: 'Components',
            ),
          ],
        ),
      ),
    );
  }
}
