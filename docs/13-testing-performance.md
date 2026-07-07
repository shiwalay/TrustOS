# 13 — Testing & Performance Strategy

> Conforms to `_shared-context.md` (BINDING). Deliverables: Testing Strategy · Performance Strategy.
> Sibling refs: `06-algorithms.md` (DTI/trust logic under test), `09-mobile-architecture.md` (mobile budgets),
> `11-security-architecture.md` (security test gates, Cerbos tests), `12-devops-platform.md` (CI/CD, SLOs, chaos, load infra).

**Testing thesis.** Coverage totals are vanity; **coverage of the code where being wrong is expensive** is the goal.
On TrustOS the expensive code is money (`ledger`), trust (`trust`/DTI), attribution (`referral`), and anything that
moves value or affects a person's reputation. We test *those* to the hilt (mutation testing, contract tests,
idempotency, replay) and keep everything else pragmatic (E2E is smoke-only). Event-driven + AI-native means two extra
test dimensions most orgs skip: **schema/consumer compatibility** and **prompt/eval regression** — both are CI gates.

---

## 1. Test Pyramid (per service)

Per-service layout is Clean Architecture (`_shared-context §5`: `api → application → domain → infrastructure`).
Tests map to layers:

```
        ▲  E2E (smoke only, few)         — critical journeys, prod-like, synthetic data
       ╱ ╲ Contract (Pact)               — every producer/consumer edge + mobile SDK
      ╱   ╲ Integration (testcontainers) — application+infra: real PG/Neo4j/Kafka/Redis
     ╱     ╲ Unit (many, fast)           — pure domain logic, no I/O
    ▔▔▔▔▔▔▔▔▔
```

| Layer | Scope | Tooling | What lives here |
|---|---|---|---|
| **Unit** | `domain/` pure logic | pytest, hypothesis (property tests) | DTI factor math, Wilson smoothing, decay, ledger double-entry invariants, relationship-score calc, policy predicates |
| **Integration** | `application/` + `infrastructure/` | pytest + **testcontainers** (PG16, Neo4j, Redis, Kafka/Redpanda) | repositories, outbox/CDC, projections, Temporal activities, Cerbos calls |
| **Contract** | service↔service + mobile SDK | **Pact** (consumer-driven) + Protobuf/Schema Registry compat | gRPC/REST contracts, event payload contracts, BFF↔mobile |
| **E2E** | cross-service journeys | Playwright (web) / integration harness | smoke: signup→verify, referral submit→attribute, payout, DM send |

### 1.1 Coverage gates that matter
| Code area | Gate | Rationale |
|---|---|---|
| **Domain layer (money/trust/referral)** | **≥ 90% line + branch** (CI fails below — `12 §2.2`) | Where bugs cost money/reputation |
| Domain (other services) | ≥ 80% | Still core logic |
| Application/infra | ≥ 60% (informational) | Integration tests cover the rest; don't chase |
| Overall repo total | **not gated** | Vanity metric; would incentivize testing getters |

`--cov=domain --cov-fail-under=90` per `12-devops-platform.md §2.2`. Coverage is scoped to `domain/`, not the whole tree.

### 1.2 Mutation testing on money/trust code
Line coverage lies (a test can execute a line without asserting its behavior). For `ledger-service`,
`trust-service` (DTI), and `referral-service` attribution, run **mutation testing** (`mutmut`/`cosmic-ray`) in CI
(nightly + on PRs touching those paths). **Gate: mutation score ≥ 85%** on those domains — surviving mutants
(e.g., flipping `>=` to `>`, dropping a decay term, sign flip in a ledger entry) fail the build. This is the single
highest-leverage test practice for a trust/money platform.

```yaml
# .github/workflows/mutation-nightly.yml (excerpt)
- name: Mutation test money/trust domains
  run: |
    for svc in ledger-service trust-service referral-service; do
      uv run mutmut run --paths-to-mutate services/$svc/domain
      uv run mutmut results | tee /tmp/$svc.txt
      score=$(uv run python scripts/mutscore.py /tmp/$svc.txt)
      awk -v s="$score" 'BEGIN{ if (s < 0.85) { print "mutation score "s" < 0.85"; exit 1 } }'
    done
```

