import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

@injectable
class NavigatorKeyProvider {
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey(debugLabel: 'root');

  GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;
}
