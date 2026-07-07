import 'dart:math';

/// Client-side ID mint: prefixed UUIDv7 (_shared-context.md §1 — time-ordered,
/// index-friendly; prefixes `usr_`, `ref_`, `cmp_`, …).
///
/// UUIDv7 lexicographic order == chronological order, which is what lets the
/// pending-operations queue use its `id` as the dispatch ordering AND the
/// Idempotency-Key (09-mobile-architecture.md §4.1/§4.3).
abstract final class TrustosId {
  static final Random _random = Random.secure();

  /// e.g. `TrustosId.generate('ref')` → `ref_01912f5e-....`
  static String generate(String prefix, {DateTime? now}) =>
      '${prefix}_${uuidV7(now: now)}';

  /// RFC 9562 UUIDv7: 48-bit unix-ms timestamp, version + variant bits,
  /// 74 random bits.
  static String uuidV7({DateTime? now}) {
    final millis = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
    final bytes = List<int>.filled(16, 0);

    // 48-bit big-endian timestamp.
    for (var i = 0; i < 6; i++) {
      bytes[i] = (millis >> (8 * (5 - i))) & 0xff;
    }
    for (var i = 6; i < 16; i++) {
      bytes[i] = _random.nextInt(256);
    }
    bytes[6] = 0x70 | (bytes[6] & 0x0f); // version 7
    bytes[8] = 0x80 | (bytes[8] & 0x3f); // RFC 4122 variant

    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
