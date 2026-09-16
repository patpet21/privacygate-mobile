import 'package:flutter/foundation.dart';

enum DesktopLinkStatus {
  unpaired,
  checking,
  connectedLocal,
  connectedRemote,
  offline,
}

class DesktopLinkPresence {
  DesktopLinkPresence._();

  static final ValueNotifier<DesktopLinkStatus> notifier =
      ValueNotifier<DesktopLinkStatus>(DesktopLinkStatus.unpaired);

  static DesktopLinkStatus get value => notifier.value;

  static bool get connected =>
      notifier.value == DesktopLinkStatus.connectedLocal ||
      notifier.value == DesktopLinkStatus.connectedRemote;

  static void set(DesktopLinkStatus value) {
    if (notifier.value != value) {
      notifier.value = value;
    }
  }
}
