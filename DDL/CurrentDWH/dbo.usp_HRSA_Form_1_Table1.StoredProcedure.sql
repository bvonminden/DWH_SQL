USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_HRSA_Form_1_Table1]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_HRSA_Form_1_Table1]
(@StartDate DATE
 ,@EndDate Date
 --,@SiteID Smallint
 ,@FundingType VARCHAR(50)
 ,@ReportType INT
 ,@ParentEntity VARCHAR(4000))
 
 AS


--declare @startdate date set @startdate = '10/1/2012'
--declare @enddate date set @enddate = '9/13/2013'
--declare @fundingtype varchar(50) set @fundingtype = 'Competitive'
----declare @siteid int set @siteid = 160
--declare @ReportType INT SET @ReportType = 2
--declare @ParentEntity VARCHAR(4000) SET @ParentEntity = 6

SELECT DISTINCT 
--EAD.ReasonForDismissal,EAD.EndDate,CASE 
--				WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) > @EndDate 
--				THEN 'Currently receiving services'
--				WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) <= @EndDate
--					AND EAD.ReasonForDismissal LIKE '%2%' 
--				THEN 'Completed program'
--				WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) <= @EndDate
--					AND EAD.ReasonForDismissal NOT LIKE '%2%' 
--				THEN 'Stopped services before completion'
--				ELSE 'Other'
--		END,
	A.AGENCY_INFO_0_NAME
	,A.Site_ID AS [Agencies Site_ID]
	,A.[State]
	,C.Client_Id
	,C.DOB
	,EAD.CLID
	,EAD.ProgramStartDate
	,EAD.EndDate
	,IBS.INFANT_BIRTH_0_DOB
	,C.Marital_Status
	--,CF.SurveyDate
	,MIN(ISNULL(CF.CLIENT_FUNDING_1_START_MIECHVP_COM,CF.CLIENT_FUNDING_1_START_MIECHVP_FORM)) [Funding Start]
	,MAX(CASE	
		WHEN EAD.ProgramStartDate BETWEEN @StartDate AND @EndDate
			AND CF.CL_EN_GEN_ID IS NOT NULL
		THEN EAD.CLID
	END) [Newly Enrolled MIECHV During Reporting Period]
	,MAX(CASE	
		WHEN HVES.SurveyDate BETWEEN @StartDate AND @EndDate
			AND CF.CL_EN_GEN_ID IS NOT NULL
		THEN EAD.CLID
	END) [MIECHV Served During Reporting Period]
	,MAX(CASE	
		WHEN IBS.INFANT_BIRTH_0_DOB BETWEEN @StartDate AND @EndDate
			AND CF.CL_EN_GEN_ID IS NOT NULL
		THEN EAD.CLID
	END) [MIECHV Infants Born During Reporting Period]
	,MAX(CASE	
		WHEN HVES.SurveyDate BETWEEN @StartDate AND @EndDate
			AND IBS.CL_EN_GEN_ID IS NOT NULL
			AND IBS.INFANT_BIRTH_0_DOB <= @EndDate
			AND CF.CL_EN_GEN_ID IS NOT NULL
		THEN EAD.CLID
	END) [MIECHV Infants Served During Reporting Period]
	,C.DEMO_CLIENT_INTAKE_0_ETHNICITY 
	,C.DEMO_CLIENT_INTAKE_0_RACE 
	,MAX(CASE	
		WHEN HVES.SurveyDate BETWEEN @StartDate AND @EndDate
			AND IBS.CL_EN_GEN_ID IS NOT NULL
			AND IBS.INFANT_BIRTH_0_DOB <= @EndDate
			AND CF.CL_EN_GEN_ID IS NOT NULL
		THEN CASE
				WHEN DATEDIFF(D,IBS.INFANT_BIRTH_0_DOB,@EndDate)/365.25 > 0
				THEN DATEDIFF(D,IBS.INFANT_BIRTH_0_DOB,@EndDate)/365.25
			END
	END) [Child Age at End of Quarter]
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
	,CASE WHEN HVES.SurveyDate BETWEEN @StartDate AND @EndDate AND HVES.CLIENT_COMPLETE_0_VISIT LIKE '%COMPLET%'
		THEN CASE 
				WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) > @EndDate 
				THEN 'Currently receiving services'
				WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) <= @EndDate
					AND EAD.ReasonForDismissal LIKE '%2%' 
				THEN 'Completed program'
				WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) <= @EndDate
					AND EAD.ReasonForDismissal NOT LIKE '%2%' 
				THEN 'Stopped services before completion'
				ELSE 'Other'
		END
	 END [Currently Rcv Svcs]
	,COUNT(DISTINCT CASE
						WHEN HVES.CLIENT_COMPLETE_0_VISIT LIKE '%COMPLET%'
							AND HVES.SurveyDate BETWEEN @StartDate AND @EndDate
						THEN HVES.SurveyResponseID
					END) [Home visits during reporting period]
					
	,CASE WHEN CF.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM] LIKE '%COMPETITIVE%' THEN 'Competitive'
		WHEN CF.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] LIKE '%FORMULA%' THEN 'Formula'
	 END FundingType
	
