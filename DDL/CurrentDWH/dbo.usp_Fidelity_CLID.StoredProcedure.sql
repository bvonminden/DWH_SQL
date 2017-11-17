USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fidelity_CLID]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_Fidelity_CLID]
AS



IF OBJECT_ID('dbo.UC_Fidelity_CLID', 'U') IS NOT NULL DROP TABLE dbo.UC_Fidelity_CLID;


  
WITH MHV AS
(SELECT
	M.CL_EN_GEN_ID
	,M.SiteID
	,M.ProgramID
	,M.AuditDate
	,M.SurveyDate
	,(M.CLIENT_HEALTH_PREGNANCY_0_EDD) EDD
	,(M.SurveyDate) FirstVisit
	,RANK () OVER(PARTITION BY M.CL_EN_GEN_ID,M.ProgramID ORDER BY M.SurveyDate DESC,M.SurveyResponseID) Ranking
FROM Maternal_Health_Survey M)


SELECT 
	ROOT.CLID
	,ROOT.CaseNumber
	,ROOT.ProgramID
	,ROOT.ProgramStartDate
	,ROOT.EndDate
	,ROOT.ReasonForDismissal
	,VolPart_Yes.SurveyDate VolPart_yes
	,VolPart_data.SurveyDate VolPart_data
	,VolPart_missing.SurveyDate VolPart_missing
	,FirstTimeMthr_Yes.SurveyDate FirstTimeMthr_Yes
	,FirstTimeMthr_data.SurveyDate FirstTimeMthr_data
	,FirstTimeMthr_missing.SurveyDate FirstTimeMthr_missing
	,LowIncCriteria_Yes.SurveyDate LowIncCriteria_Yes
	,LowIncCriteria_data.SurveyDate LowIncCriteria_data
	,LowIncCriteria_missing.SurveyDate LowIncCriteria_missing
	,GestAge.GestAgeIntake
	,GestAge.FirstVisit
	,CASE WHEN GestAge.CLID IS NOT NULL THEN 1 END GestAge_data
	,GestAge.EDD GestAge_EDD
	,IBS.INFANT_BIRTH_0_DOB DOB
	,DATEADD(YEAR,1,IBS.INFANT_BIRTH_0_DOB) BD1
	,DATEADD(YEAR,2,IBS.INFANT_BIRTH_0_DOB) BD2
	,SmokingIntakeData.SurveyDate SmokingIntakeData
	,SmokingIntakeMissing.SurveyDate SmokingIntakeMissing
	,SmokingIntake.SurveyDate SmokingIntake
	,SmokingPreg36Data.SurveyDate SmokingPreg36Data
	,SmokingPreg36Missing.SurveyDate SmokingPreg36Missing
	,SmokingPreg36.SurveyDate SmokingPreg36
	,CASE WHEN RE.Ethnicity = 'Hispanic or Latina' THEN 1
		 WHEN RE.Ethnicity = 'Not Hispanic or Latina' THEN 2
		 WHEN RE.Ethnicity = 'Declined to self-identify' THEN 3
		 WHEN RE.Ethnicity IS NULL THEN 4 END Ethnicity
	,CASE WHEN RE.Race = 'American Indian or Alaska Native' THEN 1
		 WHEN RE.Race = 'Asian' THEN 2
		 WHEN RE.Race IN('Asian;Native Hawaiian or other Pacific Islander','Native Hawaiian or other Pacific Islander;Asian') THEN 9
		 WHEN RE.Race = 'Black or African American' THEN 3
		 WHEN RE.Race = 'Native Hawaiian or other Pacific Islander' THEN 4
		 WHEN RE.Race = 'White' THEN 5
		 WHEN RE.Race = 'Declined to self-identify' THEN 6
		 WHEN RE.Race LIKE '%;%' AND RE.Race NOT IN('Asian;Native Hawaiian or other Pacific Islander','Native Hawaiian or other Pacific Islander;Asian') THEN 7
		 WHEN RE.Race IS NULL THEN 8 END Race
	,SmokingIntakeForm.SurveyDate SmokingIntakeForm
	,SmokingPreg36Form.SurveyDate SmokingPreg36Form
	,O2.GestAge
	,O2.SurveyDate O2SurveyDate
	,O2.ClientDelvAge
	,O2.Grams
	,O2.DOB O2DOB
	,O2.BreastMilk
	,Outcome6.Immuniz6_Yes
	,Outcome6.Immuniz6_Data
	,Outcome6.Immuniz6_Missing
	,Outcome6.Immuniz12_Yes
	,Outcome6.Immuniz12_Data
	,Outcome6.Immuniz12_Missing
	,Outcome6.Immuniz18_Yes
	,Outcome6.Immuniz18_Data
	,Outcome6.Immuniz18_Missing
	,Outcome6.Immuniz24_Yes
	,Outcome6.Immuniz24_Data
	,Outcome6.Immuniz24_Missing
	,OutCome7.Preg6_Yes
	,OutCome7.Preg6_Data
	,OutCome7.Preg6_Missing
	,OutCome7.Preg12_Yes
	,OutCome7.Preg12_Data
	,OutCome7.Preg12_Missing
	,OutCome7.Preg18_Yes
	,OutCome7.Preg18_Data
	,OutCome7.Preg18_Missing
	,OutCome7.Preg24_Yes
	,OutCome7.Preg24_Data
	,OutCome7.Preg24_Missing
	,OutCome8.WorkIn_Yes
	,OutCome8.WorkIn_Data
	,OutCome8.WorkIn_Missing
	,OutCome8.Work6_Yes
	,OutCome8.Work6_Data
	,OutCome8.Work6_Missing
	,OutCome8.Work12_Yes
	,OutCome8.Work12_Data
	,OutCome8.Work12_Missing
	,OutCome8.Work18_Yes
	,OutCome8.Work18_Data
	,OutCome8.Work18_Missing
	,OutCome8.Work24_Yes
	,OutCome8.Work24_Data
	,OutCome8.Work24_Missing
	,OutCome10.Breast6_Yes
	,OutCome10.Breast6_Data
	,OutCome10.Breast6_Missing
	,OutCome10.Breast12_Yes
	,OutCome10.Breast12_Data
	,OutCome10.Breast12_Missing
	,OutCome11_ASQ3.ChildWData_4
	,OutCome11_ASQ3.ChildScreened_4
	,OutCome11_ASQ3.ChildReff_4
	,OutCome11_ASQ3.ChildWData_10
	,OutCome11_ASQ3.ChildScreened_10
	,OutCome11_ASQ3.ChildReff_10
	,OutCome11_ASQ3.ChildWData_14
	,OutCome11_ASQ3.ChildScreened_14
	,OutCome11_ASQ3.ChildReff_14
	,OutCome11_ASQ3.ChildWData_20
	,OutCome11_ASQ3.ChildScreened_20
	,OutCome11_ASQ3.ChildReff_20
	,OutCome11_ASQ3.ChildWData_18
	,OutCome11_ASQ3.ChildScreened_18
	,OutCome11_ASQ3.ChildReff_18
	,OutCome11_ASQ3.ChildWData_24
	,OutCome11_ASQ3.ChildScreened_24
	,OutCome11_ASQ3.ChildReff_24
	,OutCome11_ASQ3.ASQVersion4
	,OutCome11_ASQ3.ASQVersion10
	,OutCome11_ASQ3.ASQVersion14
	,OutCome11_ASQ3.ASQVersion20
	,OutCome11_ASQ3.ASQVersion18
	,OutCome11_ASQ3.ASQVersion24
	,OutCome11.SETotalWData_6
	,OutCome11.SETotalWOData_6
	,OutCome11.SETotalScreenedCount_6
	,OutCome11.SETotalRefCount_6
	,OutCome11.SETotalNotEligibleCount_6
	,OutCome11.SETotalDeclinedCount_6
	,OutCome11.SETotalWData_12
	,OutCome11.SETotalWOData_12
	,OutCome11.SETotalScreenedCount_12
	,OutCome11.SETotalRefCount_12
	,OutCome11.SETotalNotEligibleCount_12
	,OutCome11.SETotalDeclinedCount_12
	,OutCome11.SETotalWData_18
	,OutCome11.SETotalWOData_18
	,OutCome11.SETotalScreenedCount_18
	,OutCome11.SETotalRefCount_18
	,OutCome11.SETotalNotEligibleCount_18
	,OutCome11.SETotalDeclinedCount_18
	,OutCome11.SETotalWData_24
	,OutCome11.SETotalWOData_24
	,OutCome11.SETotalScreenedCount_24
	,OutCome11.SETotalRefCount_24
	,OutCome11.SETotalNotEligibleCount_24
	,OutCome11.SETotalDeclinedCount_24

	,RE.ClientDOB
	,DATEDIFF(DAY,RE.ClientDOB,ROOT.ProgramStartDate)/365.25 [ClientAgeIntake]
	,RANK() OVER(PARTITION BY ROOT.CLID, ROOT.ProgramID ORDER BY ISNULL(ROOT.EndDate,DATEADD(DAY,1,GETDATE())) DESC,ROOT.RecID DESC) RankingLatest
	,RANK() OVER(PARTITION BY ROOT.CLID, ROOT.ProgramID ORDER BY ISNULL(ROOT.EndDate,DATEADD(DAY,1,GETDATE())) DESC,ROOT.RecID) RankingOriginal
	,RANK() OVER(PARTITION BY ROOT.CLID ORDER BY ISNULL(ROOT.EndDate,DATEADD(DAY,1,GETDATE())) DESC,ROOT.RecID DESC) LastEnrollment
	,CASE WHEN TS.CL_EN_GEN_ID IS NOT NULL THEN 1 ELSE 0 END Tribal
	,CASE WHEN TS.CLIENT_TRIBAL_0_PARITY = 'Primiparous (pregnant with her first child)' THEN 1
		  WHEN TS.CLIENT_TRIBAL_0_PARITY = 'Multiparous (pregnant with a second or subsequent child)' THEN 2 END Tribal_PM


