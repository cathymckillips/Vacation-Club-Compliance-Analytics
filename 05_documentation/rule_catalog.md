# Illustrative compliance rule catalog

**Not company policy.** All thresholds are invented for portfolio training and must be approved by the relevant business owner before operational use.

| ID | Detection | Threshold | Priority | Human validation |
|---|---|---|---|---|
| CR001 | Confirmed/completed bookings in rolling 30 days | >8 | Medium | Membership tier, authorized family bookings, seasonality |
| CR002 | Canceled booking ratio in rolling 90 days | >40% with >=5 bookings | Medium | Weather, resort closures, customer service exceptions |
| CR003 | Net points ledger balance | <0 | High | Pending adjustments, transfer timing, account entitlements |
| CR004 | Shared third-party guest token across accounts | >=3 accounts | Review | Household relationships, permitted guests, privacy rules |
| CR005 | Positive manual adjustment without approval | >10,000 points | High | Approval logs, delegated authority, correction reasons |
| CR006 | Unapproved account override | Any | High | Emergency override policy, audit trail, supervisor approval |

## Alert lifecycle
Detected -> Triaged -> Investigation opened -> Evidence reviewed -> Disposition (legitimate / confirmed / inconclusive) -> Corrective action -> Closed. Never automatically label an alert as a confirmed violation.

## Audit fields for future production extension
Rule version, run ID, detection timestamp, analyst, decision rationale, evidence location, reviewer approval, corrective action, follow-up date, and control owner.
