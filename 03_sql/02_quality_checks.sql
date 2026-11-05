-- Quality gate: each count should be zero except where explicitly expected.
SELECT 'Missing member reference' AS CheckName, COUNT(*) AS IssueCount FROM dbo.FactReservation r LEFT JOIN dbo.DimMember m ON m.MemberID=r.MemberID WHERE m.MemberID IS NULL
UNION ALL SELECT 'Missing resort reference',COUNT(*) FROM dbo.FactReservation r LEFT JOIN dbo.DimResort s ON s.ResortID=r.ResortID WHERE s.ResortID IS NULL
UNION ALL SELECT 'Invalid stay dates',COUNT(*) FROM dbo.FactReservation WHERE CheckOutDate<=CheckInDate
UNION ALL SELECT 'Negative reservation points',COUNT(*) FROM dbo.FactReservation WHERE PointsUsed<0
UNION ALL SELECT 'Duplicate member codes',COUNT(*) FROM (SELECT MemberCode FROM dbo.DimMember GROUP BY MemberCode HAVING COUNT(*)>1) d;
-- Exploratory reconciliation: reservation points and ledger redemption totals are generated independently.
-- Their mismatch is a documented SYNTHETIC DATA LIMITATION, not evidence of a real violation.
SELECT COUNT(*) AS MemberCount FROM dbo.DimMember;
SELECT COUNT(*) AS ReservationCount FROM dbo.FactReservation;
