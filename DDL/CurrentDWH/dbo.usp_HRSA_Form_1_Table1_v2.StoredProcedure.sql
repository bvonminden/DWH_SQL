USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_HRSA_Form_1_Table1_v2]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_HRSA_Form_1_Table1_v2]
(@StartDate DATE
 ,@EndDate Date
 ,@FundingType VARCHAR(MAX)
 ,@Teams VARCHAR(MAX)
 ,@NHV VARCHAR(MAX))
 
 AS
 
--declare @startdate date set @startdate = '10/1/2012'
--declare @enddate date set @enddate = '9/13/2013'
--declare @fundingtype VARCHAR(500) set @fundingtype = '1'
--declare @Teams VARCHAR(500) SET @Teams = '1001,1004,1007,1010,1013,1576,1887,1922,1925,1943,1988,854,857,860,863,866,869,971,974,977,980,983,986,989,992,995,998,'
--declare @NHV VARCHAR(500) SET @NHV = '6165,6174,6176,6178,6180,6272,6274,6276,6278,6282,6288,6290,6292,6294,6296';--7926;
;
WITH SXC AS 
(			
	SELECT StaffID,CLID,ProgramID,NULL EndDate
	FROM StaffxClient
	UNION ALL
	SELECT StaffID,CLID,ProgramID,EndDate
	FROM StaffxClientHx
)
, StaffxCL AS
(
	SELECT 
		StaffID,CLID,ProgramID,EndDate 
		,RANK() OVER(PARTITION BY CLID,ProgramID ORDER BY EndDate DESC) Ranking

	FROM SXC
	WHERE ISNULL(SXC.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate

)

SELECT 
	P.AGENCY_INFO_0_NAME
	,P.SiteID AS [Agencies Site_ID]
	,P.[StateID] [State]
	,C.Client_Id
	,C.DOB
	,EAD.CLID
	,EAD.ProgramStartDate
	,EAD.EndDate
	,IBS.INFANT_BIRTH_0_DOB
	,C.Marital_Status
	,MIN(ISNULL(CF.CLIENT_FUNDING_1_START_MIECHVP_COM,CF.CLIENT_FUNDING_1_START_MIECHVP_FORM)) [Funding Start]
	,MAX(CASE	
		WHEN EAD.ProgramStartDate BETWEEN @StartDate AND @EndDate
			--AND CF.CL_EN_GEN_ID IS NOT NULL
		THEN EAD.CLID
	END) [Newly Enrolled MIECHV During Reporting Period]
	,MAX([MIECHV Served During Reporting Period])[MIECHV Served During Reporting Period]
	,MAX([MIECHV Infants Born During Reporting Period])[MIECHV Infants Born During Reporting Period]
	,MAX([MIECHV Infants Served During Reporting Period])[MIECHV Infants Served During Reporting Period]
	,C.DEMO_CLIENT_INTAKE_0_ETHNICITY 
	,C.DEMO_CLIENT_INTAKE_0_RACE 
	,MAX([Child Age at End of Quarter])[Child Age at End of Quarter]
	,IBS.INFANT_PERSONAL_0_GENDER
	,IBS.INFANT_PERSONAL_0_ETHNICITY
	,IBS.INFANT_PERSONAL_0_RACE
	,CASE
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 0 AND 3652.49 THEN 'Under 10'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 3652.5 AND 5478.74 THEN '10-14' 
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 5478.75 AND 6574.49 THEN '15-17'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 6574.5 AND 7304.99 THEN '18-19'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 7305 AND 8035.49 THEN '20-21'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 8035.5 AND 9131.24 THEN '22-24'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 9131.25 AND 10957.49 THEN '25-29'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 10957.5 AND 12783.74 THEN '30-34'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 12783.75 AND 16436.24 THEN '35-44'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 16436.25 AND 20088.74 THEN '45-54'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 20088.75 AND 23741.24 THEN '55-64'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) >= 23741.25 THEN '65+'
		ELSE 'Unknown/Did Not Report'
	 END [Clients Age]
	,CASE
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 0 AND 3652.49 THEN 1
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 3652.5 AND 5478.74 THEN 2
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 5478.75 AND 6574.49 THEN 3
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 6574.5 AND 7304.99 THEN 4
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN  7305 AND 8035.49 THEN 5
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN  8035.5 AND 9131.24 THEN 6
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 9131.25 AND 10957.49 THEN 7
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 10957.5 AND 12783.74 THEN 8
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 12783.75 AND 16436.24 THEN 9
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 16436.25 AND 20088.74 THEN 10
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 20088.75 AND 23741.24 THEN 11
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) >= 23741.25 THEN 12
		ELSE 13
	 END [Clients Age Sorting]
	,[Currently Rcv Svcs]
	,MAX( [Home visits during reporting period]) [Home visits during reporting period]
					
	,CASE 
		WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL THEN 'Competitive'
		WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL THEN 'Formula'
		WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL IS NOT NULL THEN 'Tribal'
		ELSE 'Other'
	 END FundingType
  ,CASE
	WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL THEN 1
	WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL THEN 2
	WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL IS NOT NULL THEN 3
	ELSE 4
