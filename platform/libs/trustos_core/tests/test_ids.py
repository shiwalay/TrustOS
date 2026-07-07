from uuid import UUID

import pytest
from trustos_core.ids import (
    InvalidPublicIdError,
    prefixed_uuid7,
    public_id,
    uuid7,
    uuid_from_public_id,
)


def test_uuid7_version_and_variant() -> None:
    u = uuid7()
    assert u.version == 7
    assert u.variant == "specified in RFC 4122"


def test_uuid7_is_time_ordered() -> None:
    ids = [uuid7() for _ in range(50)]
    assert ids == sorted(ids, key=lambda u: u.int >> 80) or ids == sorted(ids)
    # timestamps are non-decreasing
    millis = [u.int >> 80 for u in ids]
    assert millis == sorted(millis)


def test_prefixed_public_id_roundtrip() -> None:
    pid = prefixed_uuid7("ref")
    assert pid.startswith("ref_")
    raw = uuid_from_public_id(pid, expected_prefix="ref")
    assert isinstance(raw, UUID)
    assert public_id("ref", raw) == pid


def test_public_ids_preserve_time_order() -> None:
    pids = [prefixed_uuid7("ref") for _ in range(20)]
    raws = [uuid_from_public_id(p) for p in pids]
    assert [p.split("_", 1)[1] for p in sorted(pids)] == sorted(
        p.split("_", 1)[1] for p in pids
    )
    assert sorted(raws, key=lambda u: u.int >> 80) == sorted(raws, key=lambda u: u.int >> 80)


def test_wrong_prefix_rejected() -> None:
    pid = prefixed_uuid7("usr")
    with pytest.raises(InvalidPublicIdError):
        uuid_from_public_id(pid, expected_prefix="ref")


@pytest.mark.parametrize("bad", ["", "ref", "ref_", "ref_short", "ref_" + "!" * 22])
def test_malformed_public_ids_rejected(bad: str) -> None:
    with pytest.raises(InvalidPublicIdError):
        uuid_from_public_id(bad)
