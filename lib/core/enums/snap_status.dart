enum SnapStatus {
  sent,
  delivered,
  opened,
  expired,
  screenshot, // If you want to track screenshots
  replay,     // If snap was replayed
}

extension SnapStatusExtension on SnapStatus {
  String get name {
    switch (this) {
      case SnapStatus.sent:
        return 'sent';
      case SnapStatus.delivered:
        return 'delivered';
      case SnapStatus.opened:
        return 'opened';
      case SnapStatus.expired:
        return 'expired';
      case SnapStatus.screenshot:
        return 'screenshot';
      case SnapStatus.replay:
        return 'replay';
    }
  }

  String get displayText {
    switch (this) {
      case SnapStatus.sent:
        return 'Sent';
      case SnapStatus.delivered:
        return 'Delivered';
      case SnapStatus.opened:
        return 'Opened';
      case SnapStatus.expired:
        return 'Expired';
      case SnapStatus.screenshot:
        return 'Screenshot taken!';
      case SnapStatus.replay:
        return 'Replayed';
    }
  }
}