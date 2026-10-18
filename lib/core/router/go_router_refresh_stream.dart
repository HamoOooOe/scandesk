import 'dart:async';

import 'package:flutter/foundation.dart';

/// Lets go_router re-run its `redirect` whenever a stream emits,
/// e.g. every time the AuthCubit state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
