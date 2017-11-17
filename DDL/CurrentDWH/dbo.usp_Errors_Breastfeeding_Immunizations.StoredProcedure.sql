USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Errors_Breastfeeding_Immunizations]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Errors_Breastfeeding_Immunizations]

@Team varchar(4000)

AS

--------------------------------------------------------------------------------
-- Limit of data by active client after date of CIS to STO conversion
---------------------------------------------------------------------
Select distinct(CLID) as 'CLID'
Into #ActiveClientlimit
From EnrollmentAndDismissal
inner join dbo.Home_Visit_Encounter_Survey on Home_Visit_Encounter_Survey.CL_EN_GEN_ID = EnrollmentAndDismissal.CLID
Where (EndDate > '2011-11-01') or (EndDate is null)

--Select * From #ActiveClientlimit

--drop table #ActiveClientlimit

--	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
--1)Report of Breastfeeding – Infant Birth (IB) form: i. Infant date of birth is not reported.
---------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, INFANT_BIRTH_0_DOB
	, SortOrder = 0
	
Into

	#BF1

From

	Infant_Birth_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Infant_Birth_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Infant_Birth_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Infant_Birth_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Infant_Birth_Survey.SurveyID

Where
  
	INFANT_BIRTH_0_DOB is null
	and Pseudonym = 'INFANT_BIRTH_0_DOB'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Stimulus 

---------------------------------------------------------------------------------------------------------------
--1)Report of Breastfeeding – Infant Birth (IB) form: ii. Infant date of birth for index child is reported and child ever received breast milk is missing.
----------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, INFANT_BREASTMILK_0_EVER_BIRTH
	, SortOrder = 0
	
Into

	#BF2

From

	Infant_Birth_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Infant_Birth_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Infant_Birth_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Infant_Birth_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Infant_Birth_Survey.SurveyID

Where
  
	INFANT_BIRTH_0_DOB is not null
	and INFANT_BREASTMILK_0_EVER_BIRTH is null
	and Pseudonym = 'INFANT_BREASTMILK_0_EVER_BIRTH'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Stimulus 

---------------------------------------------------------------------------------------------------------------
--1)Report of Breastfeeding – Infant Health Care (IHC) form: i. Infant date of birth is not reported.
-- Added this one myself... check was being done on IB and should also be done on IHC
-----------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, INFANT_BIRTH_0_DOB
	, SortOrder = (Case SurveyName
	
					When 'Infant Health Care-Infancy 6 Months' then
						1
					When 'Infant Health Care: Infancy 12 Months' then
						2
					When 'Infant Health Care: Toddler 18 Months' then
						3
					When 'Infant Health Care: Toddler 24 Months' then
						4
					Else
						5
					End)
	
Into

	#BF3

From

	Infant_Health_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Infant_Health_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Infant_Health_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Infant_Health_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Infant_Health_Survey.SurveyID

Where
  
	INFANT_BIRTH_0_DOB is null
	and Pseudonym = 'INFANT_BIRTH_0_DOB'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Stimulus 

---------------------------------------------------------------------------------------------------------------
--2)	Report of Breastfeeding – Infant Health Care (IHC) form submitted for 6, 12, 18 and 24 month intervals
--		i. Has child ever received breast milk is missing
---------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, INFANT_BREASTMILK_0_EVER_BIRTH
	, SortOrder = (Case SurveyName
	
					When 'Infant Health Care-Infancy 6 Months' then
						1
					When 'Infant Health Care: Infancy 12 Months' then
						2
					When 'Infant Health Care: Toddler 18 Months' then
						3
					When 'Infant Health Care: Toddler 24 Months' then
						4
					Else
						5
					End)
	
Into

	#BF4

From

	Infant_Health_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Infant_Health_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Infant_Health_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Infant_Health_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Infant_Health_Survey.SurveyID

Where
  
	INFANT_BREASTMILK_0_EVER_IHC is null
	and Pseudonym = 'INFANT_BREASTMILK_0_EVER_IHC'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Stimulus 

-----------------------------------------------------------------------------------------
--2)	Report of Breastfeeding – Infant Health Care (IHC) form submitted for 6, 12, 18 and 24 month intervals
--		iii. Child has ever received breast milk on submitted IB form 
--			 and all IHC forms submitted do not indicate child ever received breast milk.
---------------------------------------------------
----begin #BF5a

