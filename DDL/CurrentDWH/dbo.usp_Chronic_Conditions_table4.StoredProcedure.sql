USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Chronic_Conditions_table4]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_Chronic_Conditions_table4]

@Start date,@End date, @State varchar(30)

AS

Select 

	
	Distinct Count(CL_EN_GEN_ID) as Clients,
	--UV_PAS.Site,
	--UV_PAS.ProgramName,
	--UV_PAS.CleanTeamName,
	UV_PAS.[US State],
	

	Alcohol = sum(case when CLIENT_SUBSTANCE_ALCOHOL_0_14DAY <> 0 then 1 else 0 end),
	
	Marijuana = sum(case when CLIENT_SUBSTANCE_POT_0_14DAYS <> 0 then 1 else 0 end),
	
	Cocaine = sum(case when CLIENT_SUBSTANCE_COCAINE_0_14DAY <> 0 then 1 else 0 end),
	
	StreetDrug = sum(case when CLIENT_SUBSTANCE_OTHER_0_14DAY <> 0 then 1 else 0 end)
	
From

	Health_Habits_Survey
	inner join UV_PAS on uv_pas.ProgramID = Health_Habits_Survey.ProgramID and UV_PAS.SiteID = Health_Habits_Survey.SiteID 
	 
Where

	SurveyDate between @Start and @End
	and [US State] = @State
	and Team_Id not in 
	(
23167 
,23168 
,23218 
,23219 
,23386 
,23388 
,23389 
,23433 
,23434 
,23449 
,23450 
,23451 
,23452 
,23392 
,23460 
,23461 )
	
Group by

	--UV_PAS.Site,
	--UV_PAS.ProgramName,
	--UV_PAS.CleanTeamName,
	UV_PAS.[US State]
GO