END FundingSort
	,S.Full_Name,S.Entity_ID
	,DD.CLIENT_INCOME_1_LOW_INCOME_QUALIFY
	,HHI.CLIENT_SUBSTANCE_CIG_1_LAST_48
	,DD.CLIENT_MILITARY

FROM UV_EADT EAD
  LEFT OUTER JOIN
	DataWarehouse..UV_PAS P ON EAD.ProgramID = P.ProgramID
  INNER JOIN DataWarehouse..UV_PAS PAS
    ON EAD.ProgramID = PAS.ProgramID

	INNER JOIN DataWarehouse..Clients C
		ON EAD.CLID = C.Client_Id
	LEFT JOIN DataWarehouse..Client_Funding_Survey CF
		ON EAD.CLID = CF.CL_EN_GEN_ID
		AND EAD.ProgramID = CF.ProgramID
		AND (CF.CLIENT_FUNDING_1_START_MIECHVP_COM >= '10/1/2010'
			OR CF.CLIENT_FUNDING_1_START_MIECHVP_FORM >= '10/1/2010'
			OR CF.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL >= '10/1/2010')
	LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
		ON IBS.CL_EN_GEN_ID = EAD.CLID
		AND IBS.ProgramID = EAD.ProgramID
		AND IBS.SurveyDate < = @EndDate
	--LEFT JOIN DataWarehouse..Home_Visit_Encounter_Survey HVES
	--	ON EAD.CLID = HVES.CL_EN_GEN_ID 
	--	AND EAD.ProgramID = HVES.ProgramID
	--	AND HVES.SurveyDate BETWEEN @StartDate AND @EndDate
	--	AND HVES.CLIENT_COMPLETE_0_VISIT ='Completed'
	LEFT JOIN DataWarehouse..Demographics_Survey DD
		ON EAD.ProgramID = DD.ProgramID 
		AND EAD.CLID = DD.CL_EN_GEN_ID
		AND DataWarehouse.dbo.fnGetFormName(DD.SurveyID) LIKE '%PREG%'
		AND DD.SurveyDate < = @EndDate
		AND EAD.ProgramStartDate BETWEEN @StartDate AND @EndDate
	LEFT JOIN DataWarehouse..Health_Habits_Survey HHI
		ON HHI.CL_EN_GEN_ID = EAD.CLID
		AND HHI.ProgramID = EAD.ProgramID
		AND HHI.SurveyDate < = @EndDate
		AND DataWarehouse.dbo.fnGetFormName(HHI.SurveyID) LIKE '%INTAKE%'	
		AND EAD.ProgramStartDate BETWEEN @StartDate AND @EndDate
	INNER JOIN StaffxCL SC
		ON SC.CLID = EAD.CLID
		AND SC.ProgramID = EAD.ProgramID
		AND SC.Ranking = 1
	INNER JOIN StaffXEntities SE
		ON SE.StaffID = SC.StaffID
	INNER JOIN dbo.fn_FID_Staff_list('1/1/1900',@EndDate) S
		ON S.Entity_ID = SE.EntityID
		AND S.ProgramID = P.ProgramID
	INNER JOIN DBO.udf_HRSA_MIECHV_ServedEnrolled_v2(@StartDate, @EndDate,@FundingType,@Teams) HM
		ON HM.CLID = EAD.CLID
		AND HM.ProgramID = EAD.ProgramID
