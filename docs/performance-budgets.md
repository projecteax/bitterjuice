# BitterJuice Performance Budgets

## iOS Client Budgets

- Cold launch p50: <= 2.2s, p95: <= 3.2s
- Home dashboard render after launch: <= 500ms
- Feed first contentful paint (cached): <= 300ms
- Feed first contentful paint (network): <= 1.2s
- Max app memory during feed usage: <= 220MB

## Backend Budgets

- Callable function p95 latency:
  - `completeOnboarding`: <= 700ms
  - `logActivity`: <= 900ms
  - `purchaseReward`: <= 850ms
  - `ingestPassiveEvent`: <= 800ms
- Firestore single request read cap per screen load:
  - Dashboard: <= 12 reads
  - Feed page: <= 55 reads
  - Rewards: <= 25 reads

## Reliability Targets

- Crash-free sessions: >= 99.7%
- Server error rate (5xx equivalent): <= 0.5%
- Duplicate mutation rate with idempotency: <= 0.1%
