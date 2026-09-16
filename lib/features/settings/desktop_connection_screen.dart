import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/mobile_design.dart';
import '../../core/desktop_link/desktop_link_client.dart';
import '../../core/desktop_link/desktop_link_models.dart';
import '../../core/desktop_link/desktop_link_status.dart';

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
      if (_credential == null) {
        _message = 'No paired Desktop.';
        return;
      }
      _name.text = _credential!.clientName;
      final status = await widget.client.refreshConnectionState();
      _credential = await widget.client.credentials.load();
      if (_credential != null) _name.text = _credential!.clientName;
      _message = _statusMessage(status);
    });
  }

  String _statusMessage(DesktopLinkStatus status) => switch (status) {
        DesktopLinkStatus.connectedLocal =>
          'Connected · Local — direct pinned-TLS connection on the current network.',
        DesktopLinkStatus.connectedRemote =>
          'Connected · Remote — end-to-end encrypted Device Trust relay is active.',
        DesktopLinkStatus.checking => 'Checking Local and Remote Device Trust…',
        DesktopLinkStatus.offline =>
          'Paired, but Desktop is currently offline. Local and Remote connectivity were both unavailable.',
        DesktopLinkStatus.unpaired => 'No paired Desktop.',
      };

  Future<void> _run(Future<void> Function() action) async {
    if (mounted) setState(() => _busy = true);
    try {
      await action();
    } on DesktopLinkProtocolException catch (error) {
      _message = error.message;
    } catch (error) {
      _message = 'Connection failed: $error';
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
        _message =
            'Pairing request sent. Approve this device in PrivacyGate Desktop → Mobile Devices.';
      });
    }
    _credential = await widget.client.pair(
      bundle,
      clientName: _name.text.trim().isEmpty ? 'My mobile device' : _name.text.trim(),
    );
    _name.text = _credential!.clientName;
    _bundle.clear();
    widget.client.analysisEnabled = false;
    _message = _credential!.hasRemoteRelay
        ? 'Connected after Desktop approval. Device Trust is ready for both Local and Remote use.'
        : 'Connected after Desktop approval. Remote Device Trust will be provisioned automatically when available.';
  }

  Future<void> _renameDevice() async {
    final current = _credential;
    if (current == null) return;
    final normalized = _name.text.trim();
    if (normalized == current.clientName) {
      _message = 'Device name is already up to date.';
      return;
    }
    final updated = await widget.client.renameDevice(normalized);
    _credential = updated;
    _name.text = updated.clientName;
    _message = 'Device renamed to “${updated.clientName}”. Desktop updated immediately.';
  }

  Future<void> _removeDevice() async {
    final current = _credential;
    if (current == null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove trusted device?'),
            content: Text(
              'Remove “${current.clientName}” from PrivacyGate Desktop?\n\n'
              'Its credential and future Library grants will be revoked. '
              'Copies already saved on this phone will remain local.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Remove device'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await widget.client.removeDevice();
    _credential = null;
    _name.text = 'My mobile device';
    _message = 'Device removed from Desktop and this phone.';
  }

  Future<void> _forgetLocally() async {
    await widget.client.forget();
    _credential = null;
    _name.text = 'My mobile device';
    _message =
        'Connection removed from this phone only. If the Desktop still lists this device, remove it there too.';
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
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PgCard(
              backgroundColor: _credential == null
                  ? const Color(0xFFF8FAFC)
                  : PgColors.greenSoft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PgIconBox(
                    icon: _credential == null
                        ? Icons.link_off_rounded
                        : Icons.desktop_windows_outlined,
                    foreground: _credential == null
                        ? PgColors.textSecondary
                        : PgColors.green,
                    background: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _credential == null
                              ? 'No trusted Desktop'
                              : _credential!.clientName,
                          style: const TextStyle(
                            color: PgColors.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _message,
                          style: const TextStyle(
                            color: PgColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        if (_credential != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              const Chip(label: Text('Local TLS')),
                              Chip(
                                avatar: Icon(
                                  _credential!.hasRemoteRelay
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.hourglass_top_rounded,
                                  size: 17,
                                ),
                                label: Text(
                                  _credential!.hasRemoteRelay
                                      ? 'Remote E2E ready'
                                      : 'Remote setup pending',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _credential!.endpoint,
                            style: const TextStyle(
                              color: PgColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 16),
            if (_credential != null) ...[
              PgCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PgSectionHeader(title: 'This mobile device'),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose a recognizable name. You can change it from Mobile or Desktop without pairing again.',
                      style: TextStyle(
                        color: PgColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _name,
                      enabled: !_busy,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Device name',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _run(_renameDevice),
                      icon: const Icon(Icons.drive_file_rename_outline_rounded),
                      label: const Text('Rename device'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                final status =
                                    await widget.client.refreshConnectionState();
                                _credential =
                                    await widget.client.credentials.load();
                                if (_credential != null) {
                                  _name.text = _credential!.clientName;
                                }
                                _message = _statusMessage(status);
                              }),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Check connection'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PgCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PgSectionHeader(title: 'Desktop-assisted analysis'),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Use Desktop analysis this session'),
                      subtitle: const Text(
                        'Original text is sent only while enabled. Local uses pinned TLS; Remote adds an application-level AES-256-GCM tunnel through the relay. The switch resets after restart.',
                      ),
                      value: widget.client.analysisEnabled,
                      onChanged: _busy
                          ? null
                          : (value) => setState(
                                () => widget.client.analysisEnabled = value,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PgCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PgSectionHeader(title: 'Remove connection'),
                    const Text(
                      'Remove device revokes this credential on Desktop. Forget locally only clears this phone.',
                      style: TextStyle(
                        color: PgColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _run(_removeDevice),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Remove device from Desktop'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _run(_forgetLocally),
                      child: const Text('Forget locally only'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              PgCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PgSectionHeader(title: 'Pair this phone'),
                    const Text(
                      'Pair once while the phone can reach the Desktop locally. After approval, Device Trust can use Local or Remote automatically without another QR.',
                      style: TextStyle(
                        color: PgColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _name,
                      enabled: !_busy,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Device name',
                        helperText: 'Example: Pietro Samsung, Work iPhone',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : _scanQr,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan pairing QR from Desktop'),
                    ),
                    const SizedBox(height: 14),
                    const Center(
                      child: Text(
                        'or paste the temporary JSON manually',
                        style: TextStyle(color: PgColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bundle,
                      minLines: 4,
                      maxLines: 8,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Pairing data (JSON)',
                        helperText:
                            'Temporary pairing data contains a secret. Do not share publicly.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _busy ? null : () => _run(_pair),
                      child: const Text('Request pairing with pasted data'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const PgCard(
              backgroundColor: Color(0xFFF3F7FF),
              child: Text(
                'Device Trust prefers the direct local connection. When Local is unavailable it falls back to the ciphertext-only remote relay. Library access remains explicit and item-by-item; nothing syncs automatically.',
                style: TextStyle(
                  color: PgColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
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
