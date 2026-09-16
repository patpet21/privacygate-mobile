import 'package:flutter/material.dart';

import '../../app/mobile_design.dart';
import '../../core/mobile_link/desktop_connection.dart';
import '../../core/mobile_link/mobile_link_client.dart';

class DesktopConnectionScreen extends StatefulWidget {
  const DesktopConnectionScreen({required this.store, super.key});

  final DesktopConnectionStore store;

  @override
  State<DesktopConnectionScreen> createState() => _DesktopConnectionScreenState();
}

class _DesktopConnectionScreenState extends State<DesktopConnectionScreen> {
  final _pairingData = TextEditingController();
  PairingBootstrap? _bootstrap;
  String? _requestId;
  DesktopConnection? _connection;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pairingData.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final connection = await widget.store.load();
    if (!mounted) return;
    setState(() => _connection = connection);
  }

  Future<void> _requestPairing() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final bootstrap = PairingBootstrap.fromJsonText(_pairingData.text.trim());
      if (bootstrap.isExpired) {
        throw const MobileLinkException('Pairing data expired. Create fresh pairing data on Desktop.');
      }
      final clientId = await widget.store.ensureClientId();
      final request = await DesktopPairingClient(bootstrap).requestPairing(clientId: clientId);
      if (!mounted) return;
      setState(() {
        _bootstrap = bootstrap;
        _requestId = request.requestId;
        _message = 'Request sent. Approve this device on Desktop, then tap Check approval.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkApproval() async {
    final bootstrap = _bootstrap;
    final requestId = _requestId;
    if (bootstrap == null || requestId == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final status = await DesktopPairingClient(bootstrap).checkStatus(requestId);
      if (status.approved) {
        final clientId = await widget.store.ensureClientId();
        await widget.store.save(
          bootstrap: bootstrap,
          bearerToken: status.bearerToken!,
          clientId: clientId,
        );
        final connection = await widget.store.load();
        if (!mounted) return;
        setState(() {
          _connection = connection;
          _requestId = null;
          _bootstrap = null;
          _pairingData.clear();
          _message = 'Desktop paired. Protected-copy grants can now be refreshed from Library.';
        });
      } else {
        if (!mounted) return;
        setState(() => _message = 'Pairing status: ${status.status}.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgetConnection() async {
    await widget.store.clearConnection();
    if (!mounted) return;
    setState(() {
      _connection = null;
      _requestId = null;
      _bootstrap = null;
      _message = 'Desktop credential removed from this phone. Revoke the device on Desktop to invalidate it there too.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final paired = _connection != null;
    return Scaffold(
      backgroundColor: PgColors.background,
      appBar: AppBar(
        backgroundColor: PgColors.background,
        surfaceTintColor: PgColors.background,
        title: const Text('Desktop connection'),
      ),
      body: PgPage(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          PgCard(
            backgroundColor: paired ? PgColors.greenSoft : Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PgIconBox(
                  icon: paired ? Icons.verified_rounded : Icons.laptop_mac_outlined,
                  foreground: paired ? PgColors.green : PgColors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paired ? 'Trusted Desktop paired' : 'No trusted Desktop',
                        style: const TextStyle(
                          color: PgColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        paired
                            ? _connection!.endpoint
                            : 'Pairing authorizes this device, but does not grant automatic Library access.',
                        style: const TextStyle(color: PgColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!paired) ...[
            PgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PgSectionHeader(title: 'Pair with Desktop'),
                  const SizedBox(height: 8),
                  const Text(
                    'On Desktop open Mobile & Devices, create fresh pairing data, then copy the Advanced pairing JSON here. QR scanning can be added on top of the same protocol later.',
                    style: TextStyle(color: PgColors.textSecondary, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pairingData,
                    minLines: 5,
                    maxLines: 9,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Temporary pairing JSON',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _requestPairing,
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Request pairing'),
                  ),
                  if (_requestId != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _checkApproval,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Check approval'),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            PgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PgSectionHeader(title: 'Connection controls'),
                  const SizedBox(height: 8),
                  const Text(
                    'Protected copies become visible only when Desktop explicitly grants an item to this paired credential.',
                    style: TextStyle(color: PgColors.textSecondary, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _forgetConnection,
                    icon: const Icon(Icons.link_off_rounded),
                    label: const Text('Forget Desktop on this phone'),
                  ),
                ],
              ),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            PgCard(
              backgroundColor: const Color(0xFFF3F7FF),
              child: Text(
                _message!,
                style: const TextStyle(color: PgColors.textSecondary, height: 1.35),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const PgCard(
            backgroundColor: Color(0xFFF3F7FF),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PgIconBox(icon: Icons.shield_outlined, size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The Desktop certificate is pinned from the short-lived pairing bundle. The long-lived bearer credential is stored in platform secure storage, never in ordinary preferences.',
                    style: TextStyle(color: PgColors.textSecondary, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
