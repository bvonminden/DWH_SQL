USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISSA_ReferralsToServices]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of ReferralsToServices data where the SiteID from [Referrals_to_Services_Survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified Date: 11/30/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISSA_ReferralsToServices]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
--DECLARE @ProfileID INT --Testing
--SET @ProfileID = 27    --Testing

	SELECT [SurveyResponseID]
		  ,[ElementsProcessed]
		  ,[SurveyID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[SurveyDate])) AS [SurveyDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[AuditDate])) AS [AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
		  ,[RespondentID]
		  ,[SERVICE_REFER_0_TANF]
		  ,[SERVICE_REFER_0_FOODSTAMP]
		  ,[SERVICE_REFER_0_SOCIAL_SECURITY]
		  ,[SERVICE_REFER_0_UNEMPLOYMENT]
		  ,[SERVICE_REFER_0_SUBSID_CHILD_CARE]
		  ,[SERVICE_REFER_0_IPV]
		  ,[SERVICE_REFER_0_CPS]
		  ,[SERVICE_REFER_0_MENTAL]
		  ,[SERVICE_REFER_0_RELATIONSHIP_COUNSELING]
		  ,[SERVICE_REFER_0_SMOKE]
		  ,[SERVICE_REFER_0_ALCOHOL_ABUSE]
		  ,[SERVICE_REFER_0_MEDICAID]
		  ,[SERVICE_REFER_0_SCHIP]
		  ,[SERVICE_REFER_0_PRIVATE_INSURANCE]
		  ,[SERVICE_REFER_0_SPECIAL_NEEDS]
		  ,[SERVICE_REFER_0_PCP]
		  ,[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]
		  ,[SERVICE_REFER_0_WIC_CLIENT]
		  ,[SERVICE_REFER_0_CHILD_CARE]
		  ,[SERVICE_REFER_0_JOB_TRAINING]
		  ,[SERVICE_REFER_0_HOUSING]
		  ,[SERVICE_REFER_0_TRANSPORTATION]
		  ,[SERVICE_REFER_0_PREVENT_INJURY]
		  ,[SERVICE_REFER_0_BIRTH_EDUC_CLASS]
		  ,[SERVICE_REFER_0_LACTATION]
		  ,[SERVICE_REFER_0_GED]
		  ,[SERVICE_REFER_0_HIGHER_EDUC]
		  ,[SERVICE_REFER_0_CHARITY]
		  ,[SERVICE_REFER_0_LEGAL_CLIENT]
		  ,[SERVICE_REFER_0_PATERNITY]
		  ,[SERVICE_REFER_0_CHILD_SUPPORT]
		  ,[SERVICE_REFER_0_ADOPTION]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[SERIVCE_REFER_0_OTHER1_DESC])) AS [SERIVCE_REFER_0_OTHER1_DESC]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[SERIVCE_REFER_0_OTHER2_DESC])) AS [SERIVCE_REFER_0_OTHER2_DESC]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[SERIVCE_REFER_0_OTHER3_DESC])) AS [SERIVCE_REFER_0_OTHER3_DESC]
		  ,[SERVICE_REFER_0_DRUG_ABUSE]
		  ,[SERVICE_REFER_0_OTHER]
		  ,[REFERRALS_TO_0_FORM_TYPE]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_DOB_INTAKE])) AS [CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,[SERVICE_REFER_0_DENTAL]
		  ,[SERVICE_REFER_0_INTERVENTION]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[SERVICE_REFER_0_PCP_R2]
		  ,[SERVICE_REFER_INDIAN_HEALTH]
		  ,[SERVICE_REFER_MILITARY_INS]
		  ,[Master_SurveyID]
	   FROM [DataWarehouse].[dbo].[Referrals_to_Services_Survey] s
	  WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	  AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	  AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)

END
GO
