USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Errors_RelationshipAssessment]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Errors_RelationshipAssessment]

@Team varchar(4000)

AS

--------------------------------------------------------------------------------
-- Limit of data by active client after date of CIS to STO conversion
---------------------------------------------------------------------
Select distinct(CLID) as 'CLID'
Into #RA_ActiveClientlimit
From EnrollmentAndDismissal
inner join dbo.Home_Visit_Encounter_Survey on Home_Visit_Encounter_Survey.CL_EN_GEN_ID = EnrollmentAndDismissal.CLID
Where (EndDate > '2011-11-01') or (EndDate is null)

--Select * From #RA_ActiveClientlimit

--drop table #RA_ActiveClientlimit

--	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
--1)	Relationship Assessment - Pregnancy – Intake 
--		i.	Ever been emotionally or physically abused by your partner, ex-partner, boyfriend 
--			or ex-boyfriend is missing.
--------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA1

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	and CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER is null								----Q1 
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
----		ii.	Within the last year, have you been hit, slapped, kicked or otherwise physically hurt by your partner,
----			ex-partner, boyfriend or ex-boyfriend’ is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_HIT_0_SLAP_PARTNER
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA2

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	and CLIENT_ABUSE_HIT_0_SLAP_PARTNER is null								----Q2 
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_HIT_0_SLAP_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
--		ii.	a.	Reported no to Within the last year, have you been hit, slapped, kicked or otherwise physically 
--				hurt by your partner, ex-partner, boyfriend or ex-boyfriend 
--				AND Within the last year, has your partner,	ex-partner, boyfriend or ex-boyfriend 
--				forced you to have sexual relations is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_FORCED_0_SEX
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA3

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	------and CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'No'  ----commented out because CLIENT_ABUSE_FORCED_0_SEX can never be null
	and CLIENT_ABUSE_FORCED_0_SEX is null								----Q9 
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_FORCED_0_SEX'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
	
-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
--		ii.	a.	1.	Reported no to Within the last year, has your partner, ex-partner, boyfriend or ex-boyfriend 
--					forced you to have sexual relations 
--					AND response to ‘Since your pregnancy began, have you been hit, slapped, kicked, or otherwise 
--					physically hurt by your partner, ex-partner, boyfriend or ex-boyfriend’ is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA4

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	--------and CLIENT_ABUSE_FORCED_0_SEX = 'No'  ----commented out because CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME can never be null
	and CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME is null							----Q11 
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
	
-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
--		ii.	b.	Reported no to ‘Since your pregnancy began, have you been hit, slapped, kicked, or otherwise 
--				physically hurt by your partner, ex-partner, boyfriend or ex-boyfriend?’ 
--				AND ‘Are you afraid of your partner, ex-partner, boyfriend or ex-boyfriend?‘ is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_AFRAID_0_PARTNER
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA5

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	--------and CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'No' ----commented out because CLIENT_ABUSE_AFRAID_0_PARTNER can never be null
	and CLIENT_ABUSE_AFRAID_0_PARTNER is null								----Q13 
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_AFRAID_0_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
	
-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
--		iii.  In the last year, number of times client was physically hurt in the last year is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_TIMES_0_HURT_LAST_YR
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA6

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	and (CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER IS NULL)	----Q2 not NO, Q3 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_HURT_LAST_YR is null												----Q3
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_HURT_LAST_YR'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
--		iv.	In the last year, number of times partner, ex-partner, boyfriend or ex-boyfriend slap 
--			or push you is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA7

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	and (CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER IS NULL)	----Q2 not NO, Q4 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER is null											----Q4
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
--		v.	In the last year, number of times partner, ex-partner, boyfriend or ex-boyfriend, punch, 
--			kick or cut you is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA8

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	and (CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER IS NULL)	----Q2 not NO, Q5 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER is null											----Q5
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
	
-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
--		vi.	In the last year, number of times partner, ex-partner, boyfriend or ex-boyfriend do something 
--			that burned you, severely bruised you, or broke a bone is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA9

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	and (CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER IS NULL)	----Q2 not NO, Q6 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER is null										----Q6
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
	
-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
--		vii.	In the last year, number of times partner, ex-partner, boyfriend or ex-boyfriend cause you 
--				to have a head, internal, or permanent injury is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA10

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	and (CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER IS NULL)	----Q2 not NO, Q7 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER is null									----Q7
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
	
