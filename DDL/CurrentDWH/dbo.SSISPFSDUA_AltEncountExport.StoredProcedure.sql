USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_AltEncountExport]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of AgencyProfile data where the SiteID from Agency_Profile_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_AltEncountExport]
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT s.[SurveyResponseID]
		  ,s.[ElementsProcessed]
		  ,s.[SurveyID]
		  ,s.[SurveyDate]
		  ,s.[AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,s.[SiteID]
		  ,s.[ProgramID]
		  ,s.[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[ClientID])) AS [ClientID]
		  ,s.[RespondentID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,s.[CLIENT_TIME_0_START_ALT]
		  ,s.[CLIENT_TIME_1_END_ALT]
		  ,s.[NURSE_PERSONAL_0_NAME]
		  ,s.[CLIENT_TALKED_0_WITH_ALT]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_TALKED_1_WITH_OTHER_ALT])) AS [CLIENT_TALKED_1_WITH_OTHER_ALT]
		  ,s.[CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT])) AS [CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT]
		  ,s.[CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT]
		  ,s.[CLIENT_DOMAIN_0_ENVIRONHLTH_ALT]
		  ,s.[CLIENT_DOMAIN_0_LIFECOURSE_ALT]
		  ,s.[CLIENT_DOMAIN_0_MATERNAL_ALT]
		  ,s.[CLIENT_DOMAIN_0_FRNDFAM_ALT]
		  ,s.[CLIENT_DOMAIN_0_TOTAL_ALT]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_ALT_0_COMMENTS_ALT])) AS [CLIENT_ALT_0_COMMENTS_ALT]
		  ,s.[CLIENT_TIME_1_DURATION_ALT]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
		  ,s.[DW_AuditDate]
		  ,s.[DataSource]
		  ,s.[CLIENT_NO_REFERRAL]
		  ,s.[CLIENT_SCREENED_SRVCS]
		  ,s.[CLIENT_VISIT_SCHEDULE]
		  ,s.[Master_SurveyID]
		  ,s.[temp_time_start]
		  ,s.[temp_time_end]
		  ,s.[CLIENT_TIME_FROM_AMPM_ALT]
		  ,s.[CLIENT_TIME_FROM_HR_ALT]
		  ,s.[CLIENT_TIME_FROM_MIN_ALT]
		  ,s.[CLIENT_TIME_TO_AMPM_ALT]
		  ,s.[CLIENT_TIME_TO_HR_ALT]
		  ,s.[CLIENT_TIME_TO_MIN_ALT]
		  ,s.[Old_CLIENT_TIME_0_START_ALT]
		  ,s.[Old_CLIENT_TIME_1_END_ALT]
		  ,s.[old_CLIENT_TIME_1_DURATION_ALT]
		  ,s.[temp_DURATION]
		  ,s.[LastModified]
  FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey] s
  INNER JOIN dbo.Clients c
  ON c.Client_Id = s.CLIENT_0_ID_NSO
  WHERE s.SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID)
  AND c.PFS_STUDY_VULNERABLE_POP = 0
  
END
GO
