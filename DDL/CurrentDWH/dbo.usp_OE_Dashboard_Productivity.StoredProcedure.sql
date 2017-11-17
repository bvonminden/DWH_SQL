USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_OE_Dashboard_Productivity]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_OE_Dashboard_Productivity]

	@Startdate date
	, @Enddate date
	, @Team varchar(4000)

AS


--Declare @Startdate date
--Declare @Enddate date
--Declare @Team varchar(2000)

--Set @Startdate = '2013-05-01'
--Set @Enddate = '2014-04-30'
--Set @Team = 917



------------------------------------------------------------------------------------------
--UV_EADT Streamline of udf_oe_active_clients as #ActiveClients
------------------------------------------------------------------------------------------

--Declare @Enddate date

--Set @Enddate = GETDATE()

SELECT Distinct

	Count(distinct(EnrollmentAndDismissal.CLID)) as CLID
	--, EnrollmentAndDismissal.ProgramStartDate
	--, EnrollmentAndDismissal.EndDate
	, PAS.ProgramID
	, PAS.Team_Name
	
Into #ActiveClients
	
FROM

	EnrollmentAndDismissal
	
		INNER JOIN UV_PAS PAS ON PAS.ProgramID = EnrollmentAndDismissal.ProgramID
		
		LEFT JOIN UV_PAS P ON EnrollmentAndDismissal.ProgramID IN (P.Program_ID_NHV,P.Program_ID_Referrals,P.Program_ID_Staff_Supervision)
		
		LEFT JOIN UC_Client_Exclusion_YWCA YWCA ON YWCA.CLID = EnrollmentAndDismissal.CLID AND EnrollmentAndDismissal.SiteID = 222
	
		LEFT JOIN
			(SELECT DISTINCT HVES.CL_EN_GEN_ID,HVES.ProgramID
			FROM Home_Visit_Encounter_Survey HVES
			WHERE HVES.SurveyDate <= @EndDate
			AND HVES.CLIENT_COMPLETE_0_VISIT = 'Completed') HVES
			ON EnrollmentAndDismissal.CLID = HVES.CL_EN_GEN_ID
			AND EnrollmentAndDismissal.ProgramID = HVES.ProgramID
	
		LEFT JOIN
			(SELECT AES.CL_EN_GEN_ID, AES.ProgramID
			FROM Alternative_Encounter_Survey AES
			WHERE AES.CLIENT_TALKED_0_WITH_ALT LIKE '%Client;%'
			OR AES.CLIENT_TALKED_0_WITH_ALT  = 'Client'
			AND AES.SurveyDate <= @EndDate) AES
			ON EnrollmentAndDismissal.CLID = AES.CL_EN_GEN_ID
			AND EnrollmentAndDismissal.ProgramID = AES.ProgramID
	
WHERE

	EnrollmentAndDismissal.ProgramStartDate <= @EndDate 
	AND ISNULL(EnrollmentAndDismissal.EndDate,DATEADD(D,1,@EndDate)) >= @EndDate
	AND (HVES.CL_EN_GEN_ID IS NOT NULL OR AES.CL_EN_GEN_ID IS NOT NULL)
	AND YWCA.CLID IS NULL
	and Pas.ProgramID in (SELECT * FROM dbo.udf_ParseMultiParam (@Team))
	
Group BY

	PAS.ProgramID
	, PAS.Team_Name
	
	
	
--Select * from #ActiveClients

--Drop Table #ActiveClients
------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

--Declare @Enddate date

--Set @Enddate = GETDATE()

---------------------------------------------------------------------------------------------------
---------Begin #NHVFTE
------------------------------------------------------------------
Select

	ProgramID
	, sum((HV_FTE)) as ActiveNHV
	, count((CASE
		WHEN (NHV_Flag = 1 OR ISNULL(HV_FTE,0) > 0)
		THEN 1
		END)) as AllNHV
		
Into #NHVFTE

FROM

	dbo.fn_FID_Staff_list ('1/1/1900',@Enddate)

--Where

--	ProgramID =1820

Group by

	ProgramID
-----------------------------------------------------------------
--Select * from #NHVFTE
--drop table #NHVFTE
	
