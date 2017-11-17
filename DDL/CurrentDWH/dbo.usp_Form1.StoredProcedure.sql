USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Form1]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Form1]

@Start date
,@End date

AS

--Declare @Start date
--Declare @End date

--Set @Start = '2013-09-01'
--Set @End = '2014-05-31'


--------------------------------------------------------------------------------------------------
--Starting Population - Served
------------------------------

Select

	Distinct(CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
	, SiteID
	, ProgramID
	, CLIENT_COMPLETE_0_VISIT
	
Into #Population

From

	Home_Visit_Encounter_Survey

Where

	SurveyDate >= @Start and SurveyDate <= @End
	and CLIENT_COMPLETE_0_VISIT = 'Completed'
--------------------------------------------------------------------------------------------------
--EnrollmentAndDismissal
------------------------

Select
 
	Distinct(CLID) as 'CLID' 
	--, ProgramID
	
Into #EAD

From

	EnrollmentAndDismissal

Where

	EnrollmentAndDismissal.ProgramStartDate <= @End 
	AND (EnrollmentAndDismissal.EndDate is null or EnrollmentAndDismissal.EndDate >=@Start)

--------------------------------------------------------------------------------------------------
--Funding - MIECHV
------------------

Select

	Distinct(CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
	, Client_Funding_Survey.SiteID
	, Client_Funding_Survey.ProgramID
	, UV_PAS.ProgramName
	, UV_PAS.Abbreviation
	, SurveyDate
	, (case
		when CLIENT_FUNDING_0_SOURCE_MIECHVP_COM is not null then
		1
		else
		0
		end) as 'Competative'
	, (case
		when CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM is not null then
		1
		else
		0
		end) as 'Formula'
	, (case
		when CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL is not null then
		1
		else
		0
		end) as 'Tribal'
		
	, (case
		when CLIENT_FUNDING_0_SOURCE_MIECHVP_COM is not null
		and CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM is null
		and CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL is null
		then
		'Competative'
		when CLIENT_FUNDING_0_SOURCE_MIECHVP_COM is null
		and CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM is not null
		and CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL is null
		then	
		'Formula'
		when CLIENT_FUNDING_0_SOURCE_MIECHVP_COM is null
		and CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM is null
		and CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL is not null
		then	
		'Tribal'
		else
		'Unknown'
		end) as 'Funding'		
	
Into #FundingMIECHV

From

	Client_Funding_Survey
	inner join UV_PAS on UV_PAS.ProgramID = Client_Funding_Survey.ProgramID

--------------------------------------------------------------------------------------------------
--Newly Enrolled
----------------
Select

	Distinct(CLID) as 'CLID'
	,EnrollmentAndDismissal.SiteID
	,EnrollmentAndDismissal.ProgramID
	,ProgramStartDate
	,CaseNumber

Into #NewlyEnrolled

From

	EnrollmentAndDismissal
	inner join #FundingMIECHV on #FundingMIECHV.CL_EN_GEN_ID = EnrollmentAndDismissal.CLID
	and #FundingMIECHV.ProgramID = EnrollmentAndDismissal.ProgramID

where ProgramStartDate >= @Start and ProgramStartDate <= @End
and #FundingMIECHV.SurveyDate >= @Start and #FundingMIECHV.SurveyDate <= @End

--------------------------------------------------------------------------------------------------
--Index Childern Served
-----------------------

Select

	Distinct(CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
	, SiteID
	, ProgramID
	, datediff(yy,INFANT_BIRTH_0_DOB,@End) as 'ndxDoB'
	, INFANT_PERSONAL_0_GENDER

Into #IndexChildren

From

	Infant_Birth_Survey
	
Where

	INFANT_BIRTH_0_DOB <= @End
--------------------------------------------------------------------------------------------------
--Index Childern Newly Enrolled
-------------------------------

Select

	Distinct(Infant_Birth_Survey.CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
	, Infant_Birth_Survey.SiteID
	, Infant_Birth_Survey.ProgramID

Into #IndexChildrenNewlyEnrolled

From

	Infant_Birth_Survey
	inner join #FundingMIECHV on #FundingMIECHV.CL_EN_GEN_ID = Infant_Birth_Survey.CL_EN_GEN_ID
	and #FundingMIECHV.ProgramID = Infant_Birth_Survey.ProgramID
	
Where

	INFANT_BIRTH_0_DOB >= @Start and INFANT_BIRTH_0_DOB <= @End
	and #FundingMIECHV.SurveyDate >= @Start and #FundingMIECHV.SurveyDate <= @End
--------------------------------------------------------------------------------------------------
--Use of Government Services
----------------------------

Select

Distinct(CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
,SiteID
,ProgramID
,max(SurveyDate) as 'SurveyDate'
,(Case
when SERVICE_USE_0_MEDICAID_CLIENT in (2,5) then
1
else
0
end) as 'MedicaidClient'

, (Case
when SERVICE_USE_0_SCHIP_CLIENT in (2,5) then
1
else
0
end) as 'SchipClient'

, (Case
when SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT in (2,5) then
1
else
0
end) as 'PrivateClient'
, (Case
when SERVICE_USE_MILITARY_INS_CLIENT in (2,5) then
1
else
0
end) as 'TricareClient'

, (Case
when SERVICE_USE_0_MEDICAID_CHILD in (2,5) then
1
else
0
end) as 'MedicaidChild'
, (Case
when SERVICE_USE_0_SCHIP_CHILD in (2,5) then
1
else
0
end) as 'SchipChild'
, (Case
when SERVICE_USE_0_PRIVATE_INSURANCE_CHILD in (2,5) then
1
else
0
end) as 'PrivateChild'
, (Case
when SERVICE_USE_MILITARY_INS_CHILD in (2,5) then
1
else
0
end) as 'TricareChild'

, (Case
when SERVICE_USE_0_MEDICAID_CLIENT not in (2,5)
and SERVICE_USE_0_SCHIP_CLIENT not in (2,5)
and SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT not in (2,5)
and SERVICE_USE_MILITARY_INS_CLIENT  not in (2,5)
then
1
else
0
end) as 'NoIns'
, (Case
when SERVICE_USE_0_MEDICAID_CLIENT is null
and SERVICE_USE_0_SCHIP_CLIENT is null
and SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT is null
and SERVICE_USE_MILITARY_INS_CLIENT  is null
then
1
else
0
end) as 'Unknown'

, (Case
when SERVICE_USE_0_MEDICAID_CHILD not in (2,5)
and SERVICE_USE_0_SCHIP_CHILD not in (2,5)
and SERVICE_USE_0_PRIVATE_INSURANCE_CHILD not in (2,5)
and SERVICE_USE_MILITARY_INS_CHILD  not in (2,5)
then
1
else
0
end) as 'NoInsChild'
, (Case
when SERVICE_USE_0_MEDICAID_CHILD is null
and SERVICE_USE_0_SCHIP_CHILD is null
and SERVICE_USE_0_PRIVATE_INSURANCE_CHILD is null
and SERVICE_USE_MILITARY_INS_CHILD  is null
then
1
else
0
end) as 'UnknownChild'

Into #UseofGovernmentServices

From 

	Govt_Comm_Srvcs_Survey
	
Where

	SurveyDate >= @Start and SurveyDate <= @End

Group by

	CL_EN_GEN_ID
	, SiteID
	, ProgramID
	, SERVICE_USE_0_MEDICAID_CLIENT 
	, SERVICE_USE_0_SCHIP_CLIENT 
	, SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT
	, SERVICE_USE_MILITARY_INS_CLIENT
	, SERVICE_USE_0_MEDICAID_CHILD
	, SERVICE_USE_0_SCHIP_CHILD
	, SERVICE_USE_0_PRIVATE_INSURANCE_CHILD
	, SERVICE_USE_MILITARY_INS_CHILD
--------------------------------------------------------------------------------------------------
----******************************************************************************************************************
------------------------------------------------------------------------------------------------
--Clients - Race
----------------

Select

	distinct(Client_Id) as 'Client_Id'
	, Site_ID
	, DEMO_CLIENT_INTAKE_0_RACE
	, (Case
	when DEMO_CLIENT_INTAKE_0_RACE Like '%;%' then
	'MoreThenOne'
	else
	'Single'
	end) as 'Race'

	into #R

From
 
	Clients
	
---------------------------------------------------------------
--Clients --Race
-----------------

Select 

	distinct(Client_Id) as 'Client_Id'
	, Site_ID
	, (Case
	when Race Like 'MoreThenOne' then
	1
	else
	0
	end) as 'RMulti'

	, (Case
	when DEMO_CLIENT_INTAKE_0_RACE is null then
	1
	else
	0
	end) as 'RUnrecorded'

	, (Case
	when DEMO_CLIENT_INTAKE_0_RACE like 'Declined%' and Race = 'Single' then
	1
	else
	0
	end) as 'RDeclined'

	, (Case
	when DEMO_CLIENT_INTAKE_0_RACE = 'Asian' and Race = 'Single' then
	1
	else
	0
	end) as 'RAsian'

	, (Case
	when DEMO_CLIENT_INTAKE_0_RACE = 'White' and Race = 'Single' then
	1
	else
	0
	end) as 'RWhite'

	, (Case
	when DEMO_CLIENT_INTAKE_0_RACE = 'Other' and Race = 'Single' then
	1
	else
	0
	end) as 'ROther'

	, (Case
	when DEMO_CLIENT_INTAKE_0_RACE like '%Indian%' and Race = 'Single' then
	1
	else
	0
	end) as 'RIndian'

	, (Case
	when DEMO_CLIENT_INTAKE_0_RACE like '%Hawaiian%' and Race = 'Single' then
	1
	else
	0
	end) as 'RHawaiian'


	, (Case
	when DEMO_CLIENT_INTAKE_0_RACE like '%Black%' and Race = 'Single' then
	1
	else
	0
	end) as 'RBlack'

Into #ClientRace

From #R
------------------------------------------------------------------------
--drop table #R
--drop table #ClientRace
------------------------------------------------------------------------
Select

	distinct(Client_Id) as 'Client_Id'
	, Site_ID
	, DEMO_CLIENT_INTAKE_0_ETHNICITY
	
	, (Case
	When DEMO_CLIENT_INTAKE_0_ETHNICITY is null then
	1
	else
	0
	end) as 'EUnrecorded'
	
		, (Case
	When DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Other' then
	1
	else
	0
	end) as 'EOther'
	
		, (Case
	When DEMO_CLIENT_INTAKE_0_ETHNICITY = 'White' then
	1
	else
	0
	end) as 'EWhite'
	
		, (Case
	When DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Asian' then
	1
	else
	0
	end) as 'EAsian'
	
		, (Case
	When DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Unknown' then
	1
	else
	0
	end) as 'EUnknown'
	
		, (Case
	When DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Multiracial' then
	1
	else
	0
	end) as 'EMulti'
	
		, (Case
	When DEMO_CLIENT_INTAKE_0_ETHNICITY like 'Not%' then
	1
	else
	0
	end) as 'ENotH'
	
		, (Case
	When DEMO_CLIENT_INTAKE_0_ETHNICITY Like 'Hispanic%' then
	1
	else
	0
	end) as 'EHispanic'
	
		, (Case
	When DEMO_CLIENT_INTAKE_0_ETHNICITY Like '%Indian' then
	1
	else
	0
	end) as 'EIndian'
	
		, (Case
	When DEMO_CLIENT_INTAKE_0_ETHNICITY Like 'Declined%' then
	1
	else
	0
	end) as 'EDeclined'
	
	into #ClientEthnicity

From
 
	Clients
------------------------------------------------------------------------------	
--	drop table #ClientEthnicity

--------------------------------------------------------------------------------
Select

	distinct(Client_Id) as 'Client_Id'
	, Site_ID
	, (Case 
	when DEMO_CLIENT_INTAKE_0_LANGUAGE IS NULL then
	'Unknown'
	when DEMO_CLIENT_INTAKE_0_LANGUAGE like 'Othe%' then
	'Other'
	else
	DEMO_CLIENT_INTAKE_0_LANGUAGE
	end) as 'Lang'
	
into #ClientLanguage

From
 
	Clients
	
	--drop Table #ClientLanguage
	
-------------------------------------------------------------------------------------------
Select

	distinct(Client_Id) as 'Client_Id'
	, Clients.Site_ID
	, DOB
	, DATEDIFF(yy,DOB,@Start) as Age
	
	into #ClientAge
	
 From
 
	Clients
 
 WHERE
 
	DOB IS NOT NULL
 
------------------------------------------------------------- 
-- SELECT * FROM #ClientAge
-- DROP TABLE #ClientAge
 ------------------------------------------------------------
--drop table #ClientAge
--drop table #R
--drop table #ClientRace
--drop table #ClientEthnicity
--drop Table #ClientLanguage
----**************************************************************************************************************************
--------------------------------------------------------------------------------------------------
--Demographics
--------------

Select

	CL_EN_GEN_ID
	, SurveyName
	, SurveyDate
	, SiteID
	, ProgramID
	, CLIENT_MARITAL_0_STATUS
	, (case
		when CLIENT_MILITARY is not null then
		0
		when CLIENT_MILITARY like '%None%' then
		0
		else
		1
		end) as 'Military'
	
	, (CASE
		WHEN CLIENT_EDUCATION_1_ENROLLED_FTPT LIKE '%TIME%' OR CLIENT_SCHOOL_MIDDLE_HS <> 'NOT ENROLLED' THEN
		'Student/Trainee'
		WHEN CLIENT_EDUCATION_1_ENROLLED_CURRENT LIKE '%NO%' OR CLIENT_SCHOOL_MIDDLE_HS = 'NOT ENROLLED' THEN
		'Not a Student/Trainee'
		WHEN CLIENT_EDUCATION_1_ENROLLED_FTPT IS NULL AND CLIENT_SCHOOL_MIDDLE_HS IS NULL THEN
		'Unknown/Did Not Report'
		else
		'Unknown/Did Not Report'
		END) as 'EducationTrainingStatus'
	
	------------------------------------------------------------------------------------------------
	, (CASE
		WHEN CLIENT_SCHOOL_MIDDLE_HS = 'Yes – high school or GED program (includes alternative and technical programs)'
		OR (CLIENT_EDUCATION_0_HS_GED LIKE '%NO%' AND CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'YES') THEN
		'Currently enrolled in high school'
		--WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 4748.25 AND 6939.75
		--AND (CLIENT_EDUCATION_1_ENROLLED_CURRENT LIKE '%NO%' 
		--OR CLIENT_SCHOOL_MIDDLE_HS LIKE '%NOT%') THEN
		--'Of high school age, not enrolled'
		WHEN (CLIENT_EDUCATION_0_HS_GED LIKE '%NO%' AND (CLIENT_EDUCATION_1_ENROLLED_CURRENT LIKE '%NO%' 
		OR CLIENT_SCHOOL_MIDDLE_HS LIKE '%NOT%'))
		AND (CLIENT_SCHOOL_MIDDLE_HS <>'Yes – high school or GED program (includes alternative and technical programs)'
		OR CLIENT_SCHOOL_MIDDLE_HS LIKE '%MIDDLE%') THEN
		'Less than HS diploma'
		WHEN CLIENT_EDUCATION_0_HS_GED LIKE '%GED%' THEN
		'GED'
		WHEN CLIENT_EDUCATION_0_HS_GED LIKE '%HIGH%' THEN
		'HS diploma'
		WHEN CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%SOME COLLEGE%' THEN
		'Some college/training'
		WHEN CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%ASSOC%'
		OR CLIENT_EDUCATION_0_HS_GED LIKE '%VOCA%'
		OR CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%VOCA%' THEN
		'Technical Training Certification, Associate''s Degree'
		WHEN CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%BACH%'
		OR CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%MAST%'
		OR CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%DOCT%' THEN
		'Bachelor''s Degree, or higher'
		else
		'Unknown/Did Not Report'
		END) as 'EducationLevel'
---------------------------------------------------------------------------------------------------	
	
	, (Case 
		when CLIENT_INCOME_1_LOW_INCOME_QUALIFY = 'Yes' then
		1
		else
		0
		end) as 'Lowincome'
		
	, (CASE
		WHEN CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%FULL%' THEN
		'Employed Full-Time'
		WHEN CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%part%' THEN
		'Employed Part-Time'
		WHEN CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%no%' THEN
		'Not Employed'
		else
		'Unknown/Did Not Report'
		END) as 'EmploymentStatus'
		
	into #Demo

From
 
	Demographics_Survey
	inner join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID

	
Where

	SurveyDate >= @Start and SurveyDate <= @End
	and ((SurveyName like '%intake%') or (SurveyName like '%12%'))
	and CL_EN_GEN_ID is not null
-------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Smoking

DECLARE @Team VARCHAR(4000)

SET @Team = '854,857,1988,860,863,866,1943,869,971,974,977,983,980,986,989,992,995,998,1887,1001,1004,1007,1010,2010,1013,1576,1922,1925' -- CO


SELECT  --- note: didn't code out duplicate
       EAD.CLID
       ,EAD.ProgramID
       --,EAD.ProgramStartDate
       --,HHS.SurveyID -- if not null then they have smoking data
       --,CFS.SurveyID

into #Smoking      
 
FROM UV_EADT EAD
JOIN UV_PAS P
       ON EAD.ProgramID = P.ProgramID
LEFT JOIN DataWarehouse..Client_Funding_Survey CFS
       ON EAD.CLID = CFS.CL_EN_GEN_ID
       AND EAD.ProgramID = CFS.ProgramID
       AND (CFS.CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL OR CFS.CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL) ---Could add time frame requirements
LEFT JOIN Health_Habits_Survey HHS
       ON EAD.CLID = HHS.CL_EN_GEN_ID
       AND EAD.ProgramID = HHS.ProgramID
       AND dbo.fnGetFormName (HHS.SurveyID) = 'Health Habits: Pregnancy-Intake'
       AND (HHS.CLIENT_PERSONAL_0_DOB_INTAKE > 0 OR HHS.CLIENT_SUBSTANCE_CIG_0_DURING_PREG = 'YES')
WHERE EAD.ProgramStartDate BETWEEN @Start AND @End
AND CFS.SurveyID IS NOT NULL
AND P.ProgramID IN(SELECT * FROM dbo.udf_ParseMultiParam(@Team))

-------------------------------------------------------------------------------------------------------

--Select * from #Smoking
--order by CLID
---------------------------------------------------------------------------------------------
--Rentention
----------------------

SELECT 
      -- COUNT(*) served
		distinct(EAD.CLID)
		, EAD.ProgramID
       ,(CASE WHEN EAD.EndDate BETWEEN @Start AND @End AND EAD.ReasonForDismissal = 'Child reached 2nd birthday' THEN 1 END) completed
       ,(CASE WHEN EAD.EndDate BETWEEN @Start AND @End AND EAD.ReasonForDismissal != 'Child reached 2nd birthday' THEN 1 END) stopped

Into #Retention 

FROM UV_EADT EAD
JOIN UV_PAS P
       ON EAD.ProgramID = P.ProgramID
JOIN DataWarehouse..Client_Funding_Survey CFS
       ON EAD.CLID = CFS.CL_EN_GEN_ID
       AND EAD.ProgramID = CFS.ProgramID
       AND (CFS.CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL OR CFS.CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL) ---Could add time frame requirements
JOIN 
       (SELECT DISTINCT ProgramID,CL_EN_GEN_ID FROM UV_Fidelity_aHVES WHERE CLIENT_COMPLETE_0_VISIT = 'Completed' AND SurveyDate BETWEEN @Start AND @End) V
       ON EAD.CLID = V.CL_EN_GEN_ID
       AND EAD.ProgramID = V.ProgramID
WHERE P.ProgramID IN(SELECT * FROM dbo.udf_ParseMultiParam(@Team))

-----------------------------------------------------------------------------------------------





Select

	
	Distinct(#Population.CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
--	, #Population.ProgramID
--	, #Population.SiteID
	, #Population.CL_EN_GEN_ID as 'Served'
	, #NewlyEnrolled.CLID as 'NewlyEnrolled'
	
	, (Case
		when #IndexChildren.CL_EN_GEN_ID is not null then
			'PostPartum'
		else
			'Pregnant'
		end) as 'Mother'
		
	, (Case
		when #IndexChildren.CL_EN_GEN_ID is not null then
			1
		else
			0
		end) as 'PostPartum'

	, (Case
		when #IndexChildren.CL_EN_GEN_ID is not null then
			0
		else
			1
		end) as 'Pregnant'		
		
	, #UseofGovernmentServices.CL_EN_GEN_ID as 'INDXMom'	
	, #IndexChildren.CL_EN_GEN_ID as 'IndexChild'
	, (CAse
		when #IndexChildren.ndxDoB < 1 and #IndexChildren.INFANT_PERSONAL_0_GENDER = 'Female' then
		'Under 1 year'
		when #IndexChildren.ndxDoB >= 1 and #IndexChildren.ndxDoB <= 2 and #IndexChildren.INFANT_PERSONAL_0_GENDER = 'Female' then
		'1-2 years'
		when #IndexChildren.ndxDoB >= 2 and #IndexChildren.ndxDoB <= 3 and #IndexChildren.INFANT_PERSONAL_0_GENDER = 'Female' then
		'Over 2 years'
		end) as 'IndxChildDOBFemale'
		
		, (CAse
		when #IndexChildren.ndxDoB < 1 and #IndexChildren.INFANT_PERSONAL_0_GENDER = 'Male'then
		'Under 1 year'
		when #IndexChildren.ndxDoB >= 1 and #IndexChildren.ndxDoB <= 2 and #IndexChildren.INFANT_PERSONAL_0_GENDER = 'Male'then
		'1-2 years'
		when #IndexChildren.ndxDoB >= 2 and #IndexChildren.ndxDoB <= 3 and #IndexChildren.INFANT_PERSONAL_0_GENDER = 'Male'then
		'Over 2 years'
		end) as 'IndxChildDOBMale'	
		,  #IndexChildren.INFANT_PERSONAL_0_GENDER
	, (Case
	when #IndexChildren.INFANT_PERSONAL_0_GENDER = 'Male' then
	1
	else
	0
	end) as 'IndxMale'
	
	, (Case
	when #IndexChildren.INFANT_PERSONAL_0_GENDER = 'Female' then
	1
	else
	0
	end) 'IndxFemale'
	
	, #IndexChildrenNewlyEnrolled.CL_EN_GEN_ID as 'NewlyEnrolledChild'
	
	, MedicaidClient
	, SchipClient
	
	, (Case
	when MedicaidClient = 1 then
		1
	when SchipClient = 1 then
		1		
	else
		0
	end) as 'Medicaid/Schip Client'
	
	, PrivateClient
	, TricareClient
	, (Case
	when #UseofGovernmentServices.CL_EN_GEN_ID is null then
	1
	else
	0
	end) as 'Unknown Client'
    , (NoIns + Unknown) as 'No Insurnace Client'

	, MedicaidChild
	, SchipChild
	
		, (Case
	when MedicaidChild = 1 then
		1
	when SchipChild = 1 then
		1		
	else
		0
	end) as 'Medicaid/Schip Child'
	
	, PrivateChild
	, TricareChild
	
	, (Case
	when #UseofGovernmentServices.CL_EN_GEN_ID is null and #IndexChildren.CL_EN_GEN_ID is not null then
	1
	else
	0
	end) as 'Unknown Child'
	
		, (Case
	when #UseofGovernmentServices.CL_EN_GEN_ID is not null
	and #IndexChildren.CL_EN_GEN_ID is not null
	and NoInsChild = 1
	and UnknownChild = 1 then	
	1
	else
	0
	end) as 'No Insurnace Child'
	
	, RMulti
	, RUnrecorded
	, RDeclined
	, RAsian
	, RWhite
	, ROther
	, RIndian
	, RHawaiian
	, RBlack
	, EUnrecorded
	, EOther
	, EWhite
	, EAsian
	, EUnknown
	, EMulti
	, ENotH
	, EHispanic
	, EIndian
	, EDeclined
	, Lang
	, Age
	, (Case
	when Age >= 10 and Age <= 14 then
	'10-14'
	when Age >= 15 and Age <= 17 then
	'15-17'
	when Age >= 18 and Age <= 19 then
	'18-19'
	when Age >= 20 and Age <= 21 then
	'20-21'
	when Age >= 22 and Age <= 24 then
	'22-24'
	when Age >= 25 and Age <= 29 then
	'25-29'
	when Age >= 30 and Age <= 34 then
	'30-34'
	when Age >= 35 and Age <= 44 then
	'35-44'
	when Age >= 45 and Age <= 54 then
	'45-54'
	when Age >= 55 and Age <= 64 then
	'55-64'
	when Age >= 65 then
	'65+'
	when Age <= 10 then
	'Under 10'
	else
	'Unknown/Did Not Report'
	end) as AgeGroup
	, CLIENT_MARITAL_0_STATUS
	, Military
	, EducationTrainingStatus
	, EducationLevel
	, (Case
		when Lowincome = 1 and #NewlyEnrolled.CLID is not null then
		1
		else
		0
		end) as 'Lowincome'	
	, EmploymentStatus
	, (Case
		when Age < 21 and #IndexChildren.CL_EN_GEN_ID is not null
		and #NewlyEnrolled.CLID is not null then
		1
		else
		0
		end) as 'BirthUnder21'
	
	, 'X' as 'Popluation'
	
	, (Case
		when #Smoking.CLID is not null then
		1
		else
		0
		end) as 'Smoking'
		
	, (Case
		when #Retention.CLID is not null then
		1
		else
		0
		end) as 'RetentionServed'
		
		, (Case
		when #Retention.completed is not null then
		1
		else
		0
		end) as 'RetentionCompleted'
		
			, (Case
		when #Retention.stopped is not null then
		1
		else
		0
		end) as 'RetentionStopped'
		
	, Funding
	, CLIENT_COMPLETE_0_VISIT
	
	
From

	#Population
	
	Inner Join #FundingMIECHV on #FundingMIECHV.CL_EN_GEN_ID = #Population.CL_EN_GEN_ID
	and #FundingMIECHV.ProgramID = #Population.ProgramID
	
	Inner Join #EAD on #EAD.CLID = #Population.CL_EN_GEN_ID
	--and #EAD.ProgramID = #Population.ProgramID
	
	Left Join #NewlyEnrolled on #NewlyEnrolled.CLID = #Population.CL_EN_GEN_ID
	and #NewlyEnrolled.ProgramID = #Population.ProgramID
	Left Join #IndexChildren on #IndexChildren.CL_EN_GEN_ID = #Population.CL_EN_GEN_ID
	and #IndexChildren.ProgramID = #Population.ProgramID
	Left Join #IndexChildrenNewlyEnrolled on #IndexChildrenNewlyEnrolled.CL_EN_GEN_ID = #Population.CL_EN_GEN_ID
	and #IndexChildrenNewlyEnrolled.ProgramID = #Population.ProgramID
	Left Join #UseofGovernmentServices on #UseofGovernmentServices.CL_EN_GEN_ID = #Population.CL_EN_GEN_ID
	and #UseofGovernmentServices.ProgramID = #Population.ProgramID
	
	left Join #ClientAge on #ClientAge.Client_Id = #Population.CL_EN_GEN_ID
 	left Join #ClientRace on #ClientRace.Client_Id = #Population.CL_EN_GEN_ID
 	left Join #ClientEthnicity on #ClientEthnicity.Client_Id = #Population.CL_EN_GEN_ID
 	left Join #ClientLanguage on #ClientLanguage.Client_Id = #Population.CL_EN_GEN_ID
 	left Join #Demo on #Demo.CL_EN_GEN_ID = #Population.CL_EN_GEN_ID and #Demo.ProgramID = #Population.ProgramID
	left Join #Smoking on #Smoking.CLID = #Population.CL_EN_GEN_ID and #Smoking.ProgramID = #Population.ProgramID
	left Join #Retention on #Retention.CLID = #Population.CL_EN_GEN_ID and #Retention.ProgramID = #Population.ProgramID
	
	

Where

	Abbreviation = 'CO'
	and funding = 'Competative'

--Group by

--	#Population.CL_EN_GEN_ID

Order by

	#Population.CL_EN_GEN_ID

--------------------------------------------------------------------------------------------------
-- Clean up
-----------

Drop table #UseofGovernmentServices
Drop Table #IndexChildrenNewlyEnrolled
Drop Table #IndexChildren
Drop Table #FundingMIECHV
Drop Table #NewlyEnrolled
drop table #Demo
drop table #ClientAge
drop table #R
drop table #ClientRace
drop table #ClientEthnicity
drop Table #ClientLanguage
drop table #Smoking
drop table #Retention
drop table #EAD

Drop Table #Population
GO
