USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Errors_Demo_Survey_Sub_Preg]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_Errors_Demo_Survey_Sub_Preg]

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
---------------------------------------------------------------------------------


Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_SUBPREG_0_BEEN_PREGNANT
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
	
Into

	#SP1

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT is null
	and SurveyName not like '%intake%'
	and Pseudonym = 'CLIENT_SUBPREG_0_BEEN_PREGNANT'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder, Stimulus 

---------------------------------------------------------------------------------------------------------------

Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, '21. a. Month Subsequent Pregnancy Began' as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
 	--, CLIENT_SUBPREG_0_BEEN_PREGNANT
 	--, CLIENT_SUBPREG_1_BEGIN_MONTH

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
	
Into

	#SP2a1

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	--left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes'
	and CLIENT_SUBPREG_1_BEGIN_MONTH is null
	and SurveyName not like '%intake%'
	--and Pseudonym = 'CLIENT_SUBPREG_1_BEGIN_MONTH'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder

---------------------------------------------------------------------------------------------------------------

Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, '21. a. Year Subsequent Pregnancy Began' as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
 	--, CLIENT_SUBPREG_0_BEEN_PREGNANT
	--, CLIENT_SUBPREG_1_BEGIN_YEAR


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
	
Into

	#SP2a2

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	--left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes'
	and CLIENT_SUBPREG_1_BEGIN_YEAR is null
	and SurveyName not like '%intake%'
	--and Pseudonym = 'CLIENT_SUBPREG_1_BEGIN_YEAR'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder

-----------------------------------------------------------------------------------------------------------

Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, '21. ' + Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
 	--, CLIENT_SUBPREG_0_BEEN_PREGNANT
	--, CLIENT_SUBPREG_1_PLANNED

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
	
Into

	#SP2b

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes'
	and CLIENT_SUBPREG_1_PLANNED is null
	and SurveyName not like '%intake%'
	and Pseudonym = 'CLIENT_SUBPREG_1_PLANNED'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder, Stimulus 

-----------------------------------------------------------------------------------------------------------

Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, '21. ' + Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_SUBPREG_1_OUTCOME
	
	
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
	
Into

	#SP2c

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'YES'
	and CLIENT_SUBPREG_1_OUTCOME is null
	and SurveyName not like '%intake%'
	and Pseudonym = 'CLIENT_SUBPREG_1_OUTCOME'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder, Stimulus 

---------------------------------------------------------------------------------------------------------

Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, '22. a. Date of Birth for Subsequent Pregnancy' as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_SECOND_0_CHILD_DOB
	
	
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
	
Into

	#SP3a1

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	--left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'YES'
	and CLIENT_SUBPREG_1_OUTCOME = 'Live Birth'
	and CLIENT_SECOND_0_CHILD_DOB is null
	and SurveyName not like '%intake%'
	--and Pseudonym = 'CLIENT_SECOND_0_CHILD_DOB'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder

-------------------------------------------------------------------------------------------------------------

Select

	ProgramName
	, Demographics_Survey.CL_EN_GEN_ID as Client
	, SurveyName
	, '22. a. Date of Birth for Subsequent Pregnancy' as Question
	, 'Date of Birth for Subsequent Pregnancy before Index Date of Birth' as Error
	, Convert(varchar(8),Demographics_Survey.SurveyDate,1) as SurveyDate
	--, INFANT_BIRTH_0_DOB
	--, CLIENT_SECOND_0_CHILD_DOB
	
	
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
	
Into

	#SP3a2
	


From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	--left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join Infant_Birth_Survey on Infant_Birth_Survey.CL_EN_GEN_ID = Demographics_Survey.CL_EN_GEN_ID


Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'YES'
	and CLIENT_SUBPREG_1_OUTCOME is null
	and SurveyName not like '%intake%'
	and  INFANT_BIRTH_0_DOB > CLIENT_SECOND_0_CHILD_DOB
	and ProgramName = @Team

Order by

	ProgramName, Demographics_Survey.CL_EN_GEN_ID, SortOrder

-------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, '22. b. Gender of Subsequent Pregnancy' as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_SECOND_1_CHILD_GENDER
	
	
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
	
Into

	#SP3a3

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	--left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'YES'
	and CLIENT_SUBPREG_1_OUTCOME = 'Live Birth'
	and CLIENT_SECOND_1_CHILD_GENDER is null
	and SurveyName not like '%intake%'
	--and Pseudonym = 'CLIENT_SECOND_1_CHILD_GENDER'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder 

