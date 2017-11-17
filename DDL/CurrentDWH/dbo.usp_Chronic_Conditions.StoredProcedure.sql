USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Chronic_Conditions]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_Chronic_Conditions]

@Start date,@End date, @State varchar(4000)

AS
--------------------------------------------------
--Pulling the initial data from survey table
--------------------------------------------------

Select

	SurveyResponseID,
	SurveyDate,
	AuditDate,
	CL_EN_GEN_ID,
	SiteID,
	ProgramID,
	isnull([CLIENT_HEALTH_GENERAL_0_CONCERNS],'None Reported') as [CLIENT_HEALTH_GENERAL_0_CONCERNS],
	
	isnull([CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL],'None Reported') as [CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL],
	
	isnull([CLIENT_HEALTH_BELIEF_0_CANT_SOLVE],'None Reported') as [CLIENT_HEALTH_BELIEF_0_CANT_SOLVE],
	
	isnull([CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO],'None Reported') as [CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO],
	
	isnull([CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS],'None Reported') as [CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS],
	
	isnull([CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND],'None Reported') as [CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND],
	
	isnull([CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL],'None Reported') as [CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL],
	
	isnull([CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING],'None Reported') as [CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING],
	
	isnull([CLIENT_HEALTH_GENERAL_0_OTHER],'None Reported') as [CLIENT_HEALTH_GENERAL_0_OTHER]
	

Into #Concerns

From

	Maternal_Health_Survey
	
Where Maternal_Health_Survey.SurveyDate between @Start and @End

-----------------------------------------------------------------
--Start pull of height/weight for BMI Calc - accounting for nulls
-----------------------------------------------------------------

Select

	SurveyResponseID,
	ISNULL(CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS,0) as Pounds,
	((ISNULL(dbo.Maternal_Health_Survey.CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET,0)*12) + ISNULL(dbo.Maternal_Health_Survey.CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES,0)) as Height,
	(((ISNULL(dbo.Maternal_Health_Survey.CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET,0)*12) + ISNULL(dbo.Maternal_Health_Survey.CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES,0))*((ISNULL(dbo.Maternal_Health_Survey.CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET,0)*12) + ISNULL(dbo.Maternal_Health_Survey.CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES,0))) as BMIHeight

Into

	#Cleanup

From

	dbo.Maternal_Health_Survey

------------------------------------------------------------------
--Pulling clean calcs and accounting for div by zero
--if missing a piece of the calc will make 0 result in BMI unknown
------------------------------------------------------------------

Select

	SurveyResponseID,
	Pounds,
	Height,
	BMIHeight,
	BMI = Case 
			When pounds = 0 Then 0
			When BMIHeight = 0 Then 0
			Else
				((Pounds/BMIHeight)*703)
			End

Into #Processed

From

	#Cleanup
	
------------------------------------------------------
--Combining initial data pull, processed calcs, and 
--joining ref info for grouping
------------------------------------------------------

Select
 
 	#Processed.SurveyResponseID,
 	SurveyDate,
	AuditDate,
	CL_EN_GEN_ID,
	#Concerns.SiteID,
	ProgramsAndSites.Site,
	#Concerns.ProgramID,
	ProgramsAndSites.ProgramName,
	
	[CLIENT_HEALTH_GENERAL_0_CONCERNS],
	
	[CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL],

	[CLIENT_HEALTH_BELIEF_0_CANT_SOLVE],

	[CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO],

	[CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS],

	[CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND],

	[CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL],

	[CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING],

	[CLIENT_HEALTH_GENERAL_0_OTHER],
		
	Pounds,
	Height,
	BMIHeight,
	BMI,
	WeightStatus = Case
					When BMI = 0 Then 'Unknown'
					When BMI < 18.5 then 'Underweight'
					When BMI >= 18.5 and BMI < 25 then 'Normal'
					When BMI >= 25 and BMI < 30 then 'Overweight'
					When BMI >= 30 then 'Obese'
					End

Into #Results

From

	#Processed
	left join #Concerns on #Concerns.SurveyResponseID = #Processed.SurveyResponseID
	
	left join Clients on clients.Client_Id = #Concerns.CL_EN_GEN_ID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = #Concerns.ProgramID
		and ProgramsAndSites.SiteID = #Concerns.SiteID

-------------------------------------------------------------------------------------
--Combining the results with the cut of concerns also counting for rpt sums
-------------------------------------------------------------------------------------

