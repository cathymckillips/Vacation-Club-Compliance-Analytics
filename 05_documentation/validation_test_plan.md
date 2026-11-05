# Validation and acceptance criteria

- [ ] Generator runs twice with identical seed and yields byte-identical CSV files.
- [ ] SQL schema created in an empty database with no errors.
- [ ] All six CSV files load and row counts match.
- [ ] Referential integrity and date/point checks return zero issues.
- [ ] Alert SQL produces at least one alert for each of the six rules (verify with GROUP BY).
- [ ] Re-running detection does not duplicate alerts.
- [ ] Every investigation references a valid alert; closed cases have a disposition.
- [ ] Power BI measures match independent SQL COUNT/DISTINCTCOUNT checks.
- [ ] Date filters and member drill-through return expected results.
- [ ] No report claims an alert proves misconduct.
- [ ] Control trend is descriptive, not represented as a measured intervention effect.

## SQL validation examples
SELECT RuleID, COUNT(*) AS Alerts FROM dbo.FactComplianceAlert GROUP BY RuleID ORDER BY RuleID;
SELECT COUNT(*) AS DuplicateAlerts FROM (SELECT RuleID,MemberID,EvidenceReference,AsOfDate FROM dbo.FactComplianceAlert GROUP BY RuleID,MemberID,EvidenceReference,AsOfDate HAVING COUNT(*)>1) x;
SELECT COUNT(*) AS OrphanInvestigations FROM dbo.FactInvestigation i LEFT JOIN dbo.FactComplianceAlert a ON i.AlertID=a.AlertID WHERE a.AlertID IS NULL;
