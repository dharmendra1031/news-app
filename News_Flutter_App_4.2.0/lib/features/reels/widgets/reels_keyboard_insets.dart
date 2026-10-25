import 'dart:io';

import 'package:flutter/widgets.dart';

/// Matches [DashBoardState.buildNavBarItem] container height.
double kReelsTabBarHeight = (Platform.isIOS) ? 20 : 30; //60

/// Keyboard height (reels scaffold strips local [MediaQuery.viewInsets]).
double reelsKeyboardInset(BuildContext context) {
  final local = MediaQuery.viewInsetsOf(context).bottom;
  if (local > 0) return local;
  return MediaQueryData.fromView(View.of(context)).viewInsets.bottom;
}

bool reelsKeyboardIsOpen(BuildContext context) {
  return reelsKeyboardInset(context) > 0;
}

/// Bottom spacing for the tab bar when the keyboard is closed.
///
/// Dashboard body is already padded by [MediaQuery.viewPadding.bottom] (safe
/// area). Only the portion of the tab bar that sits below that inset is added
/// here so we avoid double-counting (iOS overflow) or under-counting (Android).
///
/// Set [ignoreKeyboard] while the comment bottom sheet is open so the reel
/// behind the modal does not jump when the keyboard appears.

double reelsTabBarBottomPadding(
  BuildContext context, {
  bool ignoreKeyboard = false,
}) {
  final mq = MediaQuery.of(context);

  // Keyboard open
  if (!ignoreKeyboard && reelsKeyboardIsOpen(context)) {
    // Android + 3-button navigation
    if (Platform.isAndroid &&
        mq.viewPadding.bottom == 0 &&
        mq.padding.bottom == 0) {
      return 0;
    }

    return 0;
  }

  final safeBottom = mq.viewPadding.bottom;

  return (kReelsTabBarHeight - safeBottom).clamp(0.0, kReelsTabBarHeight);
}
