USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Chronic_Conditions_table5]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_Chronic_Conditions_table5]

@Start date,@End date, @State varchar(30)

AS

---------------------------------------------------------------------------------------
-- Base pull to get all Client ID's from Both Surveys
---------------------------------------------------------------------------------------
SELECT

	Mix.Clients
	, Mix.Site 

INTO

	#Combined

FROM

	(Select
		
		distinct (CL_EN_GEN_ID) as Clients
		,[Site]
	From

		Maternal_Health_Survey
		inner join UV_PAS on uv_pas.ProgramID = Maternal_Health_Survey.ProgramID and UV_PAS.SiteID = Maternal_Health_Survey.SiteID 
	 
	
	Where

		[CLIENT_HEALTH_GENERAL_0_CONCERNS] is not null
		
	and [US State] = 'New York'
	and SurveyDate between @Start and @End
	

UNION ALL

    Select 
	
		distinct (CL_EN_GEN_ID) as Clients
		,[Site]
		
	From

		Health_Habits_Survey
		inner join UV_PAS on uv_pas.ProgramID = Health_Habits_Survey.ProgramID and UV_PAS.SiteID = Health_Habits_Survey.SiteID 
	 
	
	Where

		(CLIENT_SUBSTANCE_ALCOHOL_0_14DAY <> 0)
		
		or (CLIENT_SUBSTANCE_POT_0_14DAYS <> 0) 
		
		or (CLIENT_SUBSTANCE_COCAINE_0_14DAY <> 0) 
		
		or (CLIENT_SUBSTANCE_OTHER_0_14DAY <> 0)
		
	and [US State] = 'New York'
	and SurveyDate between @Start and @End
		
		) Mix
---------------------------------------------------------------------------------------------
-- Maternal Health Survey details in right format
-------------------------------------------------------------------------------------------------
Select 
distinct CL_EN_GEN_ID,
Heart = (case when UV_Dict_Client_Health_General_Concerns.Data like 'Heart%' then 1 else 0 end),		
High = (case when UV_Dict_Client_Health_General_Concerns.Data like 'High%' then 1	else 0 end),
Diabetes  = (case when UV_Dict_Client_Health_General_Concerns.Data like 'Diabetes' then 1	else 0	end),
Kidney = (case when UV_Dict_Client_Health_General_Concerns.Data like 'Kidney%' then 1	else 0	end),
Epilepsy = (case when UV_Dict_Client_Health_General_Concerns.Data like 'Epilepsy' then 1	else 0	end),
Sickle = (case when UV_Dict_Client_Health_General_Concerns.Data like 'Sickle%' then 1	else 0	end),
Chronicgastrointestinal = (case when UV_Dict_Client_Health_General_Concerns.Data like 'Chronic gastrointestinal%' then 1 else 0 end),
Asthma = (case when UV_Dict_Client_Health_General_Concerns.Data like 'Asthma%' then 1	else 0	end),
ChronicUrinary = (case when UV_Dict_Client_Health_General_Concerns.Data like 'Chronic Urinary%' then 1	else 0	end),
Chronicvaginal = (case when UV_Dict_Client_Health_General_Concerns.Data like 'Chronic vaginal%' then 1	else 0	end),
Genetic = (case when UV_Dict_Client_Health_General_Concerns.Data like 'Genetic%' then 1	else 0	end),
Mental = (case when UV_Dict_Client_Health_General_Concerns.Data like 'Mental%' then 1	else 0	end),
Other = (case when UV_Dict_Client_Health_General_Concerns.Data like 'Other%' then 1	else 0 end)

into #Twist

From UV_Dict_Client_Health_General_Concerns
---------------------------------------------------------------------------------------------------------
Select

distinct CL_EN_GEN_ID,
sum(Heart) as Heart,		
sum(High) as High,
sum(Diabetes) as Diabetes,
sum(Kidney) as Kidney,
sum(Epilepsy) as Epilepsy,
sum(Sickle) as Sickle,
sum(Chronicgastrointestinal) as Chronicgastrointestinal,
sum(Asthma) as Asthma,
sum(ChronicUrinary) as ChronicUrinary,
sum(Chronicvaginal) as Chronicvaginal,
sum(Genetic) as Genetic,
sum(Mental) as Mental,
sum(Other) as Other

