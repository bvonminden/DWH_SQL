USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Errors_EducationWorkforceIncomeStatus]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Errors_EducationWorkforceIncomeStatus]

@Team varchar(4000)

AS

--------------------------------------------------------------------------------
-- Limit of data by active client after date of CIS to STO conversion
---------------------------------------------------------------------
Select distinct(CLID) as 'CLID'
Into #DS_ActiveClientlimit
From EnrollmentAndDismissal
inner join dbo.Home_Visit_Encounter_Survey on Home_Visit_Encounter_Survey.CL_EN_GEN_ID = EnrollmentAndDismissal.CLID
Where (EndDate > '2011-11-01') or (EndDate is null)

--Select * From #DS_ActiveClientlimit

--drop table #DS_ActiveClientlimit

--	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------
--Education Status
--1)	Client education reported at intake, 6, 12, 18 or 24 month intervals
--		i. Completion of high school or GED or vocational program is missing.
--------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_EDUCATION_0_HS_GED
	, SortOrder = (Case SurveyName
					When 'Demographics: Pregnancy Intake' Then
						0
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
	
Into

	#DS1

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	CLIENT_EDUCATION_0_HS_GED is null									----Q7 null
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_EDUCATION_0_HS_GED'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

---------------------------------------------------------------------------------------------------------------
--Education Status
--1)	Client education reported at intake, 6, 12, 18 or 24 month intervals
--		ii. If client did not complete high school or GED program 
--			and last grade completed is missing.
---------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_EDUCATION_1_HS_GED_LAST_GRADE
	, SortOrder = (Case SurveyName
					When 'Demographics: Pregnancy Intake' Then
						0
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
	
Into

	#DS2

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
  	CLIENT_EDUCATION_0_HS_GED = 'No'											----Q7 = 'No' last grade required
	and CLIENT_EDUCATION_1_HS_GED_LAST_GRADE is null							----Q7 last grade						
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_EDUCATION_1_HS_GED_LAST_GRADE'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

---------------------------------------------------------------------------------------------------------------
--Education Status
--1)	Client education reported at intake, 6, 12, 18 or 24 month intervals
--			ii. If client did not complete high school or GED program and last grade completed is missing
--				a. If last grade completed is reported and does not increase incrementally 
--					across 6, 12, 18 or 24 month intervals or does not remain the same from previous intervals.
---------------------------------------------------------------------------------------------------------------
----begin #DS3a

---take the survey records and sort by client/interval
Select DemographicSurveys.*
	----this row number is needed to match curr to prev recs, below, because the SortOrder skips when an interval is not present
	----causing the rows not to match properly
	,ROW_NUMBER() OVER(PARTITION BY DemographicSurveys.Client ORDER BY DemographicSurveys.SortOrder) RowNumber

Into

	#DS3a

From
(	----survey records that have no for HS/GED and last grade is present
	----these will be checked to flag where last grade is not remaining the same or not increasing in subsequent intervals
	Select
		ProgramName
		, CL_EN_GEN_ID as Client
		, SurveyName
		, Mstr_SurveyElements.Stimulus as Question
		, 'Last grade less than previous interval' as Error
		, Convert(varchar(8),SurveyDate,1) as SurveyDate
		, SortOrder = (Case SurveyName	
						When 'Demographics: Pregnancy Intake' Then
							0
						When 'Demographics Update: Infancy 6 Months' then
							1
						When 'Demographics Update: Infancy 12 Months' then
							2
						When 'Demographics Update: Toddler 18 Months' then
							3
						When 'Demographics Update: Toddler 24 Months' then
							4
						Else
							5
						End)
		, SortOrder2 = source.SequenceOrder					----this is the order of the questions in the survey
		, CLIENT_EDUCATION_1_HS_GED_LAST_GRADE LastGrade	----grade being checked
		
	From

		Demographics_Survey
		inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
		left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
		left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
		left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
		left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

	Where
	  
  		CLIENT_EDUCATION_0_HS_GED = 'No'											----Q7 'No' 
		and CLIENT_EDUCATION_1_HS_GED_LAST_GRADE is not null						----Q7 last grade completed is present for checking/validation
		and Mstr_SurveyElements.Pseudonym = 'CLIENT_EDUCATION_1_HS_GED_LAST_GRADE'
		and ProgramName = @Team
		
)DemographicSurveys
	 
---- end #DS3a
------------------------------------------------------
---- begin #DS3b	

