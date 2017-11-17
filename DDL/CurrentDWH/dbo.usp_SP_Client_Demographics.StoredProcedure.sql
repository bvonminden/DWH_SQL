USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_SP_Client_Demographics]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_SP_Client_Demographics] 
	(@StartDate DATE
	,@EndDate DATE
	,@Team VARCHAR(4000)
	,@Client VARCHAR(100)
	,@Funding VARCHAR(4000))

AS

--DECLARE 
--	@StartDate DATE
--	,@EndDate DATE
--	,@Team VARCHAR(4000)
--	,@Client VARCHAR(100)
--	,@Funding VARCHAR(4000)

--SET @StartDate	= '1/1/2014'
--SET @EndDate	= '6/30/2014'
--SET @Client		= '1' -- 1 active, 2 new
--SET @Team		= '854,857,860,863,866,869,971,974,977,980,983,986,989,992,995,998,1001,1004,1007,1010,1013,1576,1887,1922,1925,1943,1988,2010'--'1394'
--SET @Funding	= '1,2' --1 comp, 2 formula, 3 tribal, 4 none



SET @Funding = COALESCE(@Funding,'4')


;WITH Funding AS
(SELECT 
		1 MIECHV_param
		,MAX(CASE WHEN Value = 1 THEN 1 END) MIECHV_Comp
		,MAX(CASE WHEN Value = 2 THEN 1 END) MIECHV_Form
		,MAX(CASE WHEN Value = 3 THEN 1 END) MIECHV_Trib
		,MAX(CASE WHEN Value = 4 THEN 1 END) MIECHV_none
	FROM dbo.udf_ParseMultiParam(@Funding))


SELECT 
	EAD.ProgramID
	,EAD.CLID
	,CASE WHEN EAD.ProgramStartDate <= @EndDate AND ISNULL(EAD.EndDate,@EndDate) >= @StartDate THEN 1 ELSE 0 END Active_Clients
	,CASE WHEN EAD.ProgramStartDate BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END New_Clients
	,C.DEMO_CLIENT_INTAKE_0_RACE
	,C.DEMO_CLIENT_INTAKE_0_ANCESTRY
	,C.DEMO_CLIENT_INTAKE_0_ETHNICITY
	,CFS.MIECHV_Comp
	,CFS.MIECHV_Form
	,CFS.MIECHV_Trib
	,CASE WHEN CFS.MIECHV_Comp = 0 AND CFS.MIECHV_Form = 0 AND CFS.MIECHV_Trib = 0 THEN 1 END MIECHV_None
	,F1.MIECHV_param

	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'American Indian or Alaska Native' THEN 1 ELSE 0 END Native
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Asian' THEN 1 ELSE 0 END Asian
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Black or African American' THEN 1 ELSE 0 END Black
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Native Hawaiian or other Pacific Islander' THEN 1 ELSE 0 END Pacific
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'White' THEN 1 ELSE 0 END White
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE LIKE '%;%' THEN 1 ELSE 0 END Multi
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Declined to self-identify' THEN 1 ELSE 0 END Race_Declined
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE IS NULL THEN 1 ELSE 0 END Race_Missing
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY='Declined to self-identify' THEN 1 ELSE 0 END Eth_declined
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY='Hispanic or Latina' THEN 1 ELSE 0 END Eth_Hispanic_or_Latina
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY='Not Hispanic or Latina' THEN 1 ELSE 0 END Eth_Not_Hispanic_or_Latina
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY IS NULL THEN 1 ELSE 0 END Eth_Missing
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Afro-Caribbean-excluding Haitian%' THEN 1 ELSE 0 END [Afro-Caribbean-excluding Haitian]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Anglo-Dutch Caribbean%' THEN 1 ELSE 0 END [Anglo-Dutch Caribbean]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Arab%' THEN 1 ELSE 0 END [Arab] 
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Bangladeshi/Bengali%' THEN 1 ELSE 0 END [Bangladeshi/Bengali]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Central American, including Mexican%' THEN 1 ELSE 0 END [Central American, including Mexican]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Chinese%' THEN 1 ELSE 0 END [Chinese]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Cuban%' THEN 1 ELSE 0 END [Cuban]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Dominican%' THEN 1 ELSE 0 END [Dominican]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Eritrean%' THEN 1 ELSE 0 END [Eritrean]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Filipino%' THEN 1 ELSE 0 END [Filipino]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Haitian%' THEN 1 ELSE 0 END [Haitian]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Hmong%' THEN 1 ELSE 0 END [Hmong]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Indian (South Asian)%' THEN 1 ELSE 0 END [Indian (South Asian)]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Israeli%' THEN 1 ELSE 0 END [Israeli]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Korean%' THEN 1 ELSE 0 END [Korean]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Laotian%' THEN 1 ELSE 0 END [Laotian]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%North African%' THEN 1 ELSE 0 END [North African]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Pakistani%' THEN 1 ELSE 0 END [Pakistani]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Palestinian%' THEN 1 ELSE 0 END [Palestinian]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Persian%' THEN 1 ELSE 0 END [Persian]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Polish%' THEN 1 ELSE 0 END [Polish]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Puerto Rican%' THEN 1 ELSE 0 END [Puerto Rican]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Russian%' THEN 1 ELSE 0 END [Russian]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Somali%' THEN 1 ELSE 0 END [Somali]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Sub-Saharan African%' THEN 1 ELSE 0 END [Sub-Saharan African]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%South American%' THEN 1 ELSE 0 END [South American]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Ukrainian%' THEN 1 ELSE 0 END [Ukrainian]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Vietnamese%' THEN 1 ELSE 0 END [Vietnamese]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Declined to self-identify%' THEN 1 ELSE 0 END [Ancestry_Declined to self-identify]
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ANCESTRY LIKE '%Other%' THEN 1 ELSE 0 END [Ancestry_Other]

