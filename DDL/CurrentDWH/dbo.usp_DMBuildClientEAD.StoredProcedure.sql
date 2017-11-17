USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_DMBuildClientEAD]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 11/5/2015
-- Description:	Creates the temp table ##ClientEAD and populates it with client level date from enrollments and dissmissals.
--              The client level data is referrels and home visits.
--              It also connects a client to a nurseid.
-- =============================================
CREATE PROCEDURE [dbo].[usp_DMBuildClientEAD]
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF OBJECT_ID('tempdb..##ClientEAD') IS NOT NULL
    DROP TABLE ##ClientEAD
    
CREATE Table ##CLientEAD
(
    EADRecordID INT,
	ClientID INT,
	CaseNumber INT,
	NurseID INT,
	ClientFirstName VARCHAR(50),
	ClientLastName VARCHAR(50),
	ClientDOB DATE,
	NurseFirstName VARCHAR(50),
	NurseLastName VARCHAR(50),
	SXStaffID INT,
	ProgramID INT,
	SiteID INT,
	ProgramType VARCHAR(50),
	ProgramTypeID INT,
	Agency VARCHAR(50),
	Team VARCHAR(50),
	[State] VARCHAR(2),
	ProgramStartDate DATE,
	ProgramEndDate DATE,
	SXStartDate DATE,
	SXEndDate DATE,
	NurseStartDate DATE,
	ReasonForDismissal VARCHAR(100),
	AuditStaffID INT
)

INSERT INTO ##CLientEAD
--Load Referral and Intake section
Select 
     EAD.RecID       --RecordID PK
	,EAD.CLID        --ClientID FK
	,EAD.CaseNumber  --CaseNumber FK
	,NULL            --NurseID
	,CL.First_Name   --ClientFirstName
	,CL.Last_Name    --ClientLastName
	,CL.DOB          --Date of birth for client
	,NULL            --NurseFirstName
	,NULL            --NurseLastName
	,NULL            --StaffXStaffID
	,EAD.ProgramID   --ProgramID
	,EAD.SiteID      --SiteID
	,'Referral and Intake' --ProgramType
	,1                     --ProgramTypeID
	,PAG.[Site]            --Agency
	,PAG.ProgramName       --Team 
	,AG.[State]            --State (Abbreviation)
	,EAD.ProgramStartDate  --ProgramStartDate (ProgramStartDate from EnrollmentsAndDismissmal)
	,EAD.EndDate           --ProgramEndDate (EndDate from EnrollmentsAndDismissmal)
	,NULL                  --SXStartDate (StartDate from StaffXClientHX)
	,NULL                  --SXEndDate (EndDate from StaffXClientHX)
	,NULL                  --NurseStartDate (Start_Date from IA_Staff)
	,EAD.ReasonForDismissal--ReasonForDismissal
	,EAD.AuditStaffID      --AuditStaffID
from DataWarehouse.dbo.EnrollmentAndDismissal EAD
INNER JOIN DataWarehouse.dbo.ProgramsAndSites PAG on PAG.ProgramID = EAD.ProgramID --Join to get program and site level data
INNER JOIN DataWarehouse.dbo.Agencies AG on AG.Site_ID = PAG.SiteID --Join to get agency level data, state
INNER JOIN DataWarehouse.dbo.Clients CL on CL.Client_Id = EAD.CLID --Join to get client level data, names, etc
WHERE EAD.SiteID NOT IN(65,74,75,76,77,78,79,80,81,82,83,84,85,87,88,89,90,92,93,263,264,266,269,271,272,274,276,285,291,294,317,360,362)
AND EAD.CLID IS NOT NULL
AND PAG.ProgramName LIKE '%Referral and Intake%' 
ORDER BY EAD.CaseNumber, EAD.ProgramStartDate;

--Load Nurse Home Visit section
INSERT INTO ##CLientEAD
Select
     EAD.RecID          --RecordID PK
	,EAD.CLID			--ClientID FK
	,EAD.CaseNumber		--CaseNumber FK
	,SXC.Entity_ID		--NurseID
	,CL.First_Name		--ClientFirstName
	,CL.Last_Name		--ClientLastName
	,CL.DOB             --Client date of birth      
	,IA.First_Name		--NurseFirstName
	,IA.Last_Name		--NurseLastName
	,SXC.StaffID		--StaffXStaffID
	,EAD.ProgramID		--ProgramID
	,EAD.SiteID			--SiteId
	,'Nurse Home Visit' --ProgramType
	,2					--ProgramTypeID
	,PAG.[Site]			--Agency	
	,PAG.ProgramName    --Team  
	,AG.[State]         --State (Abbreviation)
	,EAD.ProgramStartDate --ProgramStartDate (ProgramStartDate from EnrollmentsAndDismissmal)
	,EAD.EndDate          --ProgramEndDate (EndDate from EnrollmentsAndDismissmal)
	,SXC.StartDate SXStartDate --SXStartDate (StartDate from StaffXClientHX)
	,SXC.EndDate SXEndDate --SXEndDate (EndDate from StaffXClientHX)
	,IA.[START_DATE]       --NurseStartDate (Start_Date from IA_Staff)
	,EAD.ReasonForDismissal--ReasonForDismissal 
	,EAD.AuditStaffID      --AuditStaffID
from DataWarehouse.dbo.EnrollmentAndDismissal EAD
INNER JOIN DataWarehouse.dbo.ProgramsAndSites PAG on PAG.ProgramID = EAD.ProgramID --Join to get program and site level data
INNER JOIN DataWarehouse.dbo.Agencies AG on AG.Site_ID = PAG.SiteID --Join to get agency level data, state
INNER JOIN DataWarehouse.dbo.Clients CL on CL.Client_Id = EAD.CLID  --Join to get client level data, names, etc
INNER JOIN DataWarehouse.dbo.StaffxClientHx SXC on SXC.CLID = EAD.CLID  --Join to get link Client to nurse
INNER JOIN DataWarehouse.dbo.IA_Staff IA on IA.Entity_Id = SXC.Entity_ID and IA.Entity_Subtype IN('Nursing Staff','Non-Nursing Staff')--Join to limit nurse type
WHERE EAD.SiteID NOT IN(65,74,75,76,77,78,79,80,81,82,83,84,85,87,88,89,90,92,93,263,264,266,269,271,272,274,276,285,291,294,317,360,362)
AND EAD.CLID IS NOT NULL
AND PAG.ProgramName LIKE '%Nurse Home Visit%'
ORDER BY EAD.CaseNumber, EAD.ProgramStartDate;


SELECT
	EADRecordID
	,ClientID
	,CaseNumber
	,NurseID
	,ClientFirstName
	,ClientLastName
	,ClientDOB
	,NurseFirstName 
	,NurseLastName
	,SXStaffID
	,ProgramID
	,SiteID
	,ProgramType
	,ProgramTypeID
	,Agency
	,Team
	,[State]
	,ProgramStartDate
	,ProgramEndDate
	,SXStartDate
	,SXEndDate
	,NurseStartDate
	,ReasonForDismissal
	,AuditStaffID
FROM ##CLientEAD
ORDER BY CaseNumber,ProgramStartDate

END
GO