---take ALL of the IBS and IHS survey records and sort by client/infant id/interval
SELECT IBSAndIHS.*
	----this row number is needed to match curr to prev recs, below, because the SortOrder skips when an interval is not present
	----causing the rows not to match properly
	,ROW_NUMBER() OVER(PARTITION BY IBSAndIHS.Client, IBSAndIHS.InfantID ORDER BY IBSAndIHS.SortOrder) RowNumber

INTO #BF5a

FROM
(	----combine ALL the infant birth and infant health records
	SELECT 
		 ibs.ProgramID
		, ibs.CL_EN_GEN_ID Client
		, REPLACE(INFANT_0_ID_NSO,'-','') InfantID	----sometimes the infant id has a dash in it, most of the time it does not, remove for sorting in later step
		, ibs.SurveyID
		, ibs.SurveyDate
		, ms.SurveyName
		, CASE WHEN ibs.INFANT_BREASTMILK_0_EVER_BIRTH = 'Yes' THEN 1 ELSE 0 END BreastmilkEver	----flag anything not yes as 0 (No, NULL, etc.)
		, SortOrder = 0
		, Pseudonym = 'INFANT_BREASTMILK_0_EVER_BIRTH'
	FROM Infant_Birth_Survey ibs
		INNER JOIN #ActiveClientlimit on #ActiveClientlimit.CLID = ibs.CL_EN_GEN_ID	----remove inactive clients
		LEFT JOIN Mstr_surveys ms on ms.SurveyID = ibs.SurveyID
	WHERE 	ibs.CL_EN_GEN_ID IS NOT NULL											----remove surveys where client id is blank
		AND ibs.ProgramID IS NOT NULL												----remove where no program id

	UNION ALL

	SELECT 
		 ihs.ProgramID
		, ihs.CL_EN_GEN_ID Client
		, REPLACE(INFANT_0_ID_NSO,'-','') InfantID	----sometimes the infant id has a dash in it, most of the time it does not, remove for sorting in later step
		, ihs.SurveyID
		, ihs.SurveyDate
		, ms.SurveyName
		, CASE WHEN ihs.INFANT_BREASTMILK_0_EVER_IHC = 'Yes' THEN 1 ELSE 0 END BreastmilkEver	----flag anything not yes as 0 (No, NULL, etc.)
		, SortOrder = (Case ms.SurveyName
				When 'Infant Health Care-Infancy 6 Months' then
					1
				When 'Infant Health Care: Infancy 12 Months' then
					2
				When 'Infant Health Care: Toddler 18 Months' then
					3
				When 'Infant Health Care: Toddler 24 Months' then
					4
				Else
					5
				End)
		, Pseudonym = 'INFANT_BREASTMILK_0_EVER_IHC'
	FROM Infant_Health_Survey ihs 
		INNER JOIN #ActiveClientlimit on #ActiveClientlimit.CLID = ihs.CL_EN_GEN_ID	----remove inactive clients
		LEFT JOIN Mstr_surveys ms on ms.SurveyID = ihs.SurveyID
	WHERE 	ihs.CL_EN_GEN_ID IS NOT NULL											----remove surveys where client id is blank
		AND ihs.ProgramID IS NOT NULL												----remove where no program id
	
)IBSAndIHS

---- end #BF5a
----------------------------------------------------	
---- begin #BF5b	

----match line up/join the survey records so that the current record is joined to the previous record
----in order to compare and decide if a 'yes' has changed to something else in a subsequent interval
SELECT 
	curr.ProgramID
	,curr.Client
	,curr.InfantID
	,curr.SurveyID
	,curr.SurveyName
	,curr.SurveyDate	
	,curr.BreastmilkEver 	
	,curr.SortOrder 
	,curr.RowNumber 
	,curr.Pseudonym
	----only do compare if there is a previous record
	,CASE WHEN prev.Client IS NOT NULL 
		THEN----only do compare if same client/infant (there could be more than one infant per client)
			CASE WHEN curr.Client = prev.Client AND curr.InfantID = prev.InfantID
				THEN
					CASE WHEN curr.BreastmilkEver < prev.BreastmilkEver	
						THEN 1	----answer changed from a yes to something else in subsequent interval, flag this record
						ELSE 0	----answer stayed same or changed from something else to yes, this is okay
					END
			END
		ELSE 0	---no more values to compare		
	END PrevAnswerWasYes
	
INTO #BF5b

FROM #BF5a curr																
	 LEFT JOIN #BF5a prev ON (prev.Client = curr.Client						----same client, curr & prev
								AND prev.InfantID = curr.InfantID			----same child, curr & prev
								AND prev.RowNumber  = curr.RowNumber - 1)	----lines up current to previous record

---- end #BF5b
----------------------------------------------------	
---- begin #BF5c

