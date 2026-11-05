# Power BI model and build specification

## Import tables and views
Import `DimMember`, `DimResort`, `DimComplianceRule`, `FactReservation`, `FactPointsLedger`, `FactContactCenter`, `FactComplianceAlert`, `FactInvestigation`, `vw_MemberPointsBalance`, `vw_MonthlyBookingTrend`, `vw_ControlMonitoring`.

## Relationships (single-direction dimensions -> facts)
- DimMember[MemberID] 1:* FactReservation[MemberID]
- DimMember[MemberID] 1:* FactPointsLedger[MemberID]
- DimMember[MemberID] 1:* FactContactCenter[MemberID]
- DimMember[MemberID] 1:* FactComplianceAlert[MemberID]
- DimResort[ResortID] 1:* FactReservation[ResortID]
- DimComplianceRule[RuleID] 1:* FactComplianceAlert[RuleID]
- FactComplianceAlert[AlertID] 1:0..1 FactInvestigation[AlertID]
- Keep aggregate views disconnected unless you explicitly model shared date/dimension relationships; avoid ambiguous filter paths.
- Optional: create a DimDate calendar and connect to primary dates using one active relationship per fact.

## Pages
### 1. Executive Compliance Overview
Cards: Total Members, Flagged Members, Flagged Member Rate, Total Alerts, Open Cases, Confirmed Violations. Clustered column: alerts by rule. Bar: alerts by risk. Table: top flagged members with drill-through. Slicers: membership tier, risk level, rule.

### 2. Booking Behavior
Line: monthly reservation volume by status (`vw_MonthlyBookingTrend`). Bar: reservation counts by resort. Matrix: member, tier, reservations, cancellations. Drill-through: member reservation timeline and guest tokens. Do not infer wrongdoing from a shared token.

### 3. Points Integrity
Cards: members with negative balances; unapproved adjustment count. Table: `vw_MemberPointsBalance` member and net balance. Detail: ledger transactions. Add a documented limitation: synthetic reservation redemptions do not reconcile 1:1 with ledger transactions.

### 4. Investigation Management
Cards: Open Cases, Closed Cases, Overdue Open Cases, Average Closure Days. Table: alert ID, member, rule, case owner, due date, disposition. Bar: open cases by assigned team. Add member-level drill-through and evidence reference.

### 5. Control Effectiveness
Line: `vw_ControlMonitoring[UnapprovedRatePct]` by transaction month. Table: rule counts, case dispositions, root causes. Note: no control intervention is encoded in the data; do not claim a causal improvement. If desired, add a separate explicitly simulated intervention dataset in a later phase.

## Formatting
Use a restrained navy/teal palette. Reserve red for high risk and overdue; amber for review. Add tooltips explaining every KPI denominator and a prominent "Synthetic data / illustrative policy" note on each page.
