USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_SurveyIDs]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of Edinburgh data where the SiteID from Edinburgh_Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_SurveyIDs]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT DISTINCT STF.SiteID
		   ,SUR.SurveyID
		   ,SUR.SurveyName
	FROM ETOSRVR.Etosolaris.dbo.Surveys SUR
	INNER JOIN ETOSRVR.Etosolaris.dbo.SurveyElements SURE ON SURE.SurveyID = SUR.SurveyID
	LEFT  JOIN ETOSRVR.Etosolaris.dbo.SurveyElementChoices SEC on SEC.SurveyElementID = SURE.SurveyElementID
	INNER JOIN ETOSRVR.Etosolaris.dbo.SurveyElementTypes SURET on SURET.SurveyElementTypeID = SURE.SurveyElementTypeID
	INNER JOIN ETOSRVR.Etosolaris.dbo.Staff STF on STF.StaffID = SUR.AuditStaffID
	WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID)
	ORDER BY STF.SiteID, SUR.SurveyName

END

GO
