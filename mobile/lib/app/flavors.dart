/// Flavor stub per 09-mobile-architecture.md (app/flavors.dart): per-flavor
/// API host, Sentry DSN and cert-pin sets. Dev/stage are unpinned (§5.4).
enum Flavor {
  dev,
  stage,
  prod;

  static Flavor fromEnvironment() {
    const raw = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    return Flavor.values.firstWhere(
      (f) => f.name == raw,
      orElse: () => Flavor.dev,
    );
  }
}

class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.sentryDsn,
    required this.certificatePinsSpkiSha256,
  });

  factory FlavorConfig.of(Flavor flavor) => switch (flavor) {
        Flavor.dev => const FlavorConfig(
            flavor: Flavor.dev,
            apiBaseUrl: 'http://localhost:8080/v1',
            sentryDsn: '',
            certificatePinsSpkiSha256: [], // unpinned against local envs (§5.4)
          ),
        Flavor.stage => const FlavorConfig(
            flavor: Flavor.stage,
            apiBaseUrl: 'https://api.stage.trustos.app/v1',
            sentryDsn: '',
            certificatePinsSpkiSha256: [],
          ),
        Flavor.prod => const FlavorConfig(
            flavor: Flavor.prod,
            apiBaseUrl: 'https://api.trustos.app/v1',
            sentryDsn: String.fromEnvironment('SENTRY_DSN'),
            // SPKI SHA-256 of issuing CA + one backup CA — never the leaf (§5.4).
            certificatePinsSpkiSha256: [
              'sha256/PLACEHOLDER_ISSUING_CA_PIN=',
              'sha256/PLACEHOLDER_BACKUP_CA_PIN=',
            ],
          ),
      };

  final Flavor flavor;
  final String apiBaseUrl;
  final String sentryDsn;
  final List<String> certificatePinsSpkiSha256;

  String get appTitle => switch (flavor) {
        Flavor.dev => 'TrustOS (dev)',
        Flavor.stage => 'TrustOS (stage)',
        Flavor.prod => 'TrustOS',
      };
}
