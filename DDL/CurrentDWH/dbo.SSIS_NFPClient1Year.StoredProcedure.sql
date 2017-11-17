USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_NFPClient1Year]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of [nfp_client_survey_results_1_year] Encounter data where the SiteID from [nfp_client_survey_results_1_year] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_NFPClient1Year]
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT DISTINCT S.[ItemID]
		  ,S.[ClientName]
		  ,S.[ClientID]
		  ,S.[NHV_Name]
		  ,S.[NHV_ID]
		  ,S.[DateOfReport]
		  ,S.[SurveyDueDate]
		  ,S.[Question1]
		  ,S.[Question2]
		  ,S.[Question3]
		  ,S.[Question4]
		  ,S.[Question5]
		  ,S.[Question6]
		  ,S.[Question7]
		  ,S.[Question8]
		  ,S.[Question9]
		  ,S.[Question10]
		  ,S.[Question11]
		  ,S.[Question12]
		  ,dbo.fnMORemoveCRLFTAB([Question13]) [Question13]
		  ,dbo.fnMORemoveCRLFTAB([Comments]) [Comments]
		  ,S.[AgencyName]
		  ,S.[AgencyID]
		  ,S.[TeamName]
		  ,S.[TeamID]
		  ,S.[ETO_CaseNo]
		  ,S.[Passcode]
		  ,S.[Status]
		  ,S.[StatusDate]
	FROM [DataWarehouse].[dbo].[nfp_client_survey_results_1_year] S
	INNER JOIN dbo.Clients c ON c.Client_Id = S.ClientID
	INNER JOIN EnrollmentAndDismissal ead ON ead.CLID = c.Client_Id
	WHERE [AgencyID] IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	AND ead.ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	AND ClientID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = S.AgencyID)
	
END

GO
