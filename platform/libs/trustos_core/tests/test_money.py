import pytest
from trustos_core.money import Currency, CurrencyMismatchError, Money


def test_add_and_subtract_same_currency() -> None:
    a = Money(1_000, Currency.INR)
    b = Money(250, Currency.INR)
    assert a + b == Money(1_250, Currency.INR)
    assert a - b == Money(750, Currency.INR)


def test_negative_amount_rejected() -> None:
    with pytest.raises(ValueError, match="non-negative"):
        Money(-1, Currency.INR)


def test_subtraction_cannot_go_negative() -> None:
    with pytest.raises(ValueError, match="negative"):
        Money(100, Currency.USD) - Money(200, Currency.USD)


def test_currency_mismatch() -> None:
    with pytest.raises(CurrencyMismatchError):
        Money(1, Currency.INR) + Money(1, Currency.USD)


def test_percentage_basis_points_rounds_half_up() -> None:
    # 5% of 2,50,000 minor units = 12,500
    assert Money(250_000, Currency.INR).percentage(500) == Money(12_500, Currency.INR)
    # rounding: 3 bps of 16,667 = 5.0001 -> 5
    assert Money(16_667, Currency.INR).percentage(3).amount_minor == 5
    # half rounds up: 1 bps of 15,000 = 1.5 -> 2
    assert Money(15_000, Currency.INR).percentage(1).amount_minor == 2


@pytest.mark.parametrize("bps", [-1, 10_001])
def test_percentage_range_guard(bps: int) -> None:
    with pytest.raises(ValueError, match="basis points"):
        Money(100, Currency.INR).percentage(bps)


def test_zero_and_value_equality() -> None:
    assert Money.zero(Currency.EUR) == Money(0, Currency.EUR)
    assert hash(Money(5, Currency.INR)) == hash(Money(5, Currency.INR))
