import 'package:flutter/material.dart';

import '../core/detection/desktop_rule_detector.dart';
import '../core/protection/privacy_gate_protector.dart';
import '../core/protection/protection_policy.dart';
import '../core/settings/privacy_gate_settings.dart';
import '../features/activity/activity_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/protect/protect_controller.dart';
import '../features/protect/protect_screen.dart';
import '../features/restore/restore_screen.dart';
import '../features/settings/settings_screen.dart';
import 'mobile_design.dart';

class PrivacyGateApp extends StatefulWidget {
  const PrivacyGateApp({super.key});

  @override
  State<PrivacyGateApp> createState() => _PrivacyGateAppState();
}

class _PrivacyGateAppState extends State<PrivacyGateApp> {
  late final PrivacyGateSettings _settings;
  late final ProtectionPolicy _protectionPolicy;
  late final ProtectController _protectController;
  var _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _settings = PrivacyGateSettings();
    _protectionPolicy = ProtectionPolicy();
    _protectController = ProtectController(
      detector: const DesktopRuleDetector(),
      protector: const PrivacyGateProtector(),
      policy: _protectionPolicy,
    );
  }

  @override
  void dispose() {
    _protectController.dispose();
    _protectionPolicy.dispose();
    _settings.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  void _openRestore(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RestoreScreen(
          controller: _protectController,
          onBackToProtect: () => _selectTab(1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: PgColors.blue,
      brightness: Brightness.light,
    ).copyWith(
      primary: PgColors.blue,
      surface: PgColors.surface,
    );

    return MaterialApp(
      title: 'PrivacyGate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: PgColors.background,
        fontFamily: 'Roboto',
        dividerColor: PgColors.border,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: PgColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: PgColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: PgColors.blue, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: PgColors.blue,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: PgColors.blue,
            side: const BorderSide(color: Color(0xFFB9D2FF)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: PgColors.blueSoft,
          elevation: 1,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              color: PgColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeScreen(
              onSelectTab: _selectTab,
              onOpenRestore: _openRestore,
            ),
            ProtectScreen(
              controller: _protectController,
              onOpenRestore: _openRestore,
            ),
            LibraryScreen(settings: _settings),
            const ActivityScreen(),
            SettingsScreen(settings: _settings),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
              key: ValueKey('nav-home'),
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: PgColors.blue),
              label: 'Home',
            ),
            NavigationDestination(
              key: ValueKey('nav-protect'),
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield_rounded, color: PgColors.blue),
              label: 'Protect',
            ),
            NavigationDestination(
              key: ValueKey('nav-library'),
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder_rounded, color: PgColors.blue),
              label: 'Library',
            ),
            NavigationDestination(
              key: ValueKey('nav-activity'),
              icon: Icon(Icons.monitor_heart_outlined),
              selectedIcon:
                  Icon(Icons.monitor_heart_rounded, color: PgColors.blue),
              label: 'Activity',
            ),
            NavigationDestination(
              key: ValueKey('nav-settings'),
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded, color: PgColors.blue),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
