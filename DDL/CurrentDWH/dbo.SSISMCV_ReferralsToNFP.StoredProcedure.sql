USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCV_ReferralsToNFP]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 2/15/2015
-- Description:	Extract of MICHVEI data where the SiteID from the Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCV_ReferralsToNFP]
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT [SurveyResponseID]
		  ,[ElementsProcessed]
		  ,[SurveyID]
		  ,[SurveyDate]
		  ,[AuditDate]
		  ,[CL_EN_GEN_ID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,[ClientID]
		  ,[RespondentID]
		  ,[REFERRAL_PROSPECT_0_SOURCE_CODE]
		  ,[REFERRAL_SOURCE_PRIMARY_0_NAME]
		  ,[REFERRAL_SOURCE_PRIMARY_1_LOCATION]
		  ,[REFERRAL_SOURCE_SECONDARY_0_NAME]
		  ,[REFERRAL_SOURCE_SECONDARY_1_LOCATION]
		  ,REPLACE(REPLACE(REPLACE([REFERRAL_PROSPECT_0_NOTES], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [REFERRAL_PROSPECT_0_NOTES]
		  ,[REFERRAL_PROSPECT_DEMO_1_PLANG]
		  ,[REFERRAL_PROSPECT_DEMO_1_NAME_FIRST]
		  ,[REFERRAL_PROSPECT_DEMO_0_NAME_LAST]
		  ,[REFERRAL_PROSPECT_DEMO_1_DOB]
		  ,[REFERRAL_PROSPECT_DEMO_1_STREET]
		  ,[REFERRAL_PROSPECT_DEMO_1_STREET2]
		  ,[REFERRAL_PROSPECT_DEMO_1_ZIP]
		  ,[REFERRAL_PROSPECT_DEMO_1_WORK]
		  ,[REFERRAL_PROSPECT_DEMO_1_PHONE_HOME]
		  ,[REFERRAL_PROSPECT_DEMO_1_CELL]
		  ,[REFERRAL_PROSPECT_DEMO_1_EMAIL]
		  ,[REFERRAL_PROSPECT_DEMO_1_EDD]
		  ,[REFERRAL_PROSPECT_0_WAIT_LIST]
		  ,[REFERRAL_PROSPECT_0_FOLLOWUP_NURSE]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[LA_CTY_REFERRAL_SCHOOL]
		  ,[LA_CTY_REFERRAL_SOURCE_OTH]
		  ,[CLIENT_0_ID_NSO]
		  ,[Master_SurveyID]
	FROM [DataWarehouse].[dbo].[Referrals_to_NFP_Survey] s
	WHERE CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
						   where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
	AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
  
END

GO
