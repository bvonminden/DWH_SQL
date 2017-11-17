USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_ActiveNursesbyState]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Antoniette Jenik
-- Create date: 1/17/2012
-- Description:	Active Nurses Report by State
-- =============================================
CREATE PROCEDURE [dbo].[usp_ActiveNursesbyState]
	-- Add the parameters for the stored procedure here
	@StartDate Date
	,@EndDate Date
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SET NOCOUNT ON;

SELECT 
	HVES.CL_EN_GEN_ID
	,HVES.NURSE_PERSONAL_0_NAME Nurse
	,HVES.ProgramID
	,HVES.SiteID
	,YEAR(HVES.SurveyDate) [Year]
	,MONTH(HVES.SurveyDate) [Month]
	,A.STATE
	,A.AGENCY_INFO_0_NAME Agency
	
	
FROM DataWarehouse..Home_Visit_Encounter_Survey HVES
	INNER JOIN DataWarehouse..ProgramsAndSites PAS
		ON PAS.ProgramID = HVES.ProgramID
		AND PAS.ProgramName LIKE '%NURSE%'
		AND PAS.Site NOT LIKE '%TEST%'
		AND PAS.Site NOT LIKE '%TRAIN%'
		AND PAS.Site NOT LIKE '%PROOF%CONCEPT%'
	INNER JOIN DataWarehouse..Agencies A	
		ON A.Site_ID = PAS.SiteID


WHERE HVES.SurveyDate BETWEEN @StartDate AND @EndDate
	AND HVES.CLIENT_COMPLETE_0_VISIT IN ('ATTEMPTED', 'COMPLETED' )

GROUP BY 
	HVES.CL_EN_GEN_ID
	,HVES.NURSE_PERSONAL_0_NAME 
	,HVES.ProgramID
	,HVES.SiteID
	,YEAR(HVES.SurveyDate) 
	,MONTH(HVES.SurveyDate) 
	,A.STATE
	,A.AGENCY_INFO_0_NAME 

UNION 

SELECT 
	HVES.CL_EN_GEN_ID
	,HVES.NURSE_PERSONAL_0_NAME Nurse
	,HVES.ProgramID
	,HVES.SiteID
	,YEAR(HVES.SurveyDate) [Year]
	,MONTH(HVES.SurveyDate) [Month]
	,A.STATE
	,A.AGENCY_INFO_0_NAME Agency
	
	
FROM DataWarehouse..Alternative_Encounter_Survey HVES
	INNER JOIN DataWarehouse..ProgramsAndSites PAS
		ON PAS.ProgramID = HVES.ProgramID
		AND PAS.ProgramName LIKE '%NURSE%'
		AND PAS.Site NOT LIKE '%TEST%'
		AND PAS.Site NOT LIKE '%TRAIN%'
		AND PAS.Site NOT LIKE '%PROOF%CONCEPT%'
	INNER JOIN DataWarehouse..Agencies A	
		ON A.Site_ID = PAS.SiteID


WHERE HVES.SurveyDate BETWEEN @StartDate AND @EndDate

GROUP BY 
	HVES.CL_EN_GEN_ID
	,HVES.NURSE_PERSONAL_0_NAME 
	,HVES.ProgramID
	,HVES.SiteID
	,YEAR(HVES.SurveyDate) 
	,MONTH(HVES.SurveyDate) 
	,A.STATE
	,A.AGENCY_INFO_0_NAME 

END
GO
