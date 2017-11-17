USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISSA_AltEncountExport]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of AgencyProfile data where the SiteID from Agency_Profile_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified Date: 11/30/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISSA_AltEncountExport]
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT [SurveyResponseID]
		  ,[ElementsProcessed]
		  ,[SurveyID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[SurveyDate])) AS [SurveyDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[AuditDate])) AS [AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
		  ,[RespondentID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_DOB_INTAKE])) AS [CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,[CLIENT_TIME_0_START_ALT]
		  ,[CLIENT_TIME_1_END_ALT]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_TALKED_0_WITH_ALT])) AS [CLIENT_TALKED_0_WITH_ALT]
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
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[DW_AuditDate])) AS [DW_AuditDate]
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
	WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
  
END
GO
