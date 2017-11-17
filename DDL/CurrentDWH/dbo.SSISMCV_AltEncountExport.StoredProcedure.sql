USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCV_AltEncountExport]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of Alternative Encounter data where the SiteID from Alternative_Encounter_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCV_AltEncountExport]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [SurveyResponseID]
		  ,[ElementsProcessed]
		  ,[SurveyID]
		  ,[SurveyDate]
		  ,[AuditDate]
		  ,[CL_EN_GEN_ID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,[ClientID]
		  ,[RespondentID]
		  ,[CLIENT_0_ID_NSO]
		  ,[CLIENT_PERSONAL_0_NAME_FIRST]
		  ,[CLIENT_PERSONAL_0_NAME_LAST]
		  ,[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,[CLIENT_TIME_0_START_ALT]
		  ,[CLIENT_TIME_1_END_ALT]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,[CLIENT_TALKED_0_WITH_ALT]
		  ,[CLIENT_TALKED_1_WITH_OTHER_ALT]
		  ,[CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT]
		  ,[CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT]
		  ,[CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT]
		  ,[CLIENT_DOMAIN_0_ENVIRONHLTH_ALT]
		  ,[CLIENT_DOMAIN_0_LIFECOURSE_ALT]
		  ,[CLIENT_DOMAIN_0_MATERNAL_ALT]
		  ,[CLIENT_DOMAIN_0_FRNDFAM_ALT]
		  ,[CLIENT_DOMAIN_0_TOTAL_ALT]
		  ,REPLACE(REPLACE(REPLACE([CLIENT_ALT_0_COMMENTS_ALT], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_ALT_0_COMMENTS_ALT]
		  ,[CLIENT_TIME_1_DURATION_ALT]
		  ,[CLIENT_0_ID_AGENCY]
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
	 WHERE CL_EN_GEN_ID IN (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
							 where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
	   AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
  
END

GO
