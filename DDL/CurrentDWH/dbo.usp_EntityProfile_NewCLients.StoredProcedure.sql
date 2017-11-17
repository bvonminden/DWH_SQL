USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_EntityProfile_NewCLients]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_EntityProfile_NewCLients]
( @StartDate DATE, @EndDate DATE, @Team VARCHAR(max))

AS

--DECLARE @StartDate DATE, @EndDate DATE, @Team VARCHAR(max)
--SET @StartDate = CAST('1/1/2013' AS DATE)
--SET @EndDate = CAST ('12/31/2013' AS DATE)
--SET @Team = '1394'


--------------- CLIENTS SERVED POPULATION ----------------- (CTE)
;WITH Clients_Served AS
(SELECT DISTINCT 
	CL_EN_GEN_ID
	,ProgramID
FROM UV_Fidelity_aHVES
WHERE CLIENT_COMPLETE_0_VISIT = 'Completed'
AND SurveyDate BETWEEN @StartDate AND @EndDate
AND ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Team)))


---------------NEW CLIENTS POPULATION ----------------- (CTE)
, New_Clients AS
(SELECT 
	EAD.CLID
	,EAD.ProgramID
	,C.DEMO_CLIENT_INTAKE_0_RACE
	,C.DEMO_CLIENT_INTAKE_0_ETHNICITY
	,DATEDIFF(YEAR,C.DOB,EAD.ProgramStartDate) AgeAtEnroll
FROM EnrollmentAndDismissal EAD
JOIN Clients C
	ON EAD.CLID = C.Client_Id
WHERE EAD.ProgramStartDate BETWEEN @StartDate AND @EndDate
AND ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Team)))

---------------NEW CLIENTS Data ----------------- (CTE)
, New_Clients_data AS
(SELECT 
	C.CLID
	,C.ProgramID
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
FROM New_Clients C
LEFT JOIN 
	(SELECT 
		CL_EN_GEN_ID
		,ProgramID
		,CASE WHEN client_Marital_0_Status = 'Married (legal or common law)' THEN 1 END Married
	FROM Demographics_Survey
	WHERE dbo.fnGetFormName(SurveyID) LIKE 'Demographics: Pregnancy Intake') DS_married
	ON C.CLID = DS_married.CL_EN_GEN_ID
	AND C.ProgramID = DS_married.ProgramID
LEFT JOIN
	(SELECT 
		CL_EN_GEN_ID
		,ProgramID
		,SUM(CASE WHEN SERVICE_USE_0_MEDICAID_CLIENT in (2,5) THEN 1 ELSE 0 END) Medicaid
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
)

------ QUERY 1

SELECT *
FROM New_Clients_data
GO
