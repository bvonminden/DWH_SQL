USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_ClientDischarge]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Create date: 01/12/2016
-- Description:	Extract of ClientDischarge data where the SiteID from Client_Discharge_Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay for Success where client is over 14 year old
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_ClientDischarge]
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
      ,s.[RespondentID]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
	  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
	  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_DISCHARGE_1_DATE]
      ,s.[CLIENT_DISCHARGE_0_REASON]
      ,s.[CLIENT_DISCHARGE_1_MISCARRIED_DATE]
      ,s.[CLIENT_DISCHARGE_1_LOST_CUSTODY]
      ,s.[CLIENT_DISCHARGE_1_MATERNAL_DEATH_DATE]
      ,s.[CLIENT_DISCHARGE_1_INCARCERATION_DATE]
      ,s.[CLIENT_DISCHARGE_1_UNABLE_REASON]
      ,s.[NONE]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
      ,s.[CLIENT_DISCHARGE_1_LOST_CUSTODY_DATE]
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,s.[CLIENT_DISCHARGE_1_INFANTDEATH_DATE]
      ,s.[CLIENT_DISCHARGE_1_MISCARRIED_DATE2]
      ,s.[Master_SurveyID]
      ,s.[CLIENT_DISCHARGE_1_INFANTDEATH_REASON]
      ,s.[CLIENT_DISCHARGE_1_MATERNAL_DEATH_REASON]  
	FROM dbo.[Client_Discharge_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.CL_EN_GEN_ID
	WHERE SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
	AND PFS_STUDY_VULNERABLE_POP = 0

END


GO
