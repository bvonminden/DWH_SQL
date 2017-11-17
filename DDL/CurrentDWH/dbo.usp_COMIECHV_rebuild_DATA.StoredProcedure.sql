USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_COMIECHV_rebuild_DATA]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_COMIECHV_rebuild_DATA]
(
	@StartDate		DATE		--= '20140101'
	,@EndDate		DATE		--= '20141231'
	,@SiteID		VARCHAR(4000)--= '289'
	,@FundingType	INT			--= 1 --- 1 = Competitive; 2 = Formula
)

WITH EXECUTE AS OWNER

AS

SET NOCOUNT ON

--IF OBJECT_ID('tempdb..#TempRoot') IS NOT NULL  DROP TABLE #TempRoot
--IF OBJECT_ID('tempdb..#ProgramID') IS NOT NULL  DROP TABLE #ProgramID
--GO

--DECLARE 
--	@StartDate		DATE		= '20131001'
--	,@EndDate		DATE		= '20140930'
--	,@SiteID		VARCHAR(4000)= '110'--'109,110,111,112,113,114,140,141,142,143,144,145,146,147,148,149,150,151,279,371,372'--'289'
--	,@FundingType	INT			= 1 --- 1 = Competitive; 2 = Formula
	
--------------------- BUILD TEMP Tables ---------------------------

-- INSERT INTO #ProgramID 
SELECT P.ProgramID 
INTO #ProgramID
FROM UV_PAS P INNER JOIN dbo.udf_ParseMultiParam(@SiteID) S ON P.SiteID = S.Value

--INSERT INTO #TempRoot (clients)
SELECT 
	P.ProgramID
	--,P.Site
	--,P.SiteID
	,ROOT.CLID
	,ROOT.ProgramStartDate
	,ROOT.EndDate
INTO #TempRoot
FROM 
#ProgramID P

 JOIN
	(SELECT 
		EAD.CLID
		,EAD.ProgramID
		,EAD.ProgramStartDate
		,EAD.EndDate
		,EAD.ReasonForDismissal
		,ROW_NUMBER() OVER(Partition By EAD.CaseNumber Order By EAD.CLID DESC) Rank_1
	FROM EnrollmentAndDismissal EAD
	WHERE ProgramID IN(SELECT DISTINCT P.ProgramID FROM UV_PAS P INNER JOIN dbo.udf_ParseMultiParam(@SiteID) S ON P.SiteID = S.Value)
	AND ProgramStartDate <= @EndDate AND (EndDate >= @StartDate OR EndDate IS NULL)) ROOT
	ON P.ProgramID = ROOT.ProgramID
	AND ROOT.Rank_1 = 1

 JOIN 
	(SELECT 
		CFS.CL_EN_GEN_ID
		,CFS.ProgramID
		,MAX(CASE WHEN CFS.CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL THEN 1 END) Comp
		,MAX(CASE WHEN CFS.CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL THEN 1 END) Form
	FROM [DataWarehouse].[dbo].[Client_Funding_Survey] CFS -- logic regarding funding
	WHERE (CFS.CLIENT_FUNDING_1_START_MIECHVP_COM >= '10/1/2010'
		OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM >= '10/1/2010')
		AND CFS.SurveyDate <= @EndDate
	GROUP BY CFS.CL_EN_GEN_ID ,CFS.ProgramID) CFS
	ON CFS.CL_EN_GEN_ID = ROOT.CLID
	AND CFS.ProgramID = ROOT.ProgramID
	AND ((CFS.Comp = 1 AND @FundingType = 1) OR (CFS.Form = 1 AND @FundingType = 2))  -- Funding type param -- population of active clients during time frame


------------------------- Main Query -------------------------------


SELECT ROOT.CLID,