----join/display the flagged records of active clients to the program/survey tables
Select
 
	ProgramName
	, IBIHSurveys.Client
	--, IBIHSurveys.InfantID
	, IBIHSurveys.SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Prev interval yes, this interval not yes' as Error
	, Convert(varchar(8),IBIHSurveys.SurveyDate,1) as SurveyDate
	--, IBIHSurveys.PrevAnswerWasYes 
	, IBIHSurveys.SortOrder 
							
Into

	#BF5c

From

	#BF5b IBIHSurveys
	------>>inner join #ActiveClientlimit on #ActiveClientlimit.CLID = IBIHSurveys.Client---->> this join to active clients done in #BF5a, above
	left join Mstr_surveys on Mstr_surveys.SurveyID = IBIHSurveys.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = IBIHSurveys.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = IBIHSurveys.SurveyID

Where
  
	IBIHSurveys.PrevAnswerWasYes = 1							----IBS Q8 or IHS Q12 ever breastmilk changed from yes to something else in subsequent interval
	and Mstr_SurveyElements.Pseudonym = IBIHSurveys.Pseudonym	----this will be ibs.INFANT_BREASTMILK_0_EVER_BIRTH or ihs.INFANT_BREASTMILK_0_EVER_IHC
	and ProgramName = @Team

Order by

	ProgramName
	, IBIHSurveys.Client
	, IBIHSurveys.SortOrder
	, Stimulus 

-----------------------------------------------------------------------------------------
--2)	Report of Breastfeeding – Infant Health Care (IHC) form submitted for 6, 12, 18 and 24 month intervals
--		iv. Child has received breast milk on submitted IHC form(s) and does your baby continue to get breast milk is missing.
--------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, INFANT_BREASTMILK_1_CONT
	, SortOrder = (Case SurveyName
	
					When 'Infant Health Care-Infancy 6 Months' then
						1
					When 'Infant Health Care: Infancy 12 Months' then
						2
					When 'Infant Health Care: Toddler 18 Months' then
						3
					When 'Infant Health Care: Toddler 24 Months' then
						4
					Else
						5
					End)
	
Into

	#BF7

From

	Infant_Health_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Infant_Health_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Infant_Health_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Infant_Health_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Infant_Health_Survey.SurveyID

Where
  
	INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
	and INFANT_BREASTMILK_1_CONT is null
	and Pseudonym = 'INFANT_BREASTMILK_1_CONT'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Stimulus 
-----------------------------------------------------------------------------------------
-- 2)	Report of Breastfeeding – Infant Health Care (IHC) form submitted for 6, 12, 18 and 24 month intervals
--		v. Child has received breast milk on submitted IHC form(s) and age of baby when breast feeding stopped is missing.
---------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, '14. Specify - Number of weeks:' as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, INFANT_BREASTMILK_1_WEEK_STOP
	, SortOrder = (Case SurveyName
	
					When 'Infant Health Care-Infancy 6 Months' then
						1
					When 'Infant Health Care: Infancy 12 Months' then
						2
					When 'Infant Health Care: Toddler 18 Months' then
						3
					When 'Infant Health Care: Toddler 24 Months' then
						4
					Else
						5
					End)
	
Into

	#BF8

From

	Infant_Health_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Infant_Health_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Infant_Health_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Infant_Health_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Infant_Health_Survey.SurveyID

Where
  
	INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
	and INFANT_BREASTMILK_1_CONT = 'No'
	and INFANT_BREASTMILK_1_AGE_STOP <> 'Less than one week'
	and INFANT_BREASTMILK_1_WEEK_STOP is null
	and Pseudonym = 'INFANT_BREASTMILK_1_WEEK_STOP'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Stimulus 
-----------------------------------------------------------------------------------------
--2)	Report of Breastfeeding – Infant Health Care (IHC) form submitted for 6, 12, 18 and 24 month intervals
--		vi. Child has received breast milk on submitted IHC form(s) and last age baby was fed exclusively breast milk is missing
---------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, INFANT_BREASTMILK_1_AGE_STOP
	, SortOrder = (Case SurveyName
	
					When 'Infant Health Care-Infancy 6 Months' then
						1
					When 'Infant Health Care: Infancy 12 Months' then
						2
					When 'Infant Health Care: Toddler 18 Months' then
						3
					When 'Infant Health Care: Toddler 24 Months' then
						4
					Else
						5
					End)
	
Into

	#BF9

From

	Infant_Health_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Infant_Health_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Infant_Health_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Infant_Health_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Infant_Health_Survey.SurveyID

