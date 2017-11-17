USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCV_ClientFunding]    Script Date: 11/16/2017 10:44:32 AM ******/
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
-- *********************************************
-- Modified By: Jingjing
-- Modified Date: 12/19/2016
-- Dexcription: New columns are added due to ETO Oct Release 
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCV_ClientFunding]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--DECLARE @ProfileID AS INT
--SET @ProfileID = 27

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
		  ,[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM]
		  ,[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM]
		  ,[CLIENT_FUNDING_0_SOURCE_OTHER]
		  ,[CLIENT_FUNDING_0_SOURCE_OTHER_TXT]
		  ,[CLIENT_FUNDING_1_END_MIECHVP_COM]
		  ,[CLIENT_FUNDING_1_END_MIECHVP_FORM]
		  ,[CLIENT_FUNDING_1_END_OTHER]
		  ,[CLIENT_FUNDING_1_START_MIECHVP_COM]
		  ,[CLIENT_FUNDING_1_START_MIECHVP_FORM]
		  ,[CLIENT_FUNDING_1_START_OTHER]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL]
		  ,[CLIENT_FUNDING_1_END_MIECHVP_TRIBAL]
		  ,[CLIENT_FUNDING_1_START_MIECHVP_TRIBAL]
		  ,[CLIENT_FUNDING_0_SOURCE_OTHER1]
		  ,[CLIENT_FUNDING_0_SOURCE_OTHER2]
		  ,[CLIENT_FUNDING_0_SOURCE_OTHER3]
		  ,[CLIENT_FUNDING_1_END_OTHER1]
		  ,[CLIENT_FUNDING_1_END_OTHER2]
		  ,[CLIENT_FUNDING_1_END_OTHER3]
		  ,[CLIENT_FUNDING_1_START_OTHER1]
		  ,[CLIENT_FUNDING_1_START_OTHER2]
		  ,[CLIENT_FUNDING_1_START_OTHER3]
		  ,[Master_SurveyID]
		  ,[CLIENT_FUNDING_0_SOURCE_PFS]
		  ,[CLIENT_FUNDING_1_END_PFS]
		  ,[CLIENT_FUNDING_1_START_PFS]
		  ,[Archive_Record]						/*****New Columns Added on 12/19/2016*********/
		  ,[CLIENT_FUNDING_0_SOURCE_OTHER4]     /*****New Columns Added on 12/19/2016*********/
          ,[CLIENT_FUNDING_0_SOURCE_OTHER5]     /*****New Columns Added on 12/19/2016*********/
          ,[CLIENT_FUNDING_0_SOURCE_OTHER6]     /*****New Columns Added on 12/19/2016*********/
          ,[CLIENT_FUNDING_1_END_OTHER4]        /*****New Columns Added on 12/19/2016*********/
          ,[CLIENT_FUNDING_1_END_OTHER5]        /*****New Columns Added on 12/19/2016*********/
          ,[CLIENT_FUNDING_1_END_OTHER6]        /*****New Columns Added on 12/19/2016*********/
          ,[CLIENT_FUNDING_1_START_OTHER4]      /*****New Columns Added on 12/19/2016*********/
          ,[CLIENT_FUNDING_1_START_OTHER5]      /*****New Columns Added on 12/19/2016*********/
          ,[CLIENT_FUNDING_1_START_OTHER6]      /*****New Columns Added on 12/19/2016*********/
	FROM [DataWarehouse].[dbo].[Client_Funding_Survey] s
	WHERE CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
						   where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
	AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
	
END

GO
