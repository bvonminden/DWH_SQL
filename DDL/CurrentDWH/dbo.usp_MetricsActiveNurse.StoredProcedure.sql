USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_MetricsActiveNurse]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Andrew Grant
-- Create date: 12/24/2014
-- Description:	Per the requirements, I used the definition of "Active" Nurses from the report "Active Nurses Report". 
-- That report defines "Active" Nurses as an NFP with a home visit between two dates.
-- Since the purpose of this section (per the requirements) is the number of active nurses at the end of the month, I have calculated the 
-- start and end dates to be the first and last days of the month.
-- =============================================
CREATE PROCEDURE [dbo].[usp_MetricsActiveNurse]
	-- Add the parameters for the stored procedure here
	@RefDate DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	--DECLARE @EndDate As DATE = CAST('1/1/2014' AS DATE);--CAST(GETDATE() AS DATE);
    DECLARE @FirstDayOfMonth DATETIME
    
	--First day of month containing RefDate
	SET @FirstDayOfMonth = DATEADD(dd, -(DAY(@RefDate)-1), @RefDate)
	
    --DECLARE @EndDate As DATE = CAST('1/1/2014' AS DATE);--CAST(GETDATE() AS DATE);
    DECLARE @LastDayOfMonth DATETIME

	----Last Day of Month containing the @RefDate
	SET @LastDayOfMonth = DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@RefDate)+1,0))
  
;WITH ActiveNHV AS
(
	
SELECT 
	CAST(HVES.CL_EN_GEN_ID AS VARCHAR(MAX)) CL_EN_GEN_ID
	,HVES.NURSE_PERSONAL_0_NAME Nurse
	--,HVES.IA_StaffID NurseID
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


WHERE HVES.SurveyDate BETWEEN @FirstDayOfMonth AND @LastDayOfMonth
	AND HVES.CLIENT_COMPLETE_0_VISIT IN ('ATTEMPTED', 'COMPLETED' )

GROUP BY 
	HVES.CL_EN_GEN_ID
	,HVES.NURSE_PERSONAL_0_NAME 
	--,HVES.IA_StaffID
	,HVES.ProgramID
	,HVES.SiteID
	,YEAR(HVES.SurveyDate) 
	,MONTH(HVES.SurveyDate) 
	,A.STATE
	,A.AGENCY_INFO_0_NAME 

UNION 

SELECT 
	CAST(HVES.CL_EN_GEN_ID AS VARCHAR(MAX)) CL_EN_GEN_ID
	,HVES.NURSE_PERSONAL_0_NAME Nurse
	--,HVES.IA_StaffID NurseID
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


WHERE HVES.SurveyDate BETWEEN @FirstDayOfMonth AND @LastDayOfMonth

GROUP BY 
	HVES.CL_EN_GEN_ID  
	,HVES.NURSE_PERSONAL_0_NAME 
	--,HVES.IA_StaffID
	,HVES.ProgramID
	,HVES.SiteID
	,YEAR(HVES.SurveyDate) 
	,MONTH(HVES.SurveyDate) 
	,A.STATE
	,A.AGENCY_INFO_0_NAME 
	
UNION

SELECT 
	CAST(V.CLIENTID AS VARCHAR(MAX)) CL_EN_GEN_ID
	,N.NURSEID
	,'' [Site]
	,'' [ProgramID]
	,YEAR(V.FORMDATE) [Year]
	,MONTH(V.FORMDATE) [Month]
	,S.REGIONALCODE [State]
	,S.NAME
	
FROM NFP_Master.PRCLIVE.NURSE_TBL N
	INNER JOIN NFP_Master.PRCLIVE.VISIT_TBL V
		ON CAST(N.NURSEID AS VARCHAR(50)) = CAST(V.HMVSTRID AS VARCHAR(50))
	INNER JOIN NFP_Master.PRCLIVE.SITE_TBL S
		ON S.SITECODE = V.SITECODE
		AND S.NAME LIKE '%Closed%'

WHERE V.FORMDATE BETWEEN  @FirstDayOfMonth AND @LastDayOfMonth
		
GROUP BY 
	V.CLIENTID
	,N.NURSEID
	,V.SITECODE
	,V.SITECODE
	,MONTH(V.FORMDATE)
	,YEAR(V.FORMDATE)
	,S.REGIONALCODE
	,S.NAME
	
	

)

SELECT ActiveNHV.State, COUNT (DISTINCT Nurse) FROM ActiveNHV
GROUP BY ActiveNHV.State


END


GO
