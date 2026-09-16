import 'package:flutter/material.dart';

import '../core/detection/desktop_rule_detector.dart';
import '../core/detection/detection_engine.dart';
import '../core/detection/detection_engine_router.dart';
import '../core/detection/desktop_link_detection_engine.dart';
import '../core/desktop_link/desktop_link_client.dart';
import '../core/desktop_link/desktop_link_credential_store.dart';
import '../core/domain/library_document.dart';
import '../core/domain/protection_result.dart';
import '../core/library/protected_library_service.dart';
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
  late final DesktopLinkClient _desktopLink;
  late final ProtectionPolicy _protectionPolicy;
  late final ProtectController _protectController;
  Future<ProtectedLibraryService>? _libraryFuture;
  ProtectionResult? _savedResult;
  var _selectedIndex = 0;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _settings = PrivacyGateSettings();
    _desktopLink = DesktopLinkClient(DesktopLinkCredentialStore());
    _protectionPolicy = ProtectionPolicy();
    _protectController = ProtectController(
      detector: DocumentDetectionEngine(DetectionEngineRouter(
        mobileBasic: const DesktopRuleDetector(),
        desktop: DesktopLinkDetectionEngine(_desktopLink),
        desktopAvailable: _desktopLink.canAttempt,
      )),
      protector: const PrivacyGateProtector(),
      policy: _protectionPolicy,
    );
    _protectController.addListener(_refreshFromProtect);
  }

  @override
  void dispose() {
    _protectController.removeListener(_refreshFromProtect);
    _protectController.dispose();
    _protectionPolicy.dispose();
    _settings.dispose();
    super.dispose();
  }

  Future<ProtectedLibraryService> _library() =>
      _libraryFuture ??= ProtectedLibraryService.openDefault();

  void _refreshFromProtect() {
    if (mounted) setState(() {});
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

  Future<void> _saveCurrentProtected(BuildContext scaffoldContext) async {
    final result = _protectController.result;
    if (_saving ||
        result == null ||
        !_protectController.exportVerified ||
        identical(_savedResult, result)) {
      return;
    }

    setState(() => _saving = true);
    try {
      final service = await _library();
      final document = await service.saveVerifiedProtection(
        profileKey: _protectController.policy.profileKey,
        result: result,
      );
      if (!mounted || !scaffoldContext.mounted) return;
      setState(() => _savedResult = result);
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('${document.title} saved locally.'),
          action: SnackBarAction(
            label: 'View Library',
            onPressed: () => _selectTab(2),
          ),
        ),
      );
    } catch (error) {
      if (!mounted || !scaffoldContext.mounted) return;
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Could not save to Library: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openLibraryRestore(
    BuildContext context,
    LibraryDocument document,
  ) async {
    try {
      final service = await _library();
      final stored = await service.loadProtection(document.documentId);
      if (!mounted || !context.mounted) return;
      _protectController.loadPersistedProtection(
        stored.document,
        stored.mappings,
      );
      _openRestore(context);
    } catch (error) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open local restore data: $error')),
      );
    }
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
    final canSave = _selectedIndex == 1 &&
        _protectController.exportVerified &&
        _protectController.result != null &&
        !identical(_savedResult, _protectController.result);

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
            LibraryScreen(
              settings: _settings,
              active: _selectedIndex == 2,
              libraryProvider: _library,
              onOpenRestoreDocument: _openLibraryRestore,
            ),
            const ActivityScreen(),
            SettingsScreen(settings: _settings, desktopLink: _desktopLink),
          ],
        ),
        floatingActionButton: canSave
            ? Builder(
                builder: (scaffoldContext) => FloatingActionButton.extended(
                  key: const ValueKey('save-to-library'),
                  onPressed: _saving
                      ? null
                      : () => _saveCurrentProtected(scaffoldContext),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving…' : 'Save to Library'),
                ),
              )
            : null,
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