--------End #NHVFTE
---------------------------------------------------------------------------------------------------










--------------------------------------------------------------------------------------------
-- Pulling course completion info for staff 
--------------------------------------------
--SELECT
 
--	IA_Staff.Site_ID
--	,MIN(DW_Completed_Courses.Completion_Date) as CompletionDate
	
--into #Staff

--FROM
 
--	IA_Staff
--	INNER JOIN DW_Completed_Courses ON DW_Completed_Courses.Entity_ID = IA_Staff.Entity_Id

--GROUP BY

--	IA_Staff.Site_ID
	
--Select * from #Staff
--drop Table #Staff
--------------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------
--Declare @Startdate date
--Declare @Enddate date

--set @Startdate = '2014-01-01'
--set @Enddate = GETDATE()

SELECT

	UV_PAS.Abbreviation
	, UV_PAS.Site
	, UV_PAS.Team_Name
	, UV_PAS.ProgramID

	, COUNT(DISTINCT  Referrals_to_NFP_Survey.SurveyResponseID) TotalRefferals

	, COUNT(DISTINCT 
			CASE
				WHEN EnrollmentAndDismissal.ReasonForDismissal = 'Unable to Locate'
				THEN Referrals_to_NFP_Survey.SurveyResponseID
			END) ReferralsNotLocated
			
	, COUNT(DISTINCT 
			CASE
				WHEN EnrollmentAndDismissal.ReasonForDismissal = 'Did not meet local criteria'
					OR EnrollmentAndDismissal.ReasonForDismissal = 'Did not meet NFP criteria'
				THEN Referrals_to_NFP_Survey.SurveyResponseID
			END) ReferralsNotMeetingProgramCriteria
			
	, COUNT(DISTINCT 
			CASE
				WHEN EnrollmentAndDismissal.ReasonForDismissal IS NULL
				THEN Referrals_to_NFP_Survey.SurveyResponseID
			END) MissingDisposition
			
	, COUNT(DISTINCT 
			CASE
				WHEN EnrollmentAndDismissal.ReasonForDismissal NOT IN ('Did not meet local criteria','Did not meet NFP criteria')
				THEN Referrals_to_NFP_Survey.SurveyResponseID
			END) EligibleReferrals

	, COUNT(DISTINCT 
			CASE
				WHEN EnrollmentAndDismissal.ReasonForDismissal = 'Program full'
				THEN Referrals_to_NFP_Survey.SurveyResponseID
			END) ProgramFull
			
	, COUNT(DISTINCT 
			CASE
				WHEN EnrollmentAndDismissal.ReasonForDismissal NOT IN ('Program full', 'Did not meet local criteria','Did not meet NFP criteria')
				THEN Referrals_to_NFP_Survey.SurveyResponseID
			END) EligibleWithSpace
			
	, COUNT(DISTINCT 
			CASE
				WHEN EnrollmentAndDismissal.ReasonForDismissal = 'Refused participation'
				THEN Referrals_to_NFP_Survey.SurveyResponseID
			END) DeclinedEnrollment
			
	, COUNT(DISTINCT 
			CASE
				WHEN EnrollmentAndDismissal.ReasonForDismissal = 'Enrolled in NFP'
				THEN Referrals_to_NFP_Survey.SurveyResponseID
			END) EnfolledinNFP

Into #Refferrals

FROM

Referrals_to_NFP_Survey
INNER JOIN EnrollmentAndDismissal ON EnrollmentAndDismissal.ProgramID = Referrals_to_NFP_Survey.ProgramID
	AND EnrollmentAndDismissal.CLID = Referrals_to_NFP_Survey.CL_EN_GEN_ID
	AND EnrollmentAndDismissal.EndDate IS NOT NULL
	AND Referrals_to_NFP_Survey.SurveyDate BETWEEN @StartDate AND @EndDate
	AND EnrollmentAndDismissal.ProgramStartDate <= @EndDate

	INNER JOIN UV_PAS ON Referrals_to_NFP_Survey.ProgramID IN (UV_PAS.Program_ID_NHV,UV_PAS.Program_ID_Referrals,UV_PAS.Program_ID_Staff_Supervision)