FROM DataWarehouse..UV_EADT EAD
  LEFT OUTER JOIN
	DataWarehouse..UV_PAS P ON EAD.ProgramID = P.ProgramID
  INNER JOIN DataWarehouse..UV_PAS PAS
    ON EAD.ProgramID = PAS.ProgramID
    
	INNER JOIN DataWarehouse..Agencies A
		ON EAD.SiteID = A.Site_ID
	INNER JOIN DataWarehouse..Clients C
		ON EAD.CLID = C.Client_Id
	INNER JOIN DataWarehouse..Client_Funding_Survey CF
		ON EAD.CLID = CF.CL_EN_GEN_ID
		AND EAD.ProgramID = CF.ProgramID
		--AND CF.SurveyDate < = @EndDate
		AND (CF.CLIENT_FUNDING_1_START_MIECHVP_COM >= '10/1/2010'
			OR CF.CLIENT_FUNDING_1_START_MIECHVP_FORM >= '10/1/2010')
	LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
		ON IBS.CL_EN_GEN_ID = EAD.CLID
		--AND IBS.ProgramID = EAD.ProgramID
		AND IBS.SurveyDate < = @EndDate
	LEFT JOIN DataWarehouse..Home_Visit_Encounter_Survey HVES
		ON EAD.CLID = HVES.CL_EN_GEN_ID 
	AND EAD.ProgramID = HVES.ProgramID
		AND HVES.SurveyDate BETWEEN @StartDate AND @EndDate
		AND HVES.CLIENT_COMPLETE_0_VISIT ='Completed'
WHERE
	--EAD.SiteID = @SiteID
	 CASE
		WHEN @ReportType = 1 THEN 1
		WHEN @ReportType = 2 THEN P.StateID
		WHEN @ReportType = 3 THEN P.SiteID
		WHEN @ReportType = 4 THEN P.ProgramID
	  END IN (@ParentEntity)
	AND EAD.ProgramStartDate < = @EndDate
	AND ISNULL(EAD.EndDate,GETDATE()) > = @StartDate
	AND EAD.RankingLatest = 1
	AND CASE WHEN CF.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM] LIKE '%COMPETITIVE%' THEN 'Competitive'
		WHEN CF.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] LIKE '%FORMULA%' THEN 'Formula'
	 END = @FundingType
	
	--and CASE WHEN HVES.SurveyDate BETWEEN @StartDate AND @EndDate AND HVES.CLIENT_COMPLETE_0_VISIT LIKE '%COMPLET%'
	--	THEN CASE 
	--			WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) > @EndDate 
	--			THEN 'Currently receiving services'
	--			WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) < @EndDate
	--				AND EAD.ReasonForDismissal LIKE '%2%' 
	--			THEN 'Completed program'
	--			WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) < @EndDate
	--				AND EAD.ReasonForDismissal NOT LIKE '%2%' 
	--			THEN 'Stopped services before completion'
	--			ELSE 'Other'
	--	END
	-- END = 'other' 
	 
GROUP BY EAD.ReasonForDismissal,EAD.EndDate,
A.AGENCY_INFO_0_NAME
	,A.Site_ID 
	,A.[State]
	,C.Client_Id
	,EAD.ProgramStartDate
	,EAD.EndDate
	,C.Marital_Status
	--,CF.SurveyDate
	--,ISNULL(CF.CLIENT_FUNDING_1_START_MIECHVP_COM,CF.CLIENT_FUNDING_1_START_MIECHVP_FORM)
	,IBS.INFANT_BIRTH_0_DOB
	,C.DEMO_CLIENT_INTAKE_0_ETHNICITY 
	,C.DEMO_CLIENT_INTAKE_0_RACE 
	,C.DOB
	,EAD.CLID
	,IBS.INFANT_PERSONAL_0_GENDER
	,IBS.INFANT_PERSONAL_0_ETHNICITY
	,IBS.INFANT_PERSONAL_0_RACE
	,CASE WHEN HVES.SurveyDate BETWEEN @StartDate AND @EndDate AND HVES.CLIENT_COMPLETE_0_VISIT LIKE '%COMPLET%'
		THEN CASE 
				WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) > @EndDate 
				THEN 'Currently receiving services'
				WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) <= @EndDate
					AND EAD.ReasonForDismissal LIKE '%2%' 
				THEN 'Completed program'
				WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) <= @EndDate
					AND EAD.ReasonForDismissal NOT LIKE '%2%' 
				THEN 'Stopped services before completion'
				ELSE 'Other'
		END
	 END
	 --,CASE 
		--		WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) > @EndDate 
		--		THEN 'Currently receiving services'
		--		WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) < @EndDate
		--			AND EAD.ReasonForDismissal LIKE '%2%' 
		--		THEN 'Completed program'
		--		WHEN ISNULL(EAD.EndDate,DATEADD(DAY,1,@EndDate)) < @EndDate
		--			AND EAD.ReasonForDismissal NOT LIKE '%2%' 
		--		THEN 'Stopped services before completion'
		--		ELSE 'Other'
		--END
	 ,CASE WHEN CF.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM] LIKE '%COMPETITIVE%' THEN 'Competitive'
		WHEN CF.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] LIKE '%FORMULA%' THEN 'Formula'
	 END

UNION ALL
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Under 10',1,'Currently receiving services',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'10-14',2,'Completed program',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'15-17',3,'Stopped services before completion',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'18-19',4,'Other',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'20-21',5,'Other',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'22-24',6,'Other',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'25-29',7,'Other',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'30-34',8,'Other',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'35-44',9,'Other',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'45-54',10,'Other',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'55-64',11,'Other',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'65+',12,'Other',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END
UNION ALL 
SELECT 
NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Unknown/did not report',13,'Other',NULL,CASE WHEN @FundingType = 'COMPETITIVE' THEN 'Competitive' WHEN @FundingType = 'FORMULA' THEN 'Formula' END 
GO
