USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_ClinicalIPV]    Script Date: 11/16/2017 10:44:32 AM ******/
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
-- =============================================

CREATE PROCEDURE [dbo].[SSISPFSDUA_ClinicalIPV]
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
      ,s.HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,s.HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
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
      ,s.HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
      ,s.HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST ])) AS [CLIENT_PERSONAL_0_NAME_FIRST ]
      ,s.HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[IPV_Q1_4_SCORE]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[NURSE_PERSONAL_0_NAME]
  FROM [DataWarehouse].[dbo].[Clinical_IPV_Survey] s	
  	INNER JOIN dbo.Clients c ON c.Client_Id = s.CLIENT_0_ID_NSO
	WHERE s.SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						WHERE ExportProfileID = @ProfileID)
	AND c.PFS_STUDY_VULNERABLE_POP = 0

END



GO
