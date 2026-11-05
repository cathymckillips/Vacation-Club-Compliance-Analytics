-- SQL Server 2019+. Run in a dedicated empty database named VacationClubCompliance.
CREATE TABLE dbo.DimMember (MemberID int PRIMARY KEY, MemberCode varchar(20), MembershipTier varchar(20), JoinDate date, MemberStatus varchar(15));
CREATE TABLE dbo.DimResort (ResortID int PRIMARY KEY, ResortName varchar(80), Region varchar(40));
CREATE TABLE dbo.FactReservation (ReservationID int PRIMARY KEY, MemberID int REFERENCES dbo.DimMember(MemberID), ResortID int REFERENCES dbo.DimResort(ResortID), BookingDate date, CheckInDate date, CheckOutDate date, BookingStatus varchar(20), PointsUsed int, GuestToken varchar(30), ThirdPartyGuestFlag bit);
CREATE TABLE dbo.FactPointsLedger (TransactionID int PRIMARY KEY, MemberID int REFERENCES dbo.DimMember(MemberID), TransactionDate date, TransactionType varchar(25), PointsDelta int, ActorID varchar(25), ApprovedFlag bit);
CREATE TABLE dbo.FactContactCenter (InteractionID int PRIMARY KEY, MemberID int REFERENCES dbo.DimMember(MemberID), InteractionDate date, AgentID varchar(25), ActionType varchar(30), ApprovedFlag bit);
CREATE TABLE dbo.DimComplianceRule (RuleID varchar(6) PRIMARY KEY, RuleName varchar(100), RuleDescription varchar(255), Severity varchar(15), ThresholdValue int);
CREATE TABLE dbo.FactComplianceAlert (AlertID int IDENTITY(1,1) PRIMARY KEY, RuleID varchar(6) REFERENCES dbo.DimComplianceRule(RuleID), MemberID int NULL REFERENCES dbo.DimMember(MemberID), EvidenceReference varchar(80), EvidenceValue decimal(18,2), AsOfDate date NOT NULL, RiskLevel varchar(15), AlertStatus varchar(25) NOT NULL DEFAULT 'New', CONSTRAINT UQ_Alert UNIQUE(RuleID,MemberID,EvidenceReference,AsOfDate));
CREATE TABLE dbo.FactInvestigation (InvestigationID int IDENTITY(1,1) PRIMARY KEY, AlertID int NOT NULL UNIQUE REFERENCES dbo.FactComplianceAlert(AlertID), OpenDate date NOT NULL, DueDate date NOT NULL, CloseDate date NULL, AssignedTeam varchar(40), CaseStatus varchar(25), Disposition varchar(35), RootCause varchar(80), Notes varchar(500));
CREATE INDEX IX_Reservation_MemberDate ON dbo.FactReservation(MemberID,BookingDate);
CREATE INDEX IX_Ledger_MemberDate ON dbo.FactPointsLedger(MemberID,TransactionDate);