------------------------------------------Benchmark 1----------------------------------------------------------------------
	ROOT.ProgramID
	,COUNT(DISTINCT CASE 
		WHEN (ROOT.ProgramStartDate < IBS.INFANT_BIRTH_0_DOB OR IBS.INFANT_BIRTH_0_DOB IS NULL)  -- pregnant client
			AND ((ROOT.EndDate IS NULL AND ROOT.ProgramStartDate < DATEADD(Day,-84,@EndDate)) OR ROOT.EndDate > DATEADD(DAY,84,ROOT.ProgramStartDate)) -- (client is active at least 84 days)
			AND GCSS_Intake.CL_EN_GEN_ID IS NOT NULL -- client has GCSS intake
			AND (GCSS_Intake.SERVICE_USE_PCP_CLIENT_PRENATAL <> 2 OR GCSS_Intake.SERVICE_USE_PCP_CLIENT_PRENATAL IS NULL)
			AND (GCSS_Intake.SERVICE_USE_PCP_CLIENT_WELLWOMAN <> 2 OR GCSS_Intake.SERVICE_USE_PCP_CLIENT_WELLWOMAN IS NULL)
		THEN ROOT.CLID
	END) B1C1_T
	,COUNT(DISTINCT CASE 
		WHEN (ROOT.ProgramStartDate < IBS.INFANT_BIRTH_0_DOB OR IBS.INFANT_BIRTH_0_DOB IS NULL)  -- pregnant client
			AND ((ROOT.EndDate IS NULL AND ROOT.ProgramStartDate < DATEADD(Day,-84,@EndDate)) OR ROOT.EndDate > DATEADD(DAY,84,ROOT.ProgramStartDate)) -- (client is active at least 84 days)
			AND GCSS_Intake.CL_EN_GEN_ID IS NOT NULL -- client has GCSS intake
			AND (GCSS_Intake.SERVICE_USE_PCP_CLIENT_PRENATAL <> 2 OR GCSS_Intake.SERVICE_USE_PCP_CLIENT_PRENATAL IS NULL)
			AND (GCSS_Intake.SERVICE_USE_PCP_CLIENT_WELLWOMAN <> 2 OR GCSS_Intake.SERVICE_USE_PCP_CLIENT_WELLWOMAN IS NULL)
			AND HVES.Prenatal = 1
		THEN ROOT.CLID
	END) B1C1_T1
	,COUNT(DISTINCT CASE 
		WHEN HHS_Intake.CLIENT_SUBSTANCE_CIG_1_LAST_48 IS NOT NULL -- client has HHS intake data on smoking
			AND HHS_36.CLIENT_SUBSTANCE_CIG_1_LAST_48 IS NOT NULL -- client has HHS 36 data on smoking
			AND HHS_36.SurveyDate BETWEEN @StartDate AND @EndDate -- client has HHS 36 during period
			AND HHS_Intake.CLIENT_SUBSTANCE_CIG_1_LAST_48 > 0 -- Tabacoo use at intake
		THEN ROOT.CLID
	END) B1C2_T
	,COUNT(DISTINCT CASE 
		WHEN HHS_Intake.CLIENT_SUBSTANCE_CIG_1_LAST_48 IS NOT NULL -- client has HHS intake data on smoking
			AND HHS_36.CLIENT_SUBSTANCE_CIG_1_LAST_48 IS NOT NULL -- client has HHS 36 data on smoking
			AND HHS_36.SurveyDate BETWEEN @StartDate AND @EndDate -- client has HHS 36 during period
			AND HHS_36.CLIENT_SUBSTANCE_CIG_1_LAST_48 > 0 -- Tabacoo use at 36w
		THEN ROOT.CLID
	END) B1C2_T2
	,COUNT(DISTINCT CASE 
		WHEN GCSS_inf6.SurveyDate BETWEEN @StartDate AND @EndDate --GCSS inf 6 form during period
			AND (GCSS_inf6.SERVICE_USE_PCP_CLIENT_POSTPARTUM IN('2','5') --had pcp visit
			OR GCSS_inf6.SERVICE_USE_PCP_CLIENT_WELLWOMAN IN('2','5')) -- had pcp visit
		THEN ROOT.CLID
	END) B1C3_N
	,COUNT(DISTINCT CASE 
		WHEN GCSS_inf6.SurveyDate BETWEEN @StartDate AND @EndDate --GCSS inf 6 form during period
		THEN ROOT.CLID
	END) B1C3_D
	,COUNT(DISTINCT CASE 
		WHEN DS_6.SurveyDate BETWEEN @StartDate AND @EndDate --DS form during period
			AND DS_6.CLIENT_BC_0_USED_6MONTHS IS NOT NULL -- answered birth control question
		THEN ROOT.CLID
	END) B1C4_N
	,COUNT(DISTINCT CASE 
		WHEN DS_6.SurveyDate BETWEEN @StartDate AND @EndDate --DS form during period
		THEN ROOT.CLID
	END) B1C4_D
	
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB BETWEEN DATEADD(mm,-6,@StartDate) AND DATEADD(mm,-6,@EndDate) -- child reached 6 months during time frame
			AND B1C5.SurveyDate BETWEEN @StartDate AND @EndDate -- Last edinburgh or last phq9 (prior to enddate) during the time frame
			AND HVES.Visit_during_period = 1 -- client had visit during period
		THEN ROOT.CLID
	END) B1C5_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB BETWEEN DATEADD(mm,-6,@StartDate) AND DATEADD(mm,-6,@EndDate) -- child reached 6 months during time frame
			AND HVES.Visit_during_period = 1 -- client had visit during period
		THEN ROOT.CLID
	END) B1C5_D

	,COUNT(DISTINCT CASE 
		WHEN ROOT.ProgramStartDate < IBS.INFANT_BIRTH_0_DOB --enrolled prior to birth
			AND IBS.SurveyDate BETWEEN @StartDate AND @EndDate --survey during period
			AND IBS.INFANT_BREASTMILK_0_EVER_BIRTH = 'Yes'
		THEN ROOT.CLID
	END) B1C6_N
	,COUNT(DISTINCT CASE 
		WHEN ROOT.ProgramStartDate < IBS.INFANT_BIRTH_0_DOB --enrolled prior to birth
			AND IBS.SurveyDate BETWEEN @StartDate AND @EndDate --survey during period
		THEN ROOT.CLID
	END) B1C6_D
	,COUNT(DISTINCT CASE 
		WHEN IHS_6.SurveyDate BETWEEN @StartDate AND @EndDate --survey during period
			AND INFANT_HEALTH_PROVIDER_0_APPT_R2 = 'Yes' -- recieved well child visit
		THEN ROOT.CLID
	END) B1C7_N
	,COUNT(DISTINCT CASE 
		WHEN IHS_6.SurveyDate BETWEEN @StartDate AND @EndDate --survey during period
		THEN ROOT.CLID
	END) B1C7_D
	,COUNT(DISTINCT CASE 
		WHEN GCSS_inf6.SurveyDate BETWEEN @StartDate AND @EndDate -- GCSS inf 6 present
			AND GCSS_Intake.SurveyDate IS NOT NULL -- GCSS intake present
			AND (
			   (GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT  <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NULL)
			AND (GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] <> '2' OR GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] IS NULL)
			--AND (GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD IS NULL)
			--AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD IS NULL)
			--AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IS NULL)
			--AND (GCSS_Intake.SERVICE_USE_MILITARY_INS_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_MILITARY_INS_CHILD IS NULL)
			)
		THEN ROOT.CLID
	END)  +
	
	
	--COUNT(DISTINCT CASE 
	--	WHEN GCSS_inf6.SurveyDate BETWEEN @StartDate AND @EndDate -- GCSS inf 6 present
	--		AND GCSS_Intake.SurveyDate IS NOT NULL -- GCSS intake present
	--		AND (
	--		-- (GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT IS NULL)
	--		--AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT IS NULL)
	--		--AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT  <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NULL)
	--		--AND (GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] <> '2' OR GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] IS NULL)
	--		 (GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD IS NULL)
	--		AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD IS NULL)
	--		AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IS NULL)
	--		AND (GCSS_Intake.SERVICE_USE_MILITARY_INS_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_MILITARY_INS_CHILD IS NULL)
	--		)
	--	THEN ROOT.CLID
	--END) B1C8_T
	
	--Replaced with this code on 3/19/2015
	COUNT(DISTINCT CASE 
		WHEN GCSS_inf6.SurveyDate BETWEEN @StartDate AND @EndDate -- GCSS inf 6 present
			AND GCSS_infBirth.SurveyDate IS NOT NULL -- GCSS intake present
			AND (
			-- (GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT IS NULL)
			--AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT IS NULL)
			--AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT  <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NULL)
			--AND (GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] <> '2' OR GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] IS NULL)
			 (GCSS_infBirth.SERVICE_USE_0_MEDICAID_CHILD <> '2' OR GCSS_infBirth.SERVICE_USE_0_MEDICAID_CHILD IS NULL)
			AND (GCSS_infBirth.SERVICE_USE_0_SCHIP_CHILD <> '2' OR GCSS_infBirth.SERVICE_USE_0_SCHIP_CHILD IS NULL)
			AND (GCSS_infBirth.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD <> '2' OR GCSS_infBirth.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IS NULL)
			AND (GCSS_infBirth.SERVICE_USE_MILITARY_INS_CHILD <> '2' OR GCSS_infBirth.SERVICE_USE_MILITARY_INS_CHILD IS NULL)
			)
		THEN ROOT.CLID
	END) B1C8_T
	,COUNT(DISTINCT CASE 
		WHEN GCSS_inf6.SurveyDate BETWEEN @StartDate AND @EndDate -- GCSS inf 6 form during period
			AND GCSS_Intake.SurveyDate IS NOT NULL -- GCSS intake present
			
			AND ( 
			(GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT IS NULL)
			AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT  <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NULL)
			AND (GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] <> '2' OR GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] IS NULL)
			--AND (GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD IS NULL)
			--AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD IS NULL)
			--AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IS NULL)
			--AND (GCSS_Intake.SERVICE_USE_MILITARY_INS_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_MILITARY_INS_CHILD IS NULL)	
			)
			
			AND (
			GCSS_inf6.SERVICE_USE_0_MEDICAID_CLIENT IN('2','5')
			OR GCSS_inf6.SERVICE_USE_0_SCHIP_CLIENT IN('2','5')
			OR GCSS_inf6.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN('2','5')
			OR GCSS_inf6.[SERVICE_USE_MILITARY_INS_CLIENT ] IN('2','5')
			--OR GCSS_inf6.SERVICE_USE_0_MEDICAID_CHILD IN('2','5')
			--OR GCSS_inf6.SERVICE_USE_0_SCHIP_CHILD IN('2','5')
			--OR GCSS_inf6.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IN('2','5')  
			--OR GCSS_inf6.SERVICE_USE_MILITARY_INS_CHILD  <> '2'
			)
		THEN ROOT.CLID
	END)  +
	--COUNT(DISTINCT CASE 
	--	WHEN GCSS_inf6.SurveyDate BETWEEN @StartDate AND @EndDate -- GCSS inf 6 form during period
	--		AND GCSS_Intake.SurveyDate IS NOT NULL -- GCSS intake present
			
	--		AND ( 
	--		--(GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT IS NULL)
	--		--AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT IS NULL)
	--		--AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT  <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NULL)
	--		--AND (GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] <> '2' OR GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] IS NULL)
	--		 (GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CHILD IS NULL)
	--		AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CHILD IS NULL)
	--		AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IS NULL)
	--		AND (GCSS_Intake.SERVICE_USE_MILITARY_INS_CHILD <> '2' OR GCSS_Intake.SERVICE_USE_MILITARY_INS_CHILD IS NULL)	
	--		)
			
	--		AND (
	--		--GCSS_inf6.SERVICE_USE_0_MEDICAID_CLIENT IN('2','5')
	--		--OR GCSS_inf6.SERVICE_USE_0_SCHIP_CLIENT IN('2','5')
	--		--OR GCSS_inf6.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN('2','5')
	--		--OR GCSS_inf6.[SERVICE_USE_MILITARY_INS_CLIENT ] IN('2','5')
	--		 GCSS_inf6.SERVICE_USE_0_MEDICAID_CHILD IN('2','5')
	--		OR GCSS_inf6.SERVICE_USE_0_SCHIP_CHILD IN('2','5')
	--		OR GCSS_inf6.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IN('2','5')  
	--		OR GCSS_inf6.SERVICE_USE_MILITARY_INS_CHILD  IN( '2','5')
	--		)
	--	THEN ROOT.CLID
	--END)B1C8_T1
	
	--Replaced with this code on 3/19/2015
	COUNT(DISTINCT CASE 
		WHEN GCSS_inf6.SurveyDate BETWEEN @StartDate AND @EndDate -- GCSS inf 6 form during period
			AND GCSS_infBirth.SurveyDate IS NOT NULL -- GCSS intake present
			
			AND ( 
			--(GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_MEDICAID_CLIENT IS NULL)
			--AND (GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT <> '2' OR GCSS_Intake.SERVICE_USE_0_SCHIP_CLIENT IS NULL)
			--AND (GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT  <> '2' OR GCSS_Intake.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NULL)
			--AND (GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] <> '2' OR GCSS_Intake.[SERVICE_USE_MILITARY_INS_CLIENT ] IS NULL)
			 (GCSS_infBirth.SERVICE_USE_0_MEDICAID_CHILD <> '2' OR GCSS_infBirth.SERVICE_USE_0_MEDICAID_CHILD IS NULL)
			AND (GCSS_infBirth.SERVICE_USE_0_SCHIP_CHILD <> '2' OR GCSS_infBirth.SERVICE_USE_0_SCHIP_CHILD IS NULL)
			AND (GCSS_infBirth.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD <> '2' OR GCSS_infBirth.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IS NULL)
			AND (GCSS_infBirth.SERVICE_USE_MILITARY_INS_CHILD <> '2' OR GCSS_infBirth.SERVICE_USE_MILITARY_INS_CHILD IS NULL)	
			)
			
			AND (
			--GCSS_inf6.SERVICE_USE_0_MEDICAID_CLIENT IN('2','5')
			--OR GCSS_inf6.SERVICE_USE_0_SCHIP_CLIENT IN('2','5')
			--OR GCSS_inf6.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN('2','5')
			--OR GCSS_inf6.[SERVICE_USE_MILITARY_INS_CLIENT ] IN('2','5')
			 GCSS_inf6.SERVICE_USE_0_MEDICAID_CHILD IN('2','5')
			OR GCSS_inf6.SERVICE_USE_0_SCHIP_CHILD IN('2','5')
			OR GCSS_inf6.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IN('2','5')  
			OR GCSS_inf6.SERVICE_USE_MILITARY_INS_CHILD  IN( '2','5')
			)
		THEN ROOT.CLID
	END)B1C8_T1

