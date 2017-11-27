create procedure [survey_views].usp_etl_select_ ExportDetail  
(
 @p_export_profile_id int,
  @p_entity_filter char(5)=null
)
as
begin

declare  @_hash_profile   char(10);
set   @_hash_profile   = (select top 1 isnull('SA',hash_policy) from survey_views.f_get_survey_etl_work() where ExportProfileID=@p_export_profile_id);

--print  @p_export_profile_id;
--print  @_hash_profile;


select 

vbase. ExportProfileID,
vbase.ProfileName,
vbase.SiteID,
vbase.AgencyName,
vbase.FileName,
vbase.SurveyTable,
vbase.RecordCount,
vbase.ExportDT,

from survey_views.f_select_ ExportDetail (@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


ALTER PROCEDURE [dbo].[SSIS_ExportMetricsDetail]
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;
	
DECLARE @ExportDetail AS Table
(
	[ExportProfileID] INT,
	[ProfileName] NVARCHAR(200),
	[SiteID] INT,
	[AgencyName] NVARCHAR(200),
	[FileName] NVARCHAR(200),
	[SurveyTable] NVARCHAR(200),
	[RecordCount] INT,
	[ExportDT] 	DATETIME
)

--Declare @ProfileID INT
Declare @FileName NVARCHAR(100)
Declare @TableName NVARCHAR(100)
Declare @sql NVARCHAR(1000)
DECLARE @ExportDT DATETIME



SET @ExportDT = GETDATE()
--Set @ProfileID = 34 --Tesing


--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Agency_Profile.txt' AS [FileName], 'Agency_Profile_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Agency_Profile_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Alternative_Encounter.txt' AS [FileName], 'Alternative_Encounter_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'ASQ3.txt' AS [FileName], 'ASQ3_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[ASQ3_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT Distinct EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'CaseLoad.txt' AS [FileName], 'CaseLoad' AS SurveyTable, Count(*)[Count], @ExportDT
FROM      dbo.StaffXEntities  
INNER JOIN dbo.StaffxClientHx ON dbo.StaffXEntities.StaffID = dbo.StaffxClientHx.StaffID
INNER JOIN dbo.ProgramsAndSites PAS on PAS.ProgramID = StaffxClientHx.ProgramID
INNER JOIN dbo.ExportEntities EE on EE.SiteID = PAS.SiteID AND EE.ExportProfileID = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE dbo.StaffxClientHx.CLID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients)
Group By EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Client_Discharge.txt' AS [FileName], 'Client_Discharge_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Client_Discharge_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Client_Funding.txt' AS [FileName], 'Client_Funding_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Client_Funding_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Participants_and_Referrals.txt' AS [FileName], 'Clients' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Clients] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.Site_ID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.Client_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.Site_ID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Course_Completion.txt' AS [FileName], 'Course_Completion_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Course_Completion_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Dance.txt' AS [FileName], 'DANCE_survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[DANCE_survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Demographics.txt' AS [FileName], 'Demographics_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Demographics_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Edinburgh.txt' AS [FileName], 'Edinburgh_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Edinburgh_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Education_Registration.txt' AS [FileName], 'Education_Registration_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Education_Registration_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'EnrollmentsAndDismissals.txt' AS [FileName], 'EnrollmentAndDismissal' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[EnrollmentAndDismissal] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CLID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Govt_Comm_Srvcs.txt' AS [FileName], 'Govt_Comm_Srvcs_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Govt_Comm_Srvcs_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Health_Habits.txt' AS [FileName], 'Health_Habits_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Health_Habits_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Home_Visit_Encounter.txt' AS [FileName], 'Home_Visit_Encounter_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Home_Visit_Encounter_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]
 
--****************************************************************************************************************************************
INSERT INTO @ExportDetail       
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Staff.txt' AS [FileName], 'IA_Staff' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[IA_Staff] IA
INNER JOIN ExportEntities EE on EE.SiteID = IA.Site_ID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0  AND ISNULL(ExportDisabled,0) != 1 AND IA.Entity_Subtype like '%nur%' 
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]
 
--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Infant_Birth.txt' AS [FileName], 'Infant_Birth_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Infant_Birth_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]
 
--****************************************************************************************************************************************
INSERT INTO @ExportDetail 
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Infant_Health.txt' AS [FileName], 'Infant_Health_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Infant_Health_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail 
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Maternal_Health.txt' AS [FileName], 'Maternal_Health_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Maternal_Health_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
 INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'New_Hire.txt' AS [FileName], 'New_Hire_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[New_Hire_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]    

--****************************************************************************************************************************************
INSERT INTO @ExportDetail 
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'PHQ-9.txt' AS [FileName], 'PHQ_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[PHQ_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail 
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'ProgramsAndSites.txt' AS [FileName], 'ProgramsAndSites' AS SurveyTable, Count(*)[Count], @ExportDT
FROM dbo.ProgramsAndSites AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Referrals_To_NFP.txt' AS [FileName], 'Referrals_to_NFP_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Referrals_to_NFP_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]   

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Referrals_To_Services.txt' AS [FileName], 'Referrals_to_Services_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Referrals_to_Services_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName] 

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Relationships.txt' AS [FileName], 'Relationship_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Relationship_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
WHERE APS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = APS.SiteID)
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'Staff_Update.txt' AS [FileName], 'Staff_Update_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Staff_Update_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

--****************************************************************************************************************************************
INSERT INTO @ExportDetail
SELECT EP.[ExportProfileID], EP.[ProfileName], EE.SiteID, EE.AgencyName,'WeeklySupervision.txt' AS [FileName], 'Weekly_Supervision_Survey' AS SurveyTable, Count(*)[Count], @ExportDT
FROM [DataWarehouse].[dbo].[Weekly_Supervision_Survey] AS APS
INNER JOIN [DataWarehouse].dbo.ExportEntities EE on EE.SiteID = APS.SiteID AND EE.[ExportProfileID] = @ProfileID AND EE.ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1
INNER JOIN [DataWarehouse].dbo.ExportProfile EP on EP.ExportProfileID = EE.[ExportProfileID]
Group by EE.AgencyName, EE.SiteID, EP.[ExportProfileID], EP.[ProfileName]

SELECT
	[ExportProfileID],
	[ProfileName],
	[SiteID],
	[AgencyName],
	[FileName],
	[SurveyTable],
	[RecordCount],
	[ExportDT]
FROM @ExportDetail
ORDER BY SiteID, ProfileName	

END
