import 'package:flutter/material.dart';

import '../core/detection/bootstrap_pattern_detector.dart';
import '../core/protection/privacy_gate_protector.dart';
import '../features/protect/protect_controller.dart';
import '../features/protect/protect_screen.dart';

class PrivacyGateApp extends StatelessWidget {
  const PrivacyGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProtectController(
      detector: const BootstrapPatternDetector(),
      protector: const PrivacyGateProtector(),
    );

    return MaterialApp(
      title: 'PrivacyGate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0B7180),
      ),
      home: ProtectScreen(controller: controller),
    );
  }
}
