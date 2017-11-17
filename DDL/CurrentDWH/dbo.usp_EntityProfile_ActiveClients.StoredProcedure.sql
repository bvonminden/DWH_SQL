USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_EntityProfile_ActiveClients]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_EntityProfile_ActiveClients]
( @StartDate DATE, @EndDate DATE, @Team VARCHAR(max))

AS

--DECLARE @StartDate DATE, @EndDate DATE, @Team VARCHAR(max)
--SET @StartDate = CAST('1/1/2013' AS DATE)
--SET @EndDate = CAST ('12/31/2013' AS DATE)
--SET @Team = '1394'--'1988,974,1007,1013,1001,869,995,998,1004,857,860,971,977,854,866,863,1925,986,1576,1922,992,989,1943,983,1887,1010,2010,980'

--------------- CLIENTS SERVED POPULATION ----------------- (CTE)
;WITH Clients_Served AS
(SELECT  
	CL_EN_GEN_ID
	,ProgramID
FROM UV_Fidelity_aHVES
WHERE CLIENT_COMPLETE_0_VISIT = 'Completed'
AND SurveyDate BETWEEN @StartDate AND @EndDate
AND ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Team))
GROUP BY CL_EN_GEN_ID,ProgramID)


---------------ACTIVE CLIENTS POPULATION----------------- (CTE)

, Active_Clients AS

(SELECT 
	EAD.CLID
	,EAD.ProgramID
	,C.DEMO_CLIENT_INTAKE_0_RACE
	,C.DEMO_CLIENT_INTAKE_0_ETHNICITY
	,DATEDIFF(YEAR,C.DOB,EAD.ProgramStartDate) AgeAtEnroll
	,CASE WHEN EAD.ProgramStartDate BETWEEN @StartDate AND @EndDate THEN 1 END Newly_Enrolled
FROM EnrollmentAndDismissal EAD
JOIN Clients C
	ON EAD.CLID = C.Client_Id
JOIN Clients_Served  ------- BLARGHHH!!!! - Slows down the query significantly ---------------
	ON EAD.CLID = Clients_Served.CL_EN_GEN_ID
	AND EAD.ProgramID = Clients_Served.ProgramID
WHERE EAD.ProgramStartDate <= @EndDate
	AND ISNULL(EAD.EndDate,@EndDate) >= @StartDate
AND EAD.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Team)))

---------------ACTIVE CLIENTS DATA ----------------- (CTE)

