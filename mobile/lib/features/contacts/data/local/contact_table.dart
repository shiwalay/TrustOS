import 'package:drift/drift.dart';

/// Minimal contact cache (contacts feature is otherwise a skeleton). Enough
/// shape to drive the Home pulse and onboarding insights; the full import /
/// dedup pipeline (docs/09 §5.2) lands with the contacts milestone.
class ContactRows extends Table {
  TextColumn get id => text()(); //           usr_/local contact id
  TextColumn get name => text()();
  TextColumn get company => text()();
  TextColumn get industry => text()();
  TextColumn get city => text()();
  TextColumn get phone => text()(); //        E.164; PII — device-encrypted at rest
  IntColumn get relationshipStrength =>
      integer().withDefault(const Constant(0))(); // 0–100 (relationship-service)
  IntColumn get daysSinceInteraction =>
      integer().withDefault(const Constant(0))();
  BoolColumn get runsBusiness => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