where  UV_PAS.ProgramID in (SELECT * FROM dbo.udf_ParseMultiParam (@Team))

Group By

	UV_PAS.Abbreviation
	, UV_PAS.Site
	, UV_PAS.Team_Name
	, UV_PAS.ProgramID
	
--Select * from #Refferrals

--Drop table #Refferrals


--------------------------------------------------------------------------------------------
--
---------------------------------------------------------------------
--Declare @Startdate date
--Declare @enddate date

--set @Startdate = '2014-01-01'
--set @enddate = GETDATE()

SELECT 

	UV_PAS.Abbreviation
	, UV_PAS.Site
	, UV_PAS.Team_Name
	, UV_Fidelity_CLID.ProgramID

	, COUNT(DISTINCT  
			CASE WHEN ISNULL(UV_InfDOB.DOB,DATEADD(DAY,1,@EndDate)) > @StartDate
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate 
					AND ISNULL(UV_Fidelity_CLID.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND ISNULL(UV_InfDOB.DOB,DATEADD(DAY,1,@EndDate)) > UV_Fidelity_CLID.ProgramStartDate
				 THEN UV_Fidelity_CLID.CLID END) Preg_served
				 
	, COUNT(DISTINCT  
			CASE WHEN ISNULL(UV_InfDOB.DOB,DATEADD(DAY,1,@EndDate)) > @StartDate
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate 
					AND ISNULL(UV_Fidelity_CLID.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > = UV_InfDOB.DOB
					AND UV_InfDOB.DOB BETWEEN @StartDate AND @EndDate
					AND ISNULL(UV_InfDOB.DOB,DATEADD(DAY,1,@EndDate)) > UV_Fidelity_CLID.ProgramStartDate
				 THEN UV_Fidelity_CLID.CLID END) Preg_completed
				 
	, COUNT(DISTINCT  
			CASE WHEN ISNULL(UV_InfDOB.DOB,DATEADD(DAY,1,@EndDate)) > @StartDate
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate 
					AND ISNULL(UV_Fidelity_CLID.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,DATEADD(DAY,1,@EndDate)) > @EndDate
					AND (UV_InfDOB.DOB > @EndDate OR UV_InfDOB.DOB IS NULL)
					AND ISNULL(UV_InfDOB.DOB,DATEADD(DAY,1,@EndDate)) > UV_Fidelity_CLID.ProgramStartDate
				 THEN UV_Fidelity_CLID.CLID END) Preg_still_active
				 
	, COUNT(DISTINCT  
			CASE WHEN ISNULL(UV_InfDOB.DOB,DATEADD(DAY,1,@EndDate)) > @StartDate
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate 
					AND ISNULL(UV_Fidelity_CLID.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND UV_Fidelity_CLID.EndDate BETWEEN @StartDate AND @EndDate
					AND (UV_Fidelity_CLID.EndDate < UV_InfDOB.DOB OR UV_InfDOB.DOB IS NULL)
					AND ISNULL(UV_InfDOB.DOB,DATEADD(DAY,1,@EndDate)) > UV_Fidelity_CLID.ProgramStartDate
				 THEN UV_Fidelity_CLID.CLID END) Preg_leftprog
				 
	, COUNT(DISTINCT  
			CASE WHEN ISNULL(UV_InfDOB.DOB,DATEADD(DAY,1,@EndDate)) > @EndDate
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate 
					AND UV_Fidelity_CLID.EndDate <= @EndDate
					AND UV_Fidelity_CLID.GestAge_EDD BETWEEN @StartDate AND @EndDate
					AND (UV_Fidelity_CLID.EndDate < UV_InfDOB.DOB OR UV_InfDOB.DOB IS NULL)
					AND ISNULL(UV_InfDOB.DOB,DATEADD(DAY,1,@EndDate)) > UV_Fidelity_CLID.ProgramStartDate
				 THEN UV_Fidelity_CLID.CLID END) Preg_leftprogCHC
	
	--- Preg_RetainedPercent calculated
	
	, COUNT(DISTINCT  
			CASE WHEN UV_InfDOB.DOB <= @EndDate
					AND UV_InfDOB.BD1 > @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > = UV_InfDOB.DOB
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) >= @StartDate
				 THEN UV_Fidelity_CLID.CLID END) Inf_served
				 
	, COUNT(DISTINCT  
			CASE WHEN UV_InfDOB.DOB <= @EndDate
					AND UV_InfDOB.BD1 > @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > = UV_InfDOB.DOB
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) >= @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > = UV_InfDOB.BD1
					AND UV_InfDOB.BD1 BETWEEN @StartDate AND @EndDate
				 THEN UV_Fidelity_CLID.CLID END) Inf_completed
				 
	, COUNT(DISTINCT  
			CASE WHEN UV_InfDOB.DOB <= @EndDate
					AND UV_InfDOB.BD1 > @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > = UV_InfDOB.DOB
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) >= @StartDate
					AND UV_InfDOB.BD1 > @EndDate
					AND UV_InfDOB.DOB IS NOT NULL
					AND ISNULL(UV_Fidelity_CLID.EndDate,DATEADD(DAY,1,@EndDate))> @EndDate
				 THEN UV_Fidelity_CLID.CLID END) Inf_still_active
				 
	, COUNT(DISTINCT  
			CASE WHEN UV_InfDOB.DOB <= @EndDate
					AND UV_InfDOB.BD1 > @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > = UV_InfDOB.DOB
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) >= @StartDate
					AND UV_Fidelity_CLID.EndDate < UV_InfDOB.BD1
					AND UV_Fidelity_CLID.EndDate BETWEEN @StartDate AND @EndDate
				 THEN UV_Fidelity_CLID.CLID END) Inf_leftprog
				 
	, COUNT(DISTINCT  
			CASE WHEN UV_InfDOB.DOB <= @EndDate
					AND UV_InfDOB.BD1 > @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > = UV_InfDOB.DOB
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate 
					AND UV_Fidelity_CLID.EndDate < UV_InfDOB.BD1
					AND UV_InfDOB.BD1 BETWEEN @StartDate AND @EndDate
					AND UV_Fidelity_CLID.EndDate BETWEEN UV_InfDOB.DOB AND @EndDate
				 THEN UV_Fidelity_CLID.CLID END) Inf_leftprogCHC
				 
	--- Inf_RetainedPercent calcualted
	
	, COUNT(DISTINCT  
			CASE WHEN UV_InfDOB.BD1 <= @EndDate
					AND UV_InfDOB.BD2 > @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > = UV_InfDOB.BD1
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) >= @StartDate
				 THEN UV_Fidelity_CLID.CLID END) Tod_served
				 
	, COUNT(DISTINCT  
			CASE WHEN UV_InfDOB.BD1 <= @EndDate
					AND UV_InfDOB.BD2 > @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > = UV_InfDOB.BD1
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) >= @StartDate
					AND UV_Fidelity_CLID.ReasonForDismissal = 'Child reached 2nd birthday'
					AND UV_Fidelity_CLID.EndDate BETWEEN @StartDate AND @EndDate
				 THEN UV_Fidelity_CLID.CLID END) Tod_completed
				 
	, COUNT(DISTINCT  
			CASE WHEN UV_InfDOB.BD1 <= @EndDate
					AND UV_InfDOB.BD2 > @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > = UV_InfDOB.BD1
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) >= @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,DATEADD(DAY,1,@EndDate)) > @EndDate
				 THEN UV_Fidelity_CLID.CLID END) Tod_still_active
				 
	, COUNT(DISTINCT  
			CASE WHEN UV_InfDOB.BD1 <= @EndDate
					AND UV_InfDOB.BD2 > @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > = UV_InfDOB.BD1
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) >= @StartDate
					AND UV_Fidelity_CLID.ReasonForDismissal <> 'Child reached 2nd birthday'
					AND UV_Fidelity_CLID.EndDate BETWEEN @StartDate AND @EndDate
				 THEN UV_Fidelity_CLID.CLID END) Tod_leftprog
				 
	, COUNT(DISTINCT  
			CASE WHEN UV_InfDOB.BD1 <= @EndDate
					AND UV_Fidelity_CLID.EndDate BETWEEN UV_InfDOB.BD1 AND DATEADD(DAY,-1,UV_InfDOB.BD2)
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate 
					AND ISNULL(UV_Fidelity_CLID.ReasonForDismissal,'') <> 'Child reached 2nd birthday'
					AND UV_InfDOB.BD2 BETWEEN @StartDate AND @EndDate
				 THEN UV_Fidelity_CLID.CLID END) Tod_leftprogCHC
				 
	, COUNT(DISTINCT 
			CASE WHEN UV_InfDOB.BD2 BETWEEN @StartDate AND @EndDate
				 THEN UV_Fidelity_CLID.CLID END) ToddlerSecondBD
				 
	,COUNT(DISTINCT 
			CASE WHEN UV_Fidelity_CLID.EndDate BETWEEN @StartDate AND @EndDate
					AND UV_Fidelity_CLID.ReasonForDismissal = 'Child reached 2nd birthday'
				 THEN UV_Fidelity_CLID.CLID END) ToddlerGraduated

	--- Tod_RetainedPercent calcualted
	
	, COUNT(DISTINCT  
			CASE WHEN ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > @StartDate 
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) >= @StartDate
				 THEN UV_Fidelity_CLID.CLID END) Total_served
				 
	, COUNT(DISTINCT  
			CASE WHEN ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > @StartDate 
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) >= @StartDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,DATEADD(DAY,1,@EndDate)) > @EndDate
				 THEN UV_Fidelity_CLID.CLID END) Total_still_active
				 
	, COUNT(DISTINCT  
			CASE WHEN ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > @StartDate 
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) >= @StartDate
					AND UV_Fidelity_CLID.ReasonForDismissal = 'Child reached 2nd birthday'
					AND ISNULL(UV_Fidelity_CLID.EndDate,DATEADD(DAY,1,@EndDate)) BETWEEN @StartDate AND @EndDate   
				 THEN UV_Fidelity_CLID.CLID END) Total_graduated
				 
	, COUNT(DISTINCT  
			CASE WHEN ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) > @StartDate 
					AND UV_Fidelity_CLID.ProgramStartDate <= @EndDate AND ISNULL(UV_Fidelity_CLID.EndDate,@EndDate) >= @StartDate
					AND UV_Fidelity_CLID.ReasonForDismissal <> 'Child reached 2nd birthday'
					AND ISNULL(UV_Fidelity_CLID.EndDate,DATEADD(DAY,1,@EndDate)) BETWEEN @StartDate AND @EndDate
				 THEN UV_Fidelity_CLID.CLID END) Total_leftprog
				 
	--- Total_RetainedPercent calcualted
			
	, COUNT(DISTINCT 
			CASE WHEN 
					(UV_InfDOB.BD2 BETWEEN @StartDate AND @EndDate
					AND ISNULL(UV_Fidelity_CLID.EndDate,DATEADD(DAY,1,@EndDate)) > UV_InfDOB.BD2)
					OR
					(UV_Fidelity_CLID.ReasonForDismissal = 'Child reached 2nd birthday'
					AND UV_Fidelity_CLID.EndDate BETWEEN @StartDate AND @EndDate)
				 THEN UV_Fidelity_CLID.CLID END) ToddlerGradorAct
				 