INTO UC_Fidelity_CLID
FROM 

(SELECT 
	EAD.CLID
	,EAD.ProgramID 
	,EAD.SiteID
	,EAD.ProgramStartDate
	,EAD.EndDate
	,EAD.ReasonForDismissal
	,EAD.RecID
	,EAD.CaseNumber
FROM UV_EADT EAD)ROOT

LEFT JOIN Tribal_Survey TS
	ON ROOT.CLID = TS.CL_EN_GEN_ID
	AND ROOT.ProgramID = TS.ProgramID

LEFT JOIN ---- E1 VolPart_Yes ----
	(SELECT 
		DS.CL_EN_GEN_ID
		,DS.ProgramID
		,DS.SurveyDate SurveyDate
		,CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED 
		,RANK() OVER(PARTITION BY DS.CL_EN_GEN_ID,DS.ProgramID ORDER BY DS.SurveyResponseID DESC, DS.SurveyID DESC) Rank
	FROM Demographics_Survey DS
	WHERE dbo.fnGetFormName(DS.SurveyID) = 'Demographics: Pregnancy Intake') VolPart_Yes
	ON ROOT.ProgramID = VolPart_Yes.ProgramID
	AND ROOT.CLID = VolPart_Yes.CL_EN_GEN_ID
	AND VolPart_Yes.CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED = 'Yes'
	AND VolPart_Yes.Rank = 1
	
LEFT JOIN ---- E1 VolPart_data ----
	(SELECT 
		DS.CL_EN_GEN_ID
		,DS.ProgramID
		,DS.SurveyDate SurveyDate
		,CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED
		,RANK() OVER(PARTITION BY DS.CL_EN_GEN_ID,DS.ProgramID ORDER BY DS.SurveyResponseID DESC, DS.SurveyID DESC) Rank
	FROM Demographics_Survey DS
	WHERE dbo.fnGetFormName(DS.SurveyID) = 'Demographics: Pregnancy Intake') VolPart_data
	ON ROOT.ProgramID = VolPart_data.ProgramID
	AND ROOT.CLID = VolPart_data.CL_EN_GEN_ID
	AND VolPart_data.CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED IS NOT NULL
	AND VolPart_data.Rank = 1
	