,Active_Clients_data AS
(SELECT 
	C.CLID
	,C.ProgramID
	,C.Newly_Enrolled
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'American Indian or Alaska Native' THEN 1 END RIndian
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Asian' THEN 1 END RAsian
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Black or African American' THEN 1 END RBlack
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Native Hawaiian or other Pacific Islander' THEN 1 END RHawaiin
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Asian;Native Hawaiian or other Pacific Islander' THEN 1 END RAsianHawaiian
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'White' THEN 1 END RWhite
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Declined to self-identify' THEN 1 END RDeclined
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE LIKE '%;%' AND C.DEMO_CLIENT_INTAKE_0_RACE <> 'Asian;Native Hawaiian or other Pacific Islander' THEN 1 END RMulti
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_RACE IS NULL THEN 1 END RMissing
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Hispanic or Latina' THEN 1 END EHispanic
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Not Hispanic or Latina' THEN 1 END ENotHispanic
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Declined to self-identify' THEN 1 END EDeclined
	,CASE WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY IS NULL THEN 1 END EMissing
	,C.AgeAtEnroll
	,DS_married.Married
	,Medicaid.Medicaid
	,HS_GED_in.HSGED_No_in
	,HS_GED.HSGED_Yes_24
	,HS_GED.HSGED_No_24
	,HS_GED.HSGED_Enrolled_24
	,HS_GED.HSGED_Not_Enrolled_24
	,HS_GED.HSGED_data_24
	,Smok_in.Smoke Smoke_in
	,Smok_preg.Smoke Smoke_36
	,Births.Births
	,Births.Gest_Full
	,Births.Gest_lt39
	,Births.Gest_lt37
	,Births.Weight_mt2500
	,Births.Weight_lt2500
	,Births.BF_init
	,BF_6.BF_6
	,IMM_12.IMM_12
	,IMM_24.IMM_24
--INTO #Active_Clients
FROM Active_Clients C
LEFT JOIN  ------------- consider not married both missing answers and not married
	(SELECT 
		CL_EN_GEN_ID
		,ProgramID
		,CASE WHEN client_Marital_0_Status = 'Married (legal or common law)' THEN 1 END Married
	FROM Demographics_Survey
	WHERE dbo.fnGetFormName(SurveyID) = 'Demographics: Pregnancy Intake') DS_married
	ON C.CLID = DS_married.CL_EN_GEN_ID
	AND C.ProgramID = DS_married.ProgramID
LEFT JOIN
	(SELECT 
		CL_EN_GEN_ID
		,ProgramID
		,MAX(CASE WHEN SERVICE_USE_0_MEDICAID_CLIENT in (2,5) THEN 1 ELSE 0 END) Medicaid
	FROM Govt_Comm_Srvcs_Survey
	WHERE SurveyDate BETWEEN @StartDate AND @EndDate
	GROUP BY CL_EN_GEN_ID,ProgramID) Medicaid
	ON C.CLID = Medicaid.CL_EN_GEN_ID
	AND C.ProgramID = Medicaid.ProgramID
LEFT JOIN 
	(SELECT 
		CL_EN_GEN_ID
		,ProgramID
		,CASE WHEN CLIENT_EDUCATION_0_HS_GED IS NULL or CLIENT_EDUCATION_0_HS_GED = 'No' THEN 1 ELSE 0 END HSGED_No_in
	FROM Demographics_Survey 
	WHERE dbo.fnGetFormName(SurveyID)  = 'Demographics: Pregnancy Intake') HS_GED_in
	ON C.CLID = HS_GED_in.CL_EN_GEN_ID
	AND C.ProgramID = HS_GED_in.ProgramID
LEFT JOIN 
	(SELECT 
		CL_EN_GEN_ID
		,ProgramID
		,CASE WHEN CLIENT_EDUCATION_0_HS_GED LIKE '%Yes%' THEN 1 ELSE 0 END HSGED_Yes_24
		,CASE WHEN CLIENT_EDUCATION_0_HS_GED IS NULL or CLIENT_EDUCATION_0_HS_GED = 'No' THEN 1 ELSE 0 END HSGED_No_24
		,CASE WHEN CLIENT_EDUCATION_0_HS_GED IS NOT NULL THEN 1 ELSE 0 END HSGED_data_24
		,CASE WHEN CLIENT_SCHOOL_MIDDLE_HS LIKE 'Yes%' THEN 1 ELSE 0 END HSGED_Enrolled_24
		,CASE WHEN CLIENT_SCHOOL_MIDDLE_HS LIKE 'Not%' THEN 1 ELSE 0 END HSGED_Not_Enrolled_24
	FROM Demographics_Survey 
	WHERE dbo.fnGetFormName(SurveyID)  = 'Demographics Update: Toddler 24 Months') HS_GED
	ON C.CLID = HS_GED.CL_EN_GEN_ID
	AND C.ProgramID = HS_GED.ProgramID
LEFT JOIN 
	(SELECT DiSTINCT
		CL_EN_GEN_ID
		,ProgramID
		--,CASE WHEN ISNULL(CLIENT_SUBSTANCE_CIG_1_PRE_PREG,0) > 0 THEN 1 ELSE 0 END Pre_Smoke
		--,CASE WHEN ISNULL(CLIENT_SUBSTANCE_CIG_0_DURING_PREG,0) = 'Yes' THEN 1 
		--	  WHEN ISNULL(CLIENT_SUBSTANCE_CIG_0_DURING_PREG,0) = 'No' THEN 2  ELSE 0 END During_Smoke
		,CASE WHEN ISNULL( CLIENT_SUBSTANCE_CIG_1_LAST_48,0) > 0 THEN 1 ELSE 0 END Smoke
	FROM Health_Habits_Survey
	WHERE dbo.fnGetFormName(SurveyID) = 'Health Habits: Pregnancy-Intake') Smok_in
	ON C.CLID = Smok_in.CL_EN_GEN_ID
	AND C.ProgramID = Smok_in.ProgramID
LEFT JOIN 
	(SELECT DiSTINCT
		CL_EN_GEN_ID
		,ProgramID
		--,CASE WHEN ISNULL(CLIENT_SUBSTANCE_CIG_1_PRE_PREG,0) > 0 THEN 1 ELSE 0 END Pre_Smoke
		--,CASE WHEN ISNULL(CLIENT_SUBSTANCE_CIG_0_DURING_PREG,0) = 'Yes' THEN 1 
		--	  WHEN ISNULL(CLIENT_SUBSTANCE_CIG_0_DURING_PREG,0) = 'No' THEN 2  ELSE 0 END During_Smoke
		,CASE WHEN ISNULL( CLIENT_SUBSTANCE_CIG_1_LAST_48,0) > 0 THEN 1 ELSE 0 END Smoke
	FROM Health_Habits_Survey
	WHERE dbo.fnGetFormName(SurveyID) = 'Health Habits: Pregnancy-36 Weeks') Smok_preg
	ON C.CLID = Smok_preg.CL_EN_GEN_ID
	AND C.ProgramID = Smok_preg.ProgramID
LEFT JOIN
	(SELECT 
		CL_EN_GEN_ID
		,ProgramID
		,(CASE WHEN INFANT_BIRTH_0_DOB BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END)
		+(CASE WHEN INFANT_BIRTH_0_DOB2 BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END)
		+(CASE WHEN INFANT_BIRTH_0_DOB3 BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END) Births
		,(CASE WHEN INFANT_BIRTH_0_DOB BETWEEN @StartDate AND @EndDate AND INFANT_BIRTH_1_GEST_AGE > 37 THEN 1 ELSE 0 END )
		+(CASE WHEN INFANT_BIRTH_0_DOB2 BETWEEN @StartDate AND @EndDate AND INFANT_BIRTH_1_GEST_AGE2 > 37 THEN 1 ELSE 0 END )
		+(CASE WHEN INFANT_BIRTH_0_DOB3 BETWEEN @StartDate AND @EndDate AND INFANT_BIRTH_1_GEST_AGE3 > 37 THEN 1 ELSE 0 END ) Gest_Full
		,(CASE WHEN INFANT_BIRTH_0_DOB BETWEEN @StartDate AND @EndDate AND INFANT_BIRTH_1_GEST_AGE < 39 THEN 1 ELSE 0 END )
		+(CASE WHEN INFANT_BIRTH_0_DOB2 BETWEEN @StartDate AND @EndDate AND INFANT_BIRTH_1_GEST_AGE2 < 39 THEN 1 ELSE 0 END )
		+(CASE WHEN INFANT_BIRTH_0_DOB3 BETWEEN @StartDate AND @EndDate AND INFANT_BIRTH_1_GEST_AGE3 < 39 THEN 1 ELSE 0 END ) Gest_lt39
		,(CASE WHEN INFANT_BIRTH_0_DOB BETWEEN @StartDate AND @EndDate AND INFANT_BIRTH_1_GEST_AGE < 37 THEN 1 ELSE 0 END )
		+(CASE WHEN INFANT_BIRTH_0_DOB2 BETWEEN @StartDate AND @EndDate AND INFANT_BIRTH_1_GEST_AGE2 < 37 THEN 1 ELSE 0 END )
		+(CASE WHEN INFANT_BIRTH_0_DOB3 BETWEEN @StartDate AND @EndDate AND INFANT_BIRTH_1_GEST_AGE3 < 37 THEN 1 ELSE 0 END ) Gest_lt37
		,(CASE WHEN INFANT_BIRTH_0_DOB BETWEEN @StartDate AND @EndDate AND ISNULL(INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS,INFANT_BIRTH_1_WEIGHT_GRAMS) >= 2500 THEN 1 ELSE 0 END ) Weight_mt2500 --INFANT_BIRTH_1_WEIGHT_GRAMS not used
		,(CASE WHEN INFANT_BIRTH_0_DOB BETWEEN @StartDate AND @EndDate AND ISNULL(INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS,INFANT_BIRTH_1_WEIGHT_GRAMS) < 2500 THEN 1 ELSE 0 END ) Weight_lt2500
		,(CASE WHEN INFANT_BIRTH_0_DOB BETWEEN @StartDate AND @EndDate AND INFANT_BREASTMILK_0_EVER_BIRTH = 'YES' THEN 1 ELSE 0 END )
		+(CASE WHEN INFANT_BIRTH_0_DOB2 BETWEEN @StartDate AND @EndDate AND INFANT_BREASTMILK_0_EVER_BIRTH2 = 'YES' THEN 1 ELSE 0 END )
		+(CASE WHEN INFANT_BIRTH_0_DOB3 BETWEEN @StartDate AND @EndDate AND INFANT_BREASTMILK_0_EVER_BIRTH3 = 'YES' THEN 1 ELSE 0 END ) BF_init
		,INFANT_BIRTH_1_WEIGHT_GRAMS
		,INFANT_BIRTH_1_GEST_AGE
	FROM Infant_Birth_Survey) Births
	ON C.CLID = Births.CL_EN_GEN_ID
	AND C.ProgramID = Births.ProgramID
LEFT JOIN
	(SELECT 
		CL_EN_GEN_ID
		,ProgramID
		,MAX(CASE WHEN INFANT_BREASTMILK_1_CONT = 'Yes' THEN 1 ELSE 0 END) BF_6
	FROM Infant_Health_Survey
	WHERE dbo.fnGetFormName(SurveyID) = 'Infant Health Care-Infancy 6 Months'
	GROUP BY CL_EN_GEN_ID,ProgramID) BF_6
	ON C.CLID = BF_6.CL_EN_GEN_ID
	AND C.ProgramID = BF_6.ProgramID
LEFT JOIN
	(SELECT 
		CL_EN_GEN_ID
		,ProgramID
		,MAX(CASE WHEN INFANT_HEALTH_IMMUNIZ_0_UPDATE = 'Yes' THEN 1 ELSE 0 END) IMM_12
	FROM Infant_Health_Survey
	WHERE dbo.fnGetFormName(SurveyID) = 'Infant Health Care: Infancy 12 Months'
	GROUP BY CL_EN_GEN_ID,ProgramID) IMM_12
	ON C.CLID = IMM_12.CL_EN_GEN_ID
	AND C.ProgramID = IMM_12.ProgramID
LEFT JOIN
	(SELECT 
		CL_EN_GEN_ID
		,ProgramID
		,MAX(CASE WHEN INFANT_HEALTH_IMMUNIZ_0_UPDATE = 'Yes' THEN 1 ELSE 0 END) IMM_24
	FROM Infant_Health_Survey
	WHERE dbo.fnGetFormName(SurveyID) = 'Infant Health Care: Toddler 24 Months'
	GROUP BY CL_EN_GEN_ID,ProgramID) IMM_24
	ON C.CLID = IMM_24.CL_EN_GEN_ID
	AND C.ProgramID = IMM_24.ProgramID
)