Into #ServedPhases

FROM

	UV_Fidelity_CLID
	LEFT JOIN UV_InfDOB ON UV_InfDOB.CL_EN_GEN_ID = UV_Fidelity_CLID.CLID 
		AND UV_InfDOB.ProgramID = UV_Fidelity_CLID.ProgramID
		AND UV_InfDOB.MinSurvDate <= @EndDate
		AND UV_InfDOB.MaxSurvDate <= @EndDate
	INNER JOIN UV_PAS ON UV_PAS.ProgramID = UV_Fidelity_CLID.ProgramID
	
Where UV_PAS.ProgramID in (SELECT * FROM dbo.udf_ParseMultiParam (@Team))
		
Group By

	UV_PAS.Abbreviation
	, UV_PAS.Site
	, UV_PAS.Team_Name
	, UV_Fidelity_CLID.ProgramID
	
--Select * from #ServedPhases

--Drop Table #ServedPhases
--------------------------------------------------------------------------------------------

SELECT

	UV_PAS.Abbreviation
	, UV_PAS.Site
	, UV_PAS.Team_Name 

	--, CASE
	--	WHEN MIN(UV_PAS.AGENCY_INFO_1_INITIATION_DATE) <= MIN(#Staff.CompletionDate)
	--	THEN MIN(UV_PAS.AGENCY_INFO_1_INITIATION_DATE)
	--	WHEN MIN(#Staff.CompletionDate) <= MIN(UV_PAS.AGENCY_INFO_1_INITIATION_DATE)
	--	THEN MIN(#Staff.CompletionDate)
	--END [Agency Effective Date]

	, SUM(#Refferrals.EnfolledinNFP) EnrolledinNFP
	, SUM(#Refferrals.EligibleReferrals)EligibleReferrals
	, SUM(#Refferrals.ReferralsNotMeetingProgramCriteria) + SUM(#Refferrals.MissingDisposition) + SUM(#Refferrals.EligibleReferrals) TotalReferrals
	, SUM(#ServedPhases.Preg_served) PregnancyServed
	, SUM(#ServedPhases.Preg_completed) PregnancyCompleted
	, SUM(#ServedPhases.Preg_still_active)PregnancyStillActive
	, SUM(#ServedPhases.Preg_leftprog) PregnancyLeftProgram
	, SUM(#ServedPhases.Preg_leftprogCHC) PregnancyLeftCHC

	, SUM(#ServedPhases.Inf_served) InfancyServed_old
	
	
	, (SUM(#ServedPhases.Inf_completed)+SUM(#ServedPhases.Inf_still_active)+SUM(#ServedPhases.Inf_leftprog)) as InfancyServed
	
	, SUM(#ServedPhases.Inf_completed) InfancyCompleted
	, SUM(#ServedPhases.Inf_still_active)InfancyStillActive
	, SUM(#ServedPhases.Inf_leftprog) InfancyLeftProgram
	, SUM(#ServedPhases.Inf_leftprogCHC) InfancyLeftCHC

	, SUM(#ServedPhases.Tod_served) ToddlerServed
	, SUM(#ServedPhases.Tod_completed) ToddlerCompleted
	, SUM(#ServedPhases.Tod_still_active)ToddlerStillActive
	, SUM(#ServedPhases.Tod_leftprog) ToddlerLeftProgram
	, SUM(#ServedPhases.Tod_leftprogCHC) ToddlerLeftCHC
	, SUM(#ServedPhases.ToddlerGradorAct)ToddlerGradorAct

	, MAX(#ActiveClients.CLID) as ActiveClients
	, MAX(#NHVFTE.ActiveNHV) as ActiveNHV
	, MAX(#NHVFTE.AllNHV) as AllNHV
	, (MAX(#ActiveClients.CLID)/MAX(#NHVFTE.AllNHV)) as Caseload

FROM UV_PAS

	--Left Join #Staff ON #Staff.Site_ID = UV_PAS.SiteID
	inner Join #Refferrals on #Refferrals.ProgramID = UV_PAS.ProgramID
	inner Join #ServedPhases on #ServedPhases.ProgramID = UV_PAS.ProgramID
	inner Join #ActiveClients on #ActiveClients.ProgramID = UV_PAS.ProgramID
	Left Join #NHVFTE on #NHVFTE.ProgramID = UV_PAS.ProgramID
	
Where UV_PAS.ProgramID in (SELECT * FROM dbo.udf_ParseMultiParam (@Team))
	
Group By

	UV_PAS.Abbreviation
	, UV_PAS.Site
	, UV_PAS.Team_Name 
	  
-------------------------------------------------------------------------
--Clean up
----------------------
--Drop Table #Staff
Drop Table #Refferrals
Drop Table #ServedPhases
Drop Table #ActiveClients
--Drop Table #CL
Drop Table #NHVFTE	
GO