LEFT JOIN ---- E1 VolPart_missing ----
	(SELECT 
		DS.CL_EN_GEN_ID
		,DS.ProgramID
		,DS.SurveyDate SurveyDate
		,CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED
		,RANK() OVER(PARTITION BY DS.CL_EN_GEN_ID,DS.ProgramID ORDER BY DS.SurveyResponseID DESC, DS.SurveyID DESC) Rank
	FROM Demographics_Survey DS
	WHERE dbo.fnGetFormName(DS.SurveyID) = 'Demographics: Pregnancy Intake') VolPart_missing
	ON ROOT.ProgramID = VolPart_missing.ProgramID
	AND ROOT.CLID = VolPart_missing.CL_EN_GEN_ID
	AND VolPart_missing.CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED IS NULL
	AND VolPart_missing.Rank = 1
	
LEFT JOIN ---- E2 FirstTimeMthr_Yes ----
	(SELECT 
		MHS.CL_EN_GEN_ID
		,MHS.ProgramID
		,(MHS.SurveyDate) SurveyDate
		,CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS
		,RANK() OVER(PARTITION BY MHS.CL_EN_GEN_ID,MHS.ProgramID ORDER BY MHS.SurveyResponseID DESC, MHS.SurveyID DESC) Rank
	FROM Maternal_Health_Survey MHS) FirstTimeMthr_Yes
	ON ROOT.ProgramID = FirstTimeMthr_Yes.ProgramID
	AND ROOT.CLID = FirstTimeMthr_Yes.CL_EN_GEN_ID
	AND FirstTimeMthr_Yes.Rank = 1
	AND FirstTimeMthr_Yes.CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS =0
	
LEFT JOIN ---- E2 FirstTimeMthr_Yes ----
	(SELECT 
		MHS.CL_EN_GEN_ID
		,MHS.ProgramID
		,(MHS.SurveyDate) SurveyDate
		,MHS.CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS 
		,RANK() OVER(PARTITION BY MHS.CL_EN_GEN_ID,MHS.ProgramID ORDER BY MHS.SurveyResponseID DESC, MHS.SurveyID DESC) Rank
	FROM Maternal_Health_Survey MHS) FirstTimeMthr_data
	ON ROOT.ProgramID = FirstTimeMthr_data.ProgramID
	AND ROOT.CLID = FirstTimeMthr_data.CL_EN_GEN_ID
	AND FirstTimeMthr_data.Rank = 1
	AND FirstTimeMthr_data.CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS IS NOT NULL
	
LEFT JOIN ---- E2 FirstTimeMthr_Yes ----
	(SELECT 
		MHS.CL_EN_GEN_ID
		,MHS.ProgramID
		,(MHS.SurveyDate) SurveyDate
		,MHS.CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS
		,RANK() OVER(PARTITION BY MHS.CL_EN_GEN_ID,MHS.ProgramID ORDER BY MHS.SurveyResponseID DESC, MHS.SurveyID DESC) Rank
	FROM Maternal_Health_Survey MHS) FirstTimeMthr_missing
	ON ROOT.ProgramID = FirstTimeMthr_missing.ProgramID
	AND ROOT.CLID = FirstTimeMthr_missing.CL_EN_GEN_ID
	AND FirstTimeMthr_missing.CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS IS NULL
	AND FirstTimeMthr_missing.Rank = 1
	
LEFT JOIN ---- E3 LowIncCriteria_Yes ----
	(SELECT 
		DS.CL_EN_GEN_ID
		,DS.ProgramID
		,DS.SurveyDate SurveyDate
		,DS.CLIENT_INCOME_1_LOW_INCOME_QUALIFY 
		,RANK() OVER(PARTITION BY DS.CL_EN_GEN_ID,DS.ProgramID ORDER BY DS.SurveyResponseID DESC, DS.SurveyID DESC) Rank
	FROM Demographics_Survey DS
	WHERE dbo.fnGetFormName(DS.SurveyID) = 'Demographics: Pregnancy Intake') LowIncCriteria_Yes
	ON ROOT.ProgramID = LowIncCriteria_Yes.ProgramID
	AND ROOT.CLID = LowIncCriteria_Yes.CL_EN_GEN_ID
	AND LowIncCriteria_Yes.CLIENT_INCOME_1_LOW_INCOME_QUALIFY = 'Yes'
	AND LowIncCriteria_Yes.Rank = 1
	
LEFT JOIN ---- E3 LowIncCriteria_data ----
	(SELECT 
		DS.CL_EN_GEN_ID
		,DS.ProgramID
		,DS.SurveyDate SurveyDate
		,DS.CLIENT_INCOME_1_LOW_INCOME_QUALIFY
		,RANK() OVER(PARTITION BY DS.CL_EN_GEN_ID,DS.ProgramID ORDER BY DS.SurveyResponseID DESC, DS.SurveyID DESC) Rank
	FROM Demographics_Survey DS
	WHERE dbo.fnGetFormName(DS.SurveyID) = 'Demographics: Pregnancy Intake') LowIncCriteria_data
	ON ROOT.ProgramID = LowIncCriteria_data.ProgramID
	AND ROOT.CLID = LowIncCriteria_data.CL_EN_GEN_ID
	AND LowIncCriteria_data.CLIENT_INCOME_1_LOW_INCOME_QUALIFY IS NOT NULL
	AND LowIncCriteria_data.Rank = 1
	
