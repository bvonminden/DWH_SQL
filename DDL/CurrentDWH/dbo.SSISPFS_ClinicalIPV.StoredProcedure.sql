USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_ClinicalIPV]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Jingjing Gao
-- Create date: 12/09/2016
-- Description:	Extract of ClinicalIPV data where the SiteID from [Clinical_IPV_Survey] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
--				Relation survey is retired and is replaced with Clinical_IPV survey 
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. In addition, joining condition need to be changed. Use [CL_EN_GEN_ID] instead of [CLIENT_0_ID_NSO]
--              to join [dbo].[Clients] table.
-- =============================================

CREATE PROCEDURE [dbo].[SSISPFS_ClinicalIPV]
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
      ,s.[Archive_Record]
      ,s.[IPV_AFRAID]
      ,s.[IPV_CHILD_SAFETY]
      ,s.[IPV_CONTROLING]
      ,s.[IPV_FORCED_SEX]
      ,s.[IPV_INDICATED]
      ,s.[IPV_INSULTED]
      ,s.[IPV_PHYSICALLY_HURT]
      ,s.[IPV_PRN_REASON]
      ,s.[IPV_Q5_8_ANY_YES]
      ,s.[IPV_SCREAMED]
      ,s.[IPV_THREATENED]
      ,s.[IPV_TOOL_USED]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST ]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[IPV_Q1_4_SCORE]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[NURSE_PERSONAL_0_NAME]
  FROM [DataWarehouse].[dbo].[Clinical_IPV_Survey] s
  INNER JOIN dbo.Clients c ON c.Client_Id = s.[CL_EN_GEN_ID]
	WHERE s.SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0
	
	END



GO
