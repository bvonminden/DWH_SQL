USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_OE_Dashboard_APR]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_OE_Dashboard_APR]

	@Startdate date
	, @Enddate date
	, @Team varchar(4000)
	--, @Team_Name VARCHAR(4000)
AS


--declare	@Startdate date
--declare @Enddate date
--declare @Team varchar(4000)

--set	@Startdate = '2013-04-01'
--set @Enddate = '2014-03-31'
--set @Team = 1820

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
--*********************************************************************************
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
--Begin #APRData
--------------------------------------------------------------------------------------
DECLARE 
--	@StartDate		Date 
--	,@EndDate		Date 
	@GestAge INT
	
--SET @StartDate		 = CAST('12/19/2012' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
SET @GestAge			= 36.999999;

-----------------------------------------------------------------------------------
-- udf_OE_ServedPhases into #SP

SELECT 

	AC.ProgramID
		,COUNT(DISTINCT  
				CASE WHEN ISNULL(I.DOB,DATEADD(DAY,1,@EndDate)) > @StartDate
						AND AC.ProgramStartDate <= @EndDate 
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
						AND ISNULL(I.DOB,DATEADD(DAY,1,@EndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_served
		,COUNT(DISTINCT  
				CASE WHEN ISNULL(I.DOB,DATEADD(DAY,1,@EndDate)) > @StartDate
						AND AC.ProgramStartDate <= @EndDate 
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
						AND ISNULL(AC.EndDate,@EndDate) > = I.DOB
						AND I.DOB BETWEEN @StartDate AND @EndDate
						AND ISNULL(I.DOB,DATEADD(DAY,1,@EndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_completed
		,COUNT(DISTINCT  
				CASE WHEN ISNULL(I.DOB,DATEADD(DAY,1,@EndDate)) > @StartDate
						AND AC.ProgramStartDate <= @EndDate 
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@EndDate)) > @EndDate
						AND (I.DOB > @EndDate OR I.DOB IS NULL)
						AND ISNULL(I.DOB,DATEADD(DAY,1,@EndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_still_active
		,COUNT(DISTINCT  
				CASE WHEN ISNULL(I.DOB,DATEADD(DAY,1,@EndDate)) > @StartDate
						AND AC.ProgramStartDate <= @EndDate 
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
						AND AC.EndDate BETWEEN @StartDate AND @EndDate
						AND (AC.EndDate < I.DOB OR I.DOB IS NULL)
						AND ISNULL(I.DOB,DATEADD(DAY,1,@EndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_leftprog
		,COUNT(DISTINCT  
				CASE WHEN ISNULL(I.DOB,DATEADD(DAY,1,@EndDate)) > @EndDate
						AND AC.ProgramStartDate <= @EndDate 
						--AND ISNULL(AC.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
						AND AC.EndDate <= @EndDate
						AND AC.GestAge_EDD BETWEEN @StartDate AND @EndDate
						AND (AC.EndDate < I.DOB OR I.DOB IS NULL)
						AND ISNULL(I.DOB,DATEADD(DAY,1,@EndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_leftprogCHC
		--- Preg_RetainedPercent calculated
		,COUNT(DISTINCT  
				CASE WHEN I.DOB <= @EndDate
						AND I.BD1 > @StartDate
						AND ISNULL(AC.EndDate,@EndDate) > = I.DOB
						AND AC.ProgramStartDate <= @EndDate AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
					 THEN AC.CLID END) Inf_served
		,COUNT(DISTINCT  
				CASE WHEN I.DOB <= @EndDate
						AND I.BD1 > @StartDate
						AND ISNULL(AC.EndDate,@EndDate) > = I.DOB
						AND AC.ProgramStartDate <= @EndDate AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
						AND ISNULL(AC.EndDate,@EndDate) > = I.BD1
						AND I.BD1 BETWEEN @StartDate AND @EndDate
					 THEN AC.CLID END) Inf_completed
		,COUNT(DISTINCT  
				CASE WHEN I.DOB <= @EndDate
						AND I.BD1 > @StartDate
						AND ISNULL(AC.EndDate,@EndDate) > = I.DOB
						AND AC.ProgramStartDate <= @EndDate AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
						AND I.BD1 > @EndDate
						AND I.DOB IS NOT NULL
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@EndDate))> @EndDate
					 THEN AC.CLID END) Inf_still_active
					 
		,COUNT(DISTINCT  
				CASE WHEN I.DOB <= @EndDate
						AND I.BD1 > @StartDate
						AND ISNULL(AC.EndDate,@EndDate) > = I.DOB
						AND AC.ProgramStartDate <= @EndDate AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
						AND AC.EndDate < I.BD1
						AND AC.EndDate BETWEEN @StartDate AND @EndDate
						--AND I.BD1 > @EndDate
					 THEN AC.CLID END) Inf_leftprog
		,COUNT(DISTINCT  
				CASE WHEN I.DOB <= @EndDate
						AND I.BD1 > @StartDate
						AND ISNULL(AC.EndDate,@EndDate) > = I.DOB
						AND AC.ProgramStartDate <= @EndDate --AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
						AND AC.EndDate < I.BD1
						AND I.BD1 BETWEEN @StartDate AND @EndDate
						AND AC.EndDate BETWEEN I.DOB AND @EndDate
						--AND I.BD1 > @EndDate
					 THEN AC.CLID END) Inf_leftprogCHC
		--- Inf_RetainedPercent calcualted
		,COUNT(DISTINCT  
				CASE WHEN I.BD1 <= @EndDate
						AND I.BD2 > @StartDate
						AND ISNULL(AC.EndDate,@EndDate) > = I.BD1
						AND AC.ProgramStartDate <= @EndDate AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
					 THEN AC.CLID END) Tod_served
		,COUNT(DISTINCT  
				CASE WHEN I.BD1 <= @EndDate
						AND I.BD2 > @StartDate
						AND ISNULL(AC.EndDate,@EndDate) > = I.BD1
						AND AC.ProgramStartDate <= @EndDate AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
						AND AC.ReasonForDismissal = 'Child reached 2nd birthday'
						AND AC.EndDate BETWEEN @StartDate AND @EndDate
					 THEN AC.CLID END) Tod_completed
		,COUNT(DISTINCT  
				CASE WHEN I.BD1 <= @EndDate
						AND I.BD2 > @StartDate
						AND ISNULL(AC.EndDate,@EndDate) > = I.BD1
						AND AC.ProgramStartDate <= @EndDate AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@EndDate)) > @EndDate
					 THEN AC.CLID END) Tod_still_active
		,COUNT(DISTINCT  
				CASE WHEN I.BD1 <= @EndDate
						AND I.BD2 > @StartDate
						AND ISNULL(AC.EndDate,@EndDate) > = I.BD1
						AND AC.ProgramStartDate <= @EndDate AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
						AND AC.ReasonForDismissal <> 'Child reached 2nd birthday'
						AND AC.EndDate BETWEEN @StartDate AND @EndDate
					 THEN AC.CLID END) Tod_leftprog
		,COUNT(DISTINCT  
				CASE WHEN I.BD1 <= @EndDate
						AND AC.EndDate BETWEEN I.BD1 AND DATEADD(DAY,-1,I.BD2)
						AND AC.ProgramStartDate <= @EndDate --AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
						AND ISNULL(AC.ReasonForDismissal,'') <> 'Child reached 2nd birthday'
						AND I.BD2 BETWEEN @StartDate AND @EndDate
					 THEN AC.CLID END) Tod_leftprogCHC
		,COUNT(DISTINCT 
				CASE WHEN I.BD2 BETWEEN @StartDate AND @EndDate
					 THEN AC.CLID END) ToddlerSecondBD
		,COUNT(DISTINCT 
				CASE WHEN AC.EndDate BETWEEN @StartDate AND @EndDate
						AND AC.ReasonForDismissal = 'Child reached 2nd birthday'
					 THEN AC.CLID END) ToddlerGraduated

		--- Tod_RetainedPercent calcualted
		,COUNT(DISTINCT  
				CASE WHEN ISNULL(AC.EndDate,@EndDate) > @StartDate 
						AND AC.ProgramStartDate <= @EndDate AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
					 THEN AC.CLID END) Total_served
		,COUNT(DISTINCT  
				CASE WHEN ISNULL(AC.EndDate,@EndDate) > @StartDate 
						AND AC.ProgramStartDate <= @EndDate AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@EndDate)) > @EndDate
					 THEN AC.CLID END) Total_still_active
		,COUNT(DISTINCT  
				CASE WHEN ISNULL(AC.EndDate,@EndDate) > @StartDate 
						AND AC.ProgramStartDate <= @EndDate AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
						AND AC.ReasonForDismissal = 'Child reached 2nd birthday'
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@EndDate)) BETWEEN @StartDate AND @EndDate   
					 THEN AC.CLID END) Total_graduated
		,COUNT(DISTINCT  
				CASE WHEN ISNULL(AC.EndDate,@EndDate) > @StartDate 
						AND AC.ProgramStartDate <= @EndDate AND ISNULL(AC.EndDate,@EndDate) >= @StartDate
						AND AC.ReasonForDismissal <> 'Child reached 2nd birthday'
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@EndDate)) BETWEEN @StartDate AND @EndDate
					 THEN AC.CLID END) Total_leftprog
		--- Total_RetainedPercent calcualted
				
		,COUNT(DISTINCT 
				CASE WHEN 
						(I.BD2 BETWEEN @StartDate AND @EndDate
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@EndDate)) > I.BD2)
						OR
						(AC.ReasonForDismissal = 'Child reached 2nd birthday'
						AND AC.EndDate BETWEEN @StartDate AND @EndDate)
					 THEN AC.CLID END) ToddlerGradorAct
					 
into #SP

FROM

	UV_Fidelity_CLID AC
		LEFT JOIN UV_InfDOB I ON I.CL_EN_GEN_ID = AC.CLID 
		AND I.ProgramID = AC.ProgramID
		AND I.MinSurvDate <= @EndDate
		AND I.MaxSurvDate <= @EndDate

WHERE 

	AC.RankingLatest = 1
	  	
GROUP BY

	AC.ProgramID
	
-------------------------------------------------
--Select * from #SP

--Drop Table #SP
-------------------------------------------------------------------------------------
--

SELECT 

	UV_Fidelity_CLID.ProgramID
	,UV_Fidelity_CLID.Site_ID
	,UV_Fidelity_CLID.StateID
	,COUNT(DISTINCT
				CASE 
					WHEN UV_Fidelity_CLID.DOB BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID END) Eth_BirthTotal
	,COUNT(DISTINCT
				CASE 
					WHEN UV_Fidelity_CLID.GestAge BETWEEN 18 AND @GestAge
						AND UV_Fidelity_CLID.DOB BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID END) TotalPrematureCount
	,0.114 PrematureTarget

	,COUNT(DISTINCT
				CASE 
					WHEN UV_Fidelity_CLID.Grams BETWEEN 430 AND 2499.999999
						AND UV_Fidelity_CLID.O2DOB BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID END) LowWeightCount
	,0.078 LowWeightTarget

	,COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Preg24_Yes BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Preg24_Yes
	,COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Preg24_Data BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Preg24_Data
	,0.25 SubsPreg24Target

Into #Data



FROM

	UV_Fidelity_CLID

		INNER JOIN UV_PAS P ON P.ProgramID = UV_Fidelity_CLID.ProgramID
	
	
GROUP BY 

	UV_Fidelity_CLID.ProgramID
	,UV_Fidelity_CLID.Site_ID
	,UV_Fidelity_CLID.StateID
		
---------------------------------------------		
--Select * From #Data

--drop Table #Data

-------------------------------------------------------------------------------------


SELECT

Distinct

	P.Abbreviation
	, P.Site
	, P.ProgramID 
	, Agencies.AGENCY_INFO_1_COUNTY
	,25 TargetCaseload
	,SUM(#SP.Preg_completed) PregnancyCompleted
	,SUM(#SP.Preg_leftprogCHC) PregnancyLeftCHC
	,0.9 PregRetainedTarget

	,SUM(#SP.Inf_completed) InfancyCompleted
	,SUM(#SP.Inf_leftprogCHC) InfancyLeftCHC
	,0.8 InfRetainedTarget
	
	,SUM(#SP.Tod_completed) ToddlerCompleted
	,SUM(#SP.Tod_leftprogCHC) ToddlerLeftCHC
	,SUM(#SP.ToddlerGradorAct)ToddlerGradorAct
	,0.9 TodRetainedTarget
	
	,SUM(#Data.Eth_BirthTotal)Eth_BirthTotal
	,SUM(#Data.TotalPrematureCount)TotalPrematureCount
	,MAX(#Data.PrematureTarget)PrematureTarget
	
	,SUM(#Data.LowWeightCount)LowWeightCount
	,MAX(#Data.LowWeightTarget)LowWeightTarget

	,SUM(#Data.Preg24_Yes)Preg24_Yes
	,SUM(#Data.Preg24_Data)Preg24_Data
	,MAX(#Data.SubsPreg24Target)SubsPreg24Target
	
Into #APRData

FROM UV_PAS P

	LEFT JOIN (
				SELECT 
					IA_Staff.Site_ID
					,MIN(DW_Completed_Courses.Completion_Date) CompletionDate
				FROM IA_Staff
					INNER JOIN DW_Completed_Courses ON DW_Completed_Courses.Entity_ID = IA_Staff.Entity_Id
				GROUP BY IA_Staff.Site_ID
			 ) S
		ON S.Site_ID = P.SiteID
		
		
		
	LEFT JOIN #Data on #Data.ProgramID = P.ProgramID

	LEFT JOIN #SP on #SP.ProgramID = #Data.ProgramID
		
	LEFT JOIN Agencies  ON Agencies.Site_ID = #Data.Site_ID
	  	
GROUP BY 

	P.Abbreviation
	, P.Site
	, P.ProgramID
	, Agencies.AGENCY_INFO_1_COUNTY 


--End #APRData	
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- #Current Supervisor

SELECT

	Full_Name
	, S.ProgramID
	, S.StateID
	, S.SiteID
	
into #CS

FROM

	(SELECT
	
		Full_Name
		, S.ProgramID
		,S.StateID
		,S.SiteID
		FROM
		
			dbo.fn_FID_Staff_list(@EndDate,@EndDate) S 
		
		WHERE
		
			(S.NS_Flag = 1 and (S.S_FTE is not null and S.S_FTE > 0))
			AND Full_Name IS NOT NULL) S 
---------------------------------------------------------------------------------------------
--Select * from #CS order by ProgramID
--Drop Table #CS
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------Begin #Caseload
------		SELECT
		 
------			StaffxClientHx.StaffID
------			, StaffXEntities.EntityID
------			, StaffxClientHx.ProgramID
------			, COUNT(DISTINCT StaffxClientHx.CLID) as Clients

------		into #CL
		
------		FROM
		
------			StaffxClientHx
------				INNER JOIN StaffXEntities ON StaffxClientHx.StaffID = StaffXEntities.StaffID
			
------		WHERE
		
------			ISNULL(StaffxClientHx.EndDate,@EndDate) > @EndDate
------			AND StaffxClientHx.StartDate <= @EndDate
			
------		GROUP BY
		
------			StaffxClientHx.StaffID,StaffxClientHx.ProgramID,StaffXEntities.EntityID
			
------			--Select * from #CL
------			--Drop Table #CL
-------------------------------------
-------------------------------------

------SELECT

------	S.ProgramID
------	, S.Program_ID_NHV
------	,S.Program_ID_Referrals
------	,S.Program_ID_Staff_Supervision
------	,#CL.Clients
------	,#CL.EntityID
------	,#CL.StaffID
------	, (HV_FTE) ActiveNHV
------	, (CASE
------		WHEN (NHV_Flag = 1 OR ISNULL(HV_FTE,0) > 0)
------		THEN Entity_Id
------		END) as AllNHV
		
------into #Caseload

------FROM

------	dbo.fn_FID_Staff_list ('1/1/1900',@EndDate) S
------	Left Join #CL on #CL.EntityID = S.Entity_Id
------		AND #CL.ProgramID IN (S.Program_ID_NHV,S.Program_ID_Referrals,S.Program_ID_Staff_Supervision)
------	Inner Join UV_PAS PP ON PP.ProgramID = S.ProgramID

------WHERE

------	S.EndDate IS NULL OR S.EndDate > @EndDate
	
--------End #Caseload
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--------------------------------------------------
--#fix removing weird dups

Select MAX(AutoID) as AI, programid 
into #fix
from UC_CaseloadbyQuarter
left join UV_PAS on uv_pas.ProgramID = UC_CaseloadbyQuarter.ParentEntity
where 
		ReportType = 4
		and 
		Month(UC_CaseloadbyQuarter.MyCounter) = Month(@EndDate)
		and Year(UC_CaseloadbyQuarter.MyCounter) = Year(@EndDate)

group by programid

-----------------------------------------

--*********************************************************************************
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- This is the actual query that pulls the recordset for the stored procedure

SELECT

	UV_PAS.Abbreviation 
	, UV_PAS.Site
	, UV_PAS.Team_Name
	, UV_PAS.ProgramID 
	, UV_PAS.AGENCY_INFO_1_INITIATION_DATE 
	, C.ActiveClients
	, C.CountNHVFTE
	, C.CountNHVPositions
	, (C.ActiveClients/C.CountNHVFTE) as Caseload
	--, C.QYear
	--, C.QuarterEndDate
	--, C.ChildEntity ChildEntityID
----------------------------------------
	--, #APRData.[Agency Effective Date]
	--, #APRData.ChildEntity
	, #APRData.Eth_BirthTotal
	, #APRData.InfRetainedTarget
	, #APRData.InfancyCompleted
	, #APRData.InfancyLeftCHC
	, #APRData.LowWeightCount
	, #APRData.LowWeightTarget
	, #APRData.Preg24_Data
	, #APRData.Preg24_Yes
	, #APRData.PregRetainedTarget
	, #APRData.PregnancyCompleted
	, #APRData.PregnancyLeftCHC
	, #APRData.PrematureTarget
	, #APRData.SubsPreg24Target
	, #APRData.TargetCaseload
	, #APRData.TodRetainedTarget
	, #APRData.ToddlerCompleted
	, #APRData.ToddlerLeftCHC
	, #APRData.TotalPrematureCount
	, #APRData.AGENCY_INFO_1_COUNTY
	, #APRData.ToddlerGradorAct
---------------------------------------
	--, #Caseload.Clients CaseloadClients
	--, #Caseload.ActiveNHV CaseloadNHV
---------------------------------------	
	, #CS.Full_Name
FROM

	(Select

		ActiveClients
		, CountNHVFTE
		, CountNHVPositions
		, UV_PAS.ProgramID
		
	From

		UC_CaseloadbyQuarter
		left join UV_PAS on uv_pas.ProgramID = UC_CaseloadbyQuarter.ParentEntity
		inner join #fix on #Fix.AI = UC_CaseloadbyQuarter.AUTOID
		
	Where

		ReportType = 4
		and Month(UC_CaseloadbyQuarter.MyCounter) = Month(@EndDate)
		and Year(UC_CaseloadbyQuarter.MyCounter) = Year(@EndDate)) C

--------------------------------------------------------------------------------------------------------
	Left Join #APRData on #APRData.ProgramID = C.ProgramID
	--Left Join #Caseload on #Caseload.ProgramID = C.ProgramID
	Left Join #CS on #CS.ProgramID = C.ProgramID
	inner Join UV_PAS on UV_PAS.ProgramID = C.ProgramID
---------------------------------------------------------------------------------------------------


Where

	UV_PAS.ProgramID in (SELECT * FROM dbo.udf_ParseMultiParam (@Team)) --SELECT * FROM dbo.udf_ParseMultiParam (@Team)
--*************************************************************************************************
-- Clean up

Drop Table #Data

Drop Table #SP

Drop Table #APRData

--Drop Table #Caseload

Drop Table #CS

--Drop Table #CL

Drop Table #fix
GO