LEFT JOIN ---- E3 LowIncCriteria_missing ----
	(SELECT 
		DS.CL_EN_GEN_ID
		,DS.ProgramID
		,DS.SurveyDate SurveyDate
		,DS.CLIENT_INCOME_1_LOW_INCOME_QUALIFY
		,RANK() OVER(PARTITION BY DS.CL_EN_GEN_ID,DS.ProgramID ORDER BY DS.SurveyResponseID DESC, DS.SurveyID DESC) Rank
	FROM Demographics_Survey DS
	WHERE dbo.fnGetFormName(DS.SurveyID) = 'Demographics: Pregnancy Intake') LowIncCriteria_missing
	ON ROOT.ProgramID = LowIncCriteria_missing.ProgramID
	AND ROOT.CLID = LowIncCriteria_missing.CL_EN_GEN_ID
	AND LowIncCriteria_missing.CLIENT_INCOME_1_LOW_INCOME_QUALIFY IS NULL
	AND LowIncCriteria_missing.Rank = 1

LEFT JOIN ---- E4 GestAge ----
	(SELECT 
		EAD.CLID
		,MHV.EDD
		,MIN(40 - CAST(DATEDIFF(DAY, EAD.ProgramStartDate, MHV.EDD) AS DECIMAL(18, 2))/7)  [GestAgeIntake] -- REMOVED CEILING AND FLOOR DUE TO NEEDING TO HAVE GEST AGE > 0 BUT NOT EQUAL TO 0 AND < 41 BUT NOT EQUAL TO 41
		,EAD.ProgramID
		,EAD.SiteID
		,MHV.FirstVisit
	FROM UV_EADT EAD
		INNER JOIN MHV
			ON MHV.CL_EN_GEN_ID = EAD.CLID
			AND MHV.ProgramID = EAD.ProgramID
			AND MHV.Ranking = 1
	GROUP BY EAD.CLID
		,MHV.EDD
		,EAD.ProgramID
		,EAD.SiteID
		,MHV.FirstVisit
			) GestAge
	ON ROOT.ProgramID = GestAge.ProgramID
	AND ROOT.CLID = GestAge.CLID


LEFT OUTER JOIN ---- E7 ----
	(SELECT 
		I.CL_EN_GEN_ID
		,I.ProgramID
		,(I.INFANT_BIRTH_0_DOB) INFANT_BIRTH_0_DOB
		,RANK() OVER(Partition By I.CL_EN_GEN_ID,I.ProgramID Order By I.SurveyDate DESC,I.SurveyResponseID DESC) Rank
	FROM Infant_Birth_Survey I
	WHERE I.INFANT_BIRTH_0_DOB IS NOT NULL) IBS
	ON ROOT.CLID = IBS.CL_EN_GEN_ID
	AND ROOT.ProgramID = IBS.ProgramID
	AND IBS.Rank = 1

	
LEFT OUTER JOIN ---- O1 SmokingIntakeData ----
	(SELECT
		HH.CL_EN_GEN_ID
		,HH.ProgramID
		,MIN(HH.SurveyDate) SurveyDate
	FROM Health_Habits_Survey HH
	WHERE dbo.fnGetFormName(HH.SurveyID) IN('Health Habits: Pregnancy-Intake')
	GROUP BY HH.CL_EN_GEN_ID,HH.ProgramID
	HAVING MAX(HH.CLIENT_SUBSTANCE_CIG_1_LAST_48) IS NOT NULL) SmokingIntakeData
	ON ROOT.ProgramID = SmokingIntakeData.ProgramID
	AND ROOT.CLID = SmokingIntakeData.CL_EN_GEN_ID


LEFT OUTER JOIN ---- O1 SmokingIntakeMissing ----
	(SELECT 
		HH.CL_EN_GEN_ID
		,HH.ProgramID
		,MIN(HH.SurveyDate) SurveyDate
	FROM Health_Habits_Survey HH
	WHERE dbo.fnGetFormName(HH.SurveyID) IN('Health Habits: Pregnancy-Intake')
	GROUP BY HH.CL_EN_GEN_ID,HH.ProgramID
	HAVING MAX(HH.CLIENT_SUBSTANCE_CIG_1_LAST_48) IS NULL) SmokingIntakeMissing
	ON ROOT.ProgramID = SmokingIntakeMissing.ProgramID
	AND ROOT.CLID = SmokingIntakeMissing.CL_EN_GEN_ID
	
	
LEFT OUTER JOIN ---- O1 SmokingIntake ----
	(SELECT 
		HH.CL_EN_GEN_ID
		,HH.ProgramID
		,MIN(HH.SurveyDate) SurveyDate
	FROM Health_Habits_Survey HH
	WHERE dbo.fnGetFormName(HH.SurveyID) IN('Health Habits: Pregnancy-Intake')
	GROUP BY HH.CL_EN_GEN_ID,HH.ProgramID
	HAVING MAX(HH.CLIENT_SUBSTANCE_CIG_1_LAST_48) >0) SmokingIntake
	ON ROOT.ProgramID = SmokingIntake.ProgramID
	AND ROOT.CLID = SmokingIntake.CL_EN_GEN_ID
	
	
LEFT OUTER JOIN ---- O1 SmokingPreg36Data ----
	(SELECT
		HH.CL_EN_GEN_ID
		,HH.ProgramID
		,MIN(HH.SurveyDate) SurveyDate
	FROM Health_Habits_Survey HH
	WHERE dbo.fnGetFormName(HH.SurveyID) IN('Health Habits: Pregnancy-36 Weeks')
	GROUP BY HH.CL_EN_GEN_ID,HH.ProgramID
	HAVING MAX(HH.CLIENT_SUBSTANCE_CIG_1_LAST_48) IS NOT NULL) SmokingPreg36Data
	ON ROOT.ProgramID = SmokingPreg36Data.ProgramID
	AND ROOT.CLID = SmokingPreg36Data.CL_EN_GEN_ID


LEFT OUTER JOIN ---- O1 SmokingPreg36Missing ----
	(SELECT 
		HH.CL_EN_GEN_ID
		,HH.ProgramID
		,MIN(HH.SurveyDate) SurveyDate
	FROM Health_Habits_Survey HH
	WHERE dbo.fnGetFormName(HH.SurveyID) IN('Health Habits: Pregnancy-36 Weeks')
	GROUP BY HH.CL_EN_GEN_ID,HH.ProgramID
	HAVING MAX(HH.CLIENT_SUBSTANCE_CIG_1_LAST_48) IS NULL) SmokingPreg36Missing
	ON ROOT.ProgramID = SmokingPreg36Missing.ProgramID
	AND ROOT.CLID = SmokingPreg36Missing.CL_EN_GEN_ID
	
	