Where
  
	INFANT_BREASTMILK_0_EVER_IHC = 'Yes'
	and INFANT_BREASTMILK_1_CONT = 'No'
	and INFANT_BREASTMILK_1_AGE_STOP is null
	and Pseudonym = 'INFANT_BREASTMILK_1_AGE_STOP'
	and ProgramName = @Team
	
Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Stimulus 
-----------------------------------------------------------------------------------------
--3)	Report of Child’s Immunization status reported at 6, 12, 18 and 24 month intervals.
--		i. Child up to date on all vaccinations is missing.
----------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
--	, INFANT_HEALTH_IMMUNIZ_0_UPDATE
	, SortOrder = (Case SurveyName
	
					When 'Infant Health Care-Infancy 6 Months' then
						1
					When 'Infant Health Care: Infancy 12 Months' then
						2
					When 'Infant Health Care: Toddler 18 Months' then
						3
					When 'Infant Health Care: Toddler 24 Months' then
						4
					Else
						5
					End)
	
Into

	#BF10

From

	Infant_Health_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Infant_Health_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Infant_Health_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Infant_Health_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Infant_Health_Survey.SurveyID

Where
  
	INFANT_HEALTH_IMMUNIZ_0_UPDATE is null
	and Pseudonym = 'INFANT_HEALTH_IMMUNIZ_0_UPDATE'
	and ProgramName = @Team
	
Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Stimulus 
-----------------------------------------------------------------------------------------
--3)	Report of Child’s Immunization status reported at 6, 12, 18 and 24 month intervals.
--		ii. Immunization status based on written record or mothers self-report is missing.
---------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
--	, INFANT_HEALTH_IMMUNIZ_1_RECORD
	, SortOrder = (Case SurveyName
	
					When 'Infant Health Care-Infancy 6 Months' then
						1
					When 'Infant Health Care: Infancy 12 Months' then
						2
					When 'Infant Health Care: Toddler 18 Months' then
						3
					When 'Infant Health Care: Toddler 24 Months' then
						4
					Else
						5
					End)
	
Into

	#BF11

From

	Infant_Health_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Infant_Health_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Infant_Health_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Infant_Health_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Infant_Health_Survey.SurveyID

Where
  
	INFANT_HEALTH_IMMUNIZ_1_RECORD is null
	and Pseudonym = 'INFANT_HEALTH_IMMUNIZ_1_RECORD'
	and ProgramName = @Team
	
Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Stimulus
-----------------------------------------------------------------------------------------
--3)	Report of Child’s Immunization status reported at 6, 12, 18 and 24 month intervals.
--		iii. Child is up to date on all vaccinations and immunization status based on written record or mothers self-report is missing.
--------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
--	, INFANT_HEALTH_IMMUNIZ_1_RECORD
	, SortOrder = (Case SurveyName
	
					When 'Infant Health Care-Infancy 6 Months' then
						1
					When 'Infant Health Care: Infancy 12 Months' then
						2
					When 'Infant Health Care: Toddler 18 Months' then
						3
					When 'Infant Health Care: Toddler 24 Months' then
						4
					Else
						5
					End)
	
Into

	#BF12

From

	Infant_Health_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Infant_Health_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Infant_Health_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Infant_Health_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Infant_Health_Survey.SurveyID

Where
  
	INFANT_HEALTH_IMMUNIZ_0_UPDATE is not null
	and	INFANT_HEALTH_IMMUNIZ_1_RECORD is null
	and Pseudonym = 'INFANT_HEALTH_IMMUNIZ_1_RECORD'
	and ProgramName = @Team
	
Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Stimulus
-----------------------------------------------------------------------------------------
--Union All
---------------

Select * from #BF1
Union all
Select * from #BF2
Union all
Select * from #BF3
Union all
Select * from #BF4
Union all
Select * from #BF5c
Union all
Select * from #BF7
Union all
Select * from #BF8
Union all
Select * from #BF9
Union all
Select * from #BF10
Union all
Select * from #BF11
Union all
Select * from #BF12
Order by ProgramName, Client,SortOrder

-----------------------------------------------------------------------------------------
--Clean Up
---------------
Drop Table #BF1
Drop Table #BF2
Drop Table #BF3
Drop Table #BF4
Drop Table #BF5a  Drop Table #BF5b  Drop Table #BF5c
Drop Table #BF7
Drop Table #BF8
Drop Table #BF9
Drop Table #BF10
Drop Table #BF11
Drop Table #BF12
Drop Table #ActiveClientlimit
GO