-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
--		viii.	In the last year, number of times in the last year did your partner, ex-partner, boyfriend 
--				or ex-boyfriend use a weapon to hurt you is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA11

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	and (CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER IS NULL)	----Q2 not NO, Q8 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER is null										----Q8
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
--		ix.	In the last year, number of times client was forced to have sexual relations is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_FORCED_1_SEX_LAST_YR
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	

Into

	#RA12

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	and (CLIENT_ABUSE_FORCED_0_SEX = 'Yes' OR CLIENT_ABUSE_FORCED_0_SEX IS NULL)	----Q9 not NO, Q10 cannot be skipped
	and CLIENT_ABUSE_FORCED_1_SEX_LAST_YR is null									----Q10
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_FORCED_1_SEX_LAST_YR'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus

-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
--		x.	Number of times client was physically hurt while pregnant is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA13

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	and (CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME IS NULL)	----Q11 not NO, Q12 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME is null											----Q12
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus

-----------------------------------------------------------------------------------------------------------------
--	1)	Relationship Assessment - Pregnancy – Intake 
--		xi.	Client afraid of partner, ex-partner, boyfriend or ex-boyfriend is missing
-----------------------------------------------------------------------------------------------------------------

----this is handled, see 1)ii.b.
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_AFRAID_0_PARTNER
	, SortOrder = 0
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA14

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-Intake'
	and CLIENT_ABUSE_AFRAID_0_PARTNER is null									----Q13----this is handled, see 1)ii.b.
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_AFRAID_0_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus

--------------------------------------------------------------------------------------------
--	2)	Relationship Assessment - Pregnancy – 36 weeks 
--		i.	Since enrolled in this program has client been emotionally or physically abused  
--			by your partner, ex-partner, boyfriend or ex-boyfriend is missing.
--------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER
	, SortOrder = 1
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA15

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-36 Weeks'
	and CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER is null								----Q1 
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--	2)	Relationship Assessment - Pregnancy – 36 weeks 
--		ii.	Since enrolled in this program has client been hit, slapped, kicked or otherwise physically hurt 
--			by your partner, ex-partner, boyfriend or ex-boyfriend’ is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_HIT_0_SLAP_PARTNER
	, SortOrder = 1
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA16

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-36 Weeks'
	and CLIENT_ABUSE_HIT_0_SLAP_PARTNER is null								----Q2 
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_HIT_0_SLAP_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 


---------------------------------------------------------------------------------------------------------------
--	2)	Relationship Assessment - Pregnancy – 36 weeks  
--		ii.	a.	Reported no to Since enrolled in this program has the client been hit, slapped, kicked 
--				or otherwise physically hurt by your partner, ex-partner, boyfriend or ex-boyfriend 
--				AND Since enrolled in this program has the client’s partner, ex-partner, boyfriend or ex-boyfriend
--				forced her to have sexual relations is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_FORCED_0_SEX
	, SortOrder = 1
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA17

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-36 Weeks'
	------and CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'No'  ----commented out because CLIENT_ABUSE_FORCED_0_SEX can never be null
	and CLIENT_ABUSE_FORCED_0_SEX is null							----Q9
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_FORCED_0_SEX'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
	
-----------------------------------------------------------------------------------------------------------------
--	2)	Relationship Assessment - Pregnancy – 36 weeks  
--		ii.	a.	1.	Reported no to Since enrolled in this program has the client’s partner, ex-partner, 
--					boyfriend or ex-boyfriend forced her to have sexual relations  
--					AND Since enrolled in this program, is the client afraid of her partner, ex-partner, 
--					boyfriend or ex-boyfriend is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_AFRAID_0_PARTNER
	, SortOrder = 1
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA18

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-36 Weeks'
	------and CLIENT_ABUSE_FORCED_0_SEX = 'No'	----commented out because CLIENT_ABUSE_AFRAID_0_PARTNER can never be null
	and CLIENT_ABUSE_AFRAID_0_PARTNER is null								----Q11
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_AFRAID_0_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
	