LEFT OUTER JOIN ---- O1 SmokingPreg36 ----
	(SELECT 
		HH.CL_EN_GEN_ID
		,HH.ProgramID
		,MIN(HH.SurveyDate) SurveyDate
	FROM Health_Habits_Survey HH
	WHERE dbo.fnGetFormName(HH.SurveyID) IN('Health Habits: Pregnancy-36 Weeks')
	GROUP BY HH.CL_EN_GEN_ID,HH.ProgramID
	HAVING MAX(HH.CLIENT_SUBSTANCE_CIG_1_LAST_48) > 0) SmokingPreg36
	ON ROOT.ProgramID = SmokingPreg36.ProgramID
	AND ROOT.CLID = SmokingPreg36.CL_EN_GEN_ID

LEFT OUTER JOIN ---- O1 SmokingIntakeForm ----
	(SELECT 
		HH.CL_EN_GEN_ID
		,HH.ProgramID
		,MIN(HH.SurveyDate) SurveyDate
	FROM Health_Habits_Survey HH
	WHERE dbo.fnGetFormName(HH.SurveyID) IN('Health Habits: Pregnancy-Intake')
	GROUP BY HH.CL_EN_GEN_ID,HH.ProgramID) SmokingIntakeForm
	ON ROOT.ProgramID = SmokingIntakeForm.ProgramID
	AND ROOT.CLID = SmokingIntakeForm.CL_EN_GEN_ID

LEFT OUTER JOIN ---- O1 SmokingPreg36Form ----
	(SELECT 
		HH.CL_EN_GEN_ID
		,HH.ProgramID
		,MIN(HH.SurveyDate) SurveyDate
	FROM Health_Habits_Survey HH
	WHERE dbo.fnGetFormName(HH.SurveyID) IN('Health Habits: Pregnancy-36 Weeks')
	GROUP BY HH.CL_EN_GEN_ID,HH.ProgramID) SmokingPreg36Form
	ON ROOT.ProgramID = SmokingPreg36Form.ProgramID
	AND ROOT.CLID = SmokingPreg36Form.CL_EN_GEN_ID

LEFT OUTER JOIN ---- O2 ----
	(SELECT
		C.Client_Id CLID
		,IBS.ProgramID
		,IBS.INFANT_BIRTH_1_GEST_AGE GestAge
		,IBS.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS Grams
		,IBS.INFANT_BREASTMILK_0_EVER_BIRTH BreastMilk
		,IBS.INFANT_BIRTH_0_DOB DOB
		,IBS.SurveyDate SurveyDate
		,DATEDIFF(DAY,C.DOB,IBS.INFANT_BIRTH_0_DOB)/365.25 ClientDelvAge
		
	FROM Clients C
	INNER JOIN 
		(SELECT BS.INFANT_BIRTH_0_DOB,BS.INFANT_BIRTH_1_GEST_AGE,BS.CL_EN_GEN_ID,BS.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS,BS.INFANT_BREASTMILK_0_EVER_BIRTH,BS.SurveyDate,BS.ProgramID
			,RANK() OVER(Partition By BS.CL_EN_GEN_ID,BS.ProgramID Order By BS.SurveyDate DESC,BS.SurveyResponseID DESC) Rank
		 FROM Infant_Birth_Survey BS	
		 WHERE BS.INFANT_BIRTH_0_DOB IS NOT NULL) IBS
		ON C.client_id =  IBS.CL_EN_GEN_ID
		AND IBS.Rank=1) O2
	ON ROOT.CLID = O2.CLID
	AND ROOT.ProgramID = O2.ProgramID
	
LEFT OUTER JOIN ---- Race Ethnicity ClientDOB----
	(SELECT
		C.Client_Id CLID
		,C.DEMO_CLIENT_INTAKE_0_ETHNICITY Ethnicity
		,C.DEMO_CLIENT_INTAKE_0_RACE Race
		,C.DOB [ClientDOB]
	FROM Clients C) RE
	ON ROOT.CLID = RE.CLID


LEFT JOIN ---- O6 Immuniz6_Yes ----
	(SELECT 
		IHS.CL_EN_GEN_ID
		,IHS.ProgramID
		,MAX(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months' 
				AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE = 'Yes'
			  THEN IHS.SurveyDate END) Immuniz6_Yes
		,MAX(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months' 
				AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NOT NULL
			  THEN IHS.SurveyDate END) Immuniz6_Data
		,MAX(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months' 
				AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NULL
			  THEN IHS.SurveyDate END) Immuniz6_Missing
		,MAX(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months' 
				AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE = 'Yes'
			  THEN IHS.SurveyDate END) Immuniz12_Yes
		,MAX(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months' 
				AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NOT NULL
			  THEN IHS.SurveyDate END) Immuniz12_Data
		,MAX(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months' 
				AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NULL
			  THEN IHS.SurveyDate END) Immuniz12_Missing
		,MAX(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months' 
				AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE = 'Yes'
			  THEN IHS.SurveyDate END) Immuniz18_Yes
		,MAX(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months' 
				AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NOT NULL
			  THEN IHS.SurveyDate END) Immuniz18_Data
		,MAX(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months' 
				AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NULL
			  THEN IHS.SurveyDate END) Immuniz18_Missing
		,MAX(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months' 
				AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE = 'Yes'
			  THEN IHS.SurveyDate END) Immuniz24_Yes
		,MAX(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months' 
				AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NOT NULL
			  THEN IHS.SurveyDate END) Immuniz24_Data
		,MAX(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months' 
				AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NULL
			  THEN IHS.SurveyDate END) Immuniz24_Missing
	FROM Infant_Health_Survey IHS
	GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID) OutCome6
	ON ROOT.ProgramID = OutCome6.ProgramID
	AND ROOT.CLID = OutCome6.CL_EN_GEN_ID

