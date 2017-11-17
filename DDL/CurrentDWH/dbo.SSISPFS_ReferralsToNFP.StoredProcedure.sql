USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_ReferralsToNFP]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of ReferralsToNFP data where the SiteID from [Referrals_to_NFP_Survey] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14\
-- Modified by: Jingjing Gao
-- Modified on: 02/07/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. In addition, joining condition need to be changed. Use [CL_EN_GEN_ID] instead of [CLIENT_0_ID_NSO]
--              to join [dbo].[Clients] table.
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_ReferralsToNFP]
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
      ,s.[REFERRAL_PROSPECT_0_SOURCE_CODE]
      ,s.[REFERRAL_SOURCE_PRIMARY_0_NAME]
      ,s.[REFERRAL_SOURCE_PRIMARY_1_LOCATION]
      ,s.[REFERRAL_SOURCE_SECONDARY_0_NAME]
      ,s.[REFERRAL_SOURCE_SECONDARY_1_LOCATION]
      ,REPLACE(REPLACE(REPLACE(s.[REFERRAL_PROSPECT_0_NOTES], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [REFERRAL_PROSPECT_0_NOTES]
	  ,s.[REFERRAL_PROSPECT_DEMO_1_PLANG]
      ,s.[REFERRAL_PROSPECT_DEMO_1_NAME_FIRST]
      ,s.[REFERRAL_PROSPECT_DEMO_0_NAME_LAST]
      ,s.[REFERRAL_PROSPECT_DEMO_1_DOB]
      ,s.[REFERRAL_PROSPECT_DEMO_1_STREET]
      ,s.[REFERRAL_PROSPECT_DEMO_1_STREET2]
      ,s.[REFERRAL_PROSPECT_DEMO_1_ZIP]
      ,s.[REFERRAL_PROSPECT_DEMO_1_WORK]
      ,s.[REFERRAL_PROSPECT_DEMO_1_PHONE_HOME]
      ,s.[REFERRAL_PROSPECT_DEMO_1_CELL]
      ,s.[REFERRAL_PROSPECT_DEMO_1_EMAIL]
      ,s.[REFERRAL_PROSPECT_DEMO_1_EDD]
      ,s.[REFERRAL_PROSPECT_0_WAIT_LIST]
      ,s.[REFERRAL_PROSPECT_0_FOLLOWUP_NURSE]
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,s.[LA_CTY_REFERRAL_SCHOOL]
      ,s.[LA_CTY_REFERRAL_SOURCE_OTH]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[Master_SurveyID]
	FROM [DataWarehouse].[dbo].[Referrals_to_NFP_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.[CL_EN_GEN_ID]
	WHERE s.SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0

END

GO