into #Twist2

From #Twist

Group by CL_EN_GEN_ID

Order by CL_EN_GEN_ID
-----------------------------------------------------------------------------------------------------------
-- Maternal Health Survey - Other Detail
-----------------------------------------------------------------------------------------------------------

Select
 
	distinct CL_EN_GEN_ID as Oclients, 
	CLIENT_HEALTH_GENERAL_0_OTHER as OtherDetail

Into

	#Other
From

	Maternal_Health_Survey
	
Where

	CLIENT_HEALTH_GENERAL_0_OTHER is not null
-----------------------------------------------------------------------------------------------------------
-- Health Habits Data
-----------------------------------------------------------------------------------------------------------
Select 

	max(SurveyDate) as newest,
	MAX(SurveyResponseID) as SRID,
	CL_EN_GEN_ID as HHNewClient
	
Into #HHNewest
	
From

	Health_Habits_Survey
	
--Where

--	Health_Habits_Survey.SurveyDate between @Start and @End
	
Group By

	CL_EN_GEN_ID
	
	
Select 

	CL_EN_GEN_ID as HClients,

	Alcohol = (case when CLIENT_SUBSTANCE_ALCOHOL_0_14DAY <> 0 then 'X' else '' end),
	
	Marijuana = (case when CLIENT_SUBSTANCE_POT_0_14DAYS <> 0 then 'X' else '' end),
	
	Cocaine = (case when CLIENT_SUBSTANCE_COCAINE_0_14DAY <> 0 then 'X' else '' end),
	
	StreetDrug = (case when CLIENT_SUBSTANCE_OTHER_0_14DAY <> 0 then 'X' else '' end)
	
Into #HHSurvey
	
From

	Health_Habits_Survey
	inner join #HHNewest on #HHNewest.SRID = Health_Habits_Survey.SurveyResponseID
-----------------------------------------------------------------------------------------------------------
--Results Set
-----------------------------------------------------------------------------------------------------------
Select

	
	Distinct Clients,
	[Site],
	Heart = (case when Heart = 1 then 'X' else '' end),		
	High = (case when High = 1 then 'X' else '' end),
	Diabetes = (case when Diabetes = 1 then 'X' else '' end),
	Kidney = (case when Kidney = 1 then 'X' else '' end),
	Epilepsy = (case when Epilepsy = 1 then 'X' else '' end),
	Sickle = (case when Sickle = 1 then 'X' else '' end),
	Chronicgastrointestinal = (case when Chronicgastrointestinal = 1 then 'X' else '' end),
	Asthma = (case when Asthma = 1 then 'X' else '' end),
	ChronicUrinary = (case when ChronicUrinary = 1 then 'X' else '' end),
	Chronicvaginal = (case when Chronicvaginal = 1 then 'X' else '' end),
	Genetic = (case when Genetic = 1 then 'X' else '' end),
	Mental = (case when Mental = 1 then 'X' else '' end),
	Other = (case when Other = 1 then 'X' else '' end),
	OtherDetail = isnull(OtherDetail, ''),
	Alcohol = isnull(Alcohol, ''),
	Marijuana = isnull(Marijuana, ''),
	Cocaine = isnull(Cocaine, ''),
	StreetDrug = isnull(StreetDrug, '')

From

	#Combined
	
	left join #Twist2 on #Twist2.CL_EN_GEN_ID = #Combined.Clients
	left join #Other on #Other.Oclients = #Combined.Clients
	left join #HHSurvey on #HHSurvey.HClients  = #Combined.Clients
	
Order by Clients
----------------------------------------------------------------------------------------------
-- Clean up
----------------------------------------------------------------------------------------------	
Drop Table #Combined
Drop Table #Twist
Drop Table #Twist2
Drop Table #Other
Drop Table #HHNewest
Drop Table #HHSurvey
GO