LEFT JOIN ---- O7 Preg6_Yes ----
	(SELECT 
		DS.CL_EN_GEN_ID
		,DS.ProgramID
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 6 Months' 
				AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes'
			  THEN DS.SurveyDate END) Preg6_Yes
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 6 Months' 
				AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NOT NULL
			  THEN DS.SurveyDate END) Preg6_Data
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 6 Months' 
				AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NULL
			  THEN DS.SurveyDate END) Preg6_Missing
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 12 Months' 
				AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes'
			  THEN DS.SurveyDate END) Preg12_Yes
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 12 Months' 
				AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NOT NULL
			  THEN DS.SurveyDate END) Preg12_Data
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 12 Months' 
				AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NULL
			  THEN DS.SurveyDate END) Preg12_Missing
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Toddler 18 Months' 
				AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes'
			  THEN DS.SurveyDate END) Preg18_Yes
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Toddler 18 Months' 
				AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NOT NULL
			  THEN DS.SurveyDate END) Preg18_Data
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Toddler 18 Months' 
				AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NULL
			  THEN DS.SurveyDate END) Preg18_Missing
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Toddler 24 Months' 
				AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes'
			  THEN DS.SurveyDate END) Preg24_Yes
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Toddler 24 Months' 
				AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NOT NULL
			  THEN DS.SurveyDate END) Preg24_Data
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Toddler 24 Months' 
				AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NULL
			  THEN DS.SurveyDate END) Preg24_Missing
	FROM Demographics_Survey DS
	GROUP BY DS.CL_EN_GEN_ID,DS.ProgramID) OutCome7
	ON ROOT.ProgramID = OutCome7.ProgramID
	AND ROOT.CLID = OutCome7.CL_EN_GEN_ID


LEFT JOIN ---- O8 Work6_UES ----
	(SELECT 
		DS.CL_EN_GEN_ID
		,DS.ProgramID
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics: Pregnancy Intake' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE 'Yes%'
			  THEN DS.SurveyDate END) WorkIn_Yes
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics: Pregnancy Intake' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING IS NOT NULL
			  THEN DS.SurveyDate END) WorkIn_Data
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics: Pregnancy Intake' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING IS NULL
			  THEN DS.SurveyDate END) WorkIn_Missing
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 6 Months' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE 'Yes%'
			  THEN DS.SurveyDate END) Work6_Yes
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 6 Months' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING IS NOT NULL
			  THEN DS.SurveyDate END) Work6_Data
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 6 Months' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING IS NULL
			  THEN DS.SurveyDate END) Work6_Missing
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 12 Months' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE 'Yes%'
			  THEN DS.SurveyDate END) Work12_Yes
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 12 Months' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING IS NOT NULL
			  THEN DS.SurveyDate END) Work12_Data
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 12 Months' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING IS NULL
			  THEN DS.SurveyDate END) Work12_Missing
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Toddler 18 Months' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE 'Yes%'
			  THEN DS.SurveyDate END) Work18_Yes
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Toddler 18 Months' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING IS NOT NULL
			  THEN DS.SurveyDate END) Work18_Data
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Toddler 18 Months' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING IS NULL
			  THEN DS.SurveyDate END) Work18_Missing
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Toddler 24 Months' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE 'Yes%'
			  THEN DS.SurveyDate END) Work24_Yes
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Toddler 24 Months' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING IS NOT NULL
			  THEN DS.SurveyDate END) Work24_Data
		,MIN(CASE WHEN dbo.fnGetFormName(DS.SurveyID) = 'Demographics Update: Toddler 24 Months' 
				AND DS.CLIENT_WORKING_0_CURRENTLY_WORKING IS NULL
			  THEN DS.SurveyDate END) Work24_Missing
	FROM Demographics_Survey DS
	GROUP BY DS.CL_EN_GEN_ID,DS.ProgramID) OutCome8
	ON ROOT.ProgramID = OutCome8.ProgramID
	AND ROOT.CLID = OutCome8.CL_EN_GEN_ID


LEFT JOIN ---- O10 Feeding breastmilk ----
	(SELECT 
		IHS.CL_EN_GEN_ID
		,IHS.ProgramID
		,MIN(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months' 
				AND IHS.INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
				AND IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
			  THEN IHS.SurveyDate END) Breast6_Yes
		,MIN(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months' 
				AND IHS.INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
				AND IHS.INFANT_BREASTMILK_1_CONT IS NOT NULL
			  THEN IHS.SurveyDate END) Breast6_Data
		,MIN(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months' 
				AND IHS.INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
				AND IHS.INFANT_BREASTMILK_1_CONT IS NULL
			  THEN IHS.SurveyDate END) Breast6_Missing
		,MIN(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months'
				AND IHS.INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
				AND IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
			  THEN IHS.SurveyDate END) Breast12_Yes
		,MIN(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months' 
				AND IHS.INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
				AND IHS.INFANT_BREASTMILK_1_CONT IS NOT NULL
			  THEN IHS.SurveyDate END) Breast12_Data
		,MIN(CASE WHEN dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months' 
				AND IHS.INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
				AND IHS.INFANT_BREASTMILK_1_CONT IS NULL
			  THEN IHS.SurveyDate END) Breast12_Missing
	FROM Infant_Health_Survey IHS
	GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID) OutCome10
	ON ROOT.ProgramID = OutCome10.ProgramID
	AND ROOT.CLID = OutCome10.CL_EN_GEN_ID
	
