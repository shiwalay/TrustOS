"""Request-scope extractors: actor context + container access.

The gateway verifies the JWT and forwards trusted claims as headers
(``x-actor-id`` / ``x-actor-type``, 04 §1.1/§1.3); in-service we only read them.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends, Header, Request
from trustos_core.problems import UnauthenticatedProblem

from referral_service.di import Container


def get_container(request: Request) -> Container:
    container: Container = request.app.state.container
    return container


ContainerDep = Annotated[Container, Depends(get_container)]


@dataclass(frozen=True, slots=True)
class Actor:
    actor_type: str  # 'user' | 'org' | 'system'
    actor_id: str    # 'usr_...' / 'org_...'


def current_actor(
    x_actor_id: Annotated[str | None, Header()] = None,
    x_actor_type: Annotated[str, Header()] = "user",
) -> Actor:
    if not x_actor_id:
        raise UnauthenticatedProblem("Missing actor context (gateway-verified x-actor-id header).")
    return Actor(actor_type=x_actor_type, actor_id=x_actor_id)


CurrentActor = Annotated[Actor, Depends(current_actor)]
