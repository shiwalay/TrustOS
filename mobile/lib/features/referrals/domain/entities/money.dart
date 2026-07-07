import 'package:equatable/equatable.dart';

/// Money value object — _shared-context.md §1: integer minor units + ISO 4217
/// code, never floats. Authoritative values always come from ledger-service;
/// the client never does arithmetic across currencies.
class Money extends Equatable {
  const Money({required this.minorUnits, required this.currencyCode});

  final int minorUnits;

  /// ISO 4217, e.g. 'INR'. Rendered with the ENTITY's currency, never
  /// converted client-side (09-mobile-architecture.md §7).
  final String currencyCode;

  Money operator +(Money other) {
    if (other.currencyCode != currencyCode) {
      throw ArgumentError(
        'Cannot add $currencyCode and ${other.currencyCode}',
      );
    }
    return Money(
      minorUnits: minorUnits + other.minorUnits,
      currencyCode: currencyCode,
    );
  }

  @override
  List<Object?> get props => [minorUnits, currencyCode];

  @override
  String toString() => '$currencyCode $minorUnits';
}
