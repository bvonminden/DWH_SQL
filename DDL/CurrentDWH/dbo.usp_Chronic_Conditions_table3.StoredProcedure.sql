USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Chronic_Conditions_table3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_Chronic_Conditions_table3]

@Start date,@End date
--, @State varchar(30)

AS

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
	
Where Maternal_Health_Survey.SurveyDate between @Start and @End

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

--------------------------------------------------
--Count of conditions
--------------------------------------------------

Select

	Maternal_Health_Survey.SurveyResponseID,
	SurveyDate,
	Maternal_Health_Survey.CL_EN_GEN_ID,
	Maternal_Health_Survey.SiteID,
	Maternal_Health_Survey.ProgramID,
	UV_PAS.CleanTeamName,
	UV_PAS.Team_Id,
	UV_PAS.Team_Name,
	UV_PAS.[US State],

	Data = (case 
		when UV_Dict_Client_Health_General_Concerns.Data like 'Chronic gastrointestinal%' then
			'Chronic gastrointestinal condition'
		when UV_Dict_Client_Health_General_Concerns.Data like 'Chronic vaginal%' then
			'Chronic vaginal infections including STI'
		else
			UV_Dict_Client_Health_General_Concerns.Data
		end),
			
	NoConditions = (case
					when [CLIENT_HEALTH_GENERAL_0_CONCERNS] is null then 1
					else
					0
					end),
	OneOrMore = (case
					when [CLIENT_HEALTH_GENERAL_0_CONCERNS] is null then 0
					else
					1
					end),
					
	WeightStatus = Case
					When BMI = 0 Then 'Unknown'
					When BMI < 18.5 then 'Underweight'
					When BMI >= 18.5 and BMI < 25 then 'Normal'
					When BMI >= 25 and BMI < 30 then 'Overweight'
					When BMI >= 30 then 'Obese'
					End

Into #Concerns

From

	Maternal_Health_Survey
	left join UV_Dict_Client_Health_General_Concerns on UV_Dict_Client_Health_General_Concerns.SurveyResponseID = Maternal_Health_Survey.SurveyResponseID
	left join #Processed on #Processed.SurveyResponseID = Maternal_Health_Survey.SurveyResponseID
	inner join UV_PAS on uv_pas.ProgramID = Maternal_Health_Survey.ProgramID and UV_PAS.SiteID = Maternal_Health_Survey.SiteID
	
Where Maternal_Health_Survey.SurveyDate between @Start and @End
--and UV_PAS.[US State] = @State
-------------------------------------------------------------------------------------------------

Select

	#Concerns.SurveyResponseID,
	CL_EN_GEN_ID,
	WeightStatus,
	sum(NoConditions) as 'NoConditions',
	Sum(OneOrMore) as 'OneOrMore',
	SiteID,
	ProgramID,
	CleanTeamName,
	Team_Id,
	[US State]
	
Into #End
	
From 

	#Concerns
	
	
	
Group by

	#Concerns.SurveyResponseID,
	CL_EN_GEN_ID,
	WeightStatus,
	SiteID,
	ProgramID,
	CleanTeamName,
	Team_Id,
	Team_Name,
	[US State]
	
Order by SurveyResponseID

-----------------------------------------------------------------------------------------

Select

	distinct COUNT(CL_EN_GEN_ID) as Clients,
	sum(NoConditions) as NoConditions,
	sum(OneOrMore) as OneOrMore,
	WeightStatus,
	SiteID,
	ProgramID,
	CleanTeamName,
	Team_Id,
	[US State]

From

	#End
	
--where Team_ID in
 
--(
--23167 
--,23168 
--,23218 
--,23219 
--,23386 
--,23388 
--,23389 
--,23433 
--,23434 
--,23449 
--,23450 
--,23451 
--,23452 
--,23392 
--,23460 
--,23461 )

Group by

	WeightStatus,
	SiteID,
	ProgramID,
	CleanTeamName,
	Team_Id,
	[US State]
	
	
drop table #Processed
drop table #Cleanup
drop table #Concerns
drop table #End



GO
