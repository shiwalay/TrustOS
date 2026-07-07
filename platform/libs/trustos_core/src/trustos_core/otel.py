"""One-call OpenTelemetry setup (shared-context §1: Observability).

``init_telemetry`` configures a TracerProvider with service.name/region resource
attributes. With an OTLP endpoint it attaches the OTLP/HTTP span exporter
(``trustos-core[otlp]``); without one it stays export-less (local dev, tests).
Auto-instrumentation (FastAPI/SQLAlchemy/aiokafka) plugs into the returned provider.
"""

from __future__ import annotations

import logging

from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

log = logging.getLogger(__name__)

_initialized = False


def init_telemetry(
    *,
    service_name: str,
    otlp_endpoint: str | None = None,
    region: str | None = None,
    environment: str | None = None,
) -> TracerProvider:
    """Idempotent: repeated calls return the already-installed provider."""
    global _initialized
    current = trace.get_tracer_provider()
    if _initialized and isinstance(current, TracerProvider):
        return current

    attributes: dict[str, str] = {"service.name": service_name}
    if region:
        attributes["cloud.region"] = region
    if environment:
        attributes["deployment.environment"] = environment

    provider = TracerProvider(resource=Resource.create(attributes))

    if otlp_endpoint:
        try:
            from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

            provider.add_span_processor(
                BatchSpanProcessor(OTLPSpanExporter(endpoint=f"{otlp_endpoint.rstrip('/')}/v1/traces"))
            )
        except ImportError:
            log.warning(
                "OTLP endpoint configured but opentelemetry-exporter-otlp-proto-http is not "
                "installed (trustos-core[otlp]); traces will not be exported"
            )

    trace.set_tracer_provider(provider)
    _initialized = True
    return provider
