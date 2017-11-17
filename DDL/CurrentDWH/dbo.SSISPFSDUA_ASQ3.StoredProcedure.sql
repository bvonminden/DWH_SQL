USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_ASQ3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Create date: 1/11/2016
-- Description:	Extract of ASQ3 data where the SiteID from Client_Discharge_Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_ASQ3]
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
		  ,s.[DW_AuditDate]
		  ,s.[DataSource]
		  ,s.[INFANT_HEALTH_NO_ASQ_COMM]
		  ,s.[INFANT_HEALTH_NO_ASQ_FINE]
		  ,s.[INFANT_HEALTH_NO_ASQ_GROSS]
		  ,s.[INFANT_HEALTH_NO_ASQ_PERSONAL]
		  ,s.[INFANT_HEALTH_NO_ASQ_PROBLEM]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[INFANT_0_ID_NSO])) AS [INFANT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[INFANT_PERSONAL_0_NAME_FIRST])) AS [INFANT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[INFANT_PERSONAL_0_NAME_LAST])) AS [INFANT_PERSONAL_0_NAME_LAST]
		  ,s.[INFANT_AGES_STAGES_1_COMM]
		  ,s.[INFANT_AGES_STAGES_1_FMOTOR]
		  ,s.[INFANT_AGES_STAGES_1_GMOTOR]
		  ,s.[INFANT_AGES_STAGES_1_PSOCIAL]
		  ,s.[INFANT_AGES_STAGES_1_PSOLVE]
		  ,s.[INFANT_BIRTH_0_DOB]
		  ,s.[NURSE_PERSONAL_0_NAME]
		  ,s.[Master_SurveyID]
  FROM [DataWarehouse].[dbo].[ASQ3_Survey] s
  INNER JOIN dbo.Clients c
  on c.Client_Id = s.CLIENT_0_ID_NSO
  WHERE s.SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
  AND c.PFS_STUDY_VULNERABLE_POP = 0
  
END

GO
