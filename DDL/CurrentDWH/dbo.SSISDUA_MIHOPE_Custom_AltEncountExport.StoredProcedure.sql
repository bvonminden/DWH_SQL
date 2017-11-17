USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_MIHOPE_Custom_AltEncountExport]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Jingjing Gao
-- Create date: 03/09/2017
-- Description:	Custom extract of HomeEncounter data where the SiteID from [Alternative_Encounter_Survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID. 
-- Export Requirements:
-- 1)	De-identified data for customer
-- 2)	Provide the same data set with identifiable data on the S drive for the NSO
-- 3)	Join with MIHOPE provided table to provide the MIHOPE ID with the corresponding NSO ID (which will be hashed)
-- 4)	We need to provide a table so they can cross reference EntityID with Nurse Name 
-- 5)	Parameter on the export – no SurveyDates or ProgramStartDates after 12/31/2016
-- 6)	Parameter on the export – only data from the following siteIDs and only data for the provided CLID/CL_EN_GENs/ClientId (SiteIDs: 289, 179, 185, 103, 163, 212, 251, 287)
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_MIHOPE_Custom_AltEncountExport]
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT [SurveyResponseID]
		  ,[ElementsProcessed]
		  ,[SurveyID]
		  ,[SurveyDate]
		  ,[AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,[StudyID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
		  ,[RespondentID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,[CLIENT_TIME_0_START_ALT]
		  ,[CLIENT_TIME_1_END_ALT]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,[CLIENT_TALKED_0_WITH_ALT]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_TALKED_1_WITH_OTHER_ALT])) AS [CLIENT_TALKED_1_WITH_OTHER_ALT]
		  ,[CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT])) AS [CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT]
		  ,[CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT]
		  ,[CLIENT_DOMAIN_0_ENVIRONHLTH_ALT]
		  ,[CLIENT_DOMAIN_0_LIFECOURSE_ALT]
		  ,[CLIENT_DOMAIN_0_MATERNAL_ALT]
		  ,[CLIENT_DOMAIN_0_FRNDFAM_ALT]
		  ,[CLIENT_DOMAIN_0_TOTAL_ALT]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_ALT_0_COMMENTS_ALT])) AS [CLIENT_ALT_0_COMMENTS_ALT]
		  ,[CLIENT_TIME_1_DURATION_ALT]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[CLIENT_NO_REFERRAL]
		  ,[CLIENT_SCREENED_SRVCS]
		  ,[CLIENT_VISIT_SCHEDULE]
		  ,[Master_SurveyID]
		  ,[temp_time_start]
		  ,[temp_time_end]
		  ,[CLIENT_TIME_FROM_AMPM_ALT]
		  ,[CLIENT_TIME_FROM_HR_ALT]
		  ,[CLIENT_TIME_FROM_MIN_ALT]
		  ,[CLIENT_TIME_TO_AMPM_ALT]
		  ,[CLIENT_TIME_TO_HR_ALT]
		  ,[CLIENT_TIME_TO_MIN_ALT]
		  ,[Old_CLIENT_TIME_0_START_ALT]
		  ,[Old_CLIENT_TIME_1_END_ALT]
		  ,[old_CLIENT_TIME_1_DURATION_ALT]
		  ,[temp_DURATION]
	 FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey] s
	INNER JOIN [DataWarehouse].[dbo].[MIHOPE_Custom_Extract_Clients] m
  ON s.CL_EN_GEN_ID = m.Clientid_NFP
	 WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	   AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
	   AND CL_EN_GEN_ID IN (SELECT [Clientid_NFP] FROM [DataWarehouse].[dbo].[MIHOPE_Custom_Extract_Clients])
	  AND [SurveyDate] < '20170101'
	  ORDER BY SurveyDate
END

GO
