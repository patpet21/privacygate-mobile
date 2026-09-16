import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/desktop_link/desktop_link_client.dart';
import '../../core/desktop_link/desktop_link_models.dart';

class DesktopConnectionScreen extends StatefulWidget {
  const DesktopConnectionScreen({required this.client, super.key});
  final DesktopLinkClient client;

  @override
  State<DesktopConnectionScreen> createState() => _DesktopConnectionScreenState();
}

class _DesktopConnectionScreenState extends State<DesktopConnectionScreen> {
  final _bundle = TextEditingController();
  final _name = TextEditingController(text: 'My mobile device');
  DesktopLinkCredential? _credential;
  String _message = 'Loading saved connection…';
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _run(() async {
      _credential = await widget.client.credentials.load();
      _message = _credential == null ? 'No paired Desktop.' : 'Paired — availability not checked.';
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on DesktopLinkProtocolException catch (error) {
      _message = error.message;
    } catch (_) {
      _message = 'Connection failed. Check the Desktop service, pairing expiry and local network.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pair() async {
    final decoded = jsonDecode(_bundle.text);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    final bundle = DesktopLinkPairingBundle.fromJson(decoded);
    if (mounted) {
      setState(() {
        _message = 'Pairing request sent. Approve this device in PrivacyGate Desktop → Mobile Devices.';
      });
    }
    _credential = await widget.client.pair(bundle, clientName: _name.text.trim());
    _bundle.clear();
    widget.client.analysisEnabled = false;
    _message = 'Paired after Desktop approval. Enable Desktop analysis below only when you want to send text to this computer.';
  }

  Future<void> _scanQr() async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _DesktopPairingQrScannerScreen()),
    );
    if (!mounted || raw == null || raw.trim().isEmpty) return;
    _bundle.text = raw.trim();
    await _run(_pair);
  }

  @override
  void dispose() {
    _bundle.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Desktop Connection')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text(
        'Connect only to a computer you trust. Obtain pairing data directly from '
        'PrivacyGate Desktop → Mobile Devices. A valid pairing bundle only creates '
        'a request: the Desktop must approve this device before a credential is released.',
      ),
      const SizedBox(height: 16),
      Text(_message),
      if (_busy) const LinearProgressIndicator(),
      if (_credential != null) ...[
        const SizedBox(height: 12),
        Text('Desktop: ${_credential!.endpoint}'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Use Desktop analysis this session'),
          subtitle: const Text(
            'Sends original text over encrypted TLS to this PC when scanning. '
            'Restore mappings stay on this device. Disabled again after restarting the app.',
          ),
          value: widget.client.analysisEnabled,
          onChanged: _busy
              ? null
              : (value) => setState(() => widget.client.analysisEnabled = value),
        ),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run(() async {
                    final online = await widget.client.checkConnection();
                    _message = online
                        ? 'Desktop reachable and pairing accepted.'
                        : 'Desktop did not accept this pairing.';
                  }),
          child: const Text('Check connection'),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => _run(() async {
                    widget.client.analysisEnabled = false;
                    await widget.client.credentials.delete();
                    _credential = null;
                    _message =
                        'Forgot connection locally. Revoke this device on Desktop as well.';
                  }),
          child: const Text('Forget this Desktop'),
        ),
      ] else ...[
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Device name'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _scanQr,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan pairing QR from Desktop'),
        ),
        const SizedBox(height: 12),
        const Center(child: Text('or paste the temporary JSON manually')),
        const SizedBox(height: 12),
        TextField(
          controller: _bundle,
          minLines: 4,
          maxLines: 8,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'Pairing data (JSON)',
            helperText: 'Temporary pairing data contains a secret. Do not share publicly.',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _busy ? null : () => _run(_pair),
          child: const Text('Request pairing with pasted data'),
        ),
      ],
      const SizedBox(height: 20),
      const Text(
        'Library transfer is not enabled in this version. '
        'Pairing does not grant access to the Desktop Library.',
      ),
    ]),
  );
}

class _DesktopPairingQrScannerScreen extends StatefulWidget {
  const _DesktopPairingQrScannerScreen();

  @override
  State<_DesktopPairingQrScannerScreen> createState() =>
      _DesktopPairingQrScannerScreenState();
}

class _DesktopPairingQrScannerScreenState
    extends State<_DesktopPairingQrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    autoZoom: true,
  );
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map || decoded['version'] != 1) continue;
      } catch (_) {
        continue;
      }
      _handled = true;
      Navigator.of(context).pop(raw);
      return;
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan Desktop QR')),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
        ),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Keep the entire Desktop QR and its white border inside the frame. '
                'After scanning, approve the request on the computer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
