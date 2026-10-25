// Which screen is on top, readable from *outside* the Navigator.
//
// Overlays that live above the Navigator — the persistent podcast mini player —
// have no route of their own to inspect, so they listen to these notifiers.
// `Routes.currentRoute` cannot serve this: it is only written in
// `onGenerateRouted`, so it still names a screen that has already been popped.

import 'package:flutter/widgets.dart';
import 'package:news/utils/ui_utils.dart';

class RouteTracker extends NavigatorObserver {
  RouteTracker._();

  static final RouteTracker instance = RouteTracker._();

  /// Name of the topmost full screen ([PageRoute]); null until the first push.
  static final ValueNotifier<String?> topRoute = ValueNotifier<String?>(null);

  /// True while a dialog, popup menu or modal bottom sheet covers that screen.
  static final ValueNotifier<bool> popupOpen = ValueNotifier<bool>(false);

  final List<Route<dynamic>> _stack = [];

  // Not every `X.route()` factory in this app forwards its [RouteSettings] to
  // the route it builds, so `route.settings.name` is unreliable. Routes.dart
  // registers the name it was asked for instead. An Expando keeps the entry
  // alive only as long as the route itself.
  final Expando<String> _names = Expando<String>('routeName');

  void registerRouteName(Route<dynamic> route, String? name) {
    if (name != null) _names[route] = name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _sync();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _sync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final int index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index < 0) {
      if (newRoute != null) _stack.add(newRoute);
    } else if (newRoute == null) {
      _stack.removeAt(index);
    } else {
      _stack[index] = newRoute;
    }
    _sync();
  }

  void _sync() {
    Route<dynamic>? topPage;
    for (final route in _stack) {
      if (route is PageRoute) topPage = route;
    }
    UiUtils.setNotifier(
        topRoute, topPage == null ? null : _nameOf(topPage));
    UiUtils.setNotifier(
        popupOpen, _stack.isNotEmpty && _stack.last is! PageRoute);
  }

  String? _nameOf(Route<dynamic> route) =>
      _names[route] ?? route.settings.name;
}
