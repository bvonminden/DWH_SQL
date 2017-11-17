USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_Gad7]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Create date: 1/13/2016
-- Description:	Extract of [GAD7_Survey] data where the SiteID from [[GAD7_Survey]] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. In addition, joining condition need to be changed. Use [CL_EN_GEN_ID] instead of [CLIENT_0_ID_NSO]
--              to join [dbo].[Clients] table.
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_Gad7]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[Master_SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,s.[ClientID]
      ,s.[RespondentID]
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,s.[CLIENT_GAD7_AFRAID]
      ,s.[CLIENT_GAD7_CTRL_WORRY]
      ,s.[CLIENT_GAD7_IRRITABLE]
      ,s.[CLIENT_GAD7_NERVOUS]
      ,s.[CLIENT_GAD7_PROBS_DIFFICULT]
      ,s.[CLIENT_GAD7_RESTLESS]
      ,s.[CLIENT_GAD7_TRBL_RELAX]
      ,s.[CLIENT_GAD7_WORRY]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_GAD7_TOTAL]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[NURSE_PERSONAL_0_NAME]
	FROM dbo.[GAD7_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.[CL_EN_GEN_ID]
	WHERE SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0
	
END

GO