WHERE 
	EAD.ProgramStartDate < = @EndDate
	AND ISNULL(EAD.EndDate,GETDATE()) > = @StartDate
	AND EAD.RankingLatest = 1
	AND P.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Teams))
	AND CASE
			WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL THEN 1
			WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL THEN 2
			WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL IS NOT NULL THEN 3
			ELSE 4
		END IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType))
	AND S.Entity_ID IN (SELECT * FROM dbo.udf_ParseMultiParam(@NHV))
--and ead.clid in (515295,539817)	
--	and ead.clid in (488686,
--488694,
--490570,
--492281,
--499323,
--503346,
--518422,
--522769,
--281145,
--281146,
--499531,
--465205,
--449980,
--474409,
--467758,
--528325,
--494684,
--527664,
--527654,
--530313,
--532944)

	 
GROUP BY EAD.ReasonForDismissal,EAD.EndDate,
P.AGENCY_INFO_0_NAME
	,P.SiteID 
	,P.[StateID]
	,C.Client_Id
	,EAD.ProgramStartDate
	,EAD.EndDate
	,C.Marital_Status
	,IBS.INFANT_BIRTH_0_DOB
	,C.DEMO_CLIENT_INTAKE_0_ETHNICITY 
	,C.DEMO_CLIENT_INTAKE_0_RACE 
	,C.DOB
	,EAD.CLID
	,IBS.INFANT_PERSONAL_0_GENDER
	,IBS.INFANT_PERSONAL_0_ETHNICITY
	,IBS.INFANT_PERSONAL_0_RACE
	--,CASE WHEN HVES.SurveyDate BETWEEN @StartDate AND @EndDate AND HVES.CLIENT_COMPLETE_0_VISIT LIKE '%COMPLET%'
	--	THEN CASE 
	--			WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) > @EndDate 
	--			THEN 'Currently receiving services'
	--			WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) <= @EndDate
	--				AND EAD.ReasonForDismissal LIKE '%2%' 
	--			THEN 'Completed program'
	--			WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) <= @EndDate
	--				AND EAD.ReasonForDismissal NOT LIKE '%2%' 
	--			THEN 'Stopped services before completion'
	--			ELSE 'Other'
	--	END
	-- END
	 ,CASE 
		WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL THEN 'Competitive'
		WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL THEN 'Formula'
		WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL IS NOT NULL THEN 'Tribal'
		ELSE 'Other'
	 END 
  ,CASE
	WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL THEN 1
	WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL THEN 2
	WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL IS NOT NULL THEN 3
	ELSE 4
END 
	,S.Full_Name,S.Entity_ID

	,DD.CLIENT_INCOME_1_LOW_INCOME_QUALIFY
	,HHI.CLIENT_SUBSTANCE_CIG_1_LAST_48
	,DD.CLIENT_MILITARY
		,[Currently Rcv Svcs]
	
	
	
UNION ALL
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Under 10',1,'Currently receiving services',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'10-14',2,'Completed program',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'15-17',3,'Stopped services before completion',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'18-19',4,'Other',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'20-21',5,'Other',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'22-24',6,'Other',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'25-29',7,'Other',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'30-34',8,'Other',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'35-44',9,'Other',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'45-54',10,'Other',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'55-64',11,'Other',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'65+',12,'Other',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Unknown/did not report',13,'Other',NULL,CASE WHEN 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Competitive' WHEN 2 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Formula' WHEN 3 IN (SELECT * FROM dbo.udf_ParseMultiParam(@FundingType)) THEN 'Tribal' ELSE 'Other'END,NULL,NULL,NULL,NULL,NULL,NULL 
GO
