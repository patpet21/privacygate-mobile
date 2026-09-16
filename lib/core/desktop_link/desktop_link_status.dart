import 'package:flutter/foundation.dart';

enum DesktopLinkStatus {
  unpaired,
  checking,
  connected,
  offline,
}

class DesktopLinkPresence {
  DesktopLinkPresence._();

  static final ValueNotifier<DesktopLinkStatus> notifier =
      ValueNotifier<DesktopLinkStatus>(DesktopLinkStatus.unpaired);

  static DesktopLinkStatus get value => notifier.value;

  static void set(DesktopLinkStatus value) {
    if (notifier.value != value) {
      notifier.value = value;
    }
  }
}
