USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_Edinburgh]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Create date: 1/12/2016
-- Description:	Extract of Edinburgh data where the SiteID from Edinburgh_Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. In addition, joining condition need to be changed. Use [CL_EN_GEN_ID] instead of [CLIENT_0_ID_NSO]
--              to join [dbo].[Clients] table.
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_Edinburgh]
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
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[CLIENT_EPDS_1_ABLE_TO_LAUGH]
      ,s.[CLIENT_EPDS_1_ENJOY_THINGS]
      ,s.[CLIENT_EPDS_1_BLAME_SELF]
      ,s.[CLIENT_EPDS_1_ANXIOUS_WORRIED]
      ,s.[CLIENT_EPDS_1_SCARED_PANICKY]
      ,s.[CLIENT_EPDS_1_THINGS_GETTING_ON_TOP]
      ,s.[CLIENT_EPDS_1_DIFFICULTY_SLEEPING]
      ,s.[CLIENT_EPDS_1_SAD_MISERABLE]
      ,s.[CLIENT_EPDS_1_BEEN_CRYING]
      ,s.[CLIENT_EPDS_1_HARMING_SELF]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_0_ID_AGENCY]
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,s.[LA_CTY_OQ10_EDPS]
      ,s.[LA_CTY_PHQ9_SCORE_EDPS]
      ,s.[LA_CTY_STRESS_INDEX_EDPS]
      ,s.[CLIENT_EPS_TOTAL_SCORE]
      ,s.[Master_SurveyID]  
	FROM dbo.[Edinburgh_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.CL_EN_GEN_ID
	WHERE SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0

END

GO