-----------------------------------------------------------------------------------------------------------------
--	2)	Relationship Assessment - Pregnancy – 36 weeks  
--		iii.	Since enrolled in this program how many times was the client physically hurt is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_TIMES_0_HURT_LAST_YR
	, SortOrder = 1
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA19

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-36 Weeks'
	and (CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER IS NULL)	----Q2 not No, Q3 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_HURT_LAST_YR is null												----Q3
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_HURT_LAST_YR'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--	2)	Relationship Assessment - Pregnancy – 36 weeks  
--		iv.	Since enrolled in this program how many times did the client’s partner, ex-partner, boyfriend 
--			or ex-boyfriend slap or push the client is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER
	, SortOrder = 1
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA20

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-36 Weeks'
	and (CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER IS NULL)	----Q2 not No, Q4 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER is null											----Q4
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--	2)	Relationship Assessment - Pregnancy – 36 weeks  
--		v.	Since enrolled in this program how many times did the client’s partner, ex-partner, boyfriend 
--			or ex-boyfriend, punch, kick or cut her is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER
	, SortOrder = 1
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA21

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-36 Weeks'
	and (CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER IS NULL)	----Q2 not No, Q5 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER is null											----Q5
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--	2)	Relationship Assessment - Pregnancy – 36 weeks  
--		vi.	Since enrolled in this program how many times did the client’s partner, ex-partner, boyfriend or 
--			ex-boyfriend do something that burned you, severely bruised you, or broke a bone is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER
	, SortOrder = 1
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA22

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-36 Weeks'
	and (CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER IS NULL)	----Q2 not No, Q6 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER is null										----Q6
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
	
-----------------------------------------------------------------------------------------------------------------
--	2)	Relationship Assessment - Pregnancy – 36 weeks  
--		vii.	Since enrolled in this program how many times did the client’s partner, ex-partner, boyfriend 
--				or ex-boyfriend cause her to have a head, internal, or permanent injury is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER
	, SortOrder = 1
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA23

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-36 Weeks'
	and (CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER IS NULL)	----Q2 not No, Q7 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER is null									----Q7
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
	
-----------------------------------------------------------------------------------------------------------------
--	2)	Relationship Assessment - Pregnancy – 36 weeks  
--		viii.	Since enrolled in this program how many times did the client’s partner, ex-partner, 
--				boyfriend or ex-boyfriend use a weapon to hurt her is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER
	, SortOrder = 1
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA24

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-36 Weeks'
	and (CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER IS NULL)	----Q2 not No, Q8 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER is null										----Q8
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--	2)	Relationship Assessment - Pregnancy – 36 weeks  
--		ix.	Since enrolled in this program how many times was client forced to have sexual relations is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_FORCED_1_SEX_LAST_YR
	, SortOrder = 1
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA25

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-36 Weeks'
	and (CLIENT_ABUSE_FORCED_0_SEX = 'Yes' OR CLIENT_ABUSE_FORCED_0_SEX IS NULL)		----Q9 not No, Q10 cannot be skipped
	and CLIENT_ABUSE_FORCED_1_SEX_LAST_YR is null										----Q10
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_FORCED_1_SEX_LAST_YR'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus

-----------------------------------------------------------------------------------------------------------------
--	2)	Relationship Assessment - Pregnancy – 36 weeks  
--		x.	Since enrolled in this program, is the client afraid of her partner, ex-partner, boyfriend or 
--			ex-boyfriend is missing
-----------------------------------------------------------------------------------------------------------------

----handled 2)i.a.1.
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_AFRAID_0_PARTNER
	, SortOrder = 1
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA26

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Pregnancy-36 Weeks'
	and CLIENT_ABUSE_AFRAID_0_PARTNER is null							---Q11----handled 2)i.a.1.
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_AFRAID_0_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus

--------------------------------------------------------------------------------------------
--3)	Relationship Assessment – Infancy – 12 months
--		i.	Since the infant’s birth has client been emotionally or physically abused by your 
--			partner, ex-partner, boyfriend or ex-boyfriend is missing.
--------------------------------------------------------------------------------------------
Select

	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA27

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	and CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER is null								---Q1
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--3)	Relationship Assessment – Infancy – 12 months 
----		ii.	Since the infant’s birth has client been hit, slapped, kicked or otherwise physically 
--				hurt by your partner, ex-partner, boyfriend or ex-boyfriend’ is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA28

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID	
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	and CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME is null							----Q2
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--3)	Relationship Assessment – Infancy – 12 months 
--		ii.	a.	Reported no to Since the infant’s birth has the client been hit, slapped, kicked or 
--				otherwise physically hurt by your partner, ex-partner, boyfriend or ex-boyfriend 
--				AND Since the infant’s birth the client’s partner, ex-partner, boyfriend or ex-boyfriend 
--				forced her to have sexual relations is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_FORCED_0_SEX
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA29
From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID	
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	------and CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'No'	----commented out because CLIENT_ABUSE_FORCED_0_SEX can never be null
	and CLIENT_ABUSE_FORCED_0_SEX is null								----Q9
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_FORCED_0_SEX'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
	
