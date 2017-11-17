USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetSurveyIDsPerSite]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/17/2014
-- Description:	Returns the survey id's per give site code
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetSurveyIDsPerSite]
	@SiteID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
SELECT DISTINCT STF.SiteID
       ,SUR.SurveyID
       ,SUR.SurveyName
FROM ETOSRVR.Etosolaris.dbo.Surveys SUR
INNER JOIN ETOSRVR.Etosolaris.dbo.SurveyElements SURE ON SURE.SurveyID = SUR.SurveyID
LEFT  JOIN ETOSRVR.Etosolaris.dbo.SurveyElementChoices SEC on SEC.SurveyElementID = SURE.SurveyElementID
INNER JOIN ETOSRVR.Etosolaris.dbo.SurveyElementTypes SURET on SURET.SurveyElementTypeID = SURE.SurveyElementTypeID
INNER JOIN ETOSRVR.Etosolaris.dbo.Staff STF on STF.StaffID = SUR.AuditStaffID
WHERE STF.SiteID = @SiteID
ORDER BY STF.SiteID, SUR.SurveyName

END
GO