SELECT 

	curr.ProgramName
	,curr.Client
	,curr.SurveyName
	,curr.Question
	,curr.Error
	,curr.SurveyDate	
	----,curr.LastGrade currLastGrade	----used during testing
	----,prev.LastGrade prevLastGrade	----used during testing
	,curr.SortOrder
	,curr.SortOrder2	
	,curr.RowNumber
	,CASE WHEN prev.Client IS NOT NULL	----only do compare if there is a previous record
		THEN
			CASE WHEN curr.Client = prev.Client 
				THEN
					CASE WHEN CAST(curr.LastGrade AS int) < CAST(prev.LastGrade AS int)
						THEN 1	----grade not staying same or not increasing incrementally across intervals, flag it
						ELSE 0	----grade same or increasing across intervals, this is okay
					END
			END
		ELSE 0	---no more values to compare		
	END currGradeLessThanPrev
				
INTO #DS3b

FROM #DS3a curr											----surveys where Q7 = 'No' and last grade completed is present (not null), ordered
	 LEFT JOIN #DS3a prev ON prev.Client = curr.Client
		AND prev.RowNumber  = curr.RowNumber - 1		----lines up current to previous record

---- end #DS3b
------------------------------------------------------
---- begin #DS3c	

----display the survey records where grade is not the same or not increasing
SELECT 

	ProgramName
	,Client
	,SurveyName
	,Question
	,Error
	,SurveyDate	
	,SortOrder
	,SortOrder2	
					
INTO #DS3c

FROM #DS3b 
WHERE currGradeLessThanPrev = 1	----get only the survey records where grade not same or increasing

ORDER BY 

	ProgramName
	, Client
	, SortOrder
	, Question

