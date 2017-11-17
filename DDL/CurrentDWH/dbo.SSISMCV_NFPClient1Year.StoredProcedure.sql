USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCV_NFPClient1Year]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of MICHVIE [nfp_client_survey_results_1_year]]] Encounter data where the SiteID from [[nfp_client_survey_results_36_week]] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCV_NFPClient1Year]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [ItemID]
		  ,[ClientName]
		  ,[ClientID]
		  ,[NHV_Name]
		  ,[NHV_ID]
		  ,[DateOfReport]
		  ,[SurveyDueDate]
		  ,[Question1]
		  ,[Question2]
		  ,[Question3]
		  ,[Question4]
		  ,[Question5]
		  ,[Question6]
		  ,[Question7]
		  ,[Question8]
		  ,[Question9]
		  ,[Question10]
		  ,[Question11]
		  ,[Question12]
		  ,CAST([Question13] AS NVARCHAR(MAX)) AS [Question13]
		  ,CAST([Comments] AS NVARCHAR(MAX)) AS [Comments]
		  ,[AgencyName]
		  ,[AgencyID]
		  ,[TeamName]
		  ,[TeamID]
		  ,[ETO_CaseNo]
		  ,[Passcode]
		  ,[Status]
		  ,[StatusDate]
	FROM [DataWarehouse].[dbo].[nfp_client_survey_results_1_year] s
	WHERE ClientID in
					(select CL_EN_GEN_ID from View_MIECHVP_Cleints 
					  where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
	AND TeamID NOT IN (select TeamID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	AND ClientID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.AgencyID)
			  
END

GO