--------------------------------------------Benchmark 2----------------------------------------------------------------------

	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c1.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
			AND (IHS_all_c1.ER_Yes_c1 = 1 OR IHS_all_c1.ERO_Yes_c1 = 1)  -- had er visit during first six months
		THEN ROOT.CLID
	END) B2C1_N_c1
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c2.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
			AND (IHS_all_c2.ER_Yes_c2 = 1 OR IHS_all_c2.ERO_Yes_c2 = 1)  -- had er visit during last six months
		THEN ROOT.CLID
	END) B2C1_N_c2
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c1.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
		THEN ROOT.CLID
	END) B2C1_D_c1
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c2.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
		THEN ROOT.CLID
	END) B2C1_D_c2

	,COUNT(DISTINCT CASE 
		WHEN DS_all_c1.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
			AND DS_all_c1.ER_Yes_c1 = 1  -- had er visit during first six months
		THEN ROOT.CLID
	END) B2C2_N_c1
	,COUNT(DISTINCT CASE 
		WHEN DS_all_c2.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
			AND DS_all_c2.ER_Yes_c2 = 1  -- had er visit during last six months
		THEN ROOT.CLID
	END) B2C2_N_c2
	,COUNT(DISTINCT CASE 
		WHEN DS_all_c1.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
		THEN ROOT.CLID
	END) B2C2_D_c1
	,COUNT(DISTINCT CASE 
		WHEN DS_all_c2.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
		THEN ROOT.CLID
	END) B2C2_D_c2
	
	,COUNT(DISTINCT CASE 
		WHEN HVES.Visit_365 = 1 --client had visit during 365 days after start
			AND HVES.injury_prev = 1  -- had injury prev training with 365 days of enrollment
		THEN ROOT.CLID
	END) B2C3_N
	,COUNT(DISTINCT CASE 
		WHEN HVES.Visit_365 = 1 --client had visit during 365 days after start
		THEN ROOT.CLID
	END) B2C3_D

	
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c1.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
			AND (IHS_all_c1.ER_Yes_c1 = 1 AND IHS_all_c1.ER_Injury_c1 = 1)  -- had er visit during first six months and it was injury
		THEN ROOT.CLID
	END) B2C4_N_c1
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c2.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
			AND (IHS_all_c2.ER_Yes_c2 = 1 AND IHS_all_c2.ER_Injury_c2 = 1)  -- had er visit during last six months and it was injury
		THEN ROOT.CLID
	END) B2C4_N_c2
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c1.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
		THEN ROOT.CLID
	END) B2C4_D_c1
	,COUNT(DISTINCT CASE 
		WHEN IHS_all_c2.CL_EN_GEN_ID IS NOT NULL --client had survey during time period
		THEN ROOT.CLID
	END) B2C4_D_c2

	,COUNT(DISTINCT CASE 
		WHEN IHS_12.SurveyDate BETWEEN @Startdate AND @EndDate --client had survey during time period
			AND (IHS_12.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes' -- had maltreatment referral
			OR IHS_12.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes')
		THEN ROOT.CLID
	END) B2C5_N
	,COUNT(DISTINCT CASE 
		WHEN IHS_12.SurveyDate BETWEEN @Startdate AND @EndDate--client had survey during time period
		THEN ROOT.CLID
	END) B2C5_D


--------------------------------------------Benchmark 3----------------------------------------------------------------------


	,COUNT(DISTINCT CASE 
		WHEN IHS_6.SurveyDate BETWEEN @Startdate AND @EndDate --client had survey during time period
			AND IHS_6.INFANT_HOME_1_LEARNING IS NOT NULL -- Learning on HOME reported
		THEN ROOT.CLID
	END) B3C1_N
	,COUNT(DISTINCT CASE 
		WHEN IHS_6.SurveyDate BETWEEN @Startdate AND @EndDate --client had survey during time period
		THEN ROOT.CLID
	END) B3C1_D
	
	,COUNT(DISTINCT CASE 
		WHEN IHS_18.SurveyDate BETWEEN @StartDate AND @EndDate -- client had IHS 18 during period
			AND IHS_6.INFANT_HOME_0_TOTAL_calc IS NOT NULL -- HOME reported (and has survey)
			AND IHS_18.INFANT_HOME_0_TOTAL_calc IS NOT NULL -- HOME reported
		THEN ROOT.CLID
	END) B3C2_T
	,COUNT(DISTINCT CASE 
		WHEN IHS_18.SurveyDate BETWEEN @StartDate AND @EndDate -- client had IHS 18 during period
			AND IHS_6.INFANT_HOME_0_TOTAL_calc IS NOT NULL -- HOME reported (and has survey)
			AND IHS_18.INFANT_HOME_0_TOTAL_calc IS NOT NULL -- HOME reported
			AND IHS_18.INFANT_HOME_0_TOTAL_calc > IHS_6.INFANT_HOME_0_TOTAL_calc -- increase in score
		THEN ROOT.CLID
	END) B3C2_T1
	
	,COUNT(DISTINCT CASE 
		WHEN IHS_18.SurveyDate BETWEEN @StartDate AND @EndDate -- client had IHS 18 during period
			AND IHS_6.INFANT_HOME_1_ACCEPTANCE IS NOT NULL-- HOME ACC reported (and has survey)
			AND IHS_6.INFANT_HOME_1_RESPONSIVITY IS NOT NULL 
			AND IHS_18.INFANT_HOME_1_ACCEPTANCE IS NOT NULL 
			AND IHS_18.INFANT_HOME_1_RESPONSIVITY IS NOT NULL
		THEN ROOT.CLID
	END) B3C3_T
	,COUNT(DISTINCT CASE 
		WHEN IHS_18.SurveyDate BETWEEN @StartDate AND @EndDate -- client had IHS 18 during period
			AND IHS_6.INFANT_HOME_1_ACCEPTANCE IS NOT NULL-- HOME ACC reported (and has survey)
			AND IHS_6.INFANT_HOME_1_RESPONSIVITY IS NOT NULL 
			AND IHS_18.INFANT_HOME_1_ACCEPTANCE IS NOT NULL 
			AND IHS_18.INFANT_HOME_1_RESPONSIVITY IS NOT NULL
			AND IHS_18.INFANT_HOME_1_ACCEPTANCE > IHS_6.INFANT_HOME_1_ACCEPTANCE  -- acc increased
			AND IHS_18.INFANT_HOME_1_RESPONSIVITY > IHS_6.INFANT_HOME_1_RESPONSIVITY -- resp increased
		THEN ROOT.CLID
	END) B3C3_T1

	-----B3C4_N and B3C4_D are same as B1C5_N and B1C5_D
	
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB > DATEADD(MONTH,-12,@StartDate) AND IBS.INFANT_BIRTH_0_DOB < DATEADD(MONTH,-3,@EndDate) -- child between 3 and 12 months during phase
			AND ((ASQ_410.INFANT_AGES_STAGES_1_COMM = 1 OR ASQ_410.INFANT_HEALTH_NO_ASQ_COMM = 1) OR (ASQ_IHS_612.INFANT_AGES_STAGES_1_COMM = 1 OR ASQ_IHS_612.INFANT_HEALTH_NO_ASQ_COMM = 1))
		THEN ROOT.CLID
	END) B3C5_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB > DATEADD(MONTH,-12,@StartDate) AND IBS.INFANT_BIRTH_0_DOB < DATEADD(MONTH,-3,@EndDate) -- child between 3 and 12 months during phase
			AND ((ASQ_410.INFANT_AGES_STAGES_1_PSOLVE = 1 OR ASQ_410.INFANT_HEALTH_NO_ASQ_PROBLEM = 1) OR (ASQ_IHS_612.INFANT_AGES_STAGES_1_PSOLVE = 1 OR ASQ_IHS_612.INFANT_HEALTH_NO_ASQ_PROBLEM = 1)) 
		THEN ROOT.CLID
	END) B3C6_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB > DATEADD(MONTH,-12,@StartDate) AND IBS.INFANT_BIRTH_0_DOB < DATEADD(MONTH,-3,@EndDate) -- child between 3 and 12 months during phase
			AND ((ASQ_410.INFANT_AGES_STAGES_1_PSOCIAL = 1 OR ASQ_410.INFANT_HEALTH_NO_ASQ_PERSONAL = 1) OR (ASQ_IHS_612.INFANT_AGES_STAGES_1_PSOCIAL = 1 OR ASQ_IHS_612.INFANT_HEALTH_NO_ASQ_PERSONAL = 1))
		THEN ROOT.CLID
	END) B3C7_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB > DATEADD(MONTH,-12,@StartDate) AND IBS.INFANT_BIRTH_0_DOB < DATEADD(MONTH,-3,@EndDate) -- child between 3 and 12 months during phase
			AND (((ASQ_410.INFANT_AGES_STAGES_1_GMOTOR = 1 AND ASQ_410.INFANT_AGES_STAGES_1_FMOTOR = 1) OR (ASQ_410.INFANT_HEALTH_NO_ASQ_GROSS = 1 AND ASQ_410.INFANT_HEALTH_NO_ASQ_FINE = 1)) OR ((ASQ_IHS_612.INFANT_AGES_STAGES_1_GMOTOR = 1 AND ASQ_IHS_612.INFANT_AGES_STAGES_1_FMOTOR = 1) OR (ASQ_IHS_612.INFANT_HEALTH_NO_ASQ_GROSS = 1 AND ASQ_IHS_612.INFANT_HEALTH_NO_ASQ_FINE = 1)))
		THEN ROOT.CLID
	END) B3C9_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB > DATEADD(MONTH,-12,@StartDate) AND IBS.INFANT_BIRTH_0_DOB < DATEADD(MONTH,-3,@EndDate) -- child between 3 and 12 months during phase
		THEN ROOT.CLID
	END) B3C5679_D

	
	,COUNT(DISTINCT CASE 
		WHEN IHS_ASQ.CL_EN_GEN_ID IS NOT NULL -- has IHS 6 or 12 survey during period
			AND (IHS_ASQ.INFANT_AGES_STAGES_SE_0_EMOTIONAL = 1 OR IHS_ASQ.INFANT_HEALTH_NO_ASQ_TOTAL = 1) -- HOME ACC reported (and has survey)
		THEN ROOT.CLID
	END) B3C8_N
	,COUNT(DISTINCT CASE 
		WHEN IHS_ASQ.CL_EN_GEN_ID IS NOT NULL -- has IHS 6 or 12 survey during period
		THEN ROOT.CLID
	END) B3C8_D


-------------------------------------------- Benchmark 4 ---------------------------------------------------------------------

	

	,COUNT(DISTINCT CASE 
		WHEN ROOT.ProgramStartDate BETWEEn @StartDate AND @EndDate -- newly enrolled
			AND RS_i36.CL_EN_GEN_ID IS NOT NULL -- Client has intake or 36 relationship survey during period
		THEN ROOT.CLID
	END) B4C3_N
	,COUNT(DISTINCT CASE 
		WHEN ROOT.ProgramStartDate BETWEEN @StartDate AND @EndDate  -- newly enrolled
		THEN ROOT.CLID 
	END) B4C3_D --
	,COUNT(DISTINCT CASE 
		WHEN RS_i36.CL_EN_GEN_ID IS NOT NULL -- Client has intake or 36 relationship survey during period
			AND Referrals.SERVICE_REFER_0_IPV = 1 
			AND RS_i36.DV_ident = 1 --- Domestic violence identified on intake or 36 rs
		THEN ROOT.CLID
	END) B4C4_N
	,COUNT(DISTINCT CASE 
		WHEN RS_i36.CL_EN_GEN_ID IS NOT NULL -- Client has intake or 36 relationship survey during period
			AND HVES.Safety_Plan_1yr = 1 --- Safety Plan within 1 year
			AND RS_i36.DV_ident = 1 --- Domestic violence identified on intake or 36 rs
		THEN ROOT.CLID
	END) B4C5_N
	,COUNT(DISTINCT CASE 
		WHEN RS_i36.CL_EN_GEN_ID IS NOT NULL -- Client has intake or 36 relationship survey during period
			AND RS_i36.DV_ident = 1 --- Domestic violence identified on intake or 36 rs
		THEN ROOT.CLID
	END) B4C45_D
	
