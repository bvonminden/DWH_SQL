USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_NFPClient36Week]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of [[nfp_client_survey_results_36_week]] Encounter data where the SiteID from [[nfp_client_survey_results_36_week]] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_NFPClient36Week]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;

	SELECT DISTINCT s.[ItemID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[ClientName])) AS [ClientName]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[ClientID])) AS [ClientID]
		  ,s.[NHV_Name]
		  ,s.[NHV_ID]
		  ,s.[DateOfReport]
		  ,s.[SurveyDueDate]
		  ,s.[Question1]
		  ,s.[Question2]
		  ,s.[Question3]
		  ,s.[Question4]
		  ,s.[Question5]
		  ,s.[Question6]
		  ,s.[Question7]
		  ,s.[Question8]
		  ,s.[Question9]
		  ,s.[Question10]
		  ,s.[Question11]
		  ,s.[Question12]
		  ,s.[Question13]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[Question14])) AS [Question14]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[Comments])) AS [Comments]
		  ,s.[AgencyName]
		  ,s.[AgencyID]
		  ,s.[TeamName]
		  ,s.[TeamID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[ETO_CaseNo])) AS [ETO_CaseNo]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[Passcode])) AS [Passcode]
		  ,s.[Status]
		  ,s.[StatusDate]
	FROM [DataWarehouse].[dbo].[nfp_client_survey_results_36_week] s
	INNER JOIN dbo.Clients c ON c.Client_Id = S.ClientID
	WHERE [AgencyID] IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						  WHERE ExportProfileID = @ProfileID)
	AND c.PFS_STUDY_VULNERABLE_POP = 0
	
END



GO
