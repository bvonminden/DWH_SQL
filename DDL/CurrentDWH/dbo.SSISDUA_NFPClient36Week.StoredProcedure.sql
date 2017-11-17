USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_NFPClient36Week]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of [[nfp_client_survey_results_36_week]] Encounter data where the SiteID from [[nfp_client_survey_results_36_week]] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_NFPClient36Week]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT DISTINCT [ItemID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientName])) AS [ClientName]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
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
		  ,[Question13]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Question14])) AS [Question14]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Comments])) AS [Comments]
		  ,[AgencyName]
		  ,[AgencyID]
		  ,[TeamName]
		  ,[TeamID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ETO_CaseNo])) AS [ETO_CaseNo]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Passcode])) AS [Passcode]
		  ,[Status]
		  ,[StatusDate]
	FROM [DataWarehouse].[dbo].[nfp_client_survey_results_36_week] S
	INNER JOIN EnrollmentAndDismissal ead ON ead.CLID = S.ClientID
	WHERE [AgencyID] IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	AND ead.ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	AND ClientID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = S.AgencyID)
 
END

GO