FROM 
UV_EADT EAD
JOIN UV_PAS P	ON EAD.ProgramID = P.ProgramID
JOIN (SELECT * FROM dbo.udf_ParseMultiParam(@Team)) P_param ON P.ProgramID = P_param.Value --limits programs to teams

JOIN Clients C ON EAD.CLID = C.Client_Id
LEFT JOIN --- Captures latest client funding survey prior to end date
	(SELECT 
		CL_EN_GEN_ID
		,ProgramID
		,SurveyDate
		,CASE WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL THEN 1 ELSE 0 END MIECHV_Comp
		,CASE WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL THEN 1 ELSE 0 END MIECHV_Form
		,CASE WHEN CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL IS NOT NULL THEN 1 ELSE 0 END MIECHV_Trib
		,ROW_NUMBER() OVER(PARTITION BY CL_EN_GEN_ID,ProgramID ORDER BY SurveyDate DESC) rank
	FROM Client_Funding_Survey) CFS 
	ON CFS.CL_EN_GEN_ID = EAD.CLID
	AND CFS.ProgramID = EAD.ProgramID
	AND CFS.SurveyDate <= @EndDate
	AND CFS.rank = 1
LEFT JOIN Funding F1 ON CFS.MIECHV_Comp = F1.MIECHV_Comp
	OR CFS.MIECHV_Form = F1.MIECHV_Form
	OR CFS.MIECHV_Trib = F1.MIECHV_Trib
	OR (CFS.MIECHV_Comp = 0 AND CFS.MIECHV_Comp = 0 AND CFS.MIECHV_Trib = 0 AND F1.MIECHV_none = 1)
WHERE EAD.RankingLatest = 1
---Client populationm parmeters
AND ((@Client = 1 AND EAD.ProgramStartDate <= @EndDate AND (EAD.EndDate IS NULL OR EAD.EndDate >= @StartDate)) OR -- probably not the quickest because it could evaluate all statements
	(@Client = 2 AND EAD.ProgramStartDate >= @StartDate AND EAD.ProgramStartDate < DATEADD(DAY,1,@EndDate)))

AND (F1.MIECHV_param = 1 )



GO