--SELECT *
--FROM Active_Clients_data
--/*

SELECT 
	COUNT(CLID) Clients
	,COUNT(Newly_Enrolled) Newly_Enrolled
	,ISNULL(SUM(RIndian),0) RIndian
	,ISNULL(SUM(RAsian),0) RAsian
	,ISNULL(SUM(RBlack),0) RBlack
	,ISNULL(SUM(RHawaiin),0) RHawaiin
	,ISNULL(SUM(RAsianHawaiian),0) RAsianHawaiian
	,ISNULL(SUM(RWhite),0) RWhite
	,ISNULL(SUM(RDeclined),0) RDeclined
	,ISNULL(SUM(RMulti),0) RMulti
	,ISNULL(SUM(RMissing),0) RMissing
	,ISNULL(SUM(EHispanic),0) EHispanic
	,ISNULL(SUM(ENotHispanic),0) ENotHispanic
	,ISNULL(SUM(EDeclined),0) EDeclined
	,ISNULL(SUM(EMissing),0) EMissing
	,ISNULL(MAX(med_age.med_age),0) med_age
	,ISNULL(SUM(Medicaid),0) Medicaid
	,COUNT(CLID) - ISNULL(SUM(Married),0) Not_married
	,ISNULL(SUM(CASE WHEN Smoke_36 IS NOT NULL THEN Smoke_in END),0) Smoke_in 
	,ISNULL(SUM(CASE WHEN Smoke_in = 1 and Smoke_36 = 1 THEN 1 END),0) Smoke_both
	,ISNULL(SUM(CASE WHEN Smoke_in = 0 AND Smoke_36 IS NOT NULL THEN 1 END),0) Smoke_not_in
	,ISNULL(SUM(CASE WHEN Smoke_in = 0 AND Smoke_36 = 1 THEN 1 END),0) Smoke_not_in_yes_36
	,ISNULL(SUM(HSGED_No_in),0) No_HSGED
	,ISNULL(SUM(CASE WHEN HSGED_data_24 IS NOT NULL THEN HSGED_No_in END),0) No_HSGED_24_data
	,ISNULL(SUM(CASE WHEN HSGED_No_in = 1 AND HSGED_Yes_24 = 1 THEN 1 END),0) No_HSGED_24_Yes
	,ISNULL(SUM(CASE WHEN HSGED_No_in = 1 AND HSGED_No_24 = 1 AND HSGED_Enrolled_24 = 1 THEN 1 END),0) No_HSGED_24_no_enrolled
	,ISNULL(SUM(CASE WHEN HSGED_No_in = 1 AND HSGED_No_24 = 1 AND HSGED_Not_Enrolled_24 = 1 THEN 1 END),0) No_HSGED_24_no_enrolled_no
	,ISNULL(SUM(Births),0) Births
	,ISNULL(SUM(Gest_Full),0) Gest_Full
	,ISNULL(SUM(Gest_lt39),0) Gest_lt39
	,ISNULL(SUM(Gest_lt37),0) Gest_lt37
	,ISNULL(SUM(Weight_lt2500),0) Weight_lt2500
	,ISNULL(SUM(Weight_mt2500),0) Weight_mt2500
	,ISNULL(SUM(BF_init),0) BF_init
	,ISNULL(SUM(BF_6),0) BF_6
	,ISNULL(SUM(CASE WHEN BF_6 IS NOT NULL THEN 1 END),0) Data_6
	,ISNULL(SUM(IMM_12),0) IMM_12
	,ISNULL(SUM(CASE WHEN IMM_12 IS NOT NULL THEN 1 END),0) Data_12
	,ISNULL(SUM(IMM_24),0) IMM_24
	,ISNULL(SUM(CASE WHEN IMM_24 IS NOT NULL THEN 1 END),0) Data_24


FROM Active_Clients_data

LEFT JOIN        ------------------------------This is a querky way to add median age but performs nicely... ------------------
	(SELECT 	AVG(1.0 * AgeAtEnroll) med_age
	FROM
	(
		SELECT o.AgeAtEnroll, rn = ROW_NUMBER() OVER (ORDER BY o.AgeAtEnroll), c.c
		FROM Active_Clients_data AS o
		CROSS JOIN (SELECT c = COUNT(*) FROM Active_Clients_data) AS c
	) AS x
	WHERE rn IN ((c + 1)/2, (c + 2)/2)) med_age ON 1=1

	--GROUP BY CLID
--*/

GO
