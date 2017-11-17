USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_NYwoNYC_Set3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_NYwoNYC_Set3] 
	@State CHAR(2)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT
  EnrollmentAndDismissal.CLID
  ,EnrollmentAndDismissal.ProgramID AS [EnrollmentAndDismissal ProgramID]
  ,EnrollmentAndDismissal.SiteID AS [EnrollmentAndDismissal SiteID]
  ,Infant_Birth_Survey.SurveyID AS [Infant_Birth_Survey SurveyID]
  ,Infant_Birth_Survey.SurveyResponseID
  ,Infant_Birth_Survey.CL_EN_GEN_ID
  ,Infant_Birth_Survey.SiteID AS [Infant_Birth_Survey SiteID]
  ,Infant_Birth_Survey.ProgramID AS [Infant_Birth_Survey ProgramID]
  ,Infant_Birth_Survey.INFANT_BREASTMILK_0_EVER_BIRTH
  ,Mstr_surveys.SurveyID AS [Mstr_surveys SurveyID]
  ,Mstr_surveys.SurveyName
  ,ProgramsAndSites.ProgramID AS [ProgramsAndSites ProgramID]
  ,ProgramsAndSites.ProgramName
  ,ProgramsAndSites.Site
  ,ProgramsAndSites.SiteID AS [ProgramsAndSites SiteID]
  ,Agencies.Site_ID
  ,Agencies.Program_ID
  ,Infant_Birth_Survey.SurveyDate
FROM
  EnrollmentAndDismissal
  INNER JOIN ProgramsAndSites
    ON EnrollmentAndDismissal.ProgramID = ProgramsAndSites.ProgramID
  LEFT OUTER JOIN Infant_Birth_Survey
    ON EnrollmentAndDismissal.CLID = Infant_Birth_Survey.CL_EN_GEN_ID AND EnrollmentAndDismissal.ProgramID = Infant_Birth_Survey.ProgramID
  LEFT OUTER JOIN Agencies
    ON EnrollmentAndDismissal.SiteID = Agencies.Site_ID
  LEFT OUTER JOIN Mstr_surveys
    ON Infant_Birth_Survey.SurveyID = Mstr_surveys.SurveyID
	
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
