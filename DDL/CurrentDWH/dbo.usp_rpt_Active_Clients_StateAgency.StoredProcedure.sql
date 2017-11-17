USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_Active_Clients_StateAgency]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Antoniette Jenik
-- Create date: 12/16/2011
-- Description:	Active Client Detail Report
-- =============================================
CREATE PROCEDURE [dbo].[usp_rpt_Active_Clients_StateAgency]
	-- Add the parameters for the stored procedure here
	@EndDate DATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

-- Insert statements for procedure here
WITH VACS AS 
(
	SELECT     CL_EN_GEN_ID, SiteID, ProgramID, SurveyDate
	FROM         DataWarehouse.dbo.Home_Visit_Encounter_Survey
	WHERE     CLIENT_COMPLETE_0_VISIT LIKE '%comp%'
			OR CLIENT_COMPLETE_0_VISIT LIKE '%ATTEMPT%'
	UNION ALL
	SELECT     CL_EN_GEN_ID, SiteID, ProgramID, SurveyDate
	FROM         DataWarehouse.dbo.Alternative_Encounter_Survey
),
EADTable AS
(
SELECT
	  EAD2.[CLID]
      ,EAD2.[EndDate]
      ,EAD2.[CaseNumber]
      ,PAS2.ProgramName
      ,PAS2.Site
      ,EAD2.SiteID
      ,EAD2.ProgramID
      ,EAD2.AuditDate
      ,CASE
		WHEN EAD2.EndDate IS NULL THEN '1'
		ELSE '0'
	  END OpenYN
	  ,AG2.AGENCY_INFO_0_NAME
	  ,AG2.State
		FROM DataWarehouse..EnrollmentAndDismissal EAD2
			INNER JOIN DataWarehouse..ProgramsAndSites PAS2
				ON PAS2.ProgramID = EAD2.ProgramID
				AND PAS2.SiteID = EAD2.SiteID
				AND PAS2.ProgramName LIKE '%NURSE%'
			INNER JOIN DataWarehouse..Agencies AG2
				ON AG2.Site_ID = EAD2.SiteID
)


SELECT 

	EAD.CaseNumber
	,MAX(EAD.CLID) CLID
	,C.First_Name
	,C.Last_Name
	,MAX(EAD.ProgramStartDate) MostRecentProgStartDate
	,MIN(HVES.SurveyDate) FirstVisit
	,MAX(HVES.SurveyDate) LastVisit
	,MAX(IBS.INFANT_BIRTH_0_DOB) INFANT_BIRTH_0_DOB
	,DATEDIFF(D,MAX(IBS.INFANT_BIRTH_0_DOB),@EndDate) InfantAge
	,(
		SELECT TOP 1 PAS2.Site
		FROM EADTable PAS2
		WHERE PAS2.CaseNumber = EAD.CaseNumber
		ORDER BY PAS2.OpenYN DESC,PAS2.AuditDate DESC
	 ) MostRecentSite
	,(
		SELECT TOP 1 EAD2.EndDate
		FROM EADTable EAD2
		WHERE EAD2.CaseNumber = EAD.CaseNumber
		ORDER BY EAD2.OpenYN DESC,EAD2.AuditDate DESC
	 ) LatestEndDate
	,(
		SELECT TOP 1 AG.AGENCY_INFO_0_NAME
		FROM EADTable AG
		WHERE AG.CaseNumber = EAD.CaseNumber
		ORDER BY AG.OpenYN DESC, AG.AuditDate DESC
	 ) [Agency]
	,(
		SELECT TOP 1 AG.State
		FROM EADTable AG
		WHERE AG.CaseNumber = EAD.CaseNumber
		ORDER BY AG.OpenYN DESC, AG.AuditDate DESC
	 ) [Agency's State]

FROM DataWarehouse..EnrollmentAndDismissal EAD
	  LEFT JOIN DataWarehouse..VACS HVES
            ON EAD.CLID = HVES.CL_EN_GEN_ID
      LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
            ON IBS.CL_EN_GEN_ID = HVES.CL_EN_GEN_ID
      INNER JOIN DataWarehouse..ProgramsAndSites PAS
		ON PAS.SiteID = EAD.SiteID
		AND PAS.ProgramID = EAD.ProgramID
		AND PAS.ProgramName LIKE '%NURSE%'
		AND PAS.Site NOT LIKE '%TEST%'
		AND PAS.Site NOT LIKE '%TRAIN%'
		AND PAS.Site NOT LIKE '%DEMO%'
		AND PAS.Site NOT LIKE '%PROOF%'
		AND PAS.ProgramName NOT LIKE '%TEST%'
		AND PAS.ProgramName NOT LIKE '%TRAIN%'
		AND PAS.ProgramName NOT LIKE '%DEMO%'
		AND PAS.ProgramName NOT LIKE '%PROOF%'
	INNER JOIN DataWarehouse..Clients C
		ON C.Client_Id = EAD.CaseNumber	
		AND C.Last_Name <> 'FAKE'
	INNER JOIN (
					SELECT EAD2.EndDate, EAD2.CaseNumber
					FROM DataWarehouse..view_EADTable EAD2
					WHERE CASE WHEN EAD2.EndDate > @EndDate OR EAD2.OpenYN = 1 THEN 1 END IS NOT NULL
					GROUP BY EAD2.EndDate,EAD2.CaseNumber
				) EADT ON EADT.CaseNumber = EAD.CaseNumber
           
WHERE (
			HVES.SurveyDate > DATEADD(D,-180,@EndDate) 
			OR 
			(
					ABS(DATEDIFF(D,@EndDate,EAD.ProgramStartDate))<=60
						AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > @EndDate)
						AND EAD.ProgramStartDate  < DATEADD(D,1,@EndDate)
						AND (EADT.EndDate > @EndDate or EADT.EndDate is null)
			   )
		  )
      AND (
			DATEDIFF(D,IBS.INFANT_BIRTH_0_DOB,@EndDate) <= 730 
            OR IBS.INFANT_BIRTH_0_DOB IS NULL
          )
      AND DATEDIFF(D,EAD.ProgramStartDate,@EndDate) <= 1050
	  AND EAD.ProgramStartDate < DATEADD(D,1,@EndDate)

	
GROUP BY 	
	EAD.CaseNumber
	,C.First_Name
	,C.Last_Name


END
GO
