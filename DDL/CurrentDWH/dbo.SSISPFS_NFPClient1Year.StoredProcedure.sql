USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_NFPClient1Year]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Create date: 1/13/2016
-- Description:	Extract of [nfp_client_survey_results_1_year] Encounter data where the SiteID from [nfp_client_survey_results_1_year] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. 
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_NFPClient1Year]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;

	SELECT S.[ItemID]
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
	WHERE [AgencyID] IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						  WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0
    
END


GO