---------------------------------------------------------------------------------------------------------------
--Education Status
--1)	Client education reported at intake, 6, 12, 18 or 24 month intervals
--		iii. If completed high school or GED and
--			a. Completed education (highest level) other than high school or GED
---------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	----,CLIENT_EDUCATION_0_HS_GED
	--, CLIENT_EDUCATION_1_HIGHER_EDUC_COMP
	, SortOrder = (Case SurveyName
					When 'Demographics: Pregnancy Intake' Then
						0
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
	
Into

	#DS4

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	(CLIENT_EDUCATION_0_HS_GED LIKE 'Yes%' OR CLIENT_EDUCATION_0_HS_GED IS NULL)	----Q7 <> 'No', Q10 cannot be null/skipped
  	and CLIENT_EDUCATION_1_HIGHER_EDUC_COMP is null									----Q10
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_EDUCATION_1_HIGHER_EDUC_COMP'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

---------------------------------------------------------------------------------------------------------------
--Education Status
--1)	Client education reported at intake, 6, 12, 18 or 24 month intervals
--		iii. If completed high school or GED and
--			b. If currently enrolled in any educational program is missing
---------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_EDUCATION_0_HS_GED
	--, CLIENT_EDUCATION_1_ENROLLED_CURRENT
	, SortOrder = (Case SurveyName
					When 'Demographics: Pregnancy Intake' Then
						0
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
	
Into

	#DS5

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	(CLIENT_EDUCATION_0_HS_GED LIKE 'Yes%' OR CLIENT_EDUCATION_0_HS_GED IS NULL)	----Q7 <> 'No', Q8 cannot be null/skipped
	and CLIENT_EDUCATION_1_ENROLLED_CURRENT is null									----Q8
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_EDUCATION_1_ENROLLED_CURRENT'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

---------------------------------------------------------------------------------------------------------------
--Education Status
--1)	Client education reported at intake, 6, 12, 18 or 24 month intervals
--		iii. If completed high school or GED and
--			c. If currently enrolled in any educational program 
--				and type of educational program is missing
---------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate	  
	------,CLIENT_EDUCATION_0_HS_GED
	------,CLIENT_EDUCATION_1_ENROLLED_CURRENT
	--, CLIENT_ED_PROG_TYPE
	, SortOrder = (Case SurveyName
					When 'Demographics: Pregnancy Intake' Then
						0
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	

Into

	#DS6

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	(CLIENT_EDUCATION_0_HS_GED LIKE 'Yes%' OR CLIENT_EDUCATION_0_HS_GED IS NULL)	----Q7 <> 'No', Q8 = 'Yes', Q9 cannot be null/skipped
	and CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'Yes'									----Q8
	and (CLIENT_ED_PROG_TYPE is null												----Q9
		AND CLIENT_EDUCATION_1_ENROLLED_TYPE IS NULL)
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ED_PROG_TYPE'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

---------------------------------------------------------------------------------------------------------------
--Education Status
--1)	Client education reported at intake, 6, 12, 18 or 24 month intervals
--		iii. If completed high school or GED and
--			d. If currently enrolled and ???full-time??? should this be part-time ???, 
--				part-time detail is missing
---------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	------,CLIENT_EDUCATION_0_HS_GED
	------,CLIENT_EDUCATION_1_ENROLLED_CURRENT 
	------,CLIENT_EDUCATION_1_ENROLLED_FTPT
	--,CLIENT_EDUCATION_1_ENROLLED_PT_HRS 
	, SortOrder = (Case SurveyName
					When 'Demographics: Pregnancy Intake' Then
						0
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
	
Into

	#DS7

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	(CLIENT_EDUCATION_0_HS_GED LIKE 'Yes%' OR CLIENT_EDUCATION_0_HS_GED IS NULL)	----Q7 <> 'No', Q8 = 'Yes', enrolled Part-Time, PT hours cannot be null/skipped
	and CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'Yes'									----Q8 enrolled
	and CLIENT_EDUCATION_1_ENROLLED_FTPT like 'Part%'								----Q8 FTPT
	and CLIENT_EDUCATION_1_ENROLLED_PT_HRS is null									----Q8 PT hours 
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_EDUCATION_1_ENROLLED_PT_HRS'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

---------------------------------------------------------------------------------------------------------------
--Education Status
--1)	Client education reported at intake, 6, 12, 18 or 24 month intervals
--		iii. If completed high school or GED and
--			e. If not currently enrolled 
--				and plans to enroll in any kind of school, vocational or educational program is missing
---------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	----,CLIENT_EDUCATION_0_HS_GED					----(Q7 No, go to Q11)	
	----,CLIENT_EDUCATION_1_ENROLLED_CURRENT		----(Q8 No, go to Q10)
	--,CLIENT_EDUCATION_1_ENROLLED_PLAN				----(Q11 required, should never be null/skipped, adding/using other conditions will cause DUPS or MISSes)
	, SortOrder = (Case SurveyName
					When 'Demographics: Pregnancy Intake' Then
						0
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
	
Into

	#DS8

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	(CLIENT_EDUCATION_0_HS_GED LIKE 'Yes%' OR CLIENT_EDUCATION_0_HS_GED IS NULL)	---Q7 'Yes' completed HS, etc., Q8 'No' currently enrolled, Q11 plans to enroll should not be missing
	and CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'No'									---Q8 
	and	CLIENT_EDUCATION_1_ENROLLED_PLAN is null									---Q11 
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_EDUCATION_1_ENROLLED_PLAN'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus

---------------------------------------------------------------------------------------------------------------
--Workforce status:
--1)	Client currently working is missing at intake, 6, 12, 18 or 24 months intervals
---------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_WORKING_0_CURRENTLY_WORKING
	, SortOrder = (Case SurveyName
					When 'Demographics: Pregnancy Intake' Then
						0
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
	
Into

	#DS9

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	CLIENT_WORKING_0_CURRENTLY_WORKING is null									----Q12 Intake/Q14 all others, cannot be null/skipped
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_WORKING_0_CURRENTLY_WORKING'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

---------------------------------------------------------------------------------------------------------------
--Workforce status:
--2)	Client's work history since birth of infant reported at 6, 12, 18 or 24 month intervals
--		i. Client worked at a paid job is missing
--			ADDED TO THIS VALIDATION
--		AND
--		iii.  Client worked at a paid job is Yes
--				and number of months working is missing
---------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	------,CLIENT_WORKING_1_WORKED_SINCE_BIRTH
	--, CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS
	, SortOrder = (Case SurveyName
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	

Into

	#DS10

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	(CLIENT_WORKING_1_WORKED_SINCE_BIRTH = 'Yes' OR CLIENT_WORKING_1_WORKED_SINCE_BIRTH is null)	----Q12 Updates <> 'No', Q13 # months cannot be null/skipped
	and CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS is null											----Q13
	and SurveyName <> 'Demographics: Pregnancy Intake'
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

---------------------------------------------------------------------------------------------------------------
--Workforce status:
--2)	Client's work history since birth of infant reported at 6, 12, 18 or 24 month intervals
--		ii. Client worked at a paid job is missing
--			and number of months is reported
---------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing, reported # months' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_WORKING_1_WORKED_SINCE_BIRTH 
	, SortOrder = (Case SurveyName
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
	
Into

	#DS11

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
 
	CLIENT_WORKING_1_WORKED_SINCE_BIRTH is null									----Q12 worked at paid job is missing 
	and CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS is not null					----Q13 # months reported
	and SurveyName <> 'Demographics: Pregnancy Intake'
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_WORKING_1_WORKED_SINCE_BIRTH'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

---------------------------------------------------------------------------------------------------------------------
----This validation is being done in Workforce 2)i.
--------Workforce status:
--------2)	Client's work history since birth of infant reported at 6, 12, 18 or 24 month intervals
--------		iii. Client worked at a paid job is yes
--------			and number of months working is missing
----This validation is being done in Workforce 2)i.

