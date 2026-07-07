import 'app/bootstrap.dart';
import 'app/flavors.dart';

/// Single entrypoint; flavor selected via `--dart-define=FLAVOR=dev|stage|prod`
/// (09-mobile-architecture.md uses `main_<flavor>.dart` files; collapsed to one
/// entry + dart-define for the skeleton — same Flavor enum, same config).
Future<void> main() => bootstrap(Flavor.fromEnvironment());