-----------------------------------------------------------------------------------------------------------------
--3)	Relationship Assessment – Infancy – 12 months 
--		ii.	a.	1.	Reported no to Since infant’s birth has the client’s partner, ex-partner, boyfriend or 
--					ex-boyfriend forced her to have sexual relations 
--					AND Is client afraid of partner, ex-partner, boyfriend or ex-boyfriend is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_AFRAID_0_PARTNER
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA30

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID	
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	------and CLIENT_ABUSE_FORCED_0_SEX = 'No'	----commented out because CLIENT_ABUSE_AFRAID_0_PARTNER can never be null
	and CLIENT_ABUSE_AFRAID_0_PARTNER is null								----Q11
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_AFRAID_0_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
-----------------------------------------------------------------------------------------------------------------
--3)	Relationship Assessment – Infancy – 12 months 
--		iii.	Since infant’s birth how many times was the client physically hurt is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_TIMES_0_HURT_LAST_YR
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA31

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID	
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	and (CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME IS NULL)	----Q2 not No, Q3 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_HURT_LAST_YR is null													----Q3
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_HURT_LAST_YR'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--3)	Relationship Assessment – Infancy – 12 months 
--		iv.	Since infant’s birth  how many times did the client’s partner, ex-partner, boyfriend or ex-boyfriend 
--			slap or push the client is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--, CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA32

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID	
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	and (CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME IS NULL)	----Q2 not No, Q4 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER is null												----Q4
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--3)	Relationship Assessment – Infancy – 12 months 
--		v.	Since infant’s birth  how many times did the client’s partner, ex-partner, boyfriend or ex-boyfriend, 
--			punch, kick or cut her is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA33

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID	
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	and (CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME IS NULL)	----Q2 not No, Q5 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER is null												----Q5
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 
	
-----------------------------------------------------------------------------------------------------------------
--3)	Relationship Assessment – Infancy – 12 months 
--		vi.	Since infant’s birth how many times did the client’s partner, ex-partner, boyfriend or ex-boyfriend 
--			do something that burned you, severely bruised you, or broke a bone is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA34

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID	
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	and (CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME IS NULL)		----Q2 not No, Q6 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER is null												----Q6
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--3)	Relationship Assessment – Infancy – 12 months 
--		vii.	Since infant’s birth how many times did the client’s partner, ex-partner, boyfriend or 
--				ex-boyfriend cause her to have a head, internal, or permanent injury is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA35

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID	
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	and (CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME IS NULL)	----Q2 not No, Q7 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER is null										----Q7
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--3)	Relationship Assessment – Infancy – 12 months 
--		viii.	Since infant’s birth how many times did the client’s partner, ex-partner, boyfriend or 
--				ex-boyfriend use a weapon to hurt her is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA36

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID	
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	and (CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' OR CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME IS NULL)	----Q2 not No, Q8 cannot be skipped
	and CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER is null											----Q8
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus 

-----------------------------------------------------------------------------------------------------------------
--3)	Relationship Assessment – Infancy – 12 months 
--		ix.	Since infant’s birth was client forced to have sexual relations with her partner, ex-partner, 
--			boyfriend, ex-boyfriend is missing.
-----------------------------------------------------------------------------------------------------------------

----handled in 3)ii.a.
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_FORCED_0_SEX
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA37

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID	
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	and CLIENT_ABUSE_FORCED_0_SEX is null								----Q9----handled in 3)ii.a.
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_FORCED_0_SEX'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus

-----------------------------------------------------------------------------------------------------------------
--3)	Relationship Assessment – Infancy – 12 months 
--		x.	Since infant’s birth how many times was client forced to have sexual relations is missing
-----------------------------------------------------------------------------------------------------------------
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_FORCED_1_SEX_LAST_YR
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA38

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID	
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	and (CLIENT_ABUSE_FORCED_0_SEX = 'Yes' OR CLIENT_ABUSE_FORCED_0_SEX IS NULL)		----Q9 not No, Q10 cannot be skipped
	and CLIENT_ABUSE_FORCED_1_SEX_LAST_YR is null										----Q10
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_FORCED_1_SEX_LAST_YR'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus

-----------------------------------------------------------------------------------------------------------------
--	3)	Relationship Assessment – Infancy – 12 months
--		xi.	Since infant’s birth has client been afraid of her partner, ex-partner, boyfriend or ex-boyfriend
--			is missing
-----------------------------------------------------------------------------------------------------------------

----handled 3)ii.a.1.
Select
 
	ProgramName
	, CL_EN_GEN_ID as Client
	, SurveyName
	, Mstr_SurveyElements.Stimulus as Question
	, 'Missing' as Error
	, Convert(varchar(8),SurveyDate,1) as SurveyDate
	--,CLIENT_ABUSE_AFRAID_0_PARTNER
	, SortOrder = 2
	, SortOrder2 = source.SequenceOrder	
	
Into

	#RA39

From

	Relationship_Survey
	inner join #RA_ActiveClientlimit on #RA_ActiveClientlimit.CLID = Relationship_Survey.CL_EN_GEN_ID
	left join Mstr_surveys on Mstr_surveys.SurveyID = Relationship_Survey.SurveyID	
	left join ProgramsAndSites on ProgramsAndSites.ProgramID = Relationship_Survey.ProgramID
	left join Mstr_SurveyElements on Mstr_SurveyElements.SurveyID = Relationship_Survey.SurveyID
	left join Mstr_SurveyElements source ON source.SurveyElementID = Mstr_SurveyElements.SourceSurveyElementID

Where
  
	SurveyName = 'Relationship Assessment: Infancy-12 Months'
	and CLIENT_ABUSE_AFRAID_0_PARTNER is null								----Q11----handled 3)ii.a.1.
	and Mstr_SurveyElements.Pseudonym = 'CLIENT_ABUSE_AFRAID_0_PARTNER'
	and ProgramName = @Team

Order by

	ProgramName
	, CL_EN_GEN_ID
	, SortOrder
	, Mstr_SurveyElements.Stimulus
	
-----------------------------------------------------------------------------------------
--Union All
---------------

Select * from #RA1
Union all
Select * from #RA2
Union all
Select * from #RA3
Union all
Select * from #RA4
Union all
Select * from #RA5
Union all
Select * from #RA6
Union all
Select * from #RA7
Union all
Select * from #RA8
Union all
Select * from #RA9
Union all
Select * from #RA10
Union all
Select * from #RA11
Union all
Select * from #RA12
Union all
Select * from #RA13
--Union all
--Select * from #RA14
Union All
Select * from #RA15
Union all
Select * from #RA16
Union all
Select * from #RA17
Union all
Select * from #RA18
Union all
Select * from #RA19
Union all
Select * from #RA20
Union all
Select * from #RA21
Union all
Select * from #RA22
Union all
Select * from #RA23
Union all
Select * from #RA24
Union all
Select * from #RA25
--Union all
--Select * from #RA26
Union All
Select * from #RA27
Union all
Select * from #RA28
Union all
Select * from #RA29
Union all
Select * from #RA30
Union all
Select * from #RA31
Union all
Select * from #RA32
Union all
Select * from #RA33
Union all
Select * from #RA34
Union all
Select * from #RA35
Union all
Select * from #RA36
--Union all
--Select * from #RA37
Union all
Select * from #RA38
--Union all
--Select * from #RA39

Order by ProgramName, Client, SortOrder, SortOrder2

-----------------------------------------------------------------------------------------
--Clean Up
---------------

Drop Table #RA1
Drop Table #RA2
Drop Table #RA3
Drop Table #RA4
Drop Table #RA5
Drop Table #RA6
Drop Table #RA7
Drop Table #RA8
Drop Table #RA9
Drop Table #RA10
Drop Table #RA11
Drop Table #RA12
Drop Table #RA13
--Drop Table #RA14
Drop Table #RA15
Drop Table #RA16
Drop Table #RA17
Drop Table #RA18
Drop Table #RA19
Drop Table #RA20
Drop Table #RA21
Drop Table #RA22
Drop Table #RA23
Drop Table #RA24
Drop Table #RA25
--Drop Table #RA26
Drop Table #RA27
Drop Table #RA28
Drop Table #RA29
Drop Table #RA30
Drop Table #RA31
Drop Table #RA32
Drop Table #RA33
Drop Table #RA34
Drop Table #RA35
Drop Table #RA36
--Drop Table #RA37
Drop Table #RA38
--Drop Table #RA39

Drop Table #RA_ActiveClientlimit

GO