---

## 2. Event-Driven Testing

TrustOS is Kafka + CloudEvents + Protobuf + outbox/CDC (`_shared-context §1,3`). Three failure classes get dedicated tests:

### 2.1 Schema-compatibility tests (CI, against the registry)
Every event payload is Protobuf in **Confluent Schema Registry**. CI runs a **compatibility check** of the PR's `.proto`
against the registered latest for that subject; **BACKWARD** (or FULL for money topics) compatibility is enforced —
a breaking change fails the PR before it can ship a poison event.

```yaml
# CI step — schema compat gate
- name: Schema Registry compatibility check
  run: |
    for proto in $(git diff --name-only origin/main | grep 'proto$'); do
      subject=$(basename $proto .proto)-value
      jq -n --arg s "$(cat $proto)" '{schema:$s, schemaType:"PROTOBUF"}' \
        | curl -sf -X POST "$SR/compatibility/subjects/$subject/versions/latest" \
            -H 'Content-Type: application/json' -d @- \
        | jq -e '.is_compatible == true'    # fail PR if false
    done
```

### 2.2 Consumer idempotency tests
Delivery is at-least-once; consumers dedup by `event_id` (`_shared-context §3`). Every consumer has a test that
**delivers the same event twice (and out of order)** and asserts the projection/side-effect is applied exactly once
(no double DTI increment, no double ledger post, no duplicate payout). Uses testcontainers Kafka; also tests the
outbox→CDC path (Debezium) for duplicates on redeploy.

```python
async def test_referral_converted_is_idempotent(consumer, ledger_repo):
    evt = referral_converted(event_id="evt_01H...", ref_id="ref_1", amount_minor=5000)
    await consumer.handle(evt)
    await consumer.handle(evt)               # duplicate delivery
    await consumer.handle(reorder(evt))      # out of order
    entries = await ledger_repo.for_referral("ref_1")
    assert len(entries) == 1                  # commission posted exactly once
    assert sum(e.amount_minor for e in entries) == 5000
```

### 2.3 Saga / Temporal workflow replay tests
Temporal workflows (KYC, referral settlement, campaign sends, import, automations — `_shared-context §1`) must be
**deterministic**. CI runs **workflow replay tests**: capture real workflow histories, replay them against the current
worker code; any non-determinism (changed activity order, removed step) fails — catches the classic "you broke a
running workflow by editing its code" bug before deploy. Compensations (saga rollback) are unit-tested: e.g. settlement
fails mid-way → escrow released, commission reversed, ledger balanced.

### 2.4 Chaos in staging (toxiproxy)
Integration/staging tests inject network faults with **toxiproxy** between service and its stores/deps: latency,
bandwidth limits, connection drops, partitions. Asserts circuit breakers open, retries are bounded + idempotent, and
degradation matrix behavior (`12 §5.4`) holds (e.g., Neo4j slow → cached graph reads, money path unaffected). Broader
cluster chaos (pod/AZ/broker kills) is the LitmusChaos program in `12-devops-platform.md §5.3`.

---

## 3. AI Testing

The AI is model-agnostic via `ai-gateway` with prompt registry, guardrails, evals (`_shared-context §1`, `_brief` AI
reqs). AI is non-deterministic, so we test with **evals + golden datasets + gates**, not exact-match asserts.

### 3.1 Prompt eval gates in CI
Every prompt template in the registry has an **eval suite** (a golden dataset of inputs + graded expectations). On any
change to a prompt, model version, or guardrail, CI runs the evals and gates on:
- **Quality:** graded score ≥ threshold (LLM-as-judge + rules) per task (e.g., referral message eval ≥ 0.8).
- **Safety:** prompt-injection corpus (from `11 §7.4` — poisoned contact notes/listings) must **not** cause the model to leak other-tenant data, call disallowed tools, or emit the injected instruction. 0 tolerated failures.
- **Format:** structured outputs validate against schema 100% (tool-call args, JSON).
- **Refusal calibration:** must refuse clearly-abusive asks, must NOT over-refuse benign ones (both sides tested).