-------------------------------------------- Benchmark 5 ---------------------------------------------------------------------

	,COUNT(DISTINCT CASE 
		WHEN DS_in.CL_EN_GEN_ID IS NOT NULL AND DS_12.CL_EN_GEN_ID IS NOT NULL AND DS_12.SurveyDate BETWEEN @StartDate AND @EndDate -- client has DS intake at some point and DS 12 during time frame
		THEN ROOT.CLID
	END) B5C1_T
	,COUNT(DISTINCT CASE 
		WHEN DS_in.CL_EN_GEN_ID IS NOT NULL AND DS_12.CL_EN_GEN_ID IS NOT NULL AND DS_12.SurveyDate BETWEEN @StartDate AND @EndDate -- client has DS intake at some point and DS 12 during time frame
			AND DS_in.CLIENT_INCOME_AMOUNT IS NOT NULL AND DS_12.CLIENT_INCOME_AMOUNT IS NOT NULL -- income reported at both time frames
			AND DS_in.CLIENT_INCOME_AMOUNT <= DS_12.CLIENT_INCOME_AMOUNT  --- income increased or maintained
		THEN ROOT.CLID
	END) B5C1_T1
	,COUNT(DISTINCT CASE 
		WHEN DS_in.CL_EN_GEN_ID IS NOT NULL AND DS_12.CL_EN_GEN_ID IS NOT NULL AND DS_12.SurveyDate BETWEEN @StartDate AND @EndDate  -- client has DS intake at some point and DS 12 during time frame
			AND DS_in.CLIENT_EDUCATION_1_ENROLLED_PLAN IS NOT NULL AND DS_12.CLIENT_EDUCATION_1_ENROLLED_PLAN IS NOT NULL --- answered education
			AND DS_in.CLIENT_EDUCATION_1_ENROLLED_PLAN = 'Yes'
		THEN ROOT.CLID
	END) B5C2_T
	,COUNT(DISTINCT CASE 
		WHEN DS_in.CL_EN_GEN_ID IS NOT NULL AND DS_12.CL_EN_GEN_ID IS NOT NULL AND DS_12.SurveyDate BETWEEN @StartDate AND @EndDate  -- client has DS intake at some point and DS 12 during time frame
			AND (
				(DS_in.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - middle school (6th - 8th grades)' AND DS_in.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE < DS_12.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE AND DS_12.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - middle school (6th - 8th grades)') 
			OR (DS_in.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - middle school (6th - 8th grades)' AND DS_12.CLIENT_SCHOOL_MIDDLE_HS IN( 'Yes - high school or GED program (includes alternative and technical programs)','Yes - completed GED'))
			OR (DS_in.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - high school or GED program (includes alternative and technical programs)' AND DS_in.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE < DS_12.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE AND DS_12.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - high school or GED program (includes alternative and technical programs)') 
			OR (DS_in.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - high school or GED program (includes alternative and technical programs)' AND DS_12.CLIENT_EDUCATION_0_HS_GED IN( 'Yes - completed high school','Yes - completed GED','Yes - completed vocational/certification program'))
			OR (DS_in.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - high school or GED program (includes alternative and technical programs)' AND DS_12.CLIENT_EDUCATION_0_HS_GED = 'Yes - completed high school')
			OR (DS_in.CLIENT_SCHOOL_MIDDLE_HS = 'Not enrolled' AND DS_12.CLIENT_SCHOOL_MIDDLE_HS IN('Yes - middle school (6th - 8th grades)','Yes - high school or GED program (includes alternative and technical programs)'))
			OR (DS_in.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'No' AND DS_12.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'Yes')
			OR (DS_in.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'Yes' AND DS_in.CLIENT_EDUCATION_1_ENROLLED_FTPT = 'Part Time' AND DS_in.CLIENT_EDUCATION_1_ENROLLED_PT_HRS = '6 or less semester hours or equivalent' AND DS_12.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'Yes' AND DS_12.CLIENT_EDUCATION_1_ENROLLED_FTPT = 'Part Time' AND DS_12.CLIENT_EDUCATION_1_ENROLLED_PT_HRS = '7 - 11 semester hours or equivalent')
			OR (DS_in.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP < DS_12.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP)
			)
		THEN ROOT.CLID
	END) B5C2_T1
	




	
-------------------------------------------- Benchmark 6 ---------------------------------------------------------------------

	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB >= DATEADD(MONTH,-12,@EndDate) -- Client less than or equal to one at end of period
			AND HVES.No_Ref = 1 --- client screened or no referral
		THEN ROOT.CLID
	END) B6C1_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB >= DATEADD(MONTH,-12,@EndDate) -- Client less than or equal to one at end of period
		THEN ROOT.CLID
	END) B6C1_D
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB >= DATEADD(MONTH,-12,@EndDate) -- Client less than or equFal to one at end of period
			AND Referrals_B6.referred = 1 --- client screened or no referral
		THEN ROOT.CLID
	END) B6C2_N
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB >= DATEADD(MONTH,-12,@EndDate) -- Client less than or equal to one at end of period
			AND HVES.No_Ref = 1 --- client screened or no referral
		THEN ROOT.CLID
	END) B6C2_D
	,COUNT(DISTINCT CASE 
		WHEN IBS.INFANT_BIRTH_0_DOB >= DATEADD(MONTH,-12,@EndDate) -- Client less than or equal to one at end of period
			AND Referrals_B6.referred_comp = 1 --- client screened or no referral
		THEN ROOT.CLID
	END) B6C5_N


FROM #TempRoot ROOT

LEFT JOIN 
	(SELECT 
		HVES.CL_EN_GEN_ID
		,HVES.ProgramID
		,MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS = 'Yes' 
					AND HVES.SurveyDate BETWEEN C.ProgramStartDate and DATEADD(DAY,84,C.ProgramStartDate)
				  THEN 1 END) Prenatal
		,MAX(CASE WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes' 
					AND HVES.SurveyDate BETWEEN C.ProgramStartDate and DATEADD(DAY,365,C.ProgramStartDate)
				  THEN 1 END) injury_prev
		,MAX(CASE WHEN HVES.SurveyDate BETWEEN C.ProgramStartDate and DATEADD(DAY,365,C.ProgramStartDate) 
				  THEN 1 END) Visit_365
		,MAX(CASE WHEN HVES.SurveyDate > DATEADD(MONTH,12,C.ProgramStartDate)
				  THEN 1 END) Visit_After12m
		,MAX(CASE WHEN CLIENT_IPV_0_SAFETY_PLAN = 'Yes' AND HVES.SurveyDate < DATEADD(MONTH,12,C.ProgramStartDate)
				  THEN 1 END) Safety_Plan_1yr
		,MAX(CASE WHEN (CLIENT_SCREENED_SRVCS = 'Yes' OR CLIENT_NO_REFERRAL = 'No referral needed') AND HVES.SurveyDate < DATEADD(MONTH,12,C.ProgramStartDate)
				  THEN 1 END) No_Ref
		,MAX(CASE WHEN HVES.SurveyDate BETWEEN @StartDate AND @EndDate AND HVES.CLIENT_COMPLETE_0_VISIT = 'Completed'
				  THEN 1 END) Visit_during_period
	FROM Home_Visit_Encounter_Survey HVES
	INNER JOIN #TempRoot C ON HVES.CL_EN_GEN_ID = C.CLID AND HVES.ProgramID = C.ProgramID
	WHERE HVES.SurveyDate <= @EndDate
	GROUP BY 
		HVES.CL_EN_GEN_ID
		,HVES.ProgramID) HVES
	ON HVES.ProgramID = ROOT.ProgramID
	AND HVES.CL_EN_GEN_ID = ROOT.CLID

LEFT JOIN 
	(SELECT 
		I.CL_EN_GEN_ID
		,I.ProgramID
		,(I.INFANT_BIRTH_0_DOB) INFANT_BIRTH_0_DOB
		,I.SurveyDate
		,I.INFANT_BREASTMILK_0_EVER_BIRTH
		,RANK() OVER(Partition By I.CL_EN_GEN_ID,I.ProgramID Order By I.SurveyDate DESC,I.SurveyResponseID DESC) Rank
	FROM Infant_Birth_Survey I
	JOIN #ProgramID P ON I.ProgramID = P.ProgramID
	WHERE I.INFANT_BIRTH_0_DOB IS NOT NULL
	AND I.SurveyDate <= @EndDate) IBS
	ON ROOT.CLID = IBS.CL_EN_GEN_ID
	AND ROOT.ProgramID = IBS.ProgramID
	AND IBS.Rank = 1


LEFT JOIN  
	(SELECT 
		GCSS.ProgramID
		,GCSS.CL_EN_GEN_ID
		,GCSS.SurveyDate
		,RANK() OVER(PARTITION BY GCSS.ProgramID,GCSS.CL_EN_GEN_ID ORDER BY GCSS.SurveyDate DESC,GCSS.SurveyResponseID DESC) rank
		,GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL
		,GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN
		,GCSS.SERVICE_USE_0_MEDICAID_CLIENT
		,GCSS.SERVICE_USE_0_MEDICAID_CHILD
		,GCSS.SERVICE_USE_0_SCHIP_CHILD
		,GCSS.SERVICE_USE_0_SCHIP_CLIENT
		,GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD
		,GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT
		,GCSS.SERVICE_USE_MILITARY_INS_CHILD
		,GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ]
	FROM Govt_Comm_Srvcs_Survey GCSS 
	JOIN #ProgramID P ON GCSS.ProgramID = P.ProgramID
	JOIN Mstr_surveys ms ON GCSS.SurveyID = ms.SurveyID
	WHERE ms.SurveyName = 'Use of Government & Community Services-Intake'
	AND GCSS.SurveyDate <= @EndDate) GCSS_Intake
	ON ROOT.CLID = GCSS_Intake.CL_EN_GEN_ID
	AND ROOT.ProgramID = GCSS_Intake.ProgramID
	AND GCSS_Intake.rank = 1

LEFT JOIN  
	(SELECT 
		GCSS.ProgramID
		,GCSS.CL_EN_GEN_ID
		,GCSS.SurveyDate
		,RANK() OVER(PARTITION BY GCSS.ProgramID,GCSS.CL_EN_GEN_ID ORDER BY GCSS.SurveyDate DESC,GCSS.SurveyResponseID DESC) rank
		,GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL
		,GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN
		,GCSS.SERVICE_USE_0_MEDICAID_CLIENT
		,GCSS.SERVICE_USE_0_MEDICAID_CHILD
		,GCSS.SERVICE_USE_0_SCHIP_CHILD
		,GCSS.SERVICE_USE_0_SCHIP_CLIENT
		,GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD
		,GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT
		,GCSS.SERVICE_USE_MILITARY_INS_CHILD
		,GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ]
		,GCSS.SERVICE_USE_PCP_CLIENT_POSTPARTUM
	FROM Govt_Comm_Srvcs_Survey GCSS 
	JOIN #ProgramID P ON GCSS.ProgramID = P.ProgramID
	JOIN Mstr_surveys ms on GCSS.SurveyID = ms.SurveyID
	WHERE ms.SurveyName = 'Use of Government & Community Services-Infancy 6'
	AND GCSS.SurveyDate <= @EndDate) GCSS_inf6
	ON ROOT.CLID = GCSS_inf6.CL_EN_GEN_ID
	AND ROOT.ProgramID = GCSS_inf6.ProgramID
	AND GCSS_inf6.rank = 1
	
