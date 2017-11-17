USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCVDUA_ReferralsToNFP]    Script Date: 11/16/2017 10:44:32 AM ******/
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
CREATE PROCEDURE [dbo].[SSISMCVDUA_ReferralsToNFP]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [SurveyResponseID]
		  ,[ElementsProcessed]
		  ,[SurveyID]
		  ,[SurveyDate]
		  ,[AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
		  ,[RespondentID]
		  ,[REFERRAL_PROSPECT_0_SOURCE_CODE]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_SOURCE_PRIMARY_0_NAME])) AS [REFERRAL_SOURCE_PRIMARY_0_NAME]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_SOURCE_PRIMARY_1_LOCATION])) AS [REFERRAL_SOURCE_PRIMARY_1_LOCATION]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_SOURCE_SECONDARY_0_NAME])) AS [REFERRAL_SOURCE_SECONDARY_0_NAME]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_SOURCE_SECONDARY_1_LOCATION])) AS [REFERRAL_SOURCE_SECONDARY_1_LOCATION]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_PROSPECT_0_NOTES])) AS [REFERRAL_PROSPECT_0_NOTES]
		  ,[REFERRAL_PROSPECT_DEMO_1_PLANG]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_PROSPECT_DEMO_1_NAME_FIRST])) AS [REFERRAL_PROSPECT_DEMO_1_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_PROSPECT_DEMO_0_NAME_LAST])) AS [REFERRAL_PROSPECT_DEMO_0_NAME_LAST]
		  ,[REFERRAL_PROSPECT_DEMO_1_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_PROSPECT_DEMO_1_STREET])) AS [REFERRAL_PROSPECT_DEMO_1_STREET]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_PROSPECT_DEMO_1_STREET2])) AS [REFERRAL_PROSPECT_DEMO_1_STREET2]
		  ,[REFERRAL_PROSPECT_DEMO_1_ZIP]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_PROSPECT_DEMO_1_WORK])) AS [REFERRAL_PROSPECT_DEMO_1_WORK]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_PROSPECT_DEMO_1_PHONE_HOME])) AS [REFERRAL_PROSPECT_DEMO_1_PHONE_HOME]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_PROSPECT_DEMO_1_CELL])) AS [REFERRAL_PROSPECT_DEMO_1_CELL]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[REFERRAL_PROSPECT_DEMO_1_EMAIL])) AS [REFERRAL_PROSPECT_DEMO_1_EMAIL]
		  ,[REFERRAL_PROSPECT_DEMO_1_EDD]
		  ,[REFERRAL_PROSPECT_0_WAIT_LIST]
		  ,[REFERRAL_PROSPECT_0_FOLLOWUP_NURSE]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[LA_CTY_REFERRAL_SCHOOL]
		  ,[LA_CTY_REFERRAL_SOURCE_OTH]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,[Master_SurveyID]
	FROM [DataWarehouse].[dbo].[Referrals_to_NFP_Survey] s
	where CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
						   where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
	and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
  
END
GO
