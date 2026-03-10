import 'package:flutter/material.dart';
import 'storage.dart';

class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _saveRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _saveRoute(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _saveRoute(previousRoute);
    }
  }

  void _saveRoute(Route<dynamic> route) {
    final name = route.settings.name;
    final args = route.settings.arguments;

    // Don't save login, dashboard, or empty routes as persistence targets
    // as Dashboard is already handled by 'home'
    if (name != null &&
        name != '/' &&
        name != '/login' &&
        name != '/dashboard') {
      StorageHelper.saveLastRoute(name, args);
    } else if (name == '/login' || name == '/dashboard') {
      StorageHelper.saveLastRoute(null, null);
    }
  }
}
