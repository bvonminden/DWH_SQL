USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_SurveyIDs]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of Edinburgh data where the SiteID from Edinburgh_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_SurveyIDs]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
--DECLARE @ProfileID INT
--SET @ProfileID = 27

SELECT DISTINCT STF.SiteID
       ,SUR.SurveyID
       ,SUR.SurveyName
FROM ETOSRVR.Etosolaris.dbo.Surveys SUR
INNER JOIN ETOSRVR.Etosolaris.dbo.SurveyElements SURE ON SURE.SurveyID = SUR.SurveyID
LEFT  JOIN ETOSRVR.Etosolaris.dbo.SurveyElementChoices SEC on SEC.SurveyElementID = SURE.SurveyElementID
INNER JOIN ETOSRVR.Etosolaris.dbo.SurveyElementTypes SURET on SURET.SurveyElementTypeID = SURE.SurveyElementTypeID
INNER JOIN ETOSRVR.Etosolaris.dbo.Staff STF on STF.StaffID = SUR.AuditStaffID
WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
ORDER BY STF.SiteID, SUR.SurveyName

END

GO
