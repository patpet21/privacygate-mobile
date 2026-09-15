# Mobile mockup parity

This pass treats the approved PrivacyGate mobile mockups as the visual source of truth while preserving the existing local protection core.

## Navigation

The mobile shell uses five primary tabs:

1. Home
2. Protect
3. Library
4. Activity
5. Settings

## Visual direction

- White/light-gray workspace with blue PrivacyGate accents.
- Branded shield header and Desktop connection status.
- Rounded cards, compact icon tiles, clear section hierarchy, and mobile-first spacing.
- Home mirrors the approved overview structure: quick actions, privacy status, recent documents, connected apps, activity, and AI/MCP.
- Protect mirrors the approved import/profile flow and uses a dedicated Review detections stage instead of the old long Desktop-style form.
- Library mirrors the approved Vault/storage/sync layout.
- Settings mirrors the approved connection, Vault, offline, biometric, connected-app, AI-tool, notification, and privacy-default sections.

## Functional truthfulness

Mockup content that depends on unfinished infrastructure is not represented as real state. In particular:

- Desktop pairing is shown as not connected.
- Mobile Vault persistence is described as pending native Keystore/Keychain implementation.
- Gmail, Drive, camera/file import, MCP, notifications, and Desktop sync are not presented as completed features.
- The currently functional Protect path remains local pasted-text scan -> review -> protect -> second scan -> copy/restore locally.

## Core preserved

This visual pass does not replace the existing detector, protection policy, reversible placeholder behavior, protection modes, controller, or canonical parity work. It changes the Flutter presentation/navigation layer around that core.
