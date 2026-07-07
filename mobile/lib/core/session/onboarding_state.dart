import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loaded before runApp (bootstrap phase 1 — a fast vault/prefs read is on
/// the allowed startup path per docs/09 §6.1) and overridden into the
/// container.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in bootstrap()'),
);

/// Whether the user has completed first-session onboarding. The router
/// redirects to /onboarding while false; completing the flow persists it.
/// "Replay onboarding" in the You tab resets it (demo affordance).
class OnboardedNotifier extends Notifier<bool> {
  static const _key = 'onboarding.completed';

  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> complete() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
  }

  Future<void> replay() async {
    state = false;
    await ref.read(sharedPreferencesProvider).setBool(_key, false);
  }
}

final onboardedProvider =
    NotifierProvider<OnboardedNotifier, bool>(OnboardedNotifier.new);
