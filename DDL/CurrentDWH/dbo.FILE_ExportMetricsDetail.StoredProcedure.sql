USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[FILE_ExportMetricsDetail]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Michael Osborn
-- Create date: 03/10/2015
-- Description:	From given ExportProfileID record counts for each export text file is given as well as site counts
-- =============================================
CREATE PROCEDURE [dbo].[FILE_ExportMetricsDetail]
	@SiteID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
DECLARE @ExportDetail AS Table
(
	[SiteID] INT,
	[AgencyName] NVARCHAR(200),
	[SurveyTable] NVARCHAR(200),
	[RecordCount] INT,
	[ExportDT] 	DATETIME
)

--Declare @SiteID INT
--Declare @FileName NVARCHAR(100)
Declare @TableName NVARCHAR(100)
Declare @sql NVARCHAR(1000)

DECLARE @ExportDT DATETIME



SET @ExportDT = GETDATE()
--Set @SiteID = 229 --Tesing

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'Teams' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].dbo.Teams AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.Site_ID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
;With CTE
AS
(	
	Select distinct
		   [etosolaris].[dbo].fngetsiteid(SU.auditstaffid) as SiteID
		  ,SU.surveyid
		  ,SU.SurveyName 
	from [etosolaris].[dbo].[Surveys] SU
	JOIN [etosolaris].[dbo].SurveyElements SE ON SU.SurveyID = SE.SurveyID
	LEFT JOIN [etosolaris].[dbo].SurveyElementChoices SEC ON SE.SurveyElementID = SEC.SurveyElementID
	JOIN [etosolaris].[dbo].SurveyElementTypes SUET ON SUET.SurveyElementTypeID = SE.SurveyElementTypeID
	Where [etosolaris].[dbo].fngetsiteid(SU.auditstaffid) in (@SiteID)
)
INSERT INTO @ExportDetail
SELECT SiteID, AGENCY_INFO_0_NAME,'SurveyIDs' AS SurveyTable, Count(*)[Count],  GETDATE() from CTE
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = SiteID
GROUP BY SiteID, AGENCY_INFO_0_NAME;

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Star_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].dbo.[Star_Survey] Star
INNER JOIN dbo.ProgramsAndSites PnS on PnS.ProgramID = Star.ProgramID
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = PnS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************

;With CTE
AS
(	
	SELECT 
		 DISTINCT EntityID,
		  StaffXEntityID,
		  AG.AGENCY_INFO_0_NAME,
		  dbo.StaffxClientHx.StaffID,
		  TargetSiteID,
		  dbo.StaffxClientHx.AuditDate,
		  cast(dbo.StaffxClientHx.DataSource as varchar) AS 'DataSource'
	FROM dbo.StaffXEntities 
	INNER JOIN dbo.StaffxClientHx ON dbo.StaffXEntities.StaffID = dbo.StaffxClientHx.StaffID
	INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = TargetSiteID
	WHERE dbo.StaffxClientHx.ProgramID IN(SELECT ProgramID FROM dbo.ProgramsAndSites WHERE (SiteID IN (@siteid)))
)
INSERT INTO @ExportDetail
SELECT TargetSiteID, AGENCY_INFO_0_NAME, 'StaffXEntities' AS SurveyTable, Count(*)[Count],  GETDATE() from CTE
GROUP BY TargetSiteID, AGENCY_INFO_0_NAME;

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'StaffxClient' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].dbo.[StaffxClient] SXC
INNER JOIN dbo.ProgramsAndSites PnS on PnS.ProgramID = SXC.ProgramID
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = PnS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'StaffxClientHx' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[StaffxClientHx] SCHX
INNER JOIN dbo.ProgramsAndSites PnS on PnS.ProgramID = SCHX.ProgramID
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = PnS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'Staff_Update_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].dbo.Staff_Update_Survey SUS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = SUS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'Programs' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Programs] PRG
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = PRG.Site_ID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'IA_Staff' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].IA_Staff AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.Site_ID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AGS.Site_ID, AGS.AGENCY_INFO_0_NAME,'EntityXProgramHx' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].dbo.EntityXProgramHx AS AG
INNER JOIN ProgramsAndSites PAG on PAG.ProgramID = AG.ProgramID AND PAG.SiteID = @SiteID
INNER JOIN Agencies AGS on AGS.Site_ID = PAG.SiteID
Group By AGS.Site_ID, AGS.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Agencies' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Agencies] AS AG
WHERE AG.Site_ID = @SiteID
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Team_Meetings_Conf_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].dbo.Team_Meetings_Conf_Survey AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'Star_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].dbo.Star_Survey AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'JVO_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].dbo.JVO_Survey AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'GAD7_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[GAD7_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'.Course_Completion_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Course_Completion_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'Client_Funding_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Client_Funding_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************


INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Agency_Profile_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Agency_Profile_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Alternative_Encounter_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'ASQ3_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[ASQ3_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Client_Discharge_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Client_Discharge_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Client_Funding_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Client_Funding_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Clients' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Clients] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.Site_ID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Course_Completion_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Course_Completion_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 

Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'DANCE_survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[DANCE_survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'Demographics_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Demographics_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'Edinburgh_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Edinburgh_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Education_Registration_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Education_Registration_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'EnrollmentAndDismissal' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[EnrollmentAndDismissal] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Govt_Comm_Srvcs_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Govt_Comm_Srvcs_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'Health_Habits_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Health_Habits_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'Home_Visit_Encounter_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Home_Visit_Encounter_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'Infant_Birth_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Infant_Birth_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail 
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'Infant_Health_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Infant_Health_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail 
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'Maternal_Health_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Maternal_Health_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'New_Hire_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[New_Hire_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME    

--****************************************************************************************************************************************
INSERT INTO @ExportDetail 
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME, 'PHQ_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[PHQ_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail 
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'ProgramsAndSites' AS SurveyTable, Count(*)[Count], @ExportDT
FROM dbo.ProgramsAndSites AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Referrals_to_NFP_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Referrals_to_NFP_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME   

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Referrals_to_Services_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Referrals_to_Services_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME 

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Relationship_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Relationship_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT AG.Site_ID, AG.AGENCY_INFO_0_NAME,'Weekly_Supervision_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Weekly_Supervision_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.Agencies AG on AG.Site_ID = APS.SiteID AND AG.Site_ID = @SiteID 
Group By AG.Site_ID, AG.AGENCY_INFO_0_NAME

SELECT
[SiteID],
[AgencyName],
[SurveyTable],
[RecordCount],
[ExportDT]
FROM @ExportDetail
ORDER BY [SurveyTable]

END




GO
