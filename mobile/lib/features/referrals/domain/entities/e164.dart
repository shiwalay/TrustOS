/// E.164 phone value object (validation for immediate feedback only — the
/// server re-validates; 09-mobile-architecture.md §3.1).
class E164 {
  const E164._(this.value);

  final String value;

  static final RegExp _pattern = RegExp(r'^\+[1-9]\d{6,14}$');

  static E164? tryParse(String raw) {
    final compact = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    return _pattern.hasMatch(compact) ? E164._(compact) : null;
  }

  @override
  String toString() => value;
}
