import 'package:flutter/material.dart';

import '../core/detection/desktop_rule_detector.dart';
import '../core/protection/privacy_gate_protector.dart';
import '../core/protection/protection_policy.dart';
import '../core/settings/privacy_gate_settings.dart';
import '../features/protect/protect_controller.dart';
import '../features/protect/protect_screen.dart';
import '../features/settings/settings_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrivacyGate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0B7180),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            ProtectScreen(controller: _protectController),
            SettingsScreen(settings: _settings),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: 'Protect',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
