library custom_cupertino_page_route;

import 'dart:io';
import 'package:flutter/cupertino.dart';

class NoSwipePageRoute<T> extends CupertinoPageRoute<T> {
  NoSwipePageRoute({
    required super.builder,
    super.title,
    super.settings,
    super.maintainState = true,
    super.fullscreenDialog,
    super.allowSnapshotting = true,
    this.isPopGestureEnabled = false,
  });

  /// Whether a pop gesture can be started by the user.
  /// Returns true if the user can edge-swipe to a previous route.
  /// By default, this is enabled only on iOS and MacOS.
  final bool? isPopGestureEnabled;

  @override
  bool get hasScopedWillPopCallback {
    if (Platform.isIOS || Platform.isMacOS) {
      return super.hasScopedWillPopCallback;
    } else {
      return true;
    }
  }

  @override
  bool get popGestureEnabled {
    if (Platform.isIOS || Platform.isMacOS) {
      return true;
    } else if (Platform.isAndroid) {
      return false;
    }
    return isPopGestureEnabled ?? false;
  }
}
