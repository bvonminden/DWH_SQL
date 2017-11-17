USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Entity_Profile]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Entity_Profile] 
@State varchar(10)
AS
BEGIN
--------------------------------------------------------------------------------

Declare @Start date
Declare @End date
--Declare @State varchar(10)

Set @Start = '2013-01-01'
Set @End = '2013-12-01'
--Set @State = 'CO'

--------------------------------------------------------------------------------
-- Served Cumulative
--------------------

--Home Visits
Select Distinct(CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
, uv_pas.Site
, uv_pas.ProgramName
, uv_pas.ProgramID
Into #c1
From Home_Visit_Encounter_Survey
inner join UV_PAS on UV_PAS.ProgramID = Home_Visit_Encounter_Survey.ProgramID
Where
CLIENT_PERSONAL_0_NAME_LAST not like '%Fake%'
and CLIENT_PERSONAL_0_NAME_FIRST not like '%Fake%'
and CLIENT_COMPLETE_0_VISIT = 'Completed'

--Alternative Visits
Select Distinct(CL_EN_GEN_ID)as 'CL_EN_GEN_ID'
, uv_pas.Site
, uv_pas.ProgramName
, uv_pas.ProgramID
Into #c2
From Alternative_Encounter_Survey
inner join UV_PAS on UV_PAS.ProgramID = Alternative_Encounter_Survey.ProgramID
Where
CLIENT_PERSONAL_0_NAME_LAST not like '%Fake%'
and CLIENT_PERSONAL_0_NAME_FIRST not like '%Fake%'
and CLIENT_TALKED_0_WITH_ALT like '%Client%'

--Combining the two recordsets
Insert Into #c1 Select * From #c2

--Pulling distinct Clinets by site(agency) from the combined recordset
Select

	Distinct (CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
	, Site
	, ProgramName
	, ProgramID
	
Into #Cumulativepopulation

From #c1

where CL_EN_GEN_ID is not null

-------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Served within period...
--------------------------

--Home Visits
Select Distinct(CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
, uv_pas.Site
, uv_pas.ProgramName
, uv_pas.ProgramID
Into #t1
From Home_Visit_Encounter_Survey
inner join UV_PAS on UV_PAS.ProgramID = Home_Visit_Encounter_Survey.ProgramID
Where

SurveyDate >= @Start and SurveyDate <= @End
and 
CLIENT_PERSONAL_0_NAME_LAST not like '%Fake%'
and CLIENT_PERSONAL_0_NAME_FIRST not like '%Fake%'
and CLIENT_COMPLETE_0_VISIT = 'Completed'

--Alternative Visits
Select Distinct(CL_EN_GEN_ID)as 'CL_EN_GEN_ID'
, uv_pas.Site
, uv_pas.ProgramName
, uv_pas.ProgramID
Into #t2
From Alternative_Encounter_Survey
inner join UV_PAS on UV_PAS.ProgramID = Alternative_Encounter_Survey.ProgramID
Where
SurveyDate >= @Start and SurveyDate <= @End
and
CLIENT_PERSONAL_0_NAME_LAST not like '%Fake%'
and CLIENT_PERSONAL_0_NAME_FIRST not like '%Fake%'
and CLIENT_TALKED_0_WITH_ALT like '%Client%'

--Combining the two recordsets
Insert Into #t1 Select * From #t2

--Pulling distinct Clinets by site(agency) from the combined recordset
Select

	Distinct (CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
	, Site
	, ProgramName
	, ProgramID
	
Into #population

From #t1

where CL_EN_GEN_ID is not null

-------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Served start date within period...
-------------------------------------

Select distinct (CLID) as 'CLID'
, ProgramID 
into #StartDate
from EnrollmentAndDismissal
where 
programstartdate >= @Start and programstartdate <= @End
-----------------------------------------------------------

-- Defining the population

--Home Visits
Select Distinct(CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
, uv_pas.Site
, uv_pas.ProgramName
, uv_pas.ProgramID
Into #st1
From Home_Visit_Encounter_Survey
inner join UV_PAS on UV_PAS.ProgramID = Home_Visit_Encounter_Survey.ProgramID
Where

SurveyDate >= @Start and SurveyDate <= @End
and 
CLIENT_PERSONAL_0_NAME_LAST not like '%Fake%'
and CLIENT_PERSONAL_0_NAME_FIRST not like '%Fake%'
and CLIENT_COMPLETE_0_VISIT = 'Completed'

--Alternative Visits
Select Distinct(CL_EN_GEN_ID)as 'CL_EN_GEN_ID'
, uv_pas.Site
, uv_pas.ProgramName
, uv_pas.ProgramID
Into #st2
From Alternative_Encounter_Survey
inner join UV_PAS on UV_PAS.ProgramID = Alternative_Encounter_Survey.ProgramID
Where
SurveyDate >= @Start and SurveyDate <= @End
and
CLIENT_PERSONAL_0_NAME_LAST not like '%Fake%'
and CLIENT_PERSONAL_0_NAME_FIRST not like '%Fake%'
and CLIENT_TALKED_0_WITH_ALT like '%Client%'

--Combining the two recordsets
Insert Into #st1 Select * From #st2

--Pulling distinct Clinets by site(agency) from the combined recordset
Select

	Distinct (CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
	, Site
	, ProgramName
	, ProgramID
	
Into #spopulation

From #st1

where CL_EN_GEN_ID is not null

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

Select

	CL_EN_GEN_ID
	, Site
	, ProgramName
	, #spopulation.ProgramID
	
Into #spop

from #spopulation
inner join #StartDate on #StartDate.CLID = #spopulation.CL_EN_GEN_ID
and #StartDate.ProgramID = #spopulation.ProgramID

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

Select 

	#Cumulativepopulation.CL_EN_GEN_ID
	, #Cumulativepopulation.Site
	, #Cumulativepopulation.ProgramName
	, #Cumulativepopulation.ProgramID
	, #population.CL_EN_GEN_ID as 'ServedWithinPeriodCLID'
	, #spop.CL_EN_GEN_ID as 'StartDateWithinPeriodCLID'
	
Into #CompletePopulation

From

	#Cumulativepopulation
	left join #population on #population.CL_EN_GEN_ID = #Cumulativepopulation.CL_EN_GEN_ID 
	and #population.ProgramID = #Cumulativepopulation.ProgramID
	left join #spop on #spop.CL_EN_GEN_ID = #Cumulativepopulation.CL_EN_GEN_ID 
	and #spop.ProgramID = #Cumulativepopulation.ProgramID

-------------------------------------------------------------------------------------
------------------------------------------------------------------------------
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

--Select * from #ClientRace

--drop table #ClientRace
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--Ethnicity
-----------

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
	
	--Select * from #ClientEthnicity
	
	--drop table #ClientEthnicity
-------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
--Use of Government Services
----------------------------

Select

	CL_EN_GEN_ID

	,(Case
	when SERVICE_USE_0_MEDICAID_CLIENT in (2,5) then
	1
	else
	0
	end) as 'ClientMedicaid'

Into #UGS

From 

	Govt_Comm_Srvcs_Survey
	
Select

Distinct(CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
, ClientMedicaid

into #UGS2

From #UGS

where ClientMedicaid = 1

--drop table #UGS
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
Select 

	CLID
	, EnrollmentAndDismissal.CaseNumber
	, SiteID
	, ProgramID
	, ProgramStartDate
	, EndDate
	
	, Clients.DOB
	, Datediff(YEAR, Clients.DOB, programstartdate) as 'AgeAtEnrollment' 

into #ED

From

	EnrollmentAndDismissal

left Join Clients on Clients.CaseNumber = EnrollmentAndDismissal.CaseNumber
	
Where CLID is not null

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

Select

	Distinct(CLID) as 'CLID'
	, Min(AgeAtEnrollment) as 'AgeAtEnrollment'
	
into #ED2

From

	#ED

Where AgeAtEnrollment is not null
Group by CLID
Order by CLID

--Drop table #ED
--Drop table #ED2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Not Married
Select 

	Demographics_Survey.CL_EN_GEN_ID

	, (Case
	when client_Marital_0_Status like '%Single%' then
	1
	when client_Marital_0_Status like '%Divorced%' then
	1
	else
	0
	end) as 'NotMarriedAtIntake'

into #Married

From Demographics_Survey

	inner join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID

Where

	SourceSurveyID = 1575
	and Demographics_Survey.CL_EN_GEN_ID is not null

------------------------------------------------------------------------------
	
Select

	Distinct(CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
	,NotMarriedAtIntake
	
into #M2

From 

	#Married

Where 

	NotMarriedAtIntake = 1


--drop table #Married
--drop table #M2
---------------------------------------------------------------------------------------------------
-----------------------------------------------------
----
Select 

	distinct(CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
	,(case when CLIENT_SUBSTANCE_CIG_1_PRE_PREG is null then
	0
	when CLIENT_SUBSTANCE_CIG_1_PRE_PREG = 0 then
	0
	else
	1
	end) as 'SmokedAtIntake'
	--, CLIENT_SUBSTANCE_CIG_1_PRE_PREG
	--, CLIENT_SUBSTANCE_CIG_0_DURING_PREG
	--, CLIENT_SUBSTANCE_CIG_1_LAST_48
	--, *
	into #Subpop
From

	Health_Habits_Survey
	inner join Mstr_surveys on Mstr_surveys.SurveyID = Health_Habits_Survey.SurveyID

Where

	Mstr_surveys.SurveyName like '%Intake%'
---------------------------------------------------------
----------------------------------------------------------	
--
Select 

	distinct(CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
		,(case when CLIENT_SUBSTANCE_CIG_1_PRE_PREG is null then
	0
	when CLIENT_SUBSTANCE_CIG_1_PRE_PREG = 0 then
	0
	else
	1
	end) as 'SmokedAt36'
	--, CLIENT_SUBSTANCE_CIG_1_PRE_PREG
	--, CLIENT_SUBSTANCE_CIG_0_DURING_PREG
	--, CLIENT_SUBSTANCE_CIG_1_LAST_48
	--, *
	into #Subpop1
From

	Health_Habits_Survey
	inner join Mstr_surveys on Mstr_surveys.SurveyID = Health_Habits_Survey.SurveyID

Where

	Mstr_surveys.SurveyName like '%36%'
---------------------------------------------------------------	

Select

	distinct(#Subpop.CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
	, SmokedAtIntake
	, SmokedAt36
	
	into #subpop2

From

	#Subpop1
	inner join #Subpop on #Subpop.CL_EN_GEN_ID = #Subpop1.CL_EN_GEN_ID
----------------------------------------------------------------------
--drop table #Subpop
--drop table #Subpop1
-----------------------------------------------------
----HS Diploma

Select 

	Demographics_Survey.CL_EN_GEN_ID
	
	, (Case
	when CLIENT_EDUCATION_0_HS_GED like '%Yes%' then
	1
	else
	0
	end) as 'HSDiplomaAtIntake'
	
	into #HS

From Demographics_Survey

	inner join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID

Where sourcesurveyid = 1575
--Select * from #HS
--Drop Table #HS

------------------------------------------------------
---------------------------------------------------
--HS Diploma

Select 

	Demographics_Survey.CL_EN_GEN_ID
	
	, (Case
	when CLIENT_EDUCATION_0_HS_GED like '%Yes%' then
	1
	else
	0
	end) as 'HSDiplomaAt24Months'

	into #HS24

From Demographics_Survey

	inner join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID

Where sourcesurveyid = 1702

--Select * from #HS24
--Drop Table #HS24

----------------------------------------------------
Select

	distinct(#HS.CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
	, HSDiplomaAtIntake
	, HSDiplomaAt24Months
	
	into #HS3

From

	#HS
	inner join #HS24 on #HS24.CL_EN_GEN_ID = #HS.CL_EN_GEN_ID
	
------------------------------------------------------------------------------
--Multip

Select 
distinct(CL_EN_GEN_ID) as Multip
into #Multip
From dbo.Tribal_Survey
Where CLIENT_TRIBAL_0_PARITY like '%Multi%'

--Select * from #Multip
--drop table #Multip
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--Tribal
Select 
Distinct(CL_EN_GEN_ID) as 'Tribal'
into #Tribal
From dbo.Tribal_Survey
--Select * from #Tribal
--drop Table #Tribal
------------------------------------------------------------------------------




















-------------------------------------------------------------------------------------
Select

	#CompletePopulation.CL_EN_GEN_ID
	, #CompletePopulation.ProgramID
	, #CompletePopulation.ProgramName
	, UV_PAS.Abbreviation
	, #CompletePopulation.ServedWithinPeriodCLID
	, #CompletePopulation.StartDateWithinPeriodCLID
	, #ClientRace.RAsian
	, #ClientRace.RBlack
	, #ClientRace.RDeclined
	, #ClientRace.RHawaiian
	, #ClientRace.RIndian
	, #ClientRace.RMulti
	, #ClientRace.ROther
	, #ClientRace.RUnrecorded
	, #ClientRace.RWhite
	, #ClientEthnicity.DEMO_CLIENT_INTAKE_0_ETHNICITY
	, #ClientEthnicity.EAsian
	, #ClientEthnicity.EDeclined
	, #ClientEthnicity.EHispanic
	, #ClientEthnicity.EIndian
	, #ClientEthnicity.EMulti
	, #ClientEthnicity.ENotH
	, #ClientEthnicity.EOther
	, #ClientEthnicity.EUnknown
	, #ClientEthnicity.EUnrecorded
	, #ClientEthnicity.EWhite
	, #UGS2.ClientMedicaid
	
		, (case
			when #CompletePopulation.ServedWithinPeriodCLID is not null
			and #UGS2.ClientMedicaid = 1 then
			1
			else
			0
			end
		) as 'ClientMedicaidWP'
	
		, (case
			when #CompletePopulation.StartDateWithinPeriodCLID is not null
			and #UGS2.ClientMedicaid = 1 then
			1
			else
			0
			end
		) as 'ClientMedicaidSDWP'	
	
	
	, #ED2.AgeAtEnrollment
	
	
	, #M2.NotMarriedAtIntake
	
		, (case
			when #CompletePopulation.ServedWithinPeriodCLID is not null
			and #M2.NotMarriedAtIntake = 1 then
			1
			else
			0
			end
		) as 'NotMarriedAtIntakeWP'
	
		, (case
			when #CompletePopulation.StartDateWithinPeriodCLID is not null
			and #M2.NotMarriedAtIntake = 1 then
			1
			else
			0
			end
		) as 'NotMarriedAtIntakeSDWP'	
	
	
	
	
	
	, #subpop2.SmokedAtIntake
	
	, (case
			when #CompletePopulation.ServedWithinPeriodCLID is not null
			and #subpop2.SmokedAtIntake = 1 then
			1
			else
			0
			end
		) as 'SmokedAtIntakeWP'

	, (case
			when #CompletePopulation.StartDateWithinPeriodCLID is not null
			and #subpop2.SmokedAtIntake = 1 then
			1
			else
			0
			end
		) as 'SmokedAtIntakeSDWP'		

	, #subpop2.SmokedAt36
	
	, (case
			when #CompletePopulation.ServedWithinPeriodCLID is not null
			and #subpop2.SmokedAt36 = 1 then
			1
			else
			0
			end
		) as 'SmokedAt36WP'
		
	, (case
			when #CompletePopulation.StartDateWithinPeriodCLID is not null
			and #subpop2.SmokedAt36 = 1 then
			1
			else
			0
			end
		) as 'SmokedAt36SDWP'
		
	, #HS3.HSDiplomaAtIntake
	
	
	, (case
			when #CompletePopulation.ServedWithinPeriodCLID is not null
			and #HS3.HSDiplomaAtIntake = 1 then
			1
			else
			0
			end
		) as 'HSDiplomaAtIntakeWP'
		
	, (case
			when #CompletePopulation.StartDateWithinPeriodCLID is not null
			and #HS3.HSDiplomaAtIntake = 1 then
			1
			else
			0
			end
		) as 'HSDiplomaAtIntakeSDWP'	
	
	
	
	, #HS3.HSDiplomaAt24Months
	

	, (case
			when #CompletePopulation.ServedWithinPeriodCLID is not null
			and #HS3.HSDiplomaAt24Months = 1 then
			1
			else
			0
			end
		) as 'HSDiplomaAt24MonthsWP'
		
	, (case
			when #CompletePopulation.StartDateWithinPeriodCLID is not null
			and #HS3.HSDiplomaAt24Months = 1 then
			1
			else
			0
			end
		) as 'HSDiplomaAt24MonthsSDWP'
		
	, #Tribal.Tribal
	, #Multip.Multip
		




From

	#CompletePopulation
	left join #ClientRace on #ClientRace.Client_Id = #CompletePopulation.CL_EN_GEN_ID
	left join #ClientEthnicity on #ClientEthnicity.Client_Id = #CompletePopulation.CL_EN_GEN_ID
	left join #UGS2 on #UGS2.CL_EN_GEN_ID = #CompletePopulation.CL_EN_GEN_ID
	left join #ED2 on #ED2.CLID = #CompletePopulation.CL_EN_GEN_ID
	left join #M2 on #M2.CL_EN_GEN_ID = #CompletePopulation.CL_EN_GEN_ID
	left join #subpop2 on #subpop2.CL_EN_GEN_ID = #CompletePopulation.CL_EN_GEN_ID
	left join #HS3 on #HS3.CL_EN_GEN_ID = #CompletePopulation.CL_EN_GEN_ID
	left join UV_PAS on uv_pas.ProgramID = #CompletePopulation.ProgramID
	left join #Tribal on #Tribal.Tribal = #CompletePopulation.CL_EN_GEN_ID 
	left join #Multip on #Multip.Multip = #CompletePopulation.CL_EN_GEN_ID
	
	
Where UV_PAS.Abbreviation = @State
	
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--Clean Up



drop table #Multip


drop Table #Tribal




Drop Table #HS24
Drop Table #HS
Drop Table #HS3


drop table #Subpop
drop table #Subpop1
drop table #subpop2 

drop table #Married
drop table #M2

drop table #ED2
drop table #ED

drop table #UGS
drop table #UGS2
drop table #ClientEthnicity

drop table #R
drop table #ClientRace


drop table #spop

drop table #st1
drop table #st2
drop Table #StartDate
drop table #spopulation

drop table #t1
drop table #t2
drop table #population

drop table #c1
drop table #c2
drop table #Cumulativepopulation
drop table #CompletePopulation

END
GO
