# TrustOS — Platform Design

**The AI Relationship Intelligence Platform.** The operating system for human relationships — measurable trust, navigable networks, liquid referrals. Designed for 100M users across 100 countries.

Start with [`docs/00-overview.md`](docs/00-overview.md) (executive synthesis), then [`docs/_shared-context.md`](docs/_shared-context.md) (the binding decision record every document conforms to).

## Documentation Map

| Doc | Contents | Deliverables covered |
|---|---|---|
| [`_brief.md`](docs/_brief.md) | Source requirements | — |
| [`_shared-context.md`](docs/_shared-context.md) | **Binding** canonical decisions: service registry (25 services), event taxonomy, DTI trust model, platform invariants | — |
| [`00-overview.md`](docs/00-overview.md) | Thesis, challenged assumptions, hardest problems, risk register | — |
| [`01-prd.md`](docs/01-prd.md) | Complete PRD: personas, all 15 modules, journeys, business rules, monetization, metrics, GTM | 1, 15, 24 |
| [`02-system-architecture.md`](docs/02-system-architecture.md) | System + microservice architecture, event architecture, cells/multi-region, capacity model, infra diagram | 2, 3, 8, 13 |
| [`03-backend-architecture.md`](docs/03-backend-architecture.md) | FastAPI Clean Architecture, DDD patterns with code, backend folder structure, Temporal sagas | 5, 19 |
| [`04-api-design.md`](docs/04-api-design.md) | API conventions, endpoint catalog, GraphQL BFF, sequence diagrams, OpenAPI governance | 7, 14 |
| [`05-data-architecture.md`](docs/05-data-architecture.md) | PostgreSQL DDL + ER diagrams + migrations, Neo4j graph design, Qdrant vector design, ClickHouse, Redis | 6, 9, 10, 20 |
| [`06-algorithms.md`](docs/06-algorithms.md) | Trust (DTI) spec, relationship score, referral/attribution/fraud, recommendations, leaderboards, gamification | 25, 26, 27, 28, 29 |
| [`07-ai-architecture.md`](docs/07-ai-architecture.md) | ai-gateway, prompt architecture, the 8 agents, guardrails, evals, predictive ML, AI cost model | 21, 22 |
| [`08-automation-engine.md`](docs/08-automation-engine.md) | Automation DSL, Temporal workflows (with code), channel compliance, frequency governor | 23 |
| [`09-mobile-architecture.md`](docs/09-mobile-architecture.md) | Flutter Clean Architecture, complete folder structure, Riverpod, offline-first sync engine | 4, 18 |
| [`10-ux-design.md`](docs/10-ux-design.md) | Information architecture, 15 wireframes, design system, journeys, trust & safety UX | 16, 17 |
| [`11-security-architecture.md`](docs/11-security-architecture.md) | Threat model, authN/Z, encryption & E2EE, zero trust, audit, compliance (GDPR/DPDP/SOC2), fraud ops | 11 |
| [`12-devops-platform.md`](docs/12-devops-platform.md) | EKS/GitOps/CI-CD, canary + blue-green, observability & SLOs, DR, scaling ladder, cost model | 12, 32, 33, 34 |
| [`13-testing-performance.md`](docs/13-testing-performance.md) | Test pyramid, contract/event/AI testing, k6 load suite, performance budgets | 30, 31 |
| [`14-roadmap.md`](docs/14-roadmap.md) | 36-month phased roadmap, team topology, deliberate non-goals, hardest open problems | 35 |
| [`15-opportunity-network-strategy.md`](docs/15-opportunity-network-strategy.md) | BNI first-principles deconstruction rebuilt AI-native; the Opportunity Network (10 opportunity types, one pipeline), flywheels, Delta-4 moat | strategy |
| [`16-legal-compliance.md`](docs/16-legal-compliance.md) | Legal architecture: ToS/privacy/referral-terms structure, DPDP/RBI/SEBI/anti-MLM/AI-Act/FCRA risk answers, tax posture, compliance gaps & sequencing | legal |

*(Deliverable numbers refer to the 35 items in the source brief; user journeys and IA appear in 01 and 10, sequence diagrams in 04, infrastructure diagrams in 02 and 12.)*

## Reading Paths

- **Product/founder:** 00 → 15 → 01 → 10 → 14
- **Backend engineer:** _shared-context → 02 → 03 → 04 → 05
- **Mobile engineer:** _shared-context → 09 → 10 → 04
- **AI engineer:** _shared-context → 07 → 08 → 06
- **Security/compliance:** 11 → 05 §10 → 06 §1
- **SRE/platform:** 02 → 12 → 13