--NEW code by Andrew 3/19/2015
LEFT JOIN  
	(SELECT 
		GCSS.ProgramID
		,GCSS.CL_EN_GEN_ID
		,GCSS.SurveyDate
		,RANK() OVER(PARTITION BY GCSS.ProgramID,GCSS.CL_EN_GEN_ID ORDER BY GCSS.SurveyDate DESC,GCSS.SurveyResponseID DESC) rank
		,GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL
		,GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN
		,GCSS.SERVICE_USE_0_MEDICAID_CLIENT
		,GCSS.SERVICE_USE_0_MEDICAID_CHILD
		,GCSS.SERVICE_USE_0_SCHIP_CHILD
		,GCSS.SERVICE_USE_0_SCHIP_CLIENT
		,GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD
		,GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT
		,GCSS.SERVICE_USE_MILITARY_INS_CHILD
		,GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ]
		,GCSS.SERVICE_USE_PCP_CLIENT_POSTPARTUM
	FROM Govt_Comm_Srvcs_Survey GCSS 
	JOIN #ProgramID P ON GCSS.ProgramID = P.ProgramID
	JOIN Mstr_surveys ms on GCSS.SurveyID = ms.SurveyID
	WHERE ms.SurveyName = 'Use of Government & Community Services-Birth'
	AND GCSS.SurveyDate <= @EndDate) GCSS_infBirth
	ON ROOT.CLID = GCSS_infBirth.CL_EN_GEN_ID
	AND ROOT.ProgramID = GCSS_infBirth.ProgramID
	AND GCSS_infBirth.rank = 1
	
LEFT JOIN 
	(SELECT 
		HHS.ProgramID
		,HHS.CL_EN_GEN_ID
		,HHS.CLIENT_SUBSTANCE_CIG_1_LAST_48
		,RANK() OVER(PARTITION BY HHS.ProgramID,HHS.CL_EN_GEN_ID ORDER BY HHS.SurveyDate DESC,HHS.SurveyResponseID DESC) rank
	FROM Health_Habits_Survey HHS
		JOIN Mstr_surveys ms ON HHS.SurveyID = ms.SurveyID
		JOIN #ProgramID P ON HHS.ProgramID = P.ProgramID
	WHERE ms.SurveyName = 'Health Habits: Pregnancy-Intake'
	AND HHS.SurveyDate <= @EndDate) HHS_Intake
	ON ROOT.CLID = HHS_Intake.CL_EN_GEN_ID
	AND ROOT.ProgramID = HHS_Intake.ProgramID
	AND HHS_Intake.rank = 1

LEFT JOIN ---.05   170,277
	(SELECT 
		HHS.ProgramID
		,HHS.CL_EN_GEN_ID
		,HHS.SurveyDate
		,HHS.CLIENT_SUBSTANCE_CIG_1_LAST_48
		,RANK() OVER(PARTITION BY HHS.ProgramID,HHS.CL_EN_GEN_ID ORDER BY HHS.SurveyDate DESC,HHS.SurveyResponseID DESC) rank
	FROM Health_Habits_Survey HHS
		JOIN Mstr_surveys ms ON HHS.SurveyID = ms.SurveyID
		JOIN #ProgramID P ON HHS.ProgramID = P.ProgramID
	WHERE ms.SurveyName = 'Health Habits: Pregnancy-36 Weeks'
	AND HHS.SurveyDate <= @EndDate) HHS_36
	ON ROOT.CLID = HHS_36.CL_EN_GEN_ID
	AND ROOT.ProgramID = HHS_36.ProgramID
	AND HHS_36.rank = 1

LEFT JOIN 
	(SELECT 
		IHS.ProgramID
		,IHS.CL_EN_GEN_ID
		,IHS.SurveyDate
		,IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2
		,IHS.INFANT_HOME_1_LEARNING
		,CASE WHEN NOT(IHS.INFANT_HOME_1_ACCEPTANCE IS NULL
				AND IHS.INFANT_HOME_1_EXPERIENCE IS NULL
				AND IHS.INFANT_HOME_1_INVOLVEMENT IS NULL
				AND IHS.INFANT_HOME_1_LEARNING IS NULL
				AND IHS.INFANT_HOME_1_ORGANIZATION IS NULL
				AND IHS.INFANT_HOME_1_RESPONSIVITY IS NULL)
			 THEN ISNULL(IHS.INFANT_HOME_1_ACCEPTANCE,0) + 
				ISNULL(IHS.INFANT_HOME_1_EXPERIENCE,0) + 
				ISNULL(IHS.INFANT_HOME_1_INVOLVEMENT,0) + 
				ISNULL(IHS.INFANT_HOME_1_LEARNING,0) + 
				ISNULL(IHS.INFANT_HOME_1_ORGANIZATION,0) + 
				ISNULL(IHS.INFANT_HOME_1_RESPONSIVITY,0) 
		END INFANT_HOME_0_TOTAL_calc --- calculated total with all nulls set to null
		,IHS.INFANT_HOME_1_ACCEPTANCE
		,IHS.INFANT_HOME_1_RESPONSIVITY
		,RANK() OVER(PARTITION BY IHS.ProgramID,IHS.CL_EN_GEN_ID ORDER BY IHS.SurveyDate DESC,IHS.SurveyResponseID DESC) rank
	FROM Infant_Health_Survey IHS 
	JOIN #ProgramID P ON IHS.ProgramID = P.ProgramID
	JOIN Mstr_surveys ms ON IHS.SurveyID = ms.SurveyID
	WHERE ms.SurveyName = 'Infant Health Care-Infancy 6 Months'
		AND IHS.SurveyDate <= @EndDate) IHS_6
	ON ROOT.CLID = IHS_6.CL_EN_GEN_ID
	AND ROOT.ProgramID = IHS_6.ProgramID
	AND IHS_6.rank = 1

LEFT JOIN 
	(SELECT 
		IHS.ProgramID
		,IHS.CL_EN_GEN_ID
		,IHS.SurveyDate
		,IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL
		,IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL
		,RANK() OVER(PARTITION BY IHS.ProgramID,IHS.CL_EN_GEN_ID ORDER BY IHS.SurveyDate DESC,IHS.SurveyResponseID DESC) rank
	FROM Infant_Health_Survey IHS
	JOIN #ProgramID P ON IHS.ProgramID = P.ProgramID
	JOIN Mstr_Surveys ms ON IHS.SurveyID = ms.SurveyID
	WHERE ms.SurveyName = 'Infant Health Care: Infancy 12 Months'
	AND IHS.SurveyDate <= @EndDate) IHS_12
	ON ROOT.CLID = IHS_12.CL_EN_GEN_ID
	AND ROOT.ProgramID = IHS_12.ProgramID
	AND IHS_12.rank = 1

LEFT JOIN 
	(SELECT 
		IHS.ProgramID
		,IHS.CL_EN_GEN_ID
		,IHS.SurveyDate
		,CASE WHEN NOT(IHS.INFANT_HOME_1_ACCEPTANCE IS NULL
				AND IHS.INFANT_HOME_1_EXPERIENCE IS NULL
				AND IHS.INFANT_HOME_1_INVOLVEMENT IS NULL
				AND IHS.INFANT_HOME_1_LEARNING IS NULL
				AND IHS.INFANT_HOME_1_ORGANIZATION IS NULL
				AND IHS.INFANT_HOME_1_RESPONSIVITY IS NULL)
			 THEN ISNULL(IHS.INFANT_HOME_1_ACCEPTANCE,0) + 
				ISNULL(IHS.INFANT_HOME_1_EXPERIENCE,0) + 
				ISNULL(IHS.INFANT_HOME_1_INVOLVEMENT,0) + 
				ISNULL(IHS.INFANT_HOME_1_LEARNING,0) + 
				ISNULL(IHS.INFANT_HOME_1_ORGANIZATION,0) + 
				ISNULL(IHS.INFANT_HOME_1_RESPONSIVITY,0) 
		END INFANT_HOME_0_TOTAL_calc --- calculated total with all nulls set to null
		,IHS.INFANT_HOME_1_ACCEPTANCE
		,IHS.INFANT_HOME_1_RESPONSIVITY
		,RANK() OVER(PARTITION BY IHS.ProgramID,IHS.CL_EN_GEN_ID ORDER BY IHS.SurveyDate DESC,IHS.SurveyResponseID DESC) rank
	FROM Infant_Health_Survey IHS
	JOIN #ProgramID P ON IHS.ProgramID = P.ProgramID
	JOIN Mstr_Surveys ms ON IHS.SurveyID = ms.SurveyID
	WHERE ms.SurveyName = 'Infant Health Care: Toddler 18 Months'
		AND IHS.SurveyDate <= @EndDate) IHS_18
	ON ROOT.CLID = IHS_18.CL_EN_GEN_ID
	AND ROOT.ProgramID = IHS_18.ProgramID
	AND IHS_18.rank = 1

LEFT JOIN 
	(SELECT 
		IHS.ProgramID
		,IHS.CL_EN_GEN_ID
		,MAX(CASE WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'Yes' 
				  THEN 1 END) ER_Yes_c1
		,MAX(CASE WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes' 
				  THEN 1 END) ERO_Yes_c1
		,MAX(CASE WHEN IHS.INFANT_HEALTH_ER_1_TYPE = 'Injury' 
				  THEN 1 END) ER_Injury_c1
	FROM Infant_Health_Survey IHS
	JOIN #ProgramID P ON IHS.ProgramID = P.ProgramID
	--JOIN Mstr_Surveys ms ON IHS.SurveyID = ms.SurveyID
	WHERE IHS.SurveyDate >= @StartDate AND IHS.SurveyDate <= DATEADD(MONTH,6,@StartDate) AND IHS.SurveyDate <= @EndDate
	GROUP BY IHS.ProgramID, IHS.CL_EN_GEN_ID) IHS_all_c1
	ON ROOT.CLID = IHS_all_c1.CL_EN_GEN_ID
	AND ROOT.ProgramID = IHS_all_c1.ProgramID

LEFT JOIN 
	(SELECT 
		IHS.ProgramID
		,IHS.CL_EN_GEN_ID
		,MAX(CASE WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'Yes' 
				  THEN 1 END) ER_Yes_c2
		,MAX(CASE WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes' 
				  THEN 1 END) ERO_Yes_c2
		,MAX(CASE WHEN IHS.INFANT_HEALTH_ER_1_TYPE = 'Injury' 
				  THEN 1 END) ER_Injury_c2
	FROM Infant_Health_Survey IHS
	JOIN #ProgramID P ON IHS.ProgramID = P.ProgramID
	--JOIN Mstr_Surveys ms ON IHS.SurveyID = ms.SurveyID
	WHERE IHS.SurveyDate >= @StartDate AND IHS.SurveyDate >= DATEADD(MONTH,-6,@EndDate) AND IHS.SurveyDate <= @EndDate
	GROUP BY IHS.ProgramID, IHS.CL_EN_GEN_ID) IHS_all_c2
	ON ROOT.CLID = IHS_all_c2.CL_EN_GEN_ID
	AND ROOT.ProgramID = IHS_all_c2.ProgramID
	

