-- Create a reproducible illustrative investigation cohort (not real case outcomes).
-- Only one investigation per alert; deterministic sampling avoids random re-runs.
INSERT INTO dbo.FactInvestigation(AlertID,OpenDate,DueDate,CloseDate,AssignedTeam,CaseStatus,Disposition,RootCause,Notes)
SELECT a.AlertID,DATEADD(day,-(a.AlertID%25),a.AsOfDate),DATEADD(day,7-(a.AlertID%25),a.AsOfDate),
 CASE WHEN a.AlertID%5 IN (0,1) THEN DATEADD(day,2-(a.AlertID%25),a.AsOfDate) ELSE NULL END,
 CASE WHEN a.RuleID IN ('CR003','CR005') THEN 'Points Operations' WHEN a.RuleID='CR006' THEN 'Contact Center' ELSE 'Club Compliance' END,
 CASE WHEN a.AlertID%5 IN (0,1) THEN 'Closed' ELSE 'Open' END,
 CASE WHEN a.AlertID%5=0 THEN 'Confirmed Violation' WHEN a.AlertID%5=1 THEN 'Legitimate Activity' ELSE NULL END,
 CASE WHEN a.AlertID%5=0 THEN 'Control Gap' WHEN a.AlertID%5=1 THEN 'Authorized Exception' ELSE NULL END,
 'Synthetic training case; disposition assigned for demonstration only.'
FROM dbo.FactComplianceAlert a WHERE a.AlertID%4=0 AND NOT EXISTS (SELECT 1 FROM dbo.FactInvestigation i WHERE i.AlertID=a.AlertID);
GO
CREATE OR ALTER VIEW dbo.vw_ComplianceAlertDetail AS
SELECT a.AlertID,a.AsOfDate,a.RuleID,r.RuleName,a.MemberID,m.MemberCode,m.MembershipTier,a.EvidenceReference,a.EvidenceValue,a.RiskLevel,a.AlertStatus,
i.InvestigationID,i.OpenDate,i.DueDate,i.CloseDate,i.AssignedTeam,i.CaseStatus,i.Disposition,i.RootCause,
CASE WHEN i.CaseStatus='Open' AND i.DueDate<a.AsOfDate THEN 1 ELSE 0 END AS OverdueAsOfSnapshot
FROM dbo.FactComplianceAlert a JOIN dbo.DimComplianceRule r ON r.RuleID=a.RuleID
LEFT JOIN dbo.DimMember m ON m.MemberID=a.MemberID LEFT JOIN dbo.FactInvestigation i ON i.AlertID=a.AlertID;
GO
CREATE OR ALTER VIEW dbo.vw_MemberPointsBalance AS
SELECT m.MemberID,m.MemberCode,m.MembershipTier,COALESCE(SUM(p.PointsDelta),0) AS NetPointsBalance,
SUM(CASE WHEN p.TransactionType='Adjustment' AND p.ApprovedFlag=0 THEN 1 ELSE 0 END) AS UnapprovedAdjustmentCount
FROM dbo.DimMember m LEFT JOIN dbo.FactPointsLedger p ON p.MemberID=m.MemberID
GROUP BY m.MemberID,m.MemberCode,m.MembershipTier;
GO
CREATE OR ALTER VIEW dbo.vw_MonthlyBookingTrend AS
SELECT DATEFROMPARTS(YEAR(BookingDate),MONTH(BookingDate),1) AS BookingMonth,BookingStatus,COUNT(*) AS ReservationCount,SUM(PointsUsed) AS ReservedPoints
FROM dbo.FactReservation GROUP BY DATEFROMPARTS(YEAR(BookingDate),MONTH(BookingDate),1),BookingStatus;
GO
CREATE OR ALTER VIEW dbo.vw_ControlMonitoring AS
SELECT DATEFROMPARTS(YEAR(TransactionDate),MONTH(TransactionDate),1) AS TransactionMonth,
COUNT(*) AS AdjustmentCount,SUM(CASE WHEN ApprovedFlag=0 THEN 1 ELSE 0 END) AS UnapprovedCount,
CAST(100.0*SUM(CASE WHEN ApprovedFlag=0 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS decimal(7,2)) AS UnapprovedRatePct
FROM dbo.FactPointsLedger WHERE TransactionType='Adjustment'
GROUP BY DATEFROMPARTS(YEAR(TransactionDate),MONTH(TransactionDate),1);
GO