```yaml
# ai-eval gate
- name: Prompt eval gate
  run: |
    uv run trustos-evals run --suite prompts/referral_message \
      --min-quality 0.80 --injection-corpus security/injection_cases.jsonl \
      --max-injection-failures 0 --schema-valid 1.0
```

### 3.2 Golden datasets & model-upgrade regression
- **Golden datasets** per agent (Relationship, Trust, Referral, Campaign, Community, Knowledge, Support, Networking — `_brief`): curated, versioned, PII-free, with expected-behavior grades.
- **Regression on model upgrades:** bumping the default model (e.g. sonnet minor version) is a PR that reruns all eval suites; regressions block the bump. Golden outputs are diffed; graded, not exact.
- **Bias/fairness checks** on trust-adjacent AI (DPIA, `11 §8.2`): does phrasing/geography/name shift recommendations? Monitored, reported.

### 3.3 Cost-regression tests
Every eval run records **tokens + $ per task** and asserts it hasn't regressed beyond a budget (e.g. a prompt-rewrite that quietly triples context fails a **cost budget gate**). Ties to the cost model in `12-devops-platform.md §7` — AI spend is the top variable cost, so a token regression is treated like a latency regression.

---

## 4. Load & Performance

### 4.1 k6 scenario suite
Scenarios model real journeys, not synthetic hammering. Suite includes: signup+verify, contact import, feed/dashboard
read (BFF), referral submit→attribute, campaign send fan-out, DM send, leaderboard read. Run against staging seeded to
target scale by `synthgen` (`12 §3`). Excerpt — **referral-submit flow** (the money-adjacent hot path):

```javascript
// k6/referral_submit.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Rate } from 'k6/metrics';

const submitLatency = new Trend('referral_submit_latency', true);
const errors = new Rate('referral_submit_errors');

export const options = {
  scenarios: {
    steady: { executor: 'constant-arrival-rate', rate: 2000, timeUnit: '1s',
              duration: '15m', preAllocatedVUs: 500, maxVUs: 3000 },
    spike:  { executor: 'ramping-arrival-rate', startRate: 500, timeUnit: '1s',
              stages: [{ target: 8000, duration: '2m' }, { target: 8000, duration: '3m' },
                       { target: 500, duration: '2m' }], preAllocatedVUs: 1000, maxVUs: 6000 },
  },
  thresholds: {
    referral_submit_latency: ['p(99)<500'],   // money-path write SLO (12 §4.3 #3)
    referral_submit_errors: ['rate<0.001'],   // <0.1%
    http_req_failed: ['rate<0.005'],
  },
};

export default function () {
  const idem = `k6-${__VU}-${__ITER}`;
  const res = http.post(`${__ENV.BASE}/v1/referrals`, JSON.stringify({
    campaign_id: 'cmp_seed_1', referee_phone_hash: `h_${__VU}_${__ITER}`, note: 'perf',
  }), { headers: {
    'Authorization': `Bearer ${__ENV.TOKEN}`,
    'Idempotency-Key': idem,                  // exercises idempotency path (_shared-context §5)
    'Content-Type': 'application/json',
  }});
  submitLatency.add(res.timings.duration);
  errors.add(res.status >= 400);
  check(res, { 'submitted 201/200': (r) => r.status === 201 || r.status === 200 });
  sleep(Math.random() * 2);
}
```

### 4.2 Capacity test cadence & soak
- **Capacity tests** each release train against next-milestone scale (`12 §6` ladder) — find the knee before users do.
- **Soak tests** (4–24 h at steady load) catch leaks, connection-pool exhaustion, Kafka lag creep, Neo4j heap growth, memory-limit OOMs. Run weekly in staging.
- **Spike tests** validate autoscaling reaction time (HPA/KEDA/Karpenter — `12 §6`) and load-shedding (`12 §5.4`).

