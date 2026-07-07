"""Money: integer minor units + ISO 4217. Never floats (shared-context §1).

Code per 03-backend-architecture.md §2.1.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum
from typing import Self

from trustos_core.domain import ValueObject


class Currency(StrEnum):
    INR = "INR"
    USD = "USD"
    EUR = "EUR"
    AED = "AED"
    SGD = "SGD"
    # extended per launch country; ISO 4217 only


@dataclass(frozen=True, slots=True)
class Money(ValueObject):
    """Integer minor units + ISO 4217. Never floats (shared-context §1)."""

    amount_minor: int
    currency: Currency

    def __post_init__(self) -> None:
        if self.amount_minor < 0:
            raise ValueError("Money is non-negative; direction is a ledger concern")

    def __add__(self, other: Self) -> Money:
        self._assert_same_currency(other)
        return Money(self.amount_minor + other.amount_minor, self.currency)

    def __sub__(self, other: Self) -> Money:
        self._assert_same_currency(other)
        if other.amount_minor > self.amount_minor:
            raise ValueError("Money subtraction would go negative")
        return Money(self.amount_minor - other.amount_minor, self.currency)

    def percentage(self, basis_points: int) -> Money:
        """Commission math in basis points; round half-even like a bank."""
        if not 0 <= basis_points <= 10_000:
            raise ValueError("basis points must be within [0, 10000]")
        # integer math: floor of (amount * bps + 5000) / 10000 == round-half-up on minor units
        return Money((self.amount_minor * basis_points + 5_000) // 10_000, self.currency)

    def _assert_same_currency(self, other: Money) -> None:
        if self.currency is not other.currency:
            raise CurrencyMismatchError(self.currency, other.currency)

    @classmethod
    def zero(cls, currency: Currency) -> Money:
        return cls(0, currency)


class CurrencyMismatchError(ValueError):
    def __init__(self, a: Currency, b: Currency) -> None:
        super().__init__(f"currency mismatch: {a} vs {b}")
