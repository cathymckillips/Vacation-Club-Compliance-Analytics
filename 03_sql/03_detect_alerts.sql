-- Run after CSV load. Deterministic as-of date. Re-running is idempotent.
DECLARE @AsOfDate date='2026-10-31';
WITH C AS (
 SELECT MemberID, COUNT(*) AS N FROM dbo.FactReservation
 WHERE BookingDate BETWEEN DATEADD(day,-29,@AsOfDate) AND @AsOfDate
 AND BookingStatus IN ('Confirmed','Completed') GROUP BY MemberID HAVING COUNT(*)>8
)
INSERT INTO dbo.FactComplianceAlert(RuleID,MemberID,EvidenceReference,EvidenceValue,AsOfDate,RiskLevel)
SELECT 'CR001',c.MemberID,'ROLLING30',c.N,@AsOfDate,'Medium' FROM C c
WHERE NOT EXISTS (SELECT 1 FROM dbo.FactComplianceAlert a WHERE a.RuleID='CR001' AND a.MemberID=c.MemberID AND a.EvidenceReference='ROLLING30' AND a.AsOfDate=@AsOfDate);

WITH C AS (
 SELECT MemberID,COUNT(*) AS TotalBookings,SUM(CASE WHEN BookingStatus='Canceled' THEN 1 ELSE 0 END) AS CanceledBookings
 FROM dbo.FactReservation WHERE BookingDate BETWEEN DATEADD(day,-89,@AsOfDate) AND @AsOfDate
 GROUP BY MemberID HAVING COUNT(*)>=5 AND 100.0*SUM(CASE WHEN BookingStatus='Canceled' THEN 1 ELSE 0 END)/COUNT(*)>40
)
INSERT INTO dbo.FactComplianceAlert(RuleID,MemberID,EvidenceReference,EvidenceValue,AsOfDate,RiskLevel)
SELECT 'CR002',c.MemberID,'ROLLING90',100.0*c.CanceledBookings/c.TotalBookings,@AsOfDate,'Medium' FROM C c
WHERE NOT EXISTS(SELECT 1 FROM dbo.FactComplianceAlert a WHERE a.RuleID='CR002' AND a.MemberID=c.MemberID AND a.EvidenceReference='ROLLING90' AND a.AsOfDate=@AsOfDate);

WITH C AS (SELECT MemberID,SUM(PointsDelta) AS Balance FROM dbo.FactPointsLedger WHERE TransactionDate<=@AsOfDate GROUP BY MemberID HAVING SUM(PointsDelta)<0)
INSERT INTO dbo.FactComplianceAlert(RuleID,MemberID,EvidenceReference,EvidenceValue,AsOfDate,RiskLevel)
SELECT 'CR003',c.MemberID,'LEDGERBALANCE',c.Balance,@AsOfDate,'High' FROM C c
WHERE NOT EXISTS(SELECT 1 FROM dbo.FactComplianceAlert a WHERE a.RuleID='CR003' AND a.MemberID=c.MemberID AND a.EvidenceReference='LEDGERBALANCE' AND a.AsOfDate=@AsOfDate);

-- CR004 flags each involved account; shared tokens are artificial, not personally identifying.
WITH C AS (SELECT GuestToken FROM dbo.FactReservation WHERE ThirdPartyGuestFlag=1 GROUP BY GuestToken HAVING COUNT(DISTINCT MemberID)>=3),
M AS (SELECT DISTINCT r.MemberID,r.GuestToken FROM dbo.FactReservation r JOIN C ON C.GuestToken=r.GuestToken)
INSERT INTO dbo.FactComplianceAlert(RuleID,MemberID,EvidenceReference,EvidenceValue,AsOfDate,RiskLevel)
SELECT 'CR004',m.MemberID,m.GuestToken,3,@AsOfDate,'Review' FROM M m
WHERE NOT EXISTS(SELECT 1 FROM dbo.FactComplianceAlert a WHERE a.RuleID='CR004' AND a.MemberID=m.MemberID AND a.EvidenceReference=m.GuestToken AND a.AsOfDate=@AsOfDate);

INSERT INTO dbo.FactComplianceAlert(RuleID,MemberID,EvidenceReference,EvidenceValue,AsOfDate,RiskLevel)
SELECT 'CR005',p.MemberID,CONCAT('TX-',p.TransactionID),p.PointsDelta,@AsOfDate,'High'
FROM dbo.FactPointsLedger p WHERE p.TransactionDate<=@AsOfDate AND p.TransactionType='Adjustment' AND p.PointsDelta>10000 AND p.ApprovedFlag=0
AND NOT EXISTS(SELECT 1 FROM dbo.FactComplianceAlert a WHERE a.RuleID='CR005' AND a.MemberID=p.MemberID AND a.EvidenceReference=CONCAT('TX-',p.TransactionID) AND a.AsOfDate=@AsOfDate);

INSERT INTO dbo.FactComplianceAlert(RuleID,MemberID,EvidenceReference,EvidenceValue,AsOfDate,RiskLevel)
SELECT 'CR006',c.MemberID,CONCAT('INTERACTION-',c.InteractionID),1,@AsOfDate,'High'
FROM dbo.FactContactCenter c WHERE c.InteractionDate<=@AsOfDate AND c.ActionType='AccountOverride' AND c.ApprovedFlag=0
AND NOT EXISTS(SELECT 1 FROM dbo.FactComplianceAlert a WHERE a.RuleID='CR006' AND a.MemberID=c.MemberID AND a.EvidenceReference=CONCAT('INTERACTION-',c.InteractionID) AND a.AsOfDate=@AsOfDate);
SELECT RuleID,COUNT(*) AS AlertCount FROM dbo.FactComplianceAlert GROUP BY RuleID ORDER BY RuleID;
