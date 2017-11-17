USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_Edinburgh]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Create date: 1/12/2016
-- Description:	Extract of Edinburgh data where the SiteID from Edinburgh_Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_Edinburgh]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT s.[SurveyResponseID]
		  ,s.[ElementsProcessed]
		  ,s.[SurveyID]
		  ,s.[SurveyDate]
		  ,s.[AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,s.[SiteID]
		  ,s.[ProgramID]
		  ,s.[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[ClientID])) AS [ClientID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
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
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,s.[NURSE_PERSONAL_0_NAME]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
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
	AND c.PFS_STUDY_VULNERABLE_POP = 0

END


GO
