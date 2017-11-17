USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_PHQ]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of PHQ data where the SiteID from [PHQ_Survey] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. In addition, joining condition need to be changed. Use [CL_EN_GEN_ID] instead of [CLIENT_0_ID_NSO]
--              to join [dbo].[Clients] table.
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_PHQ]
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
      ,s.[CLIENT_0_ID_AGENCY]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[Need from Kim]
      ,s.[NeedFromKim]
      ,s.[CLIENT_PHQ9_0_TOTAL_SCORE]
      ,s.[CLIENT_PHQ9_1_CONCENTRATION]
      ,s.[CLIENT_PHQ9_1_DIFFICULTY]
      ,s.[CLIENT_PHQ9_1_FEEL_BAD]
      ,s.[CLIENT_PHQ9_1_FEEL_DEPRESSED]
      ,s.[CLIENT_PHQ9_1_FEEL_TIRED]
      ,s.[CLIENT_PHQ9_1_HURT_SELF]
      ,s.[CLIENT_PHQ9_1_LITTLE_INTEREST]
      ,s.[CLIENT_PHQ9_1_MOVE_SPEAK]
      ,s.[CLIENT_PHQ9_1_TROUBLE_EAT]
      ,s.[CLIENT_PHQ9_1_TROUBLE_SLEEP]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,s.[Master_SurveyID] 
	FROM dbo.[PHQ_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.[CL_EN_GEN_ID]
	WHERE s.SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0
  
END

GO