----------------------------------------------------------------------------------------------------------------

Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, '22. c. Birth Weight for Subsequent Pregnancy' as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_SECOND_1_CHILD_BW_POUNDS
	--, CLIENT_SECOND_1_CHILD_BW_OZ
	
	
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
	
Into

	#SP3a4

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	--left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'YES'
	and CLIENT_SUBPREG_1_OUTCOME = 'Live Birth'
	and CLIENT_SECOND_1_CHILD_BW_POUNDS is null
	and SurveyName not like '%intake%'
	--and Pseudonym = 'CLIENT_SECOND_1_CHILD_BW_POUNDS'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder

-------------------------------------------------------------------------------------------------------------

Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, '22. ' + Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_SECOND_1_CHILD_NICU
	
	
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
	
Into

	#SP3b1

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'YES'
	and CLIENT_SUBPREG_1_OUTCOME = 'Live Birth'
	and CLIENT_SECOND_1_CHILD_NICU is null
	and SurveyName not like '%intake%'
	and Pseudonym = 'CLIENT_SECOND_1_CHILD_NICU'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder, Stimulus 

---------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, '22. ' + Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_SECOND_1_CHILD_NICU_DAYS
	
	
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
	
Into

	#SP3b2

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'YES'
	and CLIENT_SUBPREG_1_OUTCOME = 'Live Birth'
	and CLIENT_SECOND_1_CHILD_NICU = 'Yes'
	and CLIENT_SECOND_1_CHILD_NICU_DAYS is null
	and SurveyName not like '%intake%'
	and Pseudonym = 'CLIENT_SECOND_1_CHILD_NICU_DAYS'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder, Stimulus 

----------------------------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Stimulus as Question
	, '22. d. Not in NICU but has days listed' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_SECOND_1_CHILD_NICU
	--, CLIENT_SECOND_1_CHILD_NICU_DAYS
	
	
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
	
Into

	#SP3b3

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'YES'
	and CLIENT_SUBPREG_1_OUTCOME = 'Live Birth'
	and CLIENT_SECOND_1_CHILD_NICU = 'No'
	and (CLIENT_SECOND_1_CHILD_NICU_DAYS is not null and  CLIENT_SECOND_1_CHILD_NICU_DAYS > 0)
	and SurveyName not like '%intake%'
	and Pseudonym = 'CLIENT_SECOND_1_CHILD_NICU_DAYS'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder, Stimulus 

------------------------------------------------------------------------------------------------------------------

Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	--, Stimulus as Question
	--, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	, CLIENT_SECOND_1_CHILD_BW_POUNDS
	, (CLIENT_SECOND_1_CHILD_BW_POUNDS * 16) as LbstoOz
	, CLIENT_SECOND_1_CHILD_BW_OZ
	, ((CLIENT_SECOND_1_CHILD_BW_POUNDS * 16) + CLIENT_SECOND_1_CHILD_BW_OZ) as WeightinOz
	, (((CLIENT_SECOND_1_CHILD_BW_POUNDS * 16) + CLIENT_SECOND_1_CHILD_BW_OZ)* 28.3495) as WeightinGrams
	
	
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
	
Into

	#SP4aprep

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	--left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'YES'
	and CLIENT_SUBPREG_1_OUTCOME = 'Live Birth'
	and CLIENT_SECOND_1_CHILD_BW_POUNDS is not null
	and CLIENT_SECOND_1_CHILD_BW_OZ is not null
	and SurveyName not like '%intake%'
	--and Pseudonym = 'CLIENT_SUBPREG_1_OUTCOME'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder
---------------------------------------------------

Select

	ProgramName
	, Client
	, SurveyName
	, '22. c. Infant Birth Weight: Pounds, OZ' Question
	--, WeightinGrams
	, Error = (Case 
				When WeightinGrams < 1201 then
				'Birth Weight Low - review weight'
				When WeightinGrams > 7999 then
				'Birth Weight High - review weight'				
				end)
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	, SortOrder
	
into #SP4a
from #SP4aprep
Where ((WeightinGrams < 1201) or (WeightinGrams > 7999))
and ProgramName = @Team 

--------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------
--Date prep

Select

	SurveyResponseID
	, MonthNum = (Case CLIENT_SUBPREG_1_BEGIN_MONTH
					when 'January' then
					'01'
					when 'February' then
					'02'
					when 'March' then
					'03'
					when 'April' then
					'04'
					when 'May' then
					'07'
					when 'June' then
					'06'
					when 'July' then
					'07'
					when 'August' then
					'08'
					when 'September' then
					'09'
					when 'October' then
					'10'
					when 'November' then
					'11'
					when 'December' then
					'12'
					end)
	
