USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_DANCE]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Create date: 1/12/2016
-- Description:	Extract of dance data where the SiteID from dance is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. In addition, joining condition need to be changed. Use [CL_EN_GEN_ID] instead of [CLIENT_0_ID_NSO]
--              to join [dbo].[Clients] table.
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_DANCE]
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
      ,s.[CLIENT_CAC_NA]
      ,s.[CLIENT_CI_NA]
      ,s.[CLIENT_EPA_NA]
      ,s.[CLIENT_NCCO_NA]
      ,s.[CLIENT_NI_NA]
      ,s.[CLIENT_NT_NA]
      ,s.[CLIENT_NVC_NA]
      ,s.[CLIENT_PC_NA]
      ,s.[CLIENT_PO_NA]
      ,s.[CLIENT_PRA_NA]
      ,s.[CLIENT_RP_NA]
      ,s.[CLIENT_SCA_NA]
      ,s.[CLIENT_SE_NA]
      ,s.[CLIENT_VE_NA]
      ,s.[CLIENT_VEC_NA]
      ,s.[CLIENT_VISIT_VARIABLES]
      ,s.[CLIENT_LS_NA]
      ,s.[CLIENT_RD_NA]
      ,s.[CLIENT_VQ_NA]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,REPLACE(REPLACE(REPLACE(s.[CLIENT_CAC_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_CAC_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_CI_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_CI_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_EPA_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_EPA_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_LS_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_LS_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_NCCO_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_NCCO_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_NI_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_NI_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_NT_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_NT_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_NVC_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_NVC_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_PC_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_PC_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_PO_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_PO_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_PRA_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_PRA_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_RD_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_RD_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_RP_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_RP_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_SCA_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_SCA_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_SE_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_SE_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_VE_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_VE_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_VEC_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_VEC_COMMENTS]
	  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_VQ_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_VQ_COMMENTS]
	  ,s.[CLIENT_ACTIVITY_DURATION]
      ,s.[CLIENT_CAC_PER]
      ,s.[CLIENT_CHILD_AGE]
      ,s.[CLIENT_CHILD_DURATION]
      ,s.[CLIENT_CI_PER]
      ,s.[CLIENT_EPA_PER]
      ,s.[CLIENT_LS_PER]
      ,s.[CLIENT_NCCO_PER]
      ,s.[CLIENT_NI_PER]
      ,s.[CLIENT_NT_PER]
      ,s.[CLIENT_NVC_PER]
      ,s.[CLIENT_PC_PER]
      ,s.[CLIENT_PO_PER]
      ,s.[CLIENT_PRA_PER]
      ,s.[CLIENT_RD_PER]
      ,s.[CLIENT_RP_PER]
      ,s.[CLIENT_SCA_PER]
      ,s.[CLIENT_SE_PER]
      ,s.[CLIENT_VE_PER]
      ,s.[CLIENT_VEC_PER]
      ,s.[CLIENT_VQ_PER]
      ,s.[NURSE_PERSONAL_0_NAME]   
	FROM dbo.[DANCE_survey] s
	INNER JOIN dbo.Clients c 
	ON c.Client_Id = s.CL_EN_GEN_ID
	WHERE SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0
  
END

GO
