USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_AltEncountExport]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Create date: 1/11/2016
-- Description:	Extract Alternative Encounter Survey data where the SiteID from the Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. In addition, joining condition need to be changed. Use [CL_EN_GEN_ID] instead of [CLIENT_0_ID_NSO]
--              to join [dbo].[Clients] table.
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_AltEncountExport]
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;

  SELECT s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,s.[ClientID]
      ,s.[RespondentID]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[CLIENT_TIME_0_START_ALT]
      ,s.[CLIENT_TIME_1_END_ALT]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_TALKED_0_WITH_ALT]
      ,s.[CLIENT_TALKED_1_WITH_OTHER_ALT]
      ,s.[CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT]
      ,s.[CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT]
      ,s.[CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT]
      ,s.[CLIENT_DOMAIN_0_ENVIRONHLTH_ALT]
      ,s.[CLIENT_DOMAIN_0_LIFECOURSE_ALT]
      ,s.[CLIENT_DOMAIN_0_MATERNAL_ALT]
      ,s.[CLIENT_DOMAIN_0_FRNDFAM_ALT]
      ,s.[CLIENT_DOMAIN_0_TOTAL_ALT]
      ,REPLACE(REPLACE(REPLACE(s.[CLIENT_ALT_0_COMMENTS_ALT], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_ALT_0_COMMENTS_ALT]
      ,s.[CLIENT_TIME_1_DURATION_ALT]
      ,s.[CLIENT_0_ID_AGENCY]
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
  ON c.Client_Id = s.[CL_EN_GEN_ID]
  WHERE s.SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID)
  --AND c.PFS_STUDY_VULNERABLE_POP = 0
  
END

GO
