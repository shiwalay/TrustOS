import 'package:shared_preferences/shared_preferences.dart';

/// Versioned terms acceptance (docs/16 §10: "the acceptance log is the
/// evidence"). Stores WHICH document versions were accepted and WHEN;
/// production also posts this to identity-service so the record survives
/// device loss. Bump [currentVersion] whenever either document changes —
/// the onboarding gate re-appears for anyone on an older version.
abstract final class LegalAcceptance {
  static const currentVersion = 'tos-1.0-draft · privacy-1.0-draft';

  static const _versionKey = 'legal.acceptedVersion';
  static const _atKey = 'legal.acceptedAt';

  static bool isCurrent(SharedPreferences prefs) =>
      prefs.getString(_versionKey) == currentVersion;

  static Future<void> record(SharedPreferences prefs) async {
    await prefs.setString(_versionKey, currentVersion);
    await prefs.setString(
        _atKey, DateTime.now().toUtc().toIso8601String());
  }
}
