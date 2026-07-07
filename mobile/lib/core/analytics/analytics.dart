import 'package:flutter/foundation.dart';

/// Typed analytics facade (09-mobile-architecture.md core/analytics).
/// Events flow to analytics-service (ClickHouse) with a pseudonymous user_id;
/// the skeleton ships a debug logger implementation only.
abstract interface class Analytics {
  void track(String event, [Map<String, Object?> properties = const {}]);
  void screen(String name);
}

class DebugAnalytics implements Analytics {
  const DebugAnalytics();

  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {
    debugPrint('[analytics] $event $properties');
  }

  @override
  void screen(String name) {
    debugPrint('[analytics] screen_view $name');
  }
}