### 4.3 Performance budgets

**API p99 by endpoint class (in-region, `12 §4.3`):**
| Class | Example | p99 budget |
|---|---|---|
| Cache/read-hot | leaderboard, profile | < 120 ms |
| Standard read | relationship list, feed item | < 300 ms |
| Aggregate read (BFF) | dashboard | < 400 ms (p95) |
| Standard write | referral submit, post | < 500 ms |
| Heavy/graph | networking recommendations | < 800 ms (may be async) |
| AI generation | copilot message | < 6 s (p95, streamed) |

**Kafka consumer lag SLOs:** trust/analytics < 30 s p95; ledger/referral (money) < 5 s p95 (`12 §4.3 #11`).

**Mobile budgets (ref `09-mobile-architecture.md`):** cold start < 2.5 s p95; feed first-paint < 1 s (offline-first
from Drift cache); frame build < 16 ms (60fps) / jank < 1%; sync round-trip < 5 s online; app size budget enforced in
CI; battery/network budgets for background sync. Regressions gated via mobile perf CI + Sentry release health
(`12 §4.4`).

### 4.4 Profiling toolchain
- **py-spy** for on-demand flame graphs of hot Python services (sampling, no code change).
- **Parca** (eBPF continuous profiling) fleet-wide — always-on CPU/alloc profiles, correlate cost spikes to code (`12 §7`).
- **pg_stat_statements** + `EXPLAIN (ANALYZE, BUFFERS)` for slow queries; Neo4j query logging + `PROFILE` for Cypher.
- Traces (Tempo, `12 §4.1`) locate *which* service/span; profiles locate *which line*.

---

## 5. Release Qualification & Production Verification

### 5.1 Release qualification checklist
A release train is qualified when:
- [ ] Unit/integration/contract green; **domain coverage ≥ 90%**, mutation ≥ 85% on money/trust (§1).
- [ ] Schema-compat gate passed; consumer idempotency + Temporal replay tests green (§2).
- [ ] AI eval gates passed (quality/safety/format/cost) if prompts/models changed (§3).
- [ ] trivy/semgrep clean (no HIGH/CRITICAL); image cosign-signed (`11 §5`, `12 §2.2`).
- [ ] Cerbos policy tests green (`11 §3`).
- [ ] DB migration is expand/contract & backward-compatible; pre-sync hook validated (`12 §2.6`).
- [ ] Load/capacity test met budgets for the target milestone (§4).
- [ ] Feature-flag plan documented; risky paths flag-gated with kill switch (`11 §9.3`).
- [ ] SLO error budget for target services is healthy (not in freeze — `12 §4.4`).
- [ ] Rollback plan stated (canary auto-abort / blue-green flip — `12 §2.4–2.5`).

### 5.2 Production verification — synthetic probes
Post-deploy (and continuously), **synthetic probes** run each critical journey against prod from each cell region:
| Probe | Journey | Frequency | Alert |
|---|---|---|---|
| Auth | login (test tenant) + token refresh | 1 min | page on 2 consecutive fails |
| Referral | submit → attribute → commission calc (sandbox campaign) | 5 min | page |
| Payout | ledger post + payout dry-run (test ledger) | 5 min | page (money path) |
| DM | E2EE send/receive round-trip | 5 min | ticket |
| Feed | BFF aggregate read within budget | 1 min | ticket |
| AI | copilot generation returns valid schema | 5 min | ticket |
| Trust | factor event → DTI reflects < 60 s (SLO #7) | 5 min | ticket |

Probes are first-class users (test tenants per region), so they exercise the real path incl. Cerbos, mesh mTLS, and
egress. A failing probe is a real user journey down — it pages before customers notice. Ties to SLOs and burn alerts
in `12-devops-platform.md §4`.

---

*End of 13-testing-performance.md. Cross-refs: `06-algorithms.md`, `09-mobile-architecture.md`,
`11-security-architecture.md`, `12-devops-platform.md`.*
