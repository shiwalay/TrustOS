"""UUIDv7 + prefixed public-ID helpers (shared-context §1: IDs).

Public IDs are ``<prefix>_<base62(uuid7 bytes)>`` — e.g. ``ref_01hv9k...`` style
time-ordered identifiers. base62 is fixed-width (22 chars) so lexicographic
order of public IDs preserves UUIDv7 time order.
"""

from __future__ import annotations

import os
import time
from uuid import UUID

_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
_BASE = len(_ALPHABET)
_ENCODED_LEN = 22  # ceil(128 / log2(62))
_INDEX = {c: i for i, c in enumerate(_ALPHABET)}


class InvalidPublicIdError(ValueError):
    """Raised when a public ID cannot be parsed (bad prefix or encoding)."""


def uuid7() -> UUID:
    """RFC 9562 UUIDv7: 48-bit unix-millis + version/variant bits over random tail."""
    unix_ms = time.time_ns() // 1_000_000
    rand = int.from_bytes(os.urandom(10))
    value = (unix_ms & ((1 << 48) - 1)) << 80
    value |= 0x7 << 76                          # version 7
    value |= ((rand >> 62) & 0xFFF) << 64       # rand_a (12 bits)
    value |= 0b10 << 62                         # variant
    value |= rand & ((1 << 62) - 1)             # rand_b (62 bits)
    return UUID(int=value)


def _b62_encode(raw: bytes) -> str:
    n = int.from_bytes(raw)
    chars: list[str] = []
    while n:
        n, rem = divmod(n, _BASE)
        chars.append(_ALPHABET[rem])
    return "".join(reversed(chars)).rjust(_ENCODED_LEN, _ALPHABET[0])


def _b62_decode(encoded: str) -> bytes:
    n = 0
    for char in encoded:
        try:
            n = n * _BASE + _INDEX[char]
        except KeyError:
            raise InvalidPublicIdError(f"invalid base62 character {char!r}") from None
    return n.to_bytes(16)


def public_id(prefix: str, value: UUID) -> str:
    """Render a UUID as a prefixed public ID: ``public_id('ref', u) -> 'ref_...'``."""
    return f"{prefix}_{_b62_encode(value.bytes)}"


def prefixed_uuid7(prefix: str) -> str:
    """New time-ordered public ID, e.g. ``prefixed_uuid7('ref') -> 'ref_01hv...'``."""
    return public_id(prefix, uuid7())


def uuid_from_public_id(pid: str, *, expected_prefix: str | None = None) -> UUID:
    """Recover the raw UUID from a public ID; raises InvalidPublicIdError."""
    prefix, sep, encoded = pid.rpartition("_")
    if not sep or not prefix or len(encoded) != _ENCODED_LEN:
        raise InvalidPublicIdError(f"malformed public id: {pid!r}")
    if expected_prefix is not None and prefix != expected_prefix:
        raise InvalidPublicIdError(f"expected prefix {expected_prefix!r}, got {prefix!r}")
    try:
        return UUID(bytes=_b62_decode(encoded))
    except OverflowError:
        raise InvalidPublicIdError(f"malformed public id: {pid!r}") from None
