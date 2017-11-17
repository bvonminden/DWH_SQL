USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_HealthHabits]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of HealthHabits data where the SiteID from Health_Habits_Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. In addition, joining condition need to be changed. Use [CL_EN_GEN_ID] instead of [CLIENT_0_ID_NSO]
--              to join [dbo].[Clients] table.
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_HealthHabits]
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
      ,s.[CLIENT_SUBSTANCE_CIG_1_PRE_PREG]
      ,s.[CLIENT_SUBSTANCE_CIG_0_DURING_PREG]
      ,s.[CLIENT_SUBSTANCE_CIG_1_LAST_48]
      ,s.[CLIENT_SUBSTANCE_ALCOHOL_0_14DAY]
      ,s.[CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS]
      ,s.[CLIENT_SUBSTANCE_POT_0_14DAYS]
      ,s.[CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS]
      ,s.[CLIENT_SUBSTANCE_COCAINE_0_14DAY]
      ,s.[CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES]
      ,s.[CLIENT_SUBSTANCE_OTHER_0_14DAY]
      ,s.[CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES]
      ,s.[NURSE_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_0_ID_AGENCY]
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,s.[CLIENT_SUBSTANCE_NICOTINE_0_OTHER_TYPES]
      ,s.[CLIENT_SUBSTANCE_NICOTINE_0_OTHER]
      ,s.[Master_SurveyID] 
	FROM dbo.[Health_Habits_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.CL_EN_GEN_ID
	WHERE s.SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0
   
END

GO
