USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_ClientFunding]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Create date: 1/12/2016
-- Description:	Extract of ClientFunding data where the SiteID from Client_Funding_Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- *********************************************
-- Modified By: Jingjing
-- Modified Date: 12/19/2016
-- Dexcription: New columns are added due to ETO Oct Release 
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. In addition, joining condition need to be changed. Use [CL_EN_GEN_ID] instead of [CLIENT_0_ID_NSO]
--              to join [dbo].[Clients] table.
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_ClientFunding]
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
      ,s.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM]
      ,s.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM]
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER]
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER_TXT]
      ,s.[CLIENT_FUNDING_1_END_MIECHVP_COM]
      ,s.[CLIENT_FUNDING_1_END_MIECHVP_FORM]
      ,s.[CLIENT_FUNDING_1_END_OTHER]
      ,s.[CLIENT_FUNDING_1_START_MIECHVP_COM]
      ,s.[CLIENT_FUNDING_1_START_MIECHVP_FORM]
      ,s.[CLIENT_FUNDING_1_START_OTHER]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,s.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL]
      ,s.[CLIENT_FUNDING_1_END_MIECHVP_TRIBAL]
      ,s.[CLIENT_FUNDING_1_START_MIECHVP_TRIBAL]
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER1]
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER2]
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER3]
      ,s.[CLIENT_FUNDING_1_END_OTHER1]
      ,s.[CLIENT_FUNDING_1_END_OTHER2]
      ,s.[CLIENT_FUNDING_1_END_OTHER3]
      ,s.[CLIENT_FUNDING_1_START_OTHER1]
      ,s.[CLIENT_FUNDING_1_START_OTHER2]
      ,s.[CLIENT_FUNDING_1_START_OTHER3]
      ,s.[Master_SurveyID]
      ,s.[CLIENT_FUNDING_0_SOURCE_PFS]
      ,s.[CLIENT_FUNDING_1_END_PFS]
      ,s.[CLIENT_FUNDING_1_START_PFS]
      ,s.[Archive_Record]					  /*****New Columns Added on 12/19/2016*********/
	  ,s.[CLIENT_FUNDING_0_SOURCE_OTHER4]     /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER5]     /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER6]     /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_1_END_OTHER4]        /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_1_END_OTHER5]        /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_1_END_OTHER6]        /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_1_START_OTHER4]      /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_1_START_OTHER5]      /*****New Columns Added on 12/19/2016*********/
      ,s.[CLIENT_FUNDING_1_START_OTHER6]      /*****New Columns Added on 12/19/2016*********/  
	FROM dbo.[Client_Funding_Survey] S
	INNER JOIN dbo.Clients c ON c.Client_Id = s.[CL_EN_GEN_ID]
	WHERE SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
	--AND PFS_STUDY_VULNERABLE_POP = 0
	
END

GO
