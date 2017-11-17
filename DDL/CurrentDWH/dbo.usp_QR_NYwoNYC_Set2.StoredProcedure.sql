USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_NYwoNYC_Set2]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_NYwoNYC_Set2]
	@State CHAR(2)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT
  Demographics_Survey.SurveyResponseID
  ,Demographics_Survey.SurveyID AS [Demographics_Survey SurveyID]
  ,Demographics_Survey.SurveyDate
  ,Demographics_Survey.CL_EN_GEN_ID
  ,Demographics_Survey.SiteID AS [Demographics_Survey SiteID]
  ,Demographics_Survey.ProgramID AS [Demographics_Survey ProgramID]
  ,Demographics_Survey.CLIENT_SUBPREG_0_BEEN_PREGNANT
  ,Mstr_surveys.SurveyID AS [Mstr_surveys SurveyID]
  ,Mstr_surveys.SurveyName
  ,ProgramsAndSites.ProgramID AS [ProgramsAndSites ProgramID]
  ,ProgramsAndSites.ProgramName
  ,ProgramsAndSites.SiteID AS [ProgramsAndSites SiteID]
  ,ProgramsAndSites.Site
  ,EnrollmentAndDismissal.CLID
  ,EnrollmentAndDismissal.SiteID AS [EnrollmentAndDismissal SiteID]
  ,EnrollmentAndDismissal.ProgramID AS [EnrollmentAndDismissal ProgramID]
  ,Agencies.Site_ID
  ,Agencies.AGENCY_INFO_0_NAME
  ,Agencies.Program_ID
  ,Agencies.[State]
FROM
  EnrollmentAndDismissal
  LEFT OUTER JOIN Demographics_Survey
    ON EnrollmentAndDismissal.CLID = Demographics_Survey.CL_EN_GEN_ID AND EnrollmentAndDismissal.ProgramID = Demographics_Survey.ProgramID
  LEFT OUTER JOIN Agencies
    ON EnrollmentAndDismissal.SiteID = Agencies.Site_ID
  LEFT OUTER JOIN Mstr_surveys
    ON Demographics_Survey.SurveyID = Mstr_surveys.SurveyID
  INNER JOIN ProgramsAndSites
    ON EnrollmentAndDismissal.ProgramID = ProgramsAndSites.ProgramID
	
WHERE
  ProgramsAndSites.ProgramName LIKE N'%Nurse%'
  AND (Agencies.[State] != 'NY'
  OR (Agencies.[State] = 'NY'
  AND (ProgramsAndSites.ProgramName LIKE N'%Onond%'
  OR ProgramsAndSites.ProgramName LIKE N'%Monroe%'
  --OR ProgramsAndSites.ProgramName LIKE N'%Brooklyn Hospital%'
  OR ProgramsAndSites.ProgramName LIKE N'%Cayuga%'
  --OR ProgramsAndSites.ProgramName  LIKE N'%VNS Nassau T1%'
  OR ProgramsAndSites.SiteID  IN(403,406,404,410,414))))
END
GO
