USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_OE_ClientProgStartDate]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_OE_ClientProgStartDate]

(	@StartDate		Date 
	,@EndDate		Date 
	,@ParentEntity VARCHAR(4000)
	,@REName VARCHAR(50) 
	,@ReportType VARCHAR(50) )

AS

--DECLARE
--	@StartDate		Date 
--	,@EndDate		Date 
--	,@ParentEntity	VARCHAR(4000)
--	,@REName		VARCHAR(50) 
--	,@ReportType	VARCHAR(50) 
--SET @StartDate		= CAST('' AS DATE)
--SET @EndDate		= CAST('' AS DATE)
--SET @ParentEntity	= '6'
--SET @REName			= NULL
--SET @ReportType		= '2'

DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rParentEntity Varchar(4000)
	,@rREName		VARCHAR(50) 
	,@rReportType	VARCHAR(50) 
SET @rStartDate		 = @StartDate
SET @rEndDate		 = @EndDate
SET @rParentEntity	 = @ParentEntity
SET @rREName		 = @REName
SET @rReportType	 = @ReportType




SELECT 
	unpvt.State
	,unpvt.[US State]
	,unpvt.StateID
	,unpvt.AGENCY_INFO_0_NAME
	,unpvt.ProgramID
	,unpvt.ProgramName
	,unpvt.ReportingEntity
	,unpvt.CaseNumber
	,unpvt.ProgramStartDate
	,unpvt.CaseNumber CLID
	,unpvt.DemoSDate
	,unpvt.MatSDate
	,unpvt.HHSDate
	,unpvt.FirstVisit
	,unpvt.SecondVisit
	,CONVERT(VARCHAR(50),Category) Category
	,Error

FROM 


(SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.[SiteID]
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	,DATA.CaseNumber
	,DATA.ProgramStartDate
	,DATA.CLID
	--,DATA.ProgramID
	,DATA.DemoSDate
	,DATA.MatSDate
	,DATA.HHSDate
	,DATA.FirstVisit
	,DATA.SecondVisit
	,CASE 
		WHEN DATA.ProgramStartDate > DATA.FirstVisit THEN 1 
		WHEN DATEDIFF(DAY,DATA.ProgramStartDate,DATA.FirstVisit) BETWEEN 1 AND 30 THEN 2
		WHEN DATEDIFF(DAY,DATA.ProgramStartDate,DATA.FirstVisit) BETWEEN 31 AND 60 THEN 3
		WHEN DATEDIFF(DAY,DATA.ProgramStartDate,DATA.FirstVisit) >= 90 THEN 4
	END FirstVisitErr
	,CASE
		--WHEN DATEDIFF(DAY,DATA.FirstVisit,DATA.SecondVisit) BETWEEN 0 AND 30 THEN 1
		WHEN DATEDIFF(DAY,DATA.FirstVisit,DATA.SecondVisit) BETWEEN 31 AND 60 THEN 2
		WHEN DATEDIFF(DAY,DATA.FirstVisit,DATA.SecondVisit) BETWEEN 61 AND 90 THEN 3
	END SecondVisitErr
	,CASE
		WHEN YEAR(DATA.FirstVisit) < 1996 THEN 1
	END FVB1996
	,CASE
		WHEN DATA.FirstVisit > GETDATE() THEN 1
	END FVAToday
	,CASE
		WHEN DATA.DemoSDate < DATA.FirstVisit OR 
			 DATA.MatSDate < DATA.FirstVisit OR
			 DATA.HHSDate < DATA.FirstVisit
		THEN 1
	END SurveyBFirstVisit


FROM

	(SELECT 
		ROOT.CaseNumber
		,ROOT.ProgramStartDate
		,ROOT.CLID
		,ROOT.ProgramID
		,MIN(ROOT.DemoSDate) DemoSDate
		,MIN(ROOT.MatSDate) MatSDate
		,MIN(ROOT.HHSDate) HHSDate
		,MAX(CASE WHEN ROOT.VisitOrder = 1 THEN SurveyDate END) FirstVisit
		,MAX(CASE WHEN ROOT.VisitOrder = 2 THEN SurveyDate END) SecondVisit
	FROM 
		(SELECT
			EAD.CaseNumber
			,EAD.ProgramStartDate
			,EAD.CLID
			,EAD.ProgramID
			,DS.SurveyDate DemoSDate
			,MS.SurveyDate MatSDate
			,HHS.SurveyDate HHSDate
			,v.SurveyDate
			,Row_Number() OVER(Partition By EAD.CaseNumber,EAD.ProgramStartDate,EAD.CLID,EAD.ProgramID Order By v.SurveyDate) VisitOrder
		FROM UV_EADT EAD
		LEFT OUTER JOIN UC_Fidelity_aHVES v
			ON EAD.CLID = v.CL_EN_GEN_ID
			AND EAD.ProgramID = v.ProgramID
			AND v.CLIENT_COMPLETE_0_VISIT = 'Completed'
		LEFT OUTER JOIN Demographics_Survey DS
			ON dbo.fnGetFormName(DS.SurveyID) = 'Demographics: Pregnancy Intake'
			AND DS.CL_EN_GEN_ID = EAD.CLID
			AND DS.ProgramID = EAD.ProgramID
		LEFT OUTER JOIN Maternal_Health_Survey MS
			ON MS.CL_EN_GEN_ID = EAD.CLID
			AND MS.ProgramID = EAD.ProgramID
		LEFT OUTER JOIN Health_Habits_Survey HHS
			ON dbo.fnGetFormName(HHS.SurveyID) = 'Health Habits: Pregnancy-Intake'
			AND HHS.CL_EN_GEN_ID = EAD.CLID
			AND HHS.ProgramID = EAD.ProgramID
		WHERE EAD.ProgramStartDate >= @rStartDate
		AND EAD.RankingOrig = 1) ROOT

	GROUP BY ROOT.CaseNumber,ROOT.ProgramStartDate,ROOT.CLID,ROOT.ProgramID) DATA

INNER JOIN UV_PAS P
	ON DATA.ProgramID = P.ProgramID

WHERE 
CASE
	WHEN @rReportType = 1 THEN 1
	WHEN @rReportType = 2 THEN P.StateID
	WHEN @rReportType = 3 THEN P.SiteID
	WHEN @rReportType = 4 THEN P.ProgramID
	END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	
) p

UNPIVOT
(Error FOR Category IN
	(p.FirstVisitErr
	,p.SecondVisitErr
	,p.FVB1996
	,p.FVAToday
	,p.SurveyBFirstVisit)
) unpvt
	


GO