LEFT JOIN
	(	SELECT 
		IHS.CL_EN_GEN_ID
		,IHS.ProgramID
	--,MAX(
	--	CASE WHEN ((IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL))
	--			AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months' 
				
	--		 THEN IHS.SurveyDate END) ChildWData_6
	--,MAX(
	--	CASE WHEN ((IHS.INFANT_AGES_STAGES_1_COMM >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_GMOTOR >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_FMOTOR >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOLVE >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOCIAL >= 0))
	--			AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months'  
				
	--		 THEN IHS.SurveyDate END) ChildScreened_6
	--,MAX(
	--	CASE WHEN ((IHS.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND 34.59)
	--			OR (IHS.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND 38.40)
	--			OR (IHS.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND 29.61)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND 34.97)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND 33.15))
	--			AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months'  
				
	--		 THEN IHS.SurveyDate END) ChildReff_6
	--,MAX(
	--	CASE WHEN ((IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL))
	--			AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months' 
				
	--		 THEN IHS.SurveyDate END) ChildWData_12
	--,MAX(
	--	CASE WHEN ((IHS.INFANT_AGES_STAGES_1_COMM >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_GMOTOR >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_FMOTOR >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOLVE >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOCIAL >= 0))
	--			AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months'  
				
	--		 THEN IHS.SurveyDate END) ChildScreened_12
	--,MAX(
	--	CASE WHEN ((IHS.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND 22.86)
	--			OR (IHS.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND 30.06)
	--			OR (IHS.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND 37.96)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND 32.50)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND 27.24))
	--			AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months'  
				
	--		 THEN IHS.SurveyDate END) ChildReff_12
	--,MAX(
	--	CASE WHEN ((IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL))
	--			AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months' 
				
	--		 THEN IHS.SurveyDate END) ChildWData_18
	--,MAX(
	--	CASE WHEN ((IHS.INFANT_AGES_STAGES_1_COMM >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_GMOTOR >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_FMOTOR >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOLVE >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOCIAL >= 0))
	--			AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months'   
				
	--		 THEN IHS.SurveyDate END) ChildScreened_18
	--,MAX(
	--	CASE WHEN ((IHS.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND 17.39)
	--			OR (IHS.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND 25.79)
	--			OR (IHS.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND 23.05)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND 22.55)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND 23.17))
	--			AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months'  
				
	--		 THEN IHS.SurveyDate END) ChildReff_18
	--,MAX(
	--	CASE WHEN ((IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL OR IHS.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL))
	--			AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months'  
				
	--		 THEN IHS.SurveyDate END) ChildWData_24
	--,MAX(
	--	CASE WHEN ((IHS.INFANT_AGES_STAGES_1_COMM >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_GMOTOR >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_FMOTOR >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOLVE >= 0)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOCIAL >= 0))
	--			AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months' 
				
	--		 THEN IHS.SurveyDate END) ChildScreened_24
	--,MAX(
	--	CASE WHEN ((IHS.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND 20.49)
	--			OR (IHS.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND 39.88)
	--			OR (IHS.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND 36.04)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND 28.83)
	--			OR (IHS.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND 33.35))
	--			AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months' 
				
	--		 THEN IHS.SurveyDate END) ChildReff_24
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL >= 0 OR IHS.INFANT_HEALTH_NO_ASQ_TOTAL IS NOT NULL) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months'   THEN IHS.SurveyDate END) SETotalWData_6
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NULL AND IHS.INFANT_HEALTH_NO_ASQ_TOTAL IS NULL) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months'   THEN IHS.SurveyDate END)SETotalWOData_6
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL >= 0 ) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months'   THEN IHS.SurveyDate END)SETotalScreenedCount_6
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL >= 45) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months'   THEN IHS.SurveyDate END)SETotalRefCount_6
	,MAX( CASE WHEN (IHS.INFANT_HEALTH_NO_ASQ_TOTAL = 'Child not eligible for screening in this subscale at this time because child is receiving services') AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months'  THEN IHS.SurveyDate END)SETotalNotEligibleCount_6
	,MAX( CASE WHEN (IHS.INFANT_HEALTH_NO_ASQ_TOTAL = 'Parent declined further screening') AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months'   THEN IHS.SurveyDate END)SETotalDeclinedCount_6

	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL >= 0 OR IHS.INFANT_HEALTH_NO_ASQ_TOTAL IS NOT NULL) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months'   THEN IHS.SurveyDate END) SETotalWData_12
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NULL AND IHS.INFANT_HEALTH_NO_ASQ_TOTAL IS NULL) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months'   THEN IHS.SurveyDate END)SETotalWOData_12
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL >= 0 ) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months'   THEN IHS.SurveyDate END)SETotalScreenedCount_12
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL >= 48) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months'   THEN IHS.SurveyDate END)SETotalRefCount_12
	,MAX( CASE WHEN (IHS.INFANT_HEALTH_NO_ASQ_TOTAL = 'Child not eligible for screening in this subscale at this time because child is receiving services') AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months'  THEN IHS.SurveyDate END)SETotalNotEligibleCount_12
	,MAX( CASE WHEN (IHS.INFANT_HEALTH_NO_ASQ_TOTAL = 'Parent declined further screening') AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months'   THEN IHS.SurveyDate END)SETotalDeclinedCount_12

	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL >= 0 OR IHS.INFANT_HEALTH_NO_ASQ_TOTAL IS NOT NULL) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months'   THEN IHS.SurveyDate END) SETotalWData_18
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NULL AND IHS.INFANT_HEALTH_NO_ASQ_TOTAL IS NULL) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months'   THEN IHS.SurveyDate END)SETotalWOData_18
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL >= 0 ) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months'   THEN IHS.SurveyDate END)SETotalScreenedCount_18
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL >= 50) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months'   THEN IHS.SurveyDate END)SETotalRefCount_18
	,MAX( CASE WHEN (IHS.INFANT_HEALTH_NO_ASQ_TOTAL = 'Child not eligible for screening in this subscale at this time because child is receiving services') AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months'  THEN IHS.SurveyDate END)SETotalNotEligibleCount_18
	,MAX( CASE WHEN (IHS.INFANT_HEALTH_NO_ASQ_TOTAL = 'Parent declined further screening') AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months'   THEN IHS.SurveyDate END)SETotalDeclinedCount_18
	
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL >= 0 OR IHS.INFANT_HEALTH_NO_ASQ_TOTAL IS NOT NULL) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months'   THEN IHS.SurveyDate END) SETotalWData_24
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NULL AND IHS.INFANT_HEALTH_NO_ASQ_TOTAL IS NULL) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months'   THEN IHS.SurveyDate END)SETotalWOData_24
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL >= 0 ) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months'   THEN IHS.SurveyDate END)SETotalScreenedCount_24
	,MAX( CASE WHEN (IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL >= 50) AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months'   THEN IHS.SurveyDate END)SETotalRefCount_24
	,MAX( CASE WHEN (IHS.INFANT_HEALTH_NO_ASQ_TOTAL = 'Child not eligible for screening in this subscale at this time because child is receiving services') AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months'  THEN IHS.SurveyDate END)SETotalNotEligibleCount_24
	,MAX( CASE WHEN (IHS.INFANT_HEALTH_NO_ASQ_TOTAL = 'Parent declined further screening') AND dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months'   THEN IHS.SurveyDate END)SETotalDeclinedCount_24

	--,MAX(CASE 
	--		WHEN (dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months' AND ISNULL(IHS.INFANT_AGES_STAGES_0_VERSION,'4 months') = '4 months') THEN 1
	--	 END) ASQVersion6
	--,MAX(CASE 
	--		WHEN (dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months' AND ISNULL(IHS.INFANT_AGES_STAGES_0_VERSION,'10 months') = '10 months') THEN 1
	--	 END) ASQVersion12
	--,MAX(CASE 
	--		WHEN (dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months' AND ISNULL(IHS.INFANT_AGES_STAGES_0_VERSION,'14 months') = '14 months') THEN 1
	--	 END) ASQVersion18
	--,MAX(CASE 
	--		WHEN (dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months' AND ISNULL(IHS.INFANT_AGES_STAGES_0_VERSION,'20 months') = '20 months') THEN 1
	--	 END) ASQVersion24

	FROM Infant_Health_Survey IHS
	GROUP BY
		IHS.CL_EN_GEN_ID
		,IHS.ProgramID
	) OutCome11
	ON ROOT.ProgramID = OutCome11.ProgramID
	AND ROOT.CLID = OutCome11.CL_EN_GEN_ID

-- Outcome 11 ASQ3	
LEFT JOIN
	(	SELECT 
		ASQ.CL_EN_GEN_ID
		,ASQ.ProgramID
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Infancy 4 Months' 
				
			 THEN ASQ.SurveyDate END) ChildWData_4
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL >= 0))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Infancy 4 Months'  
				
			 THEN ASQ.SurveyDate END) ChildScreened_4
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND 34.59)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND 38.40)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND 29.61)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND 34.97)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND 33.15))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Infancy 4 Months'  
				
			 THEN ASQ.SurveyDate END) ChildReff_4
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Infancy 10 Months' 
				
			 THEN ASQ.SurveyDate END) ChildWData_10
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL >= 0))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Infancy 10 Months'  
				
			 THEN ASQ.SurveyDate END) ChildScreened_10
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND 22.86)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND 30.06)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND 37.96)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND 32.50)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND 27.24))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Infancy 10 Months'  
				
			 THEN ASQ.SurveyDate END) ChildReff_10
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 14 Months' 
				
			 THEN ASQ.SurveyDate END) ChildWData_14
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL >= 0))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 14 Months'   
				
			 THEN ASQ.SurveyDate END) ChildScreened_14
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND 17.39)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND 25.79)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND 23.05)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND 22.55)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND 23.17))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 14 Months'  
				
			 THEN ASQ.SurveyDate END) ChildReff_14
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 20 Months'  
				
			 THEN ASQ.SurveyDate END) ChildWData_20
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL >= 0))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 20 Months' 
				
			 THEN ASQ.SurveyDate END) ChildScreened_20
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND 20.49)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND 39.88)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND 36.04)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND 28.83)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND 33.35))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 20 Months' 
				
			 THEN ASQ.SurveyDate END) ChildReff_20
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 18 Months' 
				
			 THEN ASQ.SurveyDate END) ChildWData_18
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL >= 0))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 18 Months'   
				
			 THEN ASQ.SurveyDate END) ChildScreened_18
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND 13.06)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND 37.38)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND 34.32)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND 25.74)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND 27.19))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 18 Months'  
				
			 THEN ASQ.SurveyDate END) ChildReff_18
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 24 Months (optional)'  
				
			 THEN ASQ.SurveyDate END) ChildWData_24
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE >= 0)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL >= 0))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 24 Months (optional)' 
				
			 THEN ASQ.SurveyDate END) ChildScreened_24
	,MAX(
		CASE WHEN ((ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND 25.17)
				OR (ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND 38.07)
				OR (ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND 35.16)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND 29.78)
				OR (ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND 31.54))
				AND dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 24 Months (optional)' 

			 THEN ASQ.SurveyDate END) ChildReff_24	
	,MAX(CASE 
			WHEN (dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Infancy 4 Months') THEN 1
		 END) ASQVersion4
	,MAX(CASE 
			WHEN (dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Infancy 10 Months') THEN 1
		 END) ASQVersion10
	,MAX(CASE 
			WHEN (dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 14 Months') THEN 1
		 END) ASQVersion14
	,MAX(CASE 
			WHEN (dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 20 Months') THEN 1
		 END) ASQVersion20
	,MAX(CASE 
			WHEN (dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 18 Months') THEN 1
		 END) ASQVersion18
	,MAX(CASE 
			WHEN (dbo.fnGetFormName(ASQ.SurveyID) = 'ASQ-3: Toddler 24 Months (optional)') THEN 1
		 END) ASQVersion24
	FROM ASQ3_Survey ASQ
	GROUP BY
		ASQ.CL_EN_GEN_ID
		,ASQ.ProgramID
	) OutCome11_ASQ3
	ON ROOT.ProgramID = OutCome11_ASQ3.ProgramID
	AND ROOT.CLID = OutCome11_ASQ3.CL_EN_GEN_ID

--GO




GO
