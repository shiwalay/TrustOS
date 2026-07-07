"""Cursor pagination (shared-context §5; 04-api-design.md §1.5).

Cursors are HMAC-signed opaque base64 of ``(sort-key values, filter hash)`` —
tamper or filter-drift decodes to ``InvalidCursorError`` (=> 400 invalid-cursor).
Never offset for user-facing lists.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any

MAX_PAGE_LIMIT = 100
DEFAULT_PAGE_LIMIT = 25


class InvalidCursorError(ValueError):
    """Cursor failed to decode, failed HMAC verification, or filters drifted."""


@dataclass(frozen=True, slots=True)
class PageInfo:
    next_cursor: str | None
    has_more: bool


def _filter_hash(filters: Mapping[str, Any] | None) -> str:
    canonical = json.dumps(filters or {}, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode()).hexdigest()[:16]


def _sign(body: bytes, secret: str) -> str:
    return hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()[:32]


def encode_cursor(
    keys: Mapping[str, Any],
    *,
    secret: str,
    filters: Mapping[str, Any] | None = None,
) -> str:
    """Encode sort-key values (+ a hash of the active filters) into an opaque token."""
    body = json.dumps({"v": 1, "k": dict(keys), "f": _filter_hash(filters)},
                      sort_keys=True, separators=(",", ":")).encode()
    token = body + b"." + _sign(body, secret).encode()
    return base64.urlsafe_b64encode(token).decode().rstrip("=")


def decode_cursor(
    cursor: str,
    *,
    secret: str,
    filters: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    """Verify + decode a cursor. Raises InvalidCursorError on any mismatch."""
    try:
        padded = cursor + "=" * (-len(cursor) % 4)
        raw = base64.urlsafe_b64decode(padded.encode())
        body, _, signature = raw.rpartition(b".")
        if not body:
            raise InvalidCursorError("malformed cursor")
        if not hmac.compare_digest(signature.decode(), _sign(body, secret)):
            raise InvalidCursorError("cursor signature mismatch")
        payload = json.loads(body)
    except InvalidCursorError:
        raise
    except Exception as exc:
        raise InvalidCursorError("malformed cursor") from exc
    if payload.get("f") != _filter_hash(filters):
        raise InvalidCursorError("cursor does not match the current filters")
    keys = payload.get("k")
    if not isinstance(keys, dict):
        raise InvalidCursorError("malformed cursor payload")
    return keys


def clamp_limit(limit: int | None) -> int:
    if limit is None:
        return DEFAULT_PAGE_LIMIT
    return max(1, min(limit, MAX_PAGE_LIMIT))
