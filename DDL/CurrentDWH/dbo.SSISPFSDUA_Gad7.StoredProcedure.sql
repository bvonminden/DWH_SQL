USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_Gad7]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Create date: 1/13/2016
-- Description:	Extract of [GAD7_Survey] data where the SiteID from [[GAD7_Survey]] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_Gad7]
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
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,s.[SiteID]
		  ,s.[ProgramID]
		  ,s.[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[ClientID])) AS [ClientID]
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
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,s.[CLIENT_GAD7_TOTAL]
		  ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,s.[NURSE_PERSONAL_0_NAME]
	FROM dbo.[GAD7_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.CLIENT_0_ID_NSO
	WHERE SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
	AND c.PFS_STUDY_VULNERABLE_POP = 0
	
END


GO
