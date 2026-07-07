import pytest
from trustos_core.pagination import (
    InvalidCursorError,
    clamp_limit,
    decode_cursor,
    encode_cursor,
)

SECRET = "test-secret"


def test_roundtrip() -> None:
    keys = {"submitted_at": "2026-07-07T10:00:00+00:00", "id": "ref_abc"}
    token = encode_cursor(keys, secret=SECRET, filters={"status": "qualified"})
    assert decode_cursor(token, secret=SECRET, filters={"status": "qualified"}) == keys


def test_cursor_is_opaque_base64() -> None:
    token = encode_cursor({"id": "x"}, secret=SECRET)
    assert "x" not in token or token != "x"
    assert all(c.isalnum() or c in "-_" for c in token)


def test_tampered_cursor_rejected() -> None:
    token = encode_cursor({"id": "ref_1"}, secret=SECRET)
    tampered = ("A" if token[0] != "A" else "B") + token[1:]
    with pytest.raises(InvalidCursorError):
        decode_cursor(tampered, secret=SECRET)


def test_wrong_secret_rejected() -> None:
    token = encode_cursor({"id": "ref_1"}, secret=SECRET)
    with pytest.raises(InvalidCursorError):
        decode_cursor(token, secret="other-secret")


def test_filter_drift_rejected() -> None:
    token = encode_cursor({"id": "ref_1"}, secret=SECRET, filters={"status": "qualified"})
    with pytest.raises(InvalidCursorError):
        decode_cursor(token, secret=SECRET, filters={"status": "converted"})


def test_garbage_rejected() -> None:
    with pytest.raises(InvalidCursorError):
        decode_cursor("not-a-cursor", secret=SECRET)


def test_clamp_limit() -> None:
    assert clamp_limit(None) == 25
    assert clamp_limit(10) == 10
    assert clamp_limit(1_000) == 100
    assert clamp_limit(0) == 1
