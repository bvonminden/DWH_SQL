USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_ReferralsToServices]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of ReferralsToServices data where the SiteID from [Referrals_to_Services_Survey] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_ReferralsToServices]
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
      ,s.[SERVICE_REFER_0_TANF]
      ,s.[SERVICE_REFER_0_FOODSTAMP]
      ,s.[SERVICE_REFER_0_SOCIAL_SECURITY]
      ,s.[SERVICE_REFER_0_UNEMPLOYMENT]
      ,s.[SERVICE_REFER_0_SUBSID_CHILD_CARE]
      ,s.[SERVICE_REFER_0_IPV]
      ,s.[SERVICE_REFER_0_CPS]
      ,s.[SERVICE_REFER_0_MENTAL]
      ,s.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING]
      ,s.[SERVICE_REFER_0_SMOKE]
      ,s.[SERVICE_REFER_0_ALCOHOL_ABUSE]
      ,s.[SERVICE_REFER_0_MEDICAID]
      ,s.[SERVICE_REFER_0_SCHIP]
      ,s.[SERVICE_REFER_0_PRIVATE_INSURANCE]
      ,s.[SERVICE_REFER_0_SPECIAL_NEEDS]
      ,s.[SERVICE_REFER_0_PCP]
      ,s.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]
      ,s.[SERVICE_REFER_0_WIC_CLIENT]
      ,s.[SERVICE_REFER_0_CHILD_CARE]
      ,s.[SERVICE_REFER_0_JOB_TRAINING]
      ,s.[SERVICE_REFER_0_HOUSING]
      ,s.[SERVICE_REFER_0_TRANSPORTATION]
      ,s.[SERVICE_REFER_0_PREVENT_INJURY]
      ,s.[SERVICE_REFER_0_BIRTH_EDUC_CLASS]
      ,s.[SERVICE_REFER_0_LACTATION]
      ,s.[SERVICE_REFER_0_GED]
      ,s.[SERVICE_REFER_0_HIGHER_EDUC]
      ,s.[SERVICE_REFER_0_CHARITY]
      ,s.[SERVICE_REFER_0_LEGAL_CLIENT]
      ,s.[SERVICE_REFER_0_PATERNITY]
      ,s.[SERVICE_REFER_0_CHILD_SUPPORT]
      ,s.[SERVICE_REFER_0_ADOPTION]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[SERIVCE_REFER_0_OTHER1_DESC])) AS [SERIVCE_REFER_0_OTHER1_DESC]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[SERIVCE_REFER_0_OTHER2_DESC])) AS [SERIVCE_REFER_0_OTHER2_DESC]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[SERIVCE_REFER_0_OTHER3_DESC])) AS [SERIVCE_REFER_0_OTHER3_DESC]
      ,s.[SERVICE_REFER_0_DRUG_ABUSE]
      ,s.[SERVICE_REFER_0_OTHER]
      ,s.[REFERRALS_TO_0_FORM_TYPE]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[SERVICE_REFER_0_DENTAL]
      ,s.[SERVICE_REFER_0_INTERVENTION]
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,s.[SERVICE_REFER_0_PCP_R2]
      ,s.[SERVICE_REFER_INDIAN_HEALTH]
      ,s.[SERVICE_REFER_MILITARY_INS]
      ,s.[Master_SurveyID]
	FROM dbo.[Referrals_to_Services_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.CLIENT_0_ID_NSO
	WHERE s.SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						WHERE ExportProfileID = @ProfileID)
	AND c.PFS_STUDY_VULNERABLE_POP = 0
	
END


GO
