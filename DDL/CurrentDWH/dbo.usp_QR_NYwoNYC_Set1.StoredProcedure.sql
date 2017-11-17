USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_NYwoNYC_Set1]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_NYwoNYC_Set1]
	@State CHAR(2)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT
  EnrollmentAndDismissal.CLID
  ,EnrollmentAndDismissal.SiteID AS [EnrollmentAndDismissal SiteID]
  ,EnrollmentAndDismissal.ProgramID AS [EnrollmentAndDismissal ProgramID]
  ,ProgramsAndSites.ProgramID AS [ProgramsAndSites ProgramID]
  ,ProgramsAndSites.ProgramName
  ,ProgramsAndSites.SiteID AS [ProgramsAndSites SiteID]
  ,Infant_Health_Survey.SurveyResponseID AS [Infant_Health_Survey SurveyResponseID]
  ,Infant_Health_Survey.SurveyID AS [Infant_Health_Survey SurveyID]
  ,Infant_Health_Survey.SurveyDate AS [Infant_Health_Survey SurveyDate]
  ,Infant_Health_Survey.CL_EN_GEN_ID AS [Infant_Health_Survey CL_EN_GEN_ID]
  ,Infant_Health_Survey.SiteID AS [Infant_Health_Survey SiteID]
  ,Infant_Health_Survey.ProgramID AS [Infant_Health_Survey ProgramID]
  ,Infant_Health_Survey.ClientID AS [Infant_Health_Survey ClientID]
  ,Infant_Health_Survey.INFANT_HEALTH_IMMUNIZ_0_UPDATE
  ,Mstr_surveys.SurveyID AS [Mstr_surveys SurveyID]
  ,Mstr_surveys.SurveyName
  ,ASQ3_Survey.INFANT_AGES_STAGES_1_COMM
  ,ASQ3_Survey.INFANT_AGES_STAGES_1_GMOTOR
  ,ASQ3_Survey.INFANT_AGES_STAGES_1_FMOTOR
  ,ASQ3_Survey.INFANT_AGES_STAGES_1_PSOLVE
  ,ASQ3_Survey.INFANT_AGES_STAGES_1_PSOCIAL
  ,Infant_Birth_Survey.SurveyResponseID AS [Infant_Birth_Survey SurveyResponseID]
  ,Infant_Birth_Survey.SurveyID AS [Infant_Birth_Survey SurveyID]
  ,Infant_Birth_Survey.SurveyDate AS [Infant_Birth_Survey SurveyDate]
  ,Infant_Birth_Survey.CL_EN_GEN_ID AS [Infant_Birth_Survey CL_EN_GEN_ID]
  ,Infant_Birth_Survey.SiteID AS [Infant_Birth_Survey SiteID]
  ,Infant_Birth_Survey.ProgramID AS [Infant_Birth_Survey ProgramID]
  ,Infant_Birth_Survey.INFANT_BIRTH_1_GEST_AGE
  ,Infant_Birth_Survey.ClientID AS [Infant_Birth_Survey ClientID]
  ,Infant_Birth_Survey.INFANT_BREASTMILK_0_EVER_BIRTH
  ,Infant_Health_Survey.INFANT_BREASTMILK_1_CONT
  ,EnrollmentAndDismissal.ProgramStartDate
  ,Clients.Client_Id
  ,Clients.Site_ID AS [Clients Site_ID]
  ,Clients.DOB
  ,Agencies.AGENCY_INFO_0_NAME
  ,Agencies.Site_ID AS [Agencies Site_ID]
  ,Agencies.[State]
  ,Agencies.Program_ID
FROM
  EnrollmentAndDismissal
  INNER JOIN ProgramsAndSites
    ON EnrollmentAndDismissal.ProgramID = ProgramsAndSites.ProgramID
  LEFT OUTER JOIN Infant_Health_Survey
    ON EnrollmentAndDismissal.CLID = Infant_Health_Survey.CL_EN_GEN_ID AND EnrollmentAndDismissal.ProgramID = Infant_Health_Survey.ProgramID
  LEFT OUTER JOIN ASQ3_Survey
	ON EnrollmentAndDismissal.CLID = ASQ3_Survey.CL_EN_GEN_ID AND EnrollmentAndDismissal.ProgramID = ASQ3_Survey.ProgramID
  LEFT OUTER JOIN Mstr_surveys
    ON Infant_Health_Survey.SurveyID = Mstr_surveys.SurveyID
  LEFT OUTER JOIN Infant_Birth_Survey
    ON EnrollmentAndDismissal.CLID = Infant_Birth_Survey.CL_EN_GEN_ID
  LEFT OUTER JOIN Agencies
    ON EnrollmentAndDismissal.SiteID = Agencies.Site_ID
  LEFT OUTER JOIN Clients
    ON EnrollmentAndDismissal.CLID = Clients.Client_Id

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
