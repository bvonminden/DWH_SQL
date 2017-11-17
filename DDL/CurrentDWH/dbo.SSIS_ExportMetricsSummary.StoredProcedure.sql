USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_ExportMetricsSummary]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 03/10/2015
-- Description:	From given ExportProfileID record counts for each export text file is given as well as site counts
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_ExportMetricsSummary]
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
DECLARE @Data TABLE
(
    ProfileID INT,
    ProfileName NVARCHAR(200),--from varchar
	[FileName] NVARCHAR(200),--from varchar
	RecordCount INT,
	TotalSites INT,
	SitesSearched INT,
	SitesExcluded INT,
	SitesFound INT,
	ExportDT DateTime
)

DECLARE @ProfileName VARCHAR(200)--from varchar
DECLARE @RCount INT
DECLARE @TotalSites INT
DECLARE @SitesSearched INT
DECLARE @SitesFound INT
DECLARE @SitesExcluded INT
--DECLARE @ProfileID INT --Testing
DECLARE @ExportDT DATETIME

--SET @ProfileID = 23 --Testing

SET @ExportDT = GETDATE()
SET @ProfileName = (SELECT ProfileName FROM [DataWarehouse].dbo.ExportProfile WHERE ExportProfileID = @ProfileID)
SET @TotalSites = (SELECT Count(*) FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1)
SET @SitesSearched = (SELECT Count(*) FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
SET @SitesExcluded = (SELECT Count(*) FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 1 AND ISNULL(ExportDisabled,0) != 1)

--****************************************************************************************************************************************
SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Agency_Profile_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Agency_Profile.txt', Count(*),@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Agency_Profile_Survey]
WHERE
	SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Alternative_Encounter.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey] s
WHERE
	SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[ASQ3_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'ASQ3.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[ASQ3_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (SELECT count(Distinct PRO.SiteID)
FROM dbo.StaffXEntities 
INNER JOIN dbo.StaffxClientHx ON dbo.StaffXEntities.StaffID = dbo.StaffxClientHx.StaffID
INNER JOIN dbo.ProgramsAndSites PRO on PRO.ProgramID = dbo.StaffxClientHx.ProgramID
WHERE PRO.SiteID  in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

SET @RCount  = (SELECT DISTINCT Count(*) 
FROM dbo.StaffXEntities 
INNER JOIN dbo.StaffxClientHx ON dbo.StaffXEntities.StaffID = dbo.StaffxClientHx.StaffID
WHERE PROGRAMID in (select programid from ProgramsAndSites where SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
AND dbo.StaffxClientHx.CLID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients))

INSERT INTO @Data
Values(@ProfileID, @ProfileName, 'CaseLoad.txt', @RCount,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Client_Discharge_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Client_Discharge.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Client_Discharge_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Client_Funding_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Client_Funding.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Client_Funding_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct Site_ID) FROM [DataWarehouse].[dbo].[Clients]
WHERE Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Participants_and_Referrals.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Clients] c
WHERE
	Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND c.Client_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = c.Site_ID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Course_Completion_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Course_Completion.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Course_Completion_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[DANCE_survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Dance.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[DANCE_survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************	

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Demographics_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Demographics.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Demographics_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Edinburgh_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Edinburgh.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Edinburgh_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Education_Registration_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Education_Registration.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Education_Registration_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)	
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[EnrollmentAndDismissal]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'EnrollmentsAndDismissals.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[EnrollmentAndDismissal] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND s.CLID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Govt_Comm_Srvcs_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Govt_Comm_Srvcs.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Govt_Comm_Srvcs_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Health_Habits_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Health_Habits.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Health_Habits_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Home_Visit_Encounter_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Home_Visit_Encounter.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Home_Visit_Encounter_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (SELECT count(distinct Site_ID)
FROM [DataWarehouse].[dbo].[IA_Staff]
WHERE 
	   Entity_Subtype like '%nur%' 
       AND Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
       	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Staff.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[IA_Staff]
WHERE 
	   Entity_Subtype like '%nur%' 
       AND Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Infant_Birth_Survey]

WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Infant_Birth.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Infant_Birth_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)			
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Infant_Health_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
						
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Infant_Health.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Infant_Health_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)		
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Maternal_Health_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Maternal_Health.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Maternal_Health_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)	
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[New_Hire_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'New_Hire.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[New_Hire_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)	
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[PHQ_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'PHQ-9.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[PHQ_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)	
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].ProgramsAndSites
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'ProgramsAndSites.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM dbo.ProgramsAndSites
WHERE
SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Referrals_to_NFP_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Referrals_To_NFP.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Referrals_to_NFP_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)	
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Referrals_to_Services_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Referrals_To_Services.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Referrals_to_Services_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)	
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Relationship_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Relationships.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Relationship_Survey] s
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)	
AND s.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Staff_Update_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Staff_Update.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Staff_Update_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)	
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Weekly_Supervision_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'WeeklySupervision.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Weekly_Supervision_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)	
				
SELECT
	ProfileID,
	ProfileName,
	[FileName],
	RecordCount,
	TotalSites,
	SitesSearched,
	SitesExcluded,
	SitesFound,
	ExportDT
FROM @Data
Order by ProfileID, ProfileName, [FileName]
END

GO
