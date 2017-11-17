USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_AltEncountExport_CombinedTypes]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sheri Scott
-- Create date: 04/25/2016
-- Description:	Extract of Alternative Encounter Survey data where the Site ID is in the
--				Site IDs for the passed @ProfileID.
--				@ProfileID is ExportProfileID in ExportEntities and ExportProfile.  The Site IDs are in ExportEntities.
--				@ExportTypeID is ExportTypeID in ExportProfile.  The Export Types are in the ExportTypes table. 
--				and Export
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_AltEncountExport_CombinedTypes]
	@ProfileID INT,
	@ExportTypeID INT
AS
BEGIN
	
	SET NOCOUNT ON;

	-- Non-MIECHV BAA
	IF @ExportTypeID IN (0,4)
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
			  ,[CLIENT_ALT_0_COMMENTS_ALT]
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
		  FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey]
		 WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
		   AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	
		-- Non-MIECHV DUA
		IF @ExportTypeID IN (1,5)
		  SELECT [SurveyResponseID]
				,[ElementsProcessed]
				,[SurveyID]
				,[SurveyDate]
				,[AuditDate]
				,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
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
			FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey]
		   WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
			 AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)

		-- Non-MIECHV SA
		IF @ExportTypeID IN (6,8)
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
			  FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey]
			 WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)
			   AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)

		-- MIECHV BAA
		IF @ExportTypeID = 2
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
				  ,[CLIENT_ALT_0_COMMENTS_ALT]
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
			  FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey]
			 WHERE CL_EN_GEN_ID IN (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
									 where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID))
			   AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)

		-- MIECHV DUA
		IF @ExportTypeID = 3
			SELECT [SurveyResponseID]
				  ,[ElementsProcessed]
				  ,[SurveyID]
				  ,[SurveyDate]
				  ,[AuditDate]
				  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
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
			 FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey]
			WHERE CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
								   where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID))
			  AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)

		-- MIECHV SA
		IF @ExportTypeID = 7
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
			 FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey]
			WHERE CL_EN_GEN_ID IN (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
								    where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID))
			  AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
  
END
GO