-------- NOTE Changed this to check if Client worked at a paid job since birth of infant is missing, 
--------		required field, never skipped
---------------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_WORKING_1_WORKED_SINCE_BIRTH
	, SortOrder = (Case SurveyName
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
		
Into

	#DS12

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	CLIENT_WORKING_1_WORKED_SINCE_BIRTH is null					----Q12
	and SurveyName <> 'Demographics: Pregnancy Intake'			----Demographics Updates only
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_WORKING_1_WORKED_SINCE_BIRTH'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-------------------------------------------------------------------------------------------------------------
--Income status:
--2)	Client income reported at intake, 6, 12, 18 or 24 months intervals
--		i. Income category is missing
--			NOTE:  Questioned Jolene about this, she wrote back indicating to check all parts a, b & c
-------------------------------------------------------------------------------------------------------------
---Q13a Intake/Q15a Updates
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	--, Mstr_SurveyElements.Stimulus as Question2
	, CASE 
		WHEN (CLIENT_INCOME_SOURCES is null AND CLIENT_INCOME_1_HH_SOURCES is null)
			OR (CLIENT_INCOME_AMOUNT is null AND CLIENT_INCOME_0_HH_INCOME is null) 
			OR CLIENT_INCOME_IN_KIND is null 
				THEN source.Stimulus 	
				ELSE ''
	END Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_INCOME_SOURCES 
	, SortOrder = (Case SurveyName
					When 'Demographics: Pregnancy Intake' Then
						0
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
	
Into

	#DS13a

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	(CLIENT_INCOME_SOURCES is null AND CLIENT_INCOME_1_HH_SOURCES is null) 				----Q13a Intake/Q15a Updates 
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_INCOME_SOURCES'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'


Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
----------------------------------------------------------------------------
----Q13b Intake/Q15b Updates 
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question2
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	----,CLIENT_INCOME_AMOUNT 
	, SortOrder = (Case SurveyName
					When 'Demographics: Pregnancy Intake' Then
						0
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
	
Into

	#DS13b

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	(CLIENT_INCOME_AMOUNT is null AND CLIENT_INCOME_0_HH_INCOME is null)		----Q13b Intake/Q15b Updates 
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_INCOME_AMOUNT'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'


Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
--------------------------------------------------------------------------------------
----Q13c Intake/Q15c Updates 
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question2
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	----,CLIENT_INCOME_IN_KIND  
	, SortOrder = (Case SurveyName
					When 'Demographics: Pregnancy Intake' Then
						0
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
	
Into

	#DS13c

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	CLIENT_INCOME_IN_KIND is null									----Q13c Intake/Q15c Updates 
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_INCOME_IN_KIND'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'


Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

---------------------------------------------------------------------------------------------------------------
--Income status:
--2)	Client income reported at intake, 6, 12, 18 or 24 months intervals
--		ii. Client qualifies for TANF, Medicaid, WIC or Food Stamps are missing.
---------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	----,CLIENT_INCOME_AMOUNT
	--, CLIENT_INCOME_1_LOW_INCOME_QUALIFY
	, SortOrder = (Case SurveyName
					When 'Demographics: Pregnancy Intake' Then
						0
					When 'Demographics Update: Infancy 6 Months' then
						1
					When 'Demographics Update: Infancy 12 Months' then
						2
					When 'Demographics Update: Toddler 18 Months' then
						3
					When 'Demographics Update: Toddler 24 Months' then
						4
					Else
						5
					End)
	, SortOrder2 = source.SequenceOrder	
	
Into

	#DS14

From

	Demographics_Survey
	inner join #DS_ActiveClientlimit on #DS_ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	CLIENT_INCOME_1_LOW_INCOME_QUALIFY is null								----Q13 Intake/Q15 Updates qualify for TANF/Medicaid/etc., cannot be null/skipped
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_INCOME_1_LOW_INCOME_QUALIFY'
	and ProgramName = @Team
	and SurveyName NOT LIKE '%MASTER%'

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------
--Union All
---------------

Select * from #DS1 
Union all
Select * from #DS2 
Union all
Select * from #DS3c 
Union all
Select * from #DS4 
Union all
Select * from #DS5  
Union all
Select * from #DS6 
Union all
Select * from #DS7 
Union all
Select * from #DS8 
Union all
Select * from #DS9 
Union all
Select * from #DS10 
Union all
Select * from #DS11 
Union all
Select * from #DS12 
Union all
Select * from #DS13a
Union all
Select * from #DS13b 
Union all
Select * from #DS13c
Union all
Select * from #DS14 

Order by ProgramName, Client, SortOrder, SortOrder2

-----------------------------------------------------------------------------------------
--Clean Up
---------------

Drop Table #DS1
Drop Table #DS2
Drop Table #DS3a Drop Table #DS3b Drop Table #DS3c
Drop Table #DS4
Drop Table #DS5
Drop Table #DS6
Drop Table #DS7
Drop Table #DS8
Drop Table #DS9
Drop Table #DS10
Drop Table #DS11
Drop Table #DS12
Drop Table #DS13a
Drop Table #DS13b
Drop Table #DS13c
Drop Table #DS14

Drop Table #DS_ActiveClientlimit
GO