LEFT JOIN 
	(SELECT 
		DS.ProgramID
		,DS.CL_EN_GEN_ID
		,MAX(CASE WHEN DS.CLIENT_CARE_0_ER = '1' 
				  THEN 1 END) ER_Yes_c1
		,MAX(CASE WHEN DS.CLIENT_CARE_0_ER = '1' 
				  THEN 1 END) ER_Yes_c2
	FROM Demographics_Survey DS
	JOIN #ProgramID P ON DS.ProgramID = P.ProgramID
	--JOIN Mstr_Surveys ms ON DS.SurveyID = ms.SurveyID
	WHERE DS.SurveyDate >= @StartDate AND DS.SurveyDate <= DATEADD(MONTH,6,@StartDate) AND DS.SurveyDate <= @EndDate
	GROUP BY DS.ProgramID, DS.CL_EN_GEN_ID) DS_all_c1
	ON ROOT.CLID = DS_all_c1.CL_EN_GEN_ID
	AND ROOT.ProgramID = DS_all_c1.ProgramID

LEFT JOIN 
	(SELECT 
		DS.ProgramID
		,DS.CL_EN_GEN_ID
		,MAX(CASE WHEN DS.CLIENT_CARE_0_ER = '1' 
				  THEN 1 END) ER_Yes_c1
		,MAX(CASE WHEN DS.CLIENT_CARE_0_ER = '1' 
				  THEN 1 END) ER_Yes_c2
	FROM Demographics_Survey DS
	JOIN #ProgramID P ON DS.ProgramID = P.ProgramID
	--JOIN Mstr_Surveys ms ON DS.SurveyID = ms.SurveyID
	WHERE DS.SurveyDate >= @StartDate AND DS.SurveyDate >= DATEADD(MONTH,-6,@EndDate) AND DS.SurveyDate <= @EndDate
	GROUP BY DS.ProgramID, DS.CL_EN_GEN_ID) DS_all_c2
	ON ROOT.CLID = DS_all_c2.CL_EN_GEN_ID
	AND ROOT.ProgramID = DS_all_c2.ProgramID
	
LEFT JOIN 
	(SELECT 
		DS.ProgramID
		,DS.CL_EN_GEN_ID
		,DS.SurveyDate
		,DS.CLIENT_BC_0_USED_6MONTHS
		,RANK() OVER(PARTITION BY DS.ProgramID,DS.CL_EN_GEN_ID ORDER BY DS.SurveyDate DESC,DS.SurveyResponseID DESC) rank
	FROM Demographics_Survey DS
	JOIN #ProgramID P ON DS.ProgramID = P.ProgramID
	JOIN Mstr_Surveys ms ON DS.SurveyID = ms.SurveyID
	WHERE DS.SurveyDate <= @EndDate
	AND ms.SurveyName = 'Demographics Update: Infancy 6 Months') DS_6
	ON ROOT.CLID = DS_6.CL_EN_GEN_ID
	AND ROOT.ProgramID = DS_6.ProgramID
	AND DS_6.rank = 1

LEFT JOIN 
	(SELECT 
		DS.ProgramID
		,DS.CL_EN_GEN_ID
		,DS.SurveyDate
		,CASE 
			WHEN DS.CLIENT_INCOME_AMOUNT = 'Client is dependent on parent/guardian' THEN 1
			WHEN DS.CLIENT_INCOME_AMOUNT = 'Less than or equal to $6,000' THEN 2
			WHEN DS.CLIENT_INCOME_AMOUNT = '$6,001 - $9,000' THEN 3
			WHEN DS.CLIENT_INCOME_AMOUNT = '$9,001 - $12,000' THEN 4
			WHEN DS.CLIENT_INCOME_AMOUNT = '$12,001 - $16,000' THEN 5
			WHEN DS.CLIENT_INCOME_AMOUNT = '$16,001 - $20,000' THEN 6
			WHEN DS.CLIENT_INCOME_AMOUNT = '$20,001 - $30,000' THEN 7
			WHEN DS.CLIENT_INCOME_AMOUNT = 'Over $30,000' THEN 8
		END CLIENT_INCOME_AMOUNT
		,DS.CLIENT_EDUCATION_1_ENROLLED_PLAN
		,DS.CLIENT_SCHOOL_MIDDLE_HS
		,DS.CLIENT_EDUCATION_0_HS_GED
		,DS.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE
		,DS.CLIENT_EDUCATION_1_ENROLLED_CURRENT
		,DS.CLIENT_ED_PROG_TYPE
		,DS.CLIENT_EDUCATION_1_ENROLLED_FTPT
		,DS.CLIENT_EDUCATION_1_ENROLLED_PT_HRS
		,CASE WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP = 'No' THEN 0
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Vocational%' THEN 1
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Some college%' THEN 2
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Associate%' THEN 3
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Bachelor%' THEN 4
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Master%' THEN 5
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Doctorate%' THEN 6
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Professional%' THEN 6
		END CLIENT_EDUCATION_1_HIGHER_EDUC_COMP
		,RANK() OVER(PARTITION BY DS.ProgramID,DS.CL_EN_GEN_ID ORDER BY DS.SurveyDate DESC,DS.SurveyResponseID DESC) rank
	FROM Demographics_Survey DS
	JOIN #ProgramID P ON DS.ProgramID = P.ProgramID
	JOIN Mstr_Surveys ms ON DS.SurveyID = ms.SurveyID
	WHERE ms.SurveyName IN ('Demographics: Pregnancy Intake')
	AND DS.SurveyDate <= @EndDate) DS_in
	ON ROOT.CLID = DS_in.CL_EN_GEN_ID
	AND ROOT.ProgramID = DS_in.ProgramID
	AND DS_in.rank = 1

	
LEFT JOIN 
	(SELECT 
		DS.ProgramID
		,DS.CL_EN_GEN_ID
		,DS.SurveyDate
		,CASE 
			WHEN DS.CLIENT_INCOME_AMOUNT = 'Client is dependent on parent/guardian' THEN 1
			WHEN DS.CLIENT_INCOME_AMOUNT = 'Less than or equal to $6,000' THEN 2
			WHEN DS.CLIENT_INCOME_AMOUNT = '$6,001 - $9,000' THEN 3
			WHEN DS.CLIENT_INCOME_AMOUNT = '$9,001 - $12,000' THEN 4
			WHEN DS.CLIENT_INCOME_AMOUNT = '$12,001 - $16,000' THEN 5
			WHEN DS.CLIENT_INCOME_AMOUNT = '$16,001 - $20,000' THEN 6
			WHEN DS.CLIENT_INCOME_AMOUNT = '$20,001 - $30,000' THEN 7
			WHEN DS.CLIENT_INCOME_AMOUNT = 'Over $30,000' THEN 8
		END CLIENT_INCOME_AMOUNT
		,DS.CLIENT_EDUCATION_1_ENROLLED_PLAN
		,DS.CLIENT_SCHOOL_MIDDLE_HS
		,DS.CLIENT_EDUCATION_0_HS_GED
		,DS.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE
		,DS.CLIENT_EDUCATION_1_ENROLLED_CURRENT
		,DS.CLIENT_ED_PROG_TYPE
		,DS.CLIENT_EDUCATION_1_ENROLLED_FTPT
		,DS.CLIENT_EDUCATION_1_ENROLLED_PT_HRS
		,CASE WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP = 'No' THEN 0
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Vocational%' THEN 1
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Some college%' THEN 2
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Associate%' THEN 3
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Bachelor%' THEN 4
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Master%' THEN 5
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Doctorate%' THEN 6
			  WHEN DS.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE 'Professional%' THEN 6
		END CLIENT_EDUCATION_1_HIGHER_EDUC_COMP
		,RANK() OVER(PARTITION BY DS.ProgramID,DS.CL_EN_GEN_ID ORDER BY DS.SurveyDate DESC,DS.SurveyResponseID DESC) rank
	FROM Demographics_Survey DS
	JOIN #ProgramID P ON DS.ProgramID = P.ProgramID
	JOIN Mstr_Surveys ms ON DS.SurveyID = ms.SurveyID
	WHERE ms.SurveyName IN ('Demographics Update: Infancy 12 Months')
		AND DS.SurveyDate <= @EndDate) DS_12
	ON ROOT.CLID = DS_12.CL_EN_GEN_ID
	AND ROOT.ProgramID = DS_12.ProgramID
	AND DS_12.rank = 1

LEFT OUTER JOIN --Most recent instance of client being screened for depression w/ edinburgh prior to 6 mos   -- .08  62,849
	(SELECT CL_EN_GEN_ID, MAX(SurveyDate) SurveyDate, ProgramID
	FROM 
	(SELECT PH.CL_EN_GEN_ID, PH.SurveyDate, PH.ProgramID
	FROM PHQ_Survey PH
	JOIN #ProgramID P ON PH.ProgramID = P.ProgramID
	JOIN Mstr_Surveys ms ON PH.SurveyID = ms.SurveyID
	WHERE ms.SurveyName IN ('PHQ-9-Infancy 4-6 mos'
							,'PHQ-9-Infancy 1-4 wks'
							,'PHQ-9-Intake'
							,'PHQ-9-Infancy 1-8 wks'
							,'PHQ-9-Pregnancy 36 wks')
	UNION

	SELECT ES.CL_EN_GEN_ID, ES.SurveyDate, ES.ProgramID
	FROM Edinburgh_Survey  ES
	JOIN #ProgramID P ON ES.ProgramID = P.ProgramID
	JOIN Mstr_Surveys ms ON ES.SurveyID = ms.SurveyID
	WHERE ms.SurveyName IN ('Edinburgh Postnatal Depression-Infancy 4-6 mos'
							,'Edinburgh Postnatal Depression-Pregnancy-36 wks'
							,'Edinburgh Postnatal Depression-Infancy 1-8 wks'
							,'Edinburgh Postnatal Depression-Infancy 1-4 wks'
							,'Edinburgh Postnatal Depression-Intake')
	) Data
	WHERE Data.SurveyDate < @EndDate
	GROUP BY ProgramID,CL_EN_GEN_ID) B1C5
	ON ROOT.CLID = B1C5.CL_EN_GEN_ID
	AND ROOT.ProgramID = B1C5.ProgramID
	