Select

	#Results.SurveyResponseID,
 	#Results.SurveyDate,
	AuditDate,
	#Results.CL_EN_GEN_ID,
	#Results.SiteID,
	#Results.Site,
	#Results.ProgramID,
	#Results.ProgramName,
	UV_PAS.CleanTeamName,
	UV_PAS.Team_Id,
	UV_PAS.Team_Name,
	UV_PAS.[US State],
	#Results.[CLIENT_HEALTH_GENERAL_0_CONCERNS],
	
	[CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL],

	[CLIENT_HEALTH_BELIEF_0_CANT_SOLVE],

	[CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO],

	[CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS],

	[CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND],

	[CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL],

	[CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING],

	[CLIENT_HEALTH_GENERAL_0_OTHER],
	
	Data = (case 
			when UV_Dict_Client_Health_General_Concerns.Data like 'Chronic gastrointestinal%' then
				'Chronic gastrointestinal condition'
			when UV_Dict_Client_Health_General_Concerns.Data like 'Chronic vaginal%' then
				'Chronic vaginal infections including STI'
			else
				UV_Dict_Client_Health_General_Concerns.Data
			end),
	Datasort = (case
				when UV_Dict_Client_Health_General_Concerns.Data like 'Heart%' then
				1
				when UV_Dict_Client_Health_General_Concerns.Data like 'High%' then
				2
				when UV_Dict_Client_Health_General_Concerns.Data like 'Diabetes' then
				3
				when UV_Dict_Client_Health_General_Concerns.Data like 'Kidney%' then
				4
				when UV_Dict_Client_Health_General_Concerns.Data like 'Epilepsy' then
				5
				when UV_Dict_Client_Health_General_Concerns.Data like 'Sickle%' then
				6
				when UV_Dict_Client_Health_General_Concerns.Data like 'Chronic gastrointestinal%' then
				7
				when UV_Dict_Client_Health_General_Concerns.Data like 'Asthma%' then
				8
				when UV_Dict_Client_Health_General_Concerns.Data like 'Chronic Urinary%' then
				9
				when UV_Dict_Client_Health_General_Concerns.Data like 'Chronic vaginal%' then
				10
				when UV_Dict_Client_Health_General_Concerns.Data like 'Genetic%' then
				11
				when UV_Dict_Client_Health_General_Concerns.Data like 'Mental%' then
				12
				when UV_Dict_Client_Health_General_Concerns.Data like 'Other%' then
				13
				else
				14				
				end),
			
			
	Pounds,
	Height,
	BMIHeight,
	BMI,
	WeightStatus,
	Unknown = (case
				when WeightStatus like 'Unknown' then
				1
				else
				0
				end),
	Underweight = (case
				when WeightStatus like 'Underweight' then
				1
				else
				0
				end),
	Normal = (case
				when WeightStatus like 'Normal' then
				1
				else
				0
				end),
	Overweight = (case
				when WeightStatus like 'Overweight' then
				1
				else
				0
				end),
	Obese = (case
				when WeightStatus like 'Obese' then
				1
				else
				0
				end),
				
	NYC = (case team_id
	when 23167 then
	'NYC'
	when 23168 then
	'NYC'
	when 23218 then
	'NYC'
	when 23219 then
	'NYC'
		when 23386 then
	'NYC'
	when 23388 then
	'NYC'
		when 23389 then
	'NYC'
	when 23433 then
	'NYC'
		when 23434 then
	'NYC'
	when 23449 then
	'NYC'
		when 23450 then
	'NYC'
	when 23451 then
	'NYC'
		when 23452 then
	'NYC'
	when 23392 then
	'NYC'
		when 23460 then
	'NYC'
	when 23461 then
	'NYC'
	else
	'not'
	end)


 from UV_Dict_Client_Health_General_Concerns

left join #Results on #Results.SurveyResponseID = UV_Dict_Client_Health_General_Concerns.SurveyResponseID
inner join UV_PAS on uv_pas.ProgramID = #Results.ProgramID and UV_PAS.SiteID = #Results.SiteID

Where #Results.SurveyDate between @Start and @End
and UV_PAS.[US State] in (SELECT * FROM dbo.udf_ParseMultiParamWild (@State, ','))
-------------------------------------------------------------------------------------	

Drop Table #Concerns
Drop Table #cleanup
Drop Table #Processed
Drop table #Results



GO
