USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_SurveyIDs]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Michael Osborn
-- Create date: 02/15/2015
-- Description:	Provide survey IDs for given site
--				
-- =============================================
CREATE PROCEDURE [dbo].[File_SurveyIDs]
	-- Add the parameters for the stored procedure here
	@SiteID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
--DECLARE @ProfileID INT
--SET @ProfileID = 27

Select distinct
       [etosolaris].[dbo].fngetsiteid(SU.auditstaffid) as SiteID
      ,SU.surveyid
      ,SU.SurveyName 
from [etosolaris].[dbo].[Surveys] SU
JOIN [etosolaris].[dbo].SurveyElements SE ON SU.SurveyID = SE.SurveyID
LEFT JOIN [etosolaris].[dbo].SurveyElementChoices SEC ON SE.SurveyElementID = SEC.SurveyElementID
JOIN [etosolaris].[dbo].SurveyElementTypes SUET ON SUET.SurveyElementTypeID = SE.SurveyElementTypeID
Where [etosolaris].[dbo].fngetsiteid(SU.auditstaffid) in (@SiteID)
ORDER BY Siteid, SU.surveyname

END


GO