LEFT JOIN 
	(SELECT 
		PHQ.CL_EN_GEN_ID
		,PHQ.ProgramID
		,MAX(CASE WHEN PHQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_COMM
		,MAX(CASE WHEN PHQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_COMM
		,MAX(CASE WHEN PHQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_PSOLVE
		,MAX(CASE WHEN PHQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_PROBLEM
		,MAX(CASE WHEN PHQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_PSOCIAL
		,MAX(CASE WHEN PHQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_PERSONAL
		--,PHQ.INFANT_AGES_STAGES_SE_0_EMOTIONAL
		--,PHQ.INFANT_HEALTH_NO_ASQ_TOTAL
		,MAX(CASE WHEN PHQ.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_GMOTOR
		,MAX(CASE WHEN PHQ.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_FMOTOR
		,MAX(CASE WHEN PHQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_GROSS
		,MAX(CASE WHEN PHQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_FINE
	FROM ASQ3_Survey PHQ
	JOIN #ProgramID P ON PHQ.ProgramID = P.ProgramID
	JOIN Mstr_Surveys ms ON PHQ.SurveyID = ms.SurveyID
	WHERE ms.SurveyName IN ('ASQ-3: Infancy 4 Months','ASQ-3: Infancy 10 Months')
		AND PHQ.SurveyDate <= @EndDate
	GROUP BY PHQ.CL_EN_GEN_ID,PHQ.ProgramID) ASQ_410
	ON ROOT.CLID = ASQ_410.CL_EN_GEN_ID
	AND ROOT.ProgramID = ASQ_410.ProgramID
		
LEFT JOIN 
	(SELECT 
		IHS.CL_EN_GEN_ID
		,IHS.ProgramID
		,MAX(CASE WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_COMM
		,MAX(CASE WHEN IHS.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_COMM
		,MAX(CASE WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_PSOLVE
		,MAX(CASE WHEN IHS.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_PROBLEM
		,MAX(CASE WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_PSOCIAL
		,MAX(CASE WHEN IHS.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_PERSONAL
		--,PHQ.INFANT_AGES_STAGES_SE_0_EMOTIONAL
		--,PHQ.INFANT_HEALTH_NO_ASQ_TOTAL
		,MAX(CASE WHEN IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_GMOTOR
		,MAX(CASE WHEN IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_1_FMOTOR
		,MAX(CASE WHEN IHS.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_GROSS
		,MAX(CASE WHEN IHS.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_FINE
	FROM Infant_Health_Survey IHS
	--JOIN #ProgramID P ON PHQ.ProgramID = P.ProgramID
	JOIN Mstr_surveys ms ON IHS.SurveyID = ms.SurveyID
	WHERE ms.SurveyName IN('Infant Health Care-Infancy 6 Months','Infant Health Care: Infancy 12 Months')
		AND IHS.SurveyDate <= @EndDate
	GROUP BY IHS.CL_EN_GEN_ID, IHS.ProgramID) ASQ_IHS_612
	ON ROOT.CLID = ASQ_IHS_612.CL_EN_GEN_ID
	AND ROOT.ProgramID = ASQ_IHS_612.ProgramID

LEFT JOIN  --.01  13,988
	(SELECT 
		IHS.CL_EN_GEN_ID
		,IHS.ProgramID
		,MAX(CASE WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL THEN 1 END) INFANT_AGES_STAGES_SE_0_EMOTIONAL
		,MAX(CASE WHEN IHS.INFANT_HEALTH_NO_ASQ_TOTAL IS NOT NULL THEN 1 END) INFANT_HEALTH_NO_ASQ_TOTAL
	FROM Infant_Health_Survey IHS
	JOIN #ProgramID P ON IHS.ProgramID = P.ProgramID
	JOIN Mstr_Surveys ms ON IHS.SurveyID = ms.SurveyID
	WHERE ms.SurveyName IN ('Infant Health Care-Infancy 6 Months','Infant Health Care: Infancy 12 Months')
	AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
	GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID) IHS_ASQ
	ON ROOT.CLID = IHS_ASQ.CL_EN_GEN_ID
	AND ROOT.ProgramID = IHS_ASQ.ProgramID

LEFT JOIN
	(SELECT
		RS.CL_EN_GEN_ID
		,RS.ProgramID
		,MAX(CASE WHEN 
				(RS.CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER = 'Yes'
				OR RS.CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes')
				AND
				(RS.CLIENT_ABUSE_TIMES_0_HURT_LAST_YR <> 'none'
				OR RS.CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER <> 'none'
				OR RS.CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER <> 'none'
				OR RS.CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER <> 'none'
				OR RS.CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER <> 'none'
				OR (RS.CLIENT_ABUSE_FORCED_0_SEX ='Yes'
					AND RS.CLIENT_ABUSE_FORCED_1_SEX_LAST_YR <> 'none')
				OR RS.CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
				OR (RS.CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes'
					AND RS.CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME <> 'none') )
				THEN 1
		END) DV_ident

	FROM Relationship_Survey RS
	JOIN #ProgramID P ON RS.ProgramID = P.ProgramID
	JOIN Mstr_Surveys ms ON RS.SurveyID = ms.SurveyID
	WHERE ms.SurveyName IN('Relationship Assessment: Pregnancy-Intake','Relationship Assessment: Pregnancy-36 Weeks')
	AND RS.SurveyDate BETWEEN @StartDate AND @EndDate
	GROUP BY RS.CL_EN_GEN_ID,RS.ProgramID)	RS_i36
	ON ROOT.CLID = RS_i36.CL_EN_GEN_ID
	AND ROOT.ProgramID = RS_i36.ProgramID

LEFT JOIN
	(SELECT
		RS.CL_EN_GEN_ID
		,RS.ProgramID
		,MAX(CASE WHEN RS.SERVICE_REFER_0_IPV = 'Client' THEN 1 END) SERVICE_REFER_0_IPV
	FROM Referrals_to_Services_Survey RS
	JOIN #ProgramID P ON RS.ProgramID = P.ProgramID
	--JOIN Mstr_Surveys ms ON RS.SurveyID = ms.SurveyID
	LEFT JOIN #TempRoot TR ON RS.ProgramID = TR.ProgramID AND RS.CL_EN_GEN_ID = TR.CLID
	WHERE RS.SurveyDate BETWEEN TR.ProgramStartDate AND DATEADD(MONTH,12,TR.ProgramStartDate)
	AND RS.SurveyDate <= @EndDate
	GROUP BY RS.CL_EN_GEN_ID,RS.ProgramID) Referrals
	ON ROOT.CLID = Referrals.CL_EN_GEN_ID
	AND ROOT.ProgramID = Referrals.ProgramID


LEFT JOIN  --- For Benchmark 6
	(SELECT 
		ROOT.CLID
		,ROOT.ProgramID
		,MAX(COALESCE(ref_1,ref_2,ref_3,ref_4,ref_5,ref_6,ref_7,ref_8,ref_9,ref_10,ref_11,ref_12,ref_13,ref_14,ref_15,ref_16,ref_17,ref_18,ref_19,ref_20,ref_21,ref_22,ref_23,ref_24,ref_25,ref_26,ref_27,ref_28,ref_29,ref_30,ref_31,ref_32,ref_33,ref_34,ref_35,ref_36)) referred
		,MAX(COALESCE(ref_comp_1,ref_comp_2,ref_comp_3,ref_comp_4,ref_comp_5,ref_comp_6,ref_comp_7,ref_comp_8,ref_comp_9,ref_comp_10,ref_comp_11,ref_comp_12,ref_comp_13,ref_comp_14,ref_comp_15,ref_comp_16,ref_comp_17,ref_comp_18,ref_comp_19,ref_comp_20,ref_comp_21,ref_comp_22,ref_comp_23,ref_comp_24,ref_comp_25,ref_comp_26,ref_comp_27,ref_comp_28,ref_comp_29,ref_comp_30,ref_comp_31,ref_comp_32,ref_comp_33,ref_comp_34,ref_comp_35,ref_comp_36)) referred_comp
	FROM (
		SELECT
			TR.CLID
			,TR.ProgramID
			,CASE WHEN RS.SERVICE_REFER_0_TANF = 'Client' THEN 1 END ref_1
			,CASE WHEN RS.SERVICE_REFER_0_TANF = 'Client' AND GCSS.SERVICE_USE_0_TANF_CLIENT IN('2','5') THEN 1 END ref_comp_1
			,CASE WHEN RS.SERVICE_REFER_0_FOODSTAMP = 'Client' THEN 1 END ref_2
			,CASE WHEN RS.SERVICE_REFER_0_FOODSTAMP = 'Client' AND GCSS.SERVICE_USE_0_FOODSTAMP_CLIENT IN('2','5') THEN 1 END ref_comp_2
			,CASE WHEN RS.SERVICE_REFER_0_SOCIAL_SECURITY = 'Client' THEN 1 END ref_3
			,CASE WHEN RS.SERVICE_REFER_0_SOCIAL_SECURITY = 'Client' AND GCSS.SERVICE_USE_0_SOCIAL_SECURITY_CLIENT IN('2','5') THEN 1 END ref_comp_3
			,CASE WHEN RS.SERVICE_REFER_0_UNEMPLOYMENT = 'Client' THEN 1 END ref_4
			,CASE WHEN RS.SERVICE_REFER_0_UNEMPLOYMENT = 'Client' AND GCSS.SERVICE_USE_0_UNEMPLOYMENT_CLIENT IN('2','5') THEN 1 END ref_comp_4
			,CASE WHEN RS.SERVICE_REFER_0_SUBSID_CHILD_CARE = 'Client' THEN 1 END ref_5
			,CASE WHEN RS.SERVICE_REFER_0_SUBSID_CHILD_CARE = 'Client' AND GCSS.SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT IN('2','5') THEN 1 END ref_comp_5
			,CASE WHEN RS.SERVICE_REFER_0_IPV = 'Client' THEN 1 END ref_6
			,CASE WHEN RS.SERVICE_REFER_0_IPV = 'Client' AND GCSS.SERVICE_USE_0_IPV_CLIENT IN('2','5') THEN 1 END ref_comp_6
			,CASE WHEN RS.SERVICE_REFER_0_CPS = 'Client' THEN 1 END ref_7
			,CASE WHEN RS.SERVICE_REFER_0_CPS = 'Client' AND GCSS.SERVICE_USE_0_CPS_CLIENT IN('2','5') THEN 1 END ref_comp_7
			,CASE WHEN RS.SERVICE_REFER_0_MENTAL = 'Client' THEN 1 END ref_8
			,CASE WHEN RS.SERVICE_REFER_0_MENTAL = 'Client' AND GCSS.SERVICE_USE_0_MENTAL_CLIENT IN('2','5') THEN 1 END ref_comp_8
			,CASE WHEN RS.SERVICE_REFER_0_RELATIONSHIP_COUNSELING = 'Client' THEN 1 END ref_9
			,CASE WHEN RS.SERVICE_REFER_0_RELATIONSHIP_COUNSELING = 'Client' AND GCSS.SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT IN('2','5') THEN 1 END ref_comp_9
			,CASE WHEN RS.SERVICE_REFER_0_SMOKE = 'Client' THEN 1 END ref_10
			,CASE WHEN RS.SERVICE_REFER_0_SMOKE = 'Client' AND GCSS.SERVICE_USE_0_SMOKE_CLIENT IN('2','5') THEN 1 END ref_comp_10
			,CASE WHEN RS.SERVICE_REFER_0_ALCOHOL_ABUSE = 'Client' THEN 1 END ref_11
			,CASE WHEN RS.SERVICE_REFER_0_ALCOHOL_ABUSE = 'Client' AND GCSS.SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT IN('2','5') THEN 1 END ref_comp_11
			,CASE WHEN RS.SERVICE_REFER_0_DRUG_ABUSE = 'Client' THEN 1 END ref_12
			,CASE WHEN RS.SERVICE_REFER_0_DRUG_ABUSE = 'Client' AND GCSS.SERVICE_USE_0_DRUG_ABUSE_CLIENT IN('2','5') THEN 1 END ref_comp_12
			,CASE WHEN RS.SERVICE_REFER_0_MEDICAID = 'Client' THEN 1 END ref_13
			,CASE WHEN RS.SERVICE_REFER_0_MEDICAID = 'Client' AND GCSS.SERVICE_USE_0_MEDICAID_CLIENT IN('2','5') THEN 1 END ref_comp_13
			,CASE WHEN RS.SERVICE_REFER_0_SCHIP = 'Client' THEN 1 END ref_14
			,CASE WHEN RS.SERVICE_REFER_0_SCHIP = 'Client' AND GCSS.SERVICE_USE_0_SCHIP_CLIENT IN('2','5') THEN 1 END ref_comp_14
			,CASE WHEN RS.SERVICE_REFER_0_PRIVATE_INSURANCE = 'Client' THEN 1 END ref_15
			,CASE WHEN RS.SERVICE_REFER_0_PRIVATE_INSURANCE = 'Client' AND GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN('2','5') THEN 1 END ref_comp_15
			,CASE WHEN RS.SERVICE_REFER_MILITARY_INS = 'Client' THEN 1 END ref_16
			,CASE WHEN RS.SERVICE_REFER_MILITARY_INS = 'Client' AND GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ] IN('2','5') THEN 1 END ref_comp_16
			,CASE WHEN RS.SERVICE_REFER_INDIAN_HEALTH = 'Client' THEN 1 END ref_17
			,CASE WHEN RS.SERVICE_REFER_INDIAN_HEALTH = 'Client' AND GCSS.SERVICE_USE_INDIAN_HEALTH_CLIENT IN('2','5') THEN 1 END ref_comp_17
			,CASE WHEN RS.SERVICE_REFER_0_SPECIAL_NEEDS = 'Client' THEN 1 END ref_18
			,CASE WHEN RS.SERVICE_REFER_0_SPECIAL_NEEDS = 'Client' AND GCSS.SERVICE_USE_0_SPECIAL_NEEDS_CLIENT IN('2','5') THEN 1 END ref_comp_18
			,CASE WHEN RS.SERVICE_REFER_0_PCP_R2  = 'Client' THEN 1 END ref_19
			,CASE WHEN RS.SERVICE_REFER_0_PCP_R2  = 'Client' AND (GCSS.SERVICE_USE_0_PCP_CLIENT IN('2','5') OR GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL IN('2','5') OR GCSS.SERVICE_USE_PCP_CLIENT_POSTPARTUM IN('2','5') OR GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN IN('2','5')) THEN 1 END ref_comp_19
			,CASE WHEN RS.SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY = 'Client' THEN 1 END ref_20
			,CASE WHEN RS.SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY = 'Client' AND GCSS.SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT IN('2','5') THEN 1 END ref_comp_20
			,CASE WHEN RS.SERVICE_REFER_0_WIC_CLIENT = 'Client' THEN 1 END ref_21
			,CASE WHEN RS.SERVICE_REFER_0_WIC_CLIENT = 'Client' AND GCSS.SERVICE_USE_0_WIC_CLIENT IN('2','5') THEN 1 END ref_comp_21
			,CASE WHEN RS.SERVICE_REFER_0_CHILD_CARE = 'Client' THEN 1 END ref_22
			,CASE WHEN RS.SERVICE_REFER_0_CHILD_CARE = 'Client' AND GCSS.SERVICE_USE_0_CHILD_CARE_CLIENT IN('2','5') THEN 1 END ref_comp_22
			,CASE WHEN RS.SERVICE_REFER_0_JOB_TRAINING = 'Client' THEN 1 END ref_23
			,CASE WHEN RS.SERVICE_REFER_0_JOB_TRAINING = 'Client' AND GCSS.SERVICE_USE_0_JOB_TRAINING_CLIENT IN('2','5') THEN 1 END ref_comp_23
			,CASE WHEN RS.SERVICE_REFER_0_HOUSING = 'Client' THEN 1 END ref_24
			,CASE WHEN RS.SERVICE_REFER_0_HOUSING = 'Client' AND GCSS.SERVICE_USE_0_HOUSING_CLIENT IN('2','5') THEN 1 END ref_comp_24
			,CASE WHEN RS.SERVICE_REFER_0_TRANSPORTATION = 'Client' THEN 1 END ref_25
			,CASE WHEN RS.SERVICE_REFER_0_TRANSPORTATION = 'Client' AND GCSS.SERVICE_USE_0_TRANSPORTATION_CLIENT IN('2','5') THEN 1 END ref_comp_25
			,CASE WHEN RS.SERVICE_REFER_0_PREVENT_INJURY = 'Client' THEN 1 END ref_26
			,CASE WHEN RS.SERVICE_REFER_0_PREVENT_INJURY = 'Client' AND GCSS.SERVICE_USE_0_PREVENT_INJURY_CLIENT IN('2','5') THEN 1 END ref_comp_26
			,CASE WHEN RS.SERVICE_REFER_0_BIRTH_EDUC_CLASS = 'Client' THEN 1 END ref_27
			,CASE WHEN RS.SERVICE_REFER_0_BIRTH_EDUC_CLASS = 'Client' AND GCSS.SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT IN('2','5') THEN 1 END ref_comp_27
			,CASE WHEN RS.SERVICE_REFER_0_LACTATION = 'Client' THEN 1 END ref_28
			,CASE WHEN RS.SERVICE_REFER_0_LACTATION = 'Client' AND GCSS.SERVICE_USE_0_LACTATION_CLIENT IN('2','5') THEN 1 END ref_comp_28
			,CASE WHEN RS.SERVICE_REFER_0_GED = 'Client' THEN 1 END ref_29
			,CASE WHEN RS.SERVICE_REFER_0_GED = 'Client' AND GCSS.SERVICE_USE_0_GED_CLIENT IN('2','5') THEN 1 END ref_comp_29
			,CASE WHEN RS.SERVICE_REFER_0_HIGHER_EDUC = 'Client' THEN 1 END ref_30
			,CASE WHEN RS.SERVICE_REFER_0_HIGHER_EDUC = 'Client' AND GCSS.SERVICE_USE_0_HIGHER_EDUC_CLIENT IN('2','5') THEN 1 END ref_comp_30
			,CASE WHEN RS.SERVICE_REFER_0_CHARITY = 'Client' THEN 1 END ref_31
			,CASE WHEN RS.SERVICE_REFER_0_CHARITY = 'Client' AND GCSS.SERVICE_USE_0_CHARITY_CLIENT IN('2','5') THEN 1 END ref_comp_31
			,CASE WHEN RS.SERVICE_REFER_0_LEGAL_CLIENT = 'Client' THEN 1 END ref_32
			,CASE WHEN RS.SERVICE_REFER_0_LEGAL_CLIENT = 'Client' AND GCSS.SERVICE_USE_0_LEGAL_CLIENT IN('2','5') THEN 1 END ref_comp_32
			,CASE WHEN RS.SERVICE_REFER_0_PATERNITY = 'Client' THEN 1 END ref_33
			,CASE WHEN RS.SERVICE_REFER_0_PATERNITY = 'Client' AND GCSS.SERVICE_USE_0_PATERNITY_CLIENT IN('2','5') THEN 1 END ref_comp_33
			,CASE WHEN RS.SERVICE_REFER_0_CHILD_SUPPORT = 'Client' THEN 1 END ref_34
			,CASE WHEN RS.SERVICE_REFER_0_CHILD_SUPPORT = 'Client' AND GCSS.SERVICE_USE_0_CHILD_SUPPORT_CLIENT IN('2','5') THEN 1 END ref_comp_34
			,CASE WHEN RS.SERVICE_REFER_0_ADOPTION = 'Client' THEN 1 END ref_35
			,CASE WHEN RS.SERVICE_REFER_0_ADOPTION = 'Client' AND GCSS.SERVICE_USE_0_ADOPTION_CLIENT IN('2','5') THEN 1 END ref_comp_35
			,CASE WHEN RS.SERVICE_REFER_0_DENTAL = 'Client' THEN 1 END ref_36
			,CASE WHEN RS.SERVICE_REFER_0_DENTAL = 'Client' AND GCSS.SERVICE_USE_0_DENTAL_CLIENT IN('2','5') THEN 1 END ref_comp_36
			,CASE WHEN RS.SERVICE_REFER_0_OTHER = 'Client' THEN 1 END ref_37
			,CASE WHEN RS.SERVICE_REFER_0_OTHER = 'Client' AND (GCSS.SERVICE_USE_0_OTHER1 IN('2','5') OR GCSS.SERVICE_USE_0_OTHER2 IN('2','5') OR GCSS.SERVICE_USE_0_OTHER3  IN('2','5')) THEN 1 END ref_comp_37

		FROM #TempRoot TR
		JOIN #ProgramID P ON TR.ProgramID = P.ProgramID
		LEFT JOIN Infant_Birth_Survey IBS ON TR.CLID = IBS.CL_EN_GEN_ID AND TR.ProgramID = IBS.ProgramID
		LEFT JOIN Referrals_to_Services_Survey RS 
			ON TR.CLID = RS.CL_EN_GEN_ID AND P.ProgramID = RS.ProgramID AND RS.SurveyDate <= @EndDate AND RS.SurveyDate BETWEEN IBS.INFANT_BIRTH_0_DOB AND DATEADD(MONTH,12,IBS.INFANT_BIRTH_0_DOB)
		LEFT JOIN Govt_Comm_Srvcs_Survey GCSS 
			JOIN Mstr_Surveys ms ON GCSS.SurveyID = ms.SurveyID
			ON TR.CLID = GCSS.CL_EN_GEN_ID AND TR.ProgramID = GCSS.ProgramID AND ms.SurveyName = 'Use of Government & Community Services-Infancy 12'
	) Root
	GROUP BY Root.CLID, Root.ProgramID) Referrals_B6
	ON ROOT.CLID = Referrals_B6.CLID
	AND ROOT.ProgramID = Referrals_B6.ProgramID


GROUP BY ROOT.ProgramID, ROOT.CLID
GO
