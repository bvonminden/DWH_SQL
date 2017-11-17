USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_ExportMetricsSummary]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Create date: 1/13/2016
-- Description:	From given ExportProfileID record counts for each export text file is given as well as site counts
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_ExportMetricsSummary]
	@ProfileID INT
AS
BEGIN

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
SET @TotalSites = (SELECT Count(*) FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID)
SET @SitesSearched = (SELECT Count(*) FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
SET @SitesExcluded = (SELECT Count(*) FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 1)

--****************************************************************************************************************************************
SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Agency_Profile_Survey]
WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Agency_Profile.txt', Count(*),@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Agency_Profile_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Alternative_Encounter.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[ASQ3_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'ASQ3.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[ASQ3_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (SELECT count(Distinct PRO.SiteID)
FROM dbo.StaffXEntities 
INNER JOIN dbo.StaffxClientHx ON dbo.StaffXEntities.StaffID = dbo.StaffxClientHx.StaffID
INNER JOIN dbo.ProgramsAndSites PRO on PRO.ProgramID = dbo.StaffxClientHx.ProgramID
WHERE PRO.SiteID  in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

SET @RCount  = (SELECT DISTINCT Count(*) 
FROM dbo.StaffXEntities 
INNER JOIN dbo.StaffxClientHx ON dbo.StaffXEntities.StaffID = dbo.StaffxClientHx.StaffID
WHERE PROGRAMID in (select programid from ProgramsAndSites where SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)))
INSERT INTO @Data
Values(@ProfileID, @ProfileName, 'CaseLoad.txt', @RCount,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Client_Discharge_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Client_Discharge.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Client_Discharge_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Client_Funding_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Client_Funding.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Client_Funding_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct Site_ID) FROM [DataWarehouse].[dbo].[Clients]
WHERE Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Participants_and_Referrals.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Clients]
WHERE
	Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Course_Completion_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Course_Completion.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Course_Completion_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[DANCE_survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Dance.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[DANCE_survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************	

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Demographics_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Demographics.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Demographics_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Edinburgh_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Edinburgh.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Edinburgh_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Education_Registration_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Education_Registration.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Education_Registration_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)	
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[EnrollmentAndDismissal]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'EnrollmentsAndDismissals.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[EnrollmentAndDismissal]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Govt_Comm_Srvcs_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Govt_Comm_Srvcs.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Govt_Comm_Srvcs_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Health_Habits_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Health_Habits.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Health_Habits_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Home_Visit_Encounter_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))
	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Home_Visit_Encounter.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Home_Visit_Encounter_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (SELECT count(distinct Site_ID)
FROM [DataWarehouse].[dbo].[IA_Staff]
WHERE 
	   Entity_Subtype like '%nur%' 
       AND Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))
       	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Staff.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[IA_Staff]
WHERE 
	   Entity_Subtype like '%nur%' 
       AND Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Infant_Birth_Survey]

WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))	
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Infant_Birth.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Infant_Birth_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)			
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Infant_Health_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))
						
INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Infant_Health.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Infant_Health_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)		
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Maternal_Health_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Maternal_Health.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Maternal_Health_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)	
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[New_Hire_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'New_Hire.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[New_Hire_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)	
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[PHQ_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'PHQ-9.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[PHQ_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)	
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].ProgramsAndSites
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'ProgramsAndSites.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM dbo.ProgramsAndSites
WHERE
SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Referrals_to_NFP_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Referrals_To_NFP.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Referrals_to_NFP_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)	
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Referrals_to_Services_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Referrals_To_Services.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Referrals_to_Services_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)	
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Relationship_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Relationships.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Relationship_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)	
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Staff_Update_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'Staff_Update.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Staff_Update_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)	
--****************************************************************************************************************************************

SET @SitesFound = (Select count(Distinct SiteID) FROM [DataWarehouse].[dbo].[Weekly_Supervision_Survey]
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0))

INSERT INTO @Data
SELECT @ProfileID, @ProfileName, 'WeeklySupervision.txt', Count(*) ,@TotalSites, @SitesSearched, @SitesExcluded, @SitesFound, @ExportDT
FROM [DataWarehouse].[dbo].[Weekly_Supervision_Survey]
WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)	
				
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