Into

	#SP5aMN

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	--left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'YES'
	and CLIENT_SUBPREG_1_OUTCOME ='Live Birth'
	and (CLIENT_SUBPREG_1_BEGIN_MONTH is not null and CLIENT_SUBPREG_1_BEGIN_YEAR is not null)
	and CLIENT_SECOND_0_CHILD_DOB is not null
	and SurveyName not like '%intake%'
--	and Pseudonym = 'CLIENT_SUBPREG_1_OUTCOME'
	

------------------------------------------------------------------


Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	--, Stimulus as Question
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	, CLIENT_SUBPREG_1_OUTCOME
	, CLIENT_SUBPREG_1_BEGIN_MONTH
	, CLIENT_SUBPREG_1_BEGIN_YEAR
	, CLIENT_SECOND_0_CHILD_DOB
	, SubPregBegin = Convert(Datetime,((CLIENT_SUBPREG_1_BEGIN_YEAR)+'-'+ (MonthNum) +'-'+ ('01')),101)
	, datediff(wk,(Convert(Datetime,((CLIENT_SUBPREG_1_BEGIN_YEAR)+'-'+ (MonthNum) +'-'+ ('01')),101)),CLIENT_SECOND_0_CHILD_DOB) as AgeinWeeks
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
	
Into

	#SP5aprep

From

	Demographics_Survey
	inner join #ActiveClientlimit on #ActiveClientlimit.CLID = Demographics_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Demographics_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Demographics_Survey.ProgramID
	--left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Demographics_Survey.SurveyID
	left join #SP5aMN on #SP5aMN.SurveyResponseID  = Demographics_Survey.SurveyResponseID

Where
  
	CLIENT_SUBPREG_0_BEEN_PREGNANT = 'YES'
	and CLIENT_SUBPREG_1_OUTCOME ='Live Birth'
	and (CLIENT_SUBPREG_1_BEGIN_MONTH is not null and CLIENT_SUBPREG_1_BEGIN_YEAR is not null)
	and CLIENT_SECOND_0_CHILD_DOB is not null
	and SurveyName not like '%intake%'
	--and Pseudonym = 'CLIENT_SUBPREG_1_OUTCOME'
	and ProgramName = @Team

Order by

	ProgramName, CL_EN_GEN_ID, SortOrder 
	

---------------------------------------------------

Select

	ProgramName
	, Client
	, SurveyName
	, 'Gestational Age at Birth: Begin Month, Begin Year, Child DOB' as Question
	--, CLIENT_SUBPREG_1_BEGIN_MONTH
	--, CLIENT_SUBPREG_1_BEGIN_YEAR
	--, CLIENT_SECOND_0_CHILD_DOB
	--, SubPregBegin
	--, AgeinWeeks
	, Error = (Case 
				When AgeinWeeks < 25 then
				'Early Birth - review dates'
				When AgeinWeeks > 43 then
				'Late Birth - review dates'				
				end)
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	, SortOrder
	
into #SP5a
from #SP5aprep
Where ((AgeinWeeks < 25) or (AgeinWeeks > 43))
and ProgramName = @Team 

-----------------------------------------------------------------------------------------------------------
-- Union All
------------

Select * from #SP1
Union all
Select * from #SP2a1
Union all
Select * from #SP2a2
Union all
Select * from #SP2b
Union all
Select * from #SP2c
Union all
Select * from #SP3a1
Union all
Select * from #SP3a2
Union all
Select * from #SP3a3
Union all
Select * from #SP3a4
Union all
Select * from #SP3b1
Union all
Select * from #SP3b2
Union all
Select * from #SP3b3
Union all
Select * from #SP4a
Union all
Select * from #SP5a
Order by ProgramName, Client,SortOrder


------------------------------------------------------------------------------------------------------
--Clean up
drop table #SP5a
drop table #SP5aprep
drop table #SP5aMN
drop table #SP1
drop table #SP4a
drop table #SP4aprep
drop table #SP3b3
drop table #SP3b2
drop table #SP3b1
drop table #SP3a4
drop table #SP3a3
drop table #SP3a2
drop table #SP3a1
drop table #SP2c
drop table #SP2b
drop table #SP2a2
drop table #SP2a1
drop table #ActiveClientlimit

GO
