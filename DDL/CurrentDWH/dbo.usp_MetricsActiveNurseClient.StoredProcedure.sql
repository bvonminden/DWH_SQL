USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_MetricsActiveNurseClient]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Andrew Grant
-- Create date: 12/24/2014
-- Description:	Per the requirements, I used the definition of "Active" Clients from the report "Active Clients by Agency and State". 
-- That report defines "Active" Client as a client with a home visit prior to the @enddate (@RefDate), with a program start date prior to the @enddate,
-- and a Program EndDate after the @enddate.  It doesn't check for clients with null Program EndDates, because this field is calculated to be exactly two years
-- after the child's DOB.
-- =============================================
CREATE PROCEDURE [dbo].[usp_MetricsActiveNurseClient]
	-- Add the parameters for the stored procedure here
	@RefDate DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --DECLARE @EndDate As DATE = CAST('1/1/2014' AS DATE);--CAST(GETDATE() AS DATE);
    DECLARE @LastDayOfMonth DATETIME

	----Last Day of Month containing the @RefDate
	SET @LastDayOfMonth = DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@RefDate)+1,0))
	
	--DECLARE @EndDate As DATE = CAST('1/1/2014' AS DATE);--CAST(GETDATE() AS DATE);
    DECLARE @FirstDayOfMonth DATETIME
    
	--First day of month containing RefDate
	SET @FirstDayOfMonth = DATEADD(dd, -(DAY(@RefDate)-1), @RefDate)
	
       
	
;WITH HV2 AS
(
				SELECT 
						H.CL_EN_GEN_ID CLID
						,MAX(H.SurveyDate) LastVisit
						,MIN(H.SurveyDate) FirstVisit
						,H.ProgramID
						,A.State [STATE]
					FROM DataWarehouse..UV_HVES H
					INNER JOIN DataWarehouse..ProgramsAndSites PAS
						ON PAS.ProgramID = H.ProgramID 
					INNER JOIN DataWarehouse..Agencies A
						ON A.Site_ID = PAS.SiteID
					WHERE H.SurveyDate < = @LastDayOfMonth
					GROUP BY H.CL_EN_GEN_ID, H.ProgramID, A.State
				)
				
,ACTClient AS
(
				
SELECT A.State [STATE]
	,A.AGENCY_INFO_0_NAME Agency
	,COUNT(*) AS ClientCount				
FROM DataWarehouse..AC_Dates AC
	INNER JOIN DataWarehouse..UV_EADT EAD
		ON EAD.CLID = AC.CLID
		AND EAD.ProgramID = AC.ProgramID
		AND EAD.RankingLatest = 1
	INNER JOIN DataWarehouse..ProgramsAndSites PAS
		ON PAS.ProgramID = EAD.ProgramID 
	LEFT JOIN HV2
		ON HV2.CLID = EAD.CLID
		AND HV2.ProgramID = EAD.ProgramID
	INNER JOIN DataWarehouse..Agencies A
		ON A.Site_ID = PAS.SiteID
	LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
		ON IBS.CL_EN_GEN_ID = EAD.CLID
	LEFT JOIN DataWarehouse..Clients C
		ON C.Client_Id = EAD.CLID

WHERE AC.ProgramStartDate <= @LastDayOfMonth
	AND AC.EndDate > @LastDayOfMonth		
GROUP BY 	
	A.State,
	A.AGENCY_INFO_0_NAME
	
),

NurseVisit AS
(
	
SELECT 
	DISTINCT
	--CAST(HVES.CL_EN_GEN_ID AS VARCHAR(MAX)) CL_EN_GEN_ID
	--,
	HVES.NURSE_PERSONAL_0_NAME Nurse
	--,HVES.IA_StaffID NurseID
	--,HVES.ProgramID
	--,HVES.SiteID
	--,YEAR(HVES.SurveyDate) [Year]
	--,MONTH(HVES.SurveyDate) [Month]
	
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
	DISTINCT
	--CAST(HVES.CL_EN_GEN_ID AS VARCHAR(MAX)) CL_EN_GEN_ID
	--,
	HVES.NURSE_PERSONAL_0_NAME Nurse
	----,HVES.IA_StaffID NurseID
	--,HVES.ProgramID
	--,HVES.SiteID
	--,YEAR(HVES.SurveyDate) [Year]
	--,MONTH(HVES.SurveyDate) [Month]
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
	DISTINCT
	--CAST(V.CLIENTID AS VARCHAR(MAX)) CL_EN_GEN_ID
	--,
	N.NURSEID
	--,'' [Site]
	--,'' [ProgramID]
	--,YEAR(V.FORMDATE) [Year]
	--,MONTH(V.FORMDATE) [Month]
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
,

ActiveNurse AS
(
	SELECT NV.State, NV.Agency, COUNT(NV.Nurse) AS NHVCount
	FROM NurseVisit NV
	GROUP BY NV.Agency,	NV.State

)


SELECT AC.STATE, AC.Agency, AC.ClientCount, AN.NHVCount 
FROM  ACTClient AC
--INNER JOIN ActiveNurse AN ON AN.State = AC.State
INNER JOIN ActiveNurse AN ON AN.Agency = AC.Agency
GROUP BY AC.State, AC.Agency, AC.ClientCount, AN.NHVCount
ORDER BY AC.STATE



END


GO
